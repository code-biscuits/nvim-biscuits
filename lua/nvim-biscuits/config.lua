local config = {}

config.default_config = function()
    return {
        min_distance = 5,
        max_length = 80,
        prefix_string = " // ",
        -- on_events example: { "InsertLeave", "CursorHoldI" }
        on_events = {},
        trim_by_words = false
    }
end

local function get_default_config(final_config, config_key)
    if final_config == nil then return config.default_config()[config_key] end

    return final_config[config_key]
end

config.get_language_config = function(final_config, language, config_key)

    if final_config == nil then
        return get_default_config(final_config, config_key)
    end

    if final_config.language_config == nil then
        return get_default_config(final_config, config_key)
    end

    if final_config.language_config[language] == nil then
        return get_default_config(final_config, config_key)
    end

    if final_config.language_config[language][config_key] == nil then
        return get_default_config(final_config, config_key)
    end

    return final_config.language_config[language][config_key]

end

return config
