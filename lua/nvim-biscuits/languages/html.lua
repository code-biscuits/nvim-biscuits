local ts_utils = require('nvim-treesitter.ts_utils')
local utils = require("nvim-biscuits.utils")

local language = {}

local function get_node_last_line(ts_node)
  local bufnr = vim.api.nvim_get_current_buf()

  local start_row, start_col, end_row, end_col = ts_utils.get_node_range(ts_node)

  local end_lines = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row+1, false)

  if end_lines == nil then
    return ''
  end

  local end_string = end_lines[1]

  if end_string == nil then
    return ''
  end

  end_string = utils.trim(end_string)
  return end_string
end

language.should_decorate = function (ts_node, text)
  if string.len(text) < 8  then
    local end_string = get_node_last_line(ts_node)
    end_string = string.gsub(end_string, '/', '')

    if text == end_string then
      return false
    end
  end
  return true
end

language.transform_text = function (ts_node, text)
  local end_string = get_node_last_line(ts_node)
  end_string = string.gsub(end_string, '/', '')
  end_string = string.gsub(end_string, '>', '')

  text = string.gsub(text, end_string, '')
  text = string.gsub(text, '>', '')
  text = string.gsub(text, '  ', ' ')

  return utils.trim(text)
end

return language
