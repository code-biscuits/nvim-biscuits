local Path = require("plenary.path")
local json = require "vendor.json"

local dev = {}

local debug_path = '~/vim-biscuits.log'

dev.console_log = function (the_string)
  Path:new(debug_path):write(json.encode(the_string)..'\n', 'a')
end

dev.clear_log = function ()
  Path:new(debug_path):write('', 'w')
end

return dev
