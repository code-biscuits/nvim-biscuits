require('nvim-treesitter')
local utils = require("nvim-biscuits.utils")
local config = require("nvim-biscuits.config")
local languages = require("nvim-biscuits.languages")

local final_config = config.default_config()

local has_ts, _ = pcall(require, 'nvim-treesitter')
if not has_ts then
  error("nvim-treesitter must be installed")
end

local ts_parsers = require('nvim-treesitter.parsers')
local ts_utils = require('nvim-treesitter.ts_utils')
local nvim_biscuits = {}

local decorateNodes = function (bufnr, lang)

  local parser = ts_parsers.get_parser(bufnr, lang)

  if parser == nil then
    utils.console_log('no parser for for '..lang)
    return
  end

  local root = parser:parse()[1]:root()

  local nodes = ts_utils.get_named_children(root)
  local children = {}
  local has_nodes = true

  while has_nodes do
    for index, node in ipairs(nodes) do
      children = utils.merge_arrays(children, ts_utils.get_named_children(node))

      local start_line, start_col, end_line, end_col = ts_utils.get_node_range(node)
      -- local text = ts_utils.get_node_text(node)[1]

      local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line+1, false)

      local text = lines[1]

      if text == nil then
        text = ''
      end

      text = utils.trim(text)

      local should_decorate = true

      if text == '' then
        should_decorate = false
      end

      if string.len(text) <= 1 then
        should_decorate = false
      end

      if start_line == end_line then
        should_decorate = false
      end

      if end_line - start_line < final_config.min_distance then
        should_decorate = false
      end

      if languages.should_decorate(lang, node, text) == false then
        should_decorate = false
      end

      if should_decorate then

        local max_length = config.get_language_config(final_config, lang, "max_length")

        if string.len(text) >= max_length then
          text = string.sub(text, 1, max_length)
          text = text..'...'
        end

        text = text:gsub('"', '\\"')

        text = text:gsub("\n", ' ')

        local prefix_string = config.get_language_config(final_config, lang, "prefix_string")

        -- language specific text filter
        text = languages.transform_text(lang, node, text)

        if utils.trim(text) ~= '' then
          text = prefix_string..text
          local nvim_clear_script = "nvim_buf_clear_namespace("..bufnr..", 0, "..end_line..", "..(end_line + 1)..")"
          vim.api.nvim_eval(nvim_clear_script)

          local nvim_script = "nvim_buf_set_virtual_text("..bufnr..", 0, "..end_line..", [[\""..text.."\"]], [])"
          vim.api.nvim_eval(nvim_script)
        end
      else
        utils.console_log('empty')
      end

    end

    nodes = children
    children = {}

    if table.getn(nodes) == 0 then
      has_nodes = false
    end
  end
end

nvim_biscuits.setup = function (user_config)
  final_config = utils.merge_tables(final_config, user_config)

  if user_config.default_config then
    final_config = utils.merge_tables(final_config, user_config.default_config)
  end

  utils.clear_log()
end

nvim_biscuits.BufferAttach = function()
  local bufnr = vim.fn.bufnr()
  local lang = ts_parsers.get_buf_lang(bufnr)
  decorateNodes(bufnr, lang)

  -- edit event
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines=function(lines_string, edited_bufnr)
      decorateNodes(edited_bufnr, lang)
    end
  })
end

return nvim_biscuits
