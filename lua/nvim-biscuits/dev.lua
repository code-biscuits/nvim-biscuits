local Path = require("plenary.path")

local dev = {}

local debug = false
local debug_path = '~/vim-biscuits.log'

dev.console_log = function (the_string)
  if debug then
    Path:new(debug_path):write(the_string..'\n', 'a')
  end
end

return dev
