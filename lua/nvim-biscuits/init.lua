require('nvim-treesitter')
local utils = require("nvim-biscuits.utils")
local config = require("nvim-biscuits.config")
local languages = require("nvim-biscuits.languages")

local final_config = config.default_config()

local has_ts, _ = pcall(require, 'nvim-treesitter')
if not has_ts then error("nvim-treesitter must be installed") end

local ts_parsers = require('nvim-treesitter.parsers')
local ts_utils = require('nvim-treesitter.ts_utils')
local nvim_biscuits = {should_render_biscuits = true}

local make_biscuit_hl_group_name =
    function(lang)
        return 'BiscuitColor' .. lang
    end

nvim_biscuits.decorate_nodes = function(bufnr, lang)
    if config.get_language_config(final_config, lang, "disabled") then return end

    local parser = ts_parsers.get_parser(bufnr, lang)

    if parser == nil then
        utils.console_log('no parser for ' .. lang)
        return
    end

    local biscuit_highlight_group_name = make_biscuit_hl_group_name(lang)
    local biscuit_highlight_group = vim.api.nvim_create_namespace(
                                        biscuit_highlight_group_name)

    if not nvim_biscuits.should_render_biscuits then
        vim.api.nvim_buf_clear_namespace(bufnr, biscuit_highlight_group, 0, -1)
        return
    end

    local root = parser:parse()[1]:root()

    local nodes = ts_utils.get_named_children(root)
    local children = {}
    local has_nodes = true

    while has_nodes do
        for index, node in ipairs(nodes) do
            children = utils.merge_arrays(children,
                                          ts_utils.get_named_children(node))

            local start_line, start_col, end_line, end_col =
                vim.treesitter.get_node_range(node)

            local lines = vim.api.nvim_buf_get_lines(bufnr, start_line,
                                                     start_line + 1, false)

            local text = lines[1]

            text = utils.trim(text)

            local should_decorate = true

            if text == '' then should_decorate = false end

            if string.len(text) <= 1 then should_decorate = false end

            if start_line == end_line then should_decorate = false end

            if end_line - start_line < final_config.min_distance then
                should_decorate = false
            end

            if languages.should_decorate(lang, node, text, bufnr) == false then
                should_decorate = false
            end

            local cursor = vim.api.nvim_win_get_cursor(0)
            local should_clear = false
            if final_config.cursor_line_only and end_line + 1 ~= cursor[1] then
                should_decorate = false
                should_clear = true
            end

            if should_decorate == true then
                local trim_by_words = config.get_language_config(final_config,
                                                                 lang,
                                                                 "trim_by_words")
                local max_length = config.get_language_config(final_config,
                                                              lang, "max_length")

                if trim_by_words == true then
                    local words = {}
                    for word in string.gmatch(text, "%w+") do
                        words[#words + 1] = word
                        if #words >= max_length then
                            break
                        end
                    end
                    text = table.concat(words, " ")
                else
                    if string.len(text) >= max_length then
                        text = string.sub(text, 1, max_length)
                        text = text .. '...'
                    end
                end

                text = text:gsub("\n", ' ')

                local prefix_string = config.get_language_config(final_config,
                                                                 lang,
                                                                 "prefix_string")

                -- language specific text filter
                text = languages.transform_text(lang, node, text, bufnr)

                if utils.trim(text) ~= '' then
                    text = prefix_string .. text

                    vim.api.nvim_buf_clear_namespace(bufnr,
                                                     biscuit_highlight_group,
                                                     end_line, end_line + 1)
                    vim.api.nvim_buf_set_extmark(bufnr, biscuit_highlight_group,
                                                 end_line, 0, {
                        virt_text_pos = "eol",
                        virt_text = {{text, biscuit_highlight_group_name}},
                        hl_mode = "combine"
                    })
                end
            end

            if should_decorate == false and should_clear == true then
                vim.api.nvim_buf_clear_namespace(bufnr, biscuit_highlight_group,
                                                 end_line, end_line + 1)
            end
        end

        nodes = children
        children = {}

        if table.getn(nodes) == 0 then has_nodes = false end
    end
end

local attached_buffers = {}
nvim_biscuits.BufferAttach = function(bufnr, lang)
    if attached_buffers[bufnr] then return end

    attached_buffers[bufnr] = true

    local toggle_keybind = config.get_language_config(final_config, lang,
                                                      "toggle_keybind")
    if toggle_keybind ~= nil then
        vim.api.nvim_set_keymap("n", toggle_keybind,
                                "<Cmd>lua require('nvim-biscuits').toggle_biscuits()<CR>",
                                { noremap = false, desc = "toggle biscuits" })
    end

    local on_lines = function() nvim_biscuits.decorate_nodes(bufnr, lang) end

    if lang then
    vim.cmd("highlight default link " .. make_biscuit_hl_group_name(lang) ..
                " BiscuitColor")
    end

    -- we need to fire once at the very start if config allows
    if (not toggle_keybind) or config.get_language_config(final_config, lang, "show_on_start") then
        if bufnr then
            nvim_biscuits.decorate_nodes(bufnr, lang)
        end
    else
        nvim_biscuits.should_render_biscuits = false
    end

    local on_events = table.concat(final_config.on_events, ',')
    if on_events ~= "" then
        vim.api.nvim_exec(string.format([[
          augroup Biscuits
            au!
            au %s <buffer=%s> :lua require("nvim-biscuits").decorate_nodes(%s, "%s")
          augroup END
        ]], on_events, bufnr, bufnr, lang), false)
    elseif final_config.cursor_line_only == true then
        vim.api.nvim_exec(string.format([[
          augroup Biscuits
            au!
            au %s <buffer=%s> :lua require("nvim-biscuits").decorate_nodes(%s, "%s")
          augroup END
        ]], "CursorMoved,CursorMovedI", bufnr, bufnr, lang), false)
    else
        vim.api.nvim_buf_attach(bufnr, false,
                                {
            on_lines = on_lines,

            on_detach = function() attached_buffers[bufnr] = nil end
        })
    end
end

nvim_biscuits.setup = function(user_config)
    if user_config == nil then
        user_config = {}
    end

    final_config = utils.merge_tables(final_config, user_config)

    if user_config.default_config then
        final_config = utils.merge_tables(final_config,
                                          user_config.default_config)
    end

    -- This uses the official nvim-treesitter api to attach/detach to buffers
    -- see: https://github.com/nvim-treesitter/nvim-treesitter#adding-modules
    -- the attach/detach functions will not run if the is_supported function
    -- returns false.
    require'nvim-treesitter'.define_modules {
        nvim_biscuits = {
            enable = true,
            attach = function(bufnr, lang)
                nvim_biscuits.BufferAttach(bufnr, lang)
            end,
            detach = function(bufnr)
                attached_buffers[bufnr] = nil
            end,
            is_supported = function(lang)
                return not config.get_language_config(final_config, lang, "disabled")
            end
        }
    }

    utils.clear_log()
end

nvim_biscuits.toggle_biscuits = function()
    nvim_biscuits.should_render_biscuits =
        not nvim_biscuits.should_render_biscuits
    local bufnr = vim.api.nvim_get_current_buf()
    local lang = ts_parsers.get_buf_lang(bufnr):gsub("-", "")
    nvim_biscuits.decorate_nodes(bufnr, lang)
end

return nvim_biscuits
