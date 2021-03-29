local ts_utils = require('nvim-treesitter.ts_utils')
local utils = require("nvim-biscuits.utils")
local html = require("nvim-biscuits.languages.html")

local language = {}

language.should_decorate = function (ts_node, text)
  local should_decorate = html.should_decorate(ts_node, text)
  return should_decorate
end

language.transform_text = function (ts_node, text)
  text = html.transform_text(ts_node, text)
  return utils.trim(text)
end

return language
