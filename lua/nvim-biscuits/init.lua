local utils = require("nvim-biscuits.utils")
local config = require("nvim-biscuits.config")
local languages = require("nvim-biscuits.languages")
local parse = require("vendor.parse")

local final_config = config.default_config()

local nvim_biscuits = { should_render_biscuits = true }
local attached_buffers = {}
local has_fallback_autocmds = false

local function is_file_too_big()
    local file_size = vim.fn.wordcount().bytes

    local max_file_size = final_config.max_file_size
    if final_config.max_file_size == nil then
        max_file_size = 0
    end

    if type(max_file_size) == "string" then
        max_file_size = parse.file_size(max_file_size)
    else
        return nil
    end

    if max_file_size == nil then
        vim.notify(
            "nvim-biscuits: max_file_size is invalid. Valid case-insensitive values include: b, kb, kib, mb, mib, gb, gib, tb, tib, pb, pib"
        )
        max_file_size = 0
    end

    return max_file_size > 0 and file_size > max_file_size
end

local function normalize_language_name(lang)
    if lang == nil then
        return nil
    end

    return lang:gsub("-", "")
end

local function get_buffer_parser_lang(bufnr)
    local filetype = vim.bo[bufnr].filetype
    if filetype == nil or filetype == "" then
        return nil
    end

    if vim.treesitter and vim.treesitter.language and vim.treesitter.language.get_lang then
        local parser_lang = vim.treesitter.language.get_lang(filetype)
        if parser_lang ~= nil and parser_lang ~= "" then
            return parser_lang
        end
    end

    return filetype
end

local function get_named_children(node)
    local nodes = {}
    for i = 0, node:named_child_count() - 1, 1 do
        nodes[i + 1] = node:named_child(i)
    end

    return nodes
end

local make_biscuit_hl_group_name = function(lang)
    return "BiscuitColor" .. lang
end

local function cleanup_buffer_augroup(bufnr)
    local augroup_name = "Biscuits_" .. bufnr
    vim.api.nvim_exec(string.format(
                         [[
                  augroup %s
                    au!
                  augroup END
                  augroup! %s
                ]], augroup_name, augroup_name), false)
end

nvim_biscuits.decorate_nodes = function(bufnr, lang)
    if bufnr == nil then
        bufnr = vim.api.nvim_get_current_buf()
    end

    local parser_lang = lang or get_buffer_parser_lang(bufnr)
    if parser_lang == nil then
        return
    end

    local language_name = normalize_language_name(parser_lang)

    if config.get_language_config(final_config, language_name, "disabled") then
        return
    end

    local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr, parser_lang)
    if not ok_parser or parser == nil then
        utils.console_log("no parser for " .. parser_lang)
        return
    end

    local parsed_trees = parser:parse()
    local root = parsed_trees and parsed_trees[1] and parsed_trees[1]:root()
    if root == nil then
        return
    end

    local biscuit_highlight_group_name = make_biscuit_hl_group_name(language_name)
    local biscuit_highlight_group = vim.api.nvim_create_namespace(
                                        biscuit_highlight_group_name)

    if not nvim_biscuits.should_render_biscuits then
        vim.api.nvim_buf_clear_namespace(bufnr, biscuit_highlight_group, 0, -1)
        return
    end

    local nodes = get_named_children(root)
    local children = {}
    local has_nodes = true

    vim.api.nvim_buf_clear_namespace(bufnr, biscuit_highlight_group, 0, -1)

    while has_nodes do
        for _, node in ipairs(nodes) do
            children = utils.merge_arrays(children, get_named_children(node))

            local start_line, _, end_line, _ = vim.treesitter.get_node_range(node)

            local lines = vim.api.nvim_buf_get_lines(bufnr, start_line,
                                                     start_line + 1, false)

            local text = lines[1]

            text = utils.trim(text)

            local should_decorate = true

            -- bail out of empty text
            if text == "" then
                should_decorate = false
            end

            -- bail out of short text
            if string.len(text) <= 1 then
                should_decorate = false
            end

            -- bail out if start line and end line are the same
            if start_line == end_line then
                should_decorate = false
            end

            -- bail out distance is less than minimum distance
            if end_line - start_line < final_config.min_distance then
                should_decorate = false
            end

            -- bail out if this node should not be decorated based on language specific filters
            if languages.should_decorate(language_name, node, text, bufnr) == false then
                should_decorate = false
            end

            -- bail out if the user has cursor line only on and we are not on their cursor line
            local cursor = vim.api.nvim_win_get_cursor(0)
            local should_clear = false
            if final_config.cursor_line_only and end_line + 1 ~= cursor[1] then
                should_decorate = false
                should_clear = true
            end

            if should_decorate == true then
                local trim_by_words = config.get_language_config(final_config,
                                                                 language_name,
                                                                 "trim_by_words")
                local max_length = config.get_language_config(final_config,
                                                              language_name,
                                                              "max_length")

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
                        text = text .. "..."
                    end
                end

                text = text:gsub("\n", " ")

                local prefix_string = config.get_language_config(final_config,
                                                                 language_name,
                                                                 "prefix_string")

                -- language specific text filter
                text = languages.transform_text(language_name, node, text, bufnr)

                if utils.trim(text) ~= "" then
                    text = prefix_string .. text

                    -- Get the line count of the buffer
                    local line_count = vim.api.nvim_buf_line_count(bufnr)

                    -- Only set extmark if the line is within buffer bounds
                    if end_line < line_count then
                        vim.api.nvim_buf_clear_namespace(bufnr,
                                                         biscuit_highlight_group,
                                                         end_line, end_line + 1)
                        vim.api.nvim_buf_set_extmark(bufnr,
                                                     biscuit_highlight_group,
                                                     end_line, 0, {
                            virt_text_pos = "eol",
                            virt_text = {
                                { text, biscuit_highlight_group_name }
                            },
                            hl_mode = "combine"
                        })
                    end
                end
            end

            if should_decorate == false and should_clear == true then
                vim.api.nvim_buf_clear_namespace(bufnr, biscuit_highlight_group,
                                                 end_line, end_line + 1)
            end
        end

        nodes = children
        children = {}

        if #nodes == 0 then
            has_nodes = false
        end
    end
end

nvim_biscuits.BufferAttach = function(bufnr, lang)
    if bufnr == nil then
        bufnr = vim.api.nvim_get_current_buf()
    end

    local parser_lang = lang or get_buffer_parser_lang(bufnr)
    if parser_lang == nil then
        return
    end

    local language_name = normalize_language_name(parser_lang)

    local has_parser = pcall(vim.treesitter.get_parser, bufnr, parser_lang)
    if not has_parser then
        return
    end

    if attached_buffers[bufnr] then
        return
    end

    attached_buffers[bufnr] = true

    local toggle_keybind = config.get_language_config(final_config, language_name,
                                                      "toggle_keybind")
    if toggle_keybind ~= nil then
        vim.api.nvim_set_keymap("n", toggle_keybind,
                                "<Cmd>lua require('nvim-biscuits').toggle_biscuits()<CR>",
                                { noremap = false, desc = "toggle biscuits" })
    end

    if is_file_too_big() then
        vim.notify_once(
            "nvim-biscuits: File is larger than configured max_file_size")
        return
    end

    local on_lines = function()
        nvim_biscuits.decorate_nodes(bufnr, parser_lang)
    end

    vim.cmd("highlight default link " ..
                make_biscuit_hl_group_name(language_name) .. " BiscuitColor")

    -- we need to fire once at the very start if config allows
    if (not toggle_keybind) or
        config.get_language_config(final_config, language_name, "show_on_start") then
        nvim_biscuits.decorate_nodes(bufnr, parser_lang)
    else
        nvim_biscuits.should_render_biscuits = false
    end

    local on_events = table.concat(final_config.on_events, ",")
    local augroup_name = "Biscuits_" .. bufnr
    if on_events ~= "" then
        vim.api.nvim_exec(string.format(
                             [[
          augroup %s
            au!
            au %s <buffer=%s> :lua require("nvim-biscuits").decorate_nodes(%s, "%s")
          augroup END
        ]], augroup_name, on_events, bufnr, bufnr, parser_lang), false)
    elseif final_config.cursor_line_only == true then
        vim.api.nvim_exec(string.format(
                             [[
          augroup %s
            au!
            au %s <buffer=%s> :lua require("nvim-biscuits").decorate_nodes(%s, "%s")
          augroup END
        ]], augroup_name, "CursorMoved,CursorMovedI", bufnr, bufnr,
                                 parser_lang), false)
    else
        vim.api.nvim_buf_attach(bufnr, false, {
            on_lines = on_lines,

            on_detach = function()
                attached_buffers[bufnr] = nil
                cleanup_buffer_augroup(bufnr)
            end
        })
    end
end

local function register_fallback_attach()
    if has_fallback_autocmds then
        return
    end

    has_fallback_autocmds = true

    local group = vim.api.nvim_create_augroup("NvimBiscuitsAutoAttach",
                                               { clear = true })

    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].buftype ~= "" then
                return
            end

            nvim_biscuits.BufferAttach(args.buf)
        end,
        desc = "Auto attach nvim-biscuits"
    })

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "" then
            nvim_biscuits.BufferAttach(bufnr)
        end
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

    -- Use legacy nvim-treesitter module registration when available.
    local has_ts, nvim_treesitter = pcall(require, "nvim-treesitter")
    if has_ts and type(nvim_treesitter.define_modules) == "function" then
        nvim_treesitter.define_modules {
            nvim_biscuits = {
                enable = true,
                attach = function(bufnr, lang)
                    nvim_biscuits.BufferAttach(bufnr, lang)
                end,
                detach = function(bufnr)
                    attached_buffers[bufnr] = nil
                    cleanup_buffer_augroup(bufnr)
                end,
                is_supported = function(lang)
                    local language_name = normalize_language_name(lang)
                    if language_name == nil then
                        return true
                    end
                    return not config.get_language_config(final_config,
                                                          language_name,
                                                          "disabled")
                end
            }
        }
    else
        register_fallback_attach()
    end

    utils.clear_log()
end

nvim_biscuits.toggle_biscuits = function()
    if is_file_too_big() then
        vim.notify("nvim-biscuits: File is larger than configured max_file_size")
        return
    end

    nvim_biscuits.should_render_biscuits = not nvim_biscuits.should_render_biscuits
    local bufnr = vim.api.nvim_get_current_buf()
    local parser_lang = get_buffer_parser_lang(bufnr)
    if parser_lang == nil then
        return
    end

    nvim_biscuits.decorate_nodes(bufnr, parser_lang)
end

return nvim_biscuits
