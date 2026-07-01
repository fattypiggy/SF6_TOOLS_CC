local json = json

local CharacterRules = {
    name = "ComboTrials.CharacterRules"
}

local EXCEPTION_DIR = "TrainingComboTrials_data/exceptions"
local COMMON_EXCEPTIONS_FILE = EXCEPTION_DIR .. "/Common.json"

function CharacterRules.get_exception_filename(character_name)
    return EXCEPTION_DIR .. "/" .. tostring(character_name or ""):gsub("[^%w_]", "") .. ".json"
end

function CharacterRules.load_common()
    local common_exceptions = {}
    pcall(function()
        local loaded = _G.safe_load_json(COMMON_EXCEPTIONS_FILE)
        if loaded then common_exceptions = loaded end
    end)
    return common_exceptions
end

function CharacterRules.load_for_character(character_name)
    local loaded = json.load_file(CharacterRules.get_exception_filename(character_name))
    if loaded then return loaded end
    return {}
end

function CharacterRules.get_exception(character_rules, common_rules, action_id)
    local id = tostring(action_id)
    local character_exception = character_rules and character_rules[id] or nil
    local common_exception = common_rules and common_rules[id] or nil
    return character_exception or common_exception, character_exception, common_exception
end

function CharacterRules.has_character_exception(character_rules, action_id)
    return character_rules and character_rules[tostring(action_id)] and true or false
end

function CharacterRules.apply_runtime_overrides(character_name, action_id, exception, log)
    if character_name == "Cammy" and (action_id == 908 or action_id == 922) then
        if #log > 0 and (log[1].id == 652 or log[1].id == 653 or log[1].id == 926) then
            if not exception then exception = {} end
            exception.force = true
            if action_id == 908 then
                exception.override_name = "236+HK"
            elseif action_id == 922 then
                exception.override_name = "623+HK"
            end
        end
    end
    return exception
end

return CharacterRules
