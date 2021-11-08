local html = require("nvim-biscuits.languages.html")
local vue = require("nvim-biscuits.languages.vue")
local javascript = require("nvim-biscuits.languages.javascript")
local python = require("nvim-biscuits.languages.python")
local utils = require("nvim-biscuits.utils")

local languages = {}

local handled_languages = {
    html = html,
    javascript = javascript,
    vue = vue,
    python = python
}

languages.should_decorate = function(language_name, ts_node, text)
    local language = handled_languages[language_name]

    if language == nil then return true end

    return language.should_decorate(ts_node, text)
end

languages.transform_text = function(language_name, ts_node, text)
    local language = handled_languages[language_name]
    if language == nil then return text end

    return language.transform_text(ts_node, text)
end

return languages
