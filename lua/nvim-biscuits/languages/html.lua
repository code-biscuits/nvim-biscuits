local utils = require("nvim-biscuits.utils")

local language = {}

local function get_node_last_line(ts_node)
    local bufnr = vim.api.nvim_get_current_buf()

    local start_row, start_col, end_row, end_col =
        vim.treesitter.get_node_range(ts_node)

    local end_lines = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1,
                                                 false)

    if end_lines == nil then return '' end

    local end_string = end_lines[1]

    if end_string == nil then return '' end

    end_string = utils.trim(end_string)
    return end_string
end

language.should_decorate = function(ts_node, text, bufnr)
    if string.len(text) < 8 then
        local end_string = get_node_last_line(ts_node)
        end_string = string.gsub(end_string, '/', '')

        if text == end_string then return false end
    end

    local elements = {
        "element", "jsx_element", "self_closing_element",
        "jsx_self_closing_element"
    }

    if utils.list_contains(elements, ts_node:type()) then return true end

    return false
end

language.transform_text = function(ts_node, text, bufnr)

    local end_string = get_node_last_line(ts_node)
    end_string = string.gsub(end_string, '/', '')
    end_string = string.gsub(end_string, '>', '')

    pcall(function() text = string.gsub(text, end_string, '') end)

    text = string.gsub(text, '>', '')
    text = string.gsub(text, '  ', ' ')

    text = utils.trim(text)

    if text == '<p className="p0"' then
        local type = ts_node:type()
        local parent = ts_node:parent()
        utils.console_log("-----------------------------------------------")
        utils.console_log("HTML type: " .. type)
        utils.console_log("HTML Parent type: " .. parent:type())
        utils.console_log("HTML text: " .. text)
        -- utils.console_log("JS name: " .. ts_node:named())
        -- utils.console_log("JS sexpr: " .. ts_node:sexpr())
        utils.console_log("-----------------------------------------------")
    end
    return text
end

return language
