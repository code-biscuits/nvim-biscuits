local Path = require("plenary.path")

local utils = {}

local debug = false
local debug_path = '~/vim-biscuits.log'

utils.console_log = function (the_string)
  if debug then
    Path:new(debug_path):write(the_string..'\n', 'a')
  end
end

utils.merge_arrays = function(a, b)
  local result = {unpack(a)}
  table.move(b, 1, #b, #result + 1, result)
  return result
end

utils.merge_tables = function(t1, t2)
  for k,v in pairs(t2) do
      if type(v) == "table" then
          if type(t1[k] or false) == "table" then
              tableMerge(t1[k] or {}, t2[k] or {})
          else
              t1[k] = v
          end
      else
          t1[k] = v
      end
  end
  return t1
end

utils.trim = function(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

utils.clear_log = function ()
  if debug == true then
    Path:new(debug_path):write('', 'w')
  end
end

return utils
