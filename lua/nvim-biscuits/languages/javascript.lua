local ts_utils = require('nvim-treesitter.ts_utils')
local utils = require("nvim-biscuits.utils")
local html = require("nvim-biscuits.languages.html")

local language = {}

language.should_decorate = function(ts_node, text, bufnr)
    local type = ts_node:type()
    local elements = {"jsx_element", "jsx_self_closing_element"}

    local should_decorate = true
    if utils.list_contains(elements, type) then
        should_decorate = html.should_decorate(ts_node, text, bufnr)
    end

    local ignored_element_types = {
        -- "identifier"
        "jsx_text"
    }

    if utils.list_contains(ignored_element_types, type) then
        should_decorate = false
    end

    return should_decorate
end

language.transform_text = function(ts_node, text, bufnr)
    text = html.transform_text(ts_node, text, bufnr)
    return utils.trim(text)
end

return language
