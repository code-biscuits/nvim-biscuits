local utils = require("nvim-biscuits.utils")

local language = {}

language.should_decorate = function(ts_node, text, bufnr)
    local should_decorate = true
    return should_decorate
end

language.transform_text = function(ts_node, text, bufnr)
    local start_line, start_col, end_line, end_col =
        vim.treesitter.get_node_range(ts_node)
    local parent_start_line, parent_start_col, parent_end_line, parent_end_col =
        vim.treesitter.get_node_range(ts_node:parent())
    if parent_start_line == start_line - 1 then
        start_line = parent_start_line
        start_col = parent_start_col
        end_line = parent_end_line
        end_col = parent_end_col
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 1,
                                             false)
    local text = lines[1]

    -- text = html.transform_text(ts_node, text, bufnr)
    return utils.trim(text)
end

return language
