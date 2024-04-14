local utils = {}

local is_debug_mode = os.getenv("DEBUG")

if is_debug_mode then Dev = require("nvim-biscuits.dev") end

utils.console_log = function(the_string)
    if is_debug_mode then Dev.console_log(the_string) end
end

utils.clear_log = function() if is_debug_mode then Dev.clear_log() end end

utils.clone_table = function(_table)
    local new_table = { }
    for k, v in pairs(_table) do new_table[k] = v end
    return setmetatable(new_table, getmetatable(_table))
end

utils.merge_arrays = function(a, b)
    local result = utils.clone_table(a)
    for i = 1, #b do result[#a + i] = b[i] end
    return result
end

utils.merge_tables = function(t1, t2)
    for k, v in pairs(t2) do t1[k] = v end
    return t1
end

utils.merge_tables_deep = function(t1, t2)
    for k, v in pairs(t2) do
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
    if s == nil then return '' end
    return s:match '^()%s*$' and '' or s:match '^%s*(.*%S)'
end

utils.list_contains = function(list, needle)
    for index, value in ipairs(list) do
        if value == needle then return true; end
    end

    return false;
end

return utils
