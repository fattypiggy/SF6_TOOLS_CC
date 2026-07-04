-- DynamicRecords.lua
-- Minimal import/export helpers for SF6 training dynamic record slots.

local sdk = sdk
local json = json
local fs = fs
local os = os

local M = {}
local JSON_NULL = json and (json.null or json.NULL) or nil

M.SCHEMA = "sf6cc.dynamic_records.v1"
M.DATA_DIR = "SF6CC_DynamicRecords"
M.BACKUP_DIR = M.DATA_DIR .. "/backups"
M.EXPORT_PATH = M.DATA_DIR .. "/export_current.json"
M.IMPORT_PATH = M.DATA_DIR .. "/import.json"
M.LATEST_BACKUP_PATH = M.DATA_DIR .. "/latest_backup.json"
M._last_backup_path = nil

local SOURCE_PLAYER = "P2"
local SOURCE_PLAYER_INDEX = 1
local SLOT_COUNT = 8
local write_latest_backup_marker

local CHARACTER_NAMES = {
    [1] = "Ryu",        [2] = "Luke",       [3] = "Kimberly",   [4] = "Chun-Li",
    [5] = "Manon",      [6] = "Zangief",    [7] = "JP",         [8] = "Dhalsim",
    [9] = "Cammy",      [10] = "Ken",       [11] = "Dee Jay",   [12] = "Lily",
    [13] = "A.K.I",     [14] = "Rashid",    [15] = "Blanka",    [16] = "Juri",
    [17] = "Marisa",    [18] = "Guile",     [19] = "Ed",        [20] = "E. Honda",
    [21] = "Jamie",     [22] = "Akuma",     [23] = "M. Bison",  [24] = "Terry",
    [25] = "Sagat",     [26] = "M. Bison",  [27] = "Terry",     [28] = "Mai",
    [29] = "Elena",     [30] = "Viper",
}

local cached_context = {
    fighter_id = nil,
    fighter_name = "",
    source_player = SOURCE_PLAYER,
}

local function ensure_dirs()
    if fs and fs.create_dir then
        pcall(fs.create_dir, M.DATA_DIR)
        pcall(fs.create_dir, M.BACKUP_DIR)
    end
end

local function now_display()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function now_stamp()
    return os.date("%Y%m%d_%H%M%S")
end

local function as_int(value, default)
    local n = tonumber(value)
    if n == nil then return default end
    return math.floor(n)
end

local function get_char_name(fighter_id)
    return CHARACTER_NAMES[fighter_id] or ("Unknown(" .. tostring(fighter_id) .. ")")
end

local function get_collection_item(collection, index)
    if not collection then return nil end

    local ok, item = pcall(function() return collection:call("get_Item", index) end)
    if ok and item then return item end

    ok, item = pcall(function() return collection[index] end)
    if ok then return item end

    return nil
end

local function read_selected_fighter_id()
    local mgr = sdk.get_managed_singleton("app.training.TrainingManager")
    if not mgr then return nil, "No TrainingManager" end

    local t_data = mgr:get_field("_tData")
    if not t_data then return nil, "No TrainingManager._tData" end

    local select_menu = t_data:get_field("SelectMenu")
    if not select_menu then return nil, "No SelectMenu" end

    local player_datas = select_menu:get_field("PlayerDatas")
    if not player_datas then return nil, "No SelectMenu.PlayerDatas" end

    local player_data = get_collection_item(player_datas, SOURCE_PLAYER_INDEX)
    if not player_data then return nil, "No P2 PlayerData" end

    local fighter_id = as_int(player_data:get_field("FighterID"), nil)
    if fighter_id == nil then return nil, "No P2 FighterID" end

    return fighter_id, nil
end

function M.get_context()
    local fighter_id, err = read_selected_fighter_id()
    if fighter_id ~= nil then
        cached_context.fighter_id = fighter_id
        cached_context.fighter_name = get_char_name(fighter_id)
        cached_context.source_player = SOURCE_PLAYER
        return cached_context
    end

    return {
        fighter_id = cached_context.fighter_id,
        fighter_name = cached_context.fighter_name,
        source_player = SOURCE_PLAYER,
        error = err,
    }
end

local function get_record_func()
    local mgr = sdk.get_managed_singleton("app.training.TrainingManager")
    if not mgr then return nil, "No TrainingManager" end

    local rec_func = mgr:call("get_RecordFunc")
    if not rec_func then return nil, "No RecordFunc" end

    return rec_func, nil
end

local function get_slots_for_fighter(fighter_id)
    if fighter_id == nil then return nil, "No fighter_id" end

    local rec_func, rec_err = get_record_func()
    if not rec_func then return nil, rec_err end

    local t_data = rec_func:get_field("_tData")
    if not t_data then return nil, "No RecordFunc._tData" end

    local record_setting = t_data:get_field("RecordSetting")
    if not record_setting then return nil, "No RecordSetting" end

    local fighter_list = record_setting:get_field("FighterDataList")
    if not fighter_list then return nil, "No FighterDataList" end

    local fighter_data = get_collection_item(fighter_list, fighter_id)
    if not fighter_data then return nil, "No FighterData for id " .. tostring(fighter_id) end

    local slots = fighter_data:get_field("RecordSlots")
    if not slots then return nil, "No RecordSlots" end

    return slots, nil, rec_func
end

local function get_current_slots()
    local ctx = M.get_context()
    if ctx.error and ctx.fighter_id == nil then return nil, ctx.error, ctx end

    local slots, err, rec_func = get_slots_for_fighter(ctx.fighter_id)
    if not slots then return nil, err, ctx end

    return slots, nil, ctx, rec_func
end

local function get_bool_field(obj, name)
    local raw = obj:get_field(name)
    return raw == true or raw == 1
end

local function get_buffer(input_data)
    if not input_data then return nil end
    return input_data:get_field("buff")
end

local function get_buffer_length(buffer)
    if not buffer then return 0 end
    local ok, len = pcall(function() return buffer:call("get_Length") end)
    if ok and len then return as_int(len, 0) end
    return 0
end

local function read_buffer_values(buffer, frames)
    local values = {}
    local length = get_buffer_length(buffer)
    local read_count = math.min(math.max(as_int(frames, 0) or 0, 0), length)

    for index = 0, read_count - 1 do
        local ok, raw = pcall(function() return buffer:call("GetValue", index) end)
        local value = 0
        if ok and raw then
            value = as_int(raw:get_field("mValue"), 0)
        end
        values[#values + 1] = value
    end

    return values, length
end

local function collect_slot(slot_obj, slot_number, include_buff)
    local frame = as_int(slot_obj:get_field("Frame"), 0) or 0
    local weight = as_int(slot_obj:get_field("Weight"), 0) or 0
    local input_data = slot_obj:get_field("InputData")
    local input_num = input_data and as_int(input_data:get_field("Num"), frame) or frame
    local buffer = get_buffer(input_data)
    local input_buff = {}
    local capacity = get_buffer_length(buffer)

    if include_buff and buffer then
        input_buff, capacity = read_buffer_values(buffer, frame)
    end

    return {
        slot = slot_number,
        name = "slot" .. tostring(slot_number),
        is_valid = get_bool_field(slot_obj, "IsValid"),
        is_active = get_bool_field(slot_obj, "IsActive"),
        frame = frame,
        weight = weight,
        input_num = input_num or frame,
        input_buff = include_buff and input_buff or nil,
        capacity = capacity,
    }
end

local function collect_snapshot(include_buff)
    local slots, err, ctx = get_current_slots()
    if not slots then return nil, err end

    local out_slots = {}
    for index = 0, SLOT_COUNT - 1 do
        local slot_obj = get_collection_item(slots, index)
        if not slot_obj then return nil, "Missing slot " .. tostring(index + 1) end
        out_slots[#out_slots + 1] = collect_slot(slot_obj, index + 1, include_buff)
    end

    return {
        schema = M.SCHEMA,
        created_at = now_display(),
        fighter_id = ctx.fighter_id,
        fighter_name = ctx.fighter_name,
        source_player = ctx.source_player,
        slots = out_slots,
        settings = {
            play_info_display = JSON_NULL,
            repeat_playback = JSON_NULL,
        },
    }, nil
end

function M.get_slot_summaries()
    local snapshot, err = collect_snapshot(false)
    if not snapshot then return nil, err end
    return snapshot.slots, nil, snapshot
end

local function dump_snapshot(path, include_buff)
    ensure_dirs()
    local snapshot, err = collect_snapshot(include_buff)
    if not snapshot then return nil, err end

    local ok, write_result = pcall(json.dump_file, path, snapshot)
    if not ok then return nil, tostring(write_result) end
    if write_result == false then return nil, "json.dump_file returned false" end

    return snapshot, nil
end

function M.export_current(path)
    local out_path = path or M.EXPORT_PATH
    local snapshot, err = dump_snapshot(out_path, true)
    if not snapshot then return false, err end
    return true, "Exported: data/" .. out_path, out_path, snapshot
end

function M.backup_current()
    local stamp = now_stamp()
    local path = M.BACKUP_DIR .. "/records_backup_" .. stamp .. ".json"
    local suffix = 1
    while json.load_file(path) do
        path = M.BACKUP_DIR .. "/records_backup_" .. stamp .. "_" .. string.format("%03d", suffix) .. ".json"
        suffix = suffix + 1
    end

    local snapshot, err = dump_snapshot(path, true)
    if not snapshot then return false, err end
    local marker_ok, marker_err = write_latest_backup_marker(path, stamp)
    if not marker_ok then
        return false, "Backup saved but latest marker failed: " .. tostring(marker_err)
    end
    return true, "Backup saved: data/" .. path, path, snapshot
end

local function normalize_slot_number(raw_slot, fallback_index)
    local slot_number = as_int(raw_slot, nil)
    if slot_number == nil then slot_number = fallback_index end
    if slot_number < 1 or slot_number > SLOT_COUNT then return nil end
    return slot_number
end

local function normalize_input_value(value)
    local n = tonumber(value)
    if n == nil then return nil end
    n = math.floor(n)
    if n < 0 or n > 0xFFFF then return nil end
    return n
end

local function has_importable_input(slot_data)
    return type(slot_data.input_buff) == "table" and #slot_data.input_buff > 0
end

local function should_write_slot(slot_data, options)
    if slot_data.is_valid == true then return true end
    if options.only_import_valid == true then return false end
    return has_importable_input(slot_data)
end

local function validate_slot_for_import(index, slot_data, slots, options, seen_slots)
    if type(slot_data) ~= "table" then
        return nil, "slot entry " .. tostring(index) .. " is not an object"
    end

    local slot_number = normalize_slot_number(slot_data.slot or slot_data.id, index)
    if not slot_number then
        return nil, "slot entry " .. tostring(index) .. " has invalid slot number"
    end

    if seen_slots[slot_number] then
        return nil, "duplicate slot " .. tostring(slot_number)
    end
    seen_slots[slot_number] = true

    local source_valid = slot_data.is_valid == true
    local write_slot = should_write_slot(slot_data, options)
    local clear_slot = (not source_valid) and options.clear_empty_slots == true

    if not write_slot and not clear_slot then
        return false, nil
    end

    local slot_obj = get_collection_item(slots, slot_number - 1)
    if not slot_obj then
        return nil, "slot " .. tostring(slot_number) .. " not found in game data"
    end

    if clear_slot and not write_slot then
        return {
            kind = "clear",
            slot = slot_number,
            slot_obj = slot_obj,
            weight = as_int(slot_data.weight, nil),
        }, nil
    end

    if type(slot_data.input_buff) ~= "table" then
        return nil, "slot " .. tostring(slot_number) .. " input_buff is not an array"
    end

    local frame = as_int(slot_data.frame, nil)
    local input_num = as_int(slot_data.input_num, nil)
    local buff_len = #slot_data.input_buff

    if frame == nil then frame = buff_len end
    if input_num == nil then input_num = frame end

    if frame < 0 or input_num < 0 then
        return nil, "slot " .. tostring(slot_number) .. " has negative frame/input_num"
    end

    if frame > buff_len or input_num > buff_len then
        return nil, "slot " .. tostring(slot_number) .. " frame/input_num exceeds input_buff length"
    end

    local input_data = slot_obj:get_field("InputData")
    local buffer = get_buffer(input_data)
    local capacity = get_buffer_length(buffer)

    if not input_data or not buffer then
        return nil, "slot " .. tostring(slot_number) .. " has no InputData.buff"
    end

    if buff_len > capacity then
        return nil, "slot " .. tostring(slot_number)
            .. " input_buff length " .. tostring(buff_len)
            .. " exceeds capacity " .. tostring(capacity)
    end

    local normalized_buff = {}
    for buff_index = 1, buff_len do
        local n = normalize_input_value(slot_data.input_buff[buff_index])
        if n == nil then
            return nil, "slot " .. tostring(slot_number)
                .. " has invalid input value at " .. tostring(buff_index)
        end
        normalized_buff[buff_index] = n
    end

    return {
        kind = "write",
        slot = slot_number,
        slot_obj = slot_obj,
        input_data = input_data,
        buffer = buffer,
        is_valid = slot_data.is_valid == true,
        is_active = slot_data.is_active == true,
        frame = frame,
        weight = as_int(slot_data.weight, 0) or 0,
        input_num = input_num,
        input_buff = normalized_buff,
    }, nil
end

local function build_import_plan(data, slots, options)
    local plan = {}
    local errors = {}
    local seen_slots = {}

    if type(data) ~= "table" then
        return nil, { "Import JSON root is not an object" }
    end

    if data.schema ~= M.SCHEMA then
        return nil, { "Schema mismatch: " .. tostring(data.schema) }
    end

    local ctx = M.get_context()
    if options.reject_fighter_mismatch ~= false then
        if as_int(data.fighter_id, nil) ~= as_int(ctx.fighter_id, nil) then
            return nil, {
                "fighter_id mismatch: file=" .. tostring(data.fighter_id)
                    .. " current=" .. tostring(ctx.fighter_id)
            }
        end
    end

    if type(data.slots) ~= "table" then
        return nil, { "slots is not an array" }
    end

    for index, slot_data in ipairs(data.slots) do
        local step, err = validate_slot_for_import(index, slot_data, slots, options, seen_slots)
        if err then
            errors[#errors + 1] = err
        elseif step then
            plan[#plan + 1] = step
        end
    end

    if #errors > 0 then return nil, errors end
    return plan, nil
end

local function validate_import_header(data, options)
    if type(data) ~= "table" then
        return false, "Import JSON root is not an object"
    end

    if data.schema ~= M.SCHEMA then
        return false, "Schema mismatch: " .. tostring(data.schema)
    end

    if type(data.slots) ~= "table" then
        return false, "slots is not an array"
    end

    local ctx = M.get_context()
    if options.reject_fighter_mismatch ~= false then
        if as_int(data.fighter_id, nil) ~= as_int(ctx.fighter_id, nil) then
            return false, "fighter_id mismatch: file=" .. tostring(data.fighter_id)
                .. " current=" .. tostring(ctx.fighter_id)
        end
    end

    return true, nil
end

local function apply_import_plan(plan)
    local written = 0
    local cleared = 0

    for _, step in ipairs(plan) do
        if step.kind == "clear" then
            if step.weight ~= nil then step.slot_obj:set_field("Weight", step.weight) end
            step.slot_obj:set_field("IsValid", false)
            step.slot_obj:set_field("IsActive", false)
            step.slot_obj:set_field("Frame", 0)
            local input_data = step.slot_obj:get_field("InputData")
            if input_data then input_data:set_field("Num", 0) end
            cleared = cleared + 1
        elseif step.kind == "write" then
            step.slot_obj:set_field("Weight", step.weight)
            step.slot_obj:set_field("IsActive", step.is_active)
            step.slot_obj:set_field("Frame", step.frame)
            step.input_data:set_field("Num", step.input_num)

            for index, value in ipairs(step.input_buff) do
                step.buffer:call("SetValue", sdk.create_uint16(value), index - 1)
            end

            step.slot_obj:set_field("IsValid", step.is_valid)
            written = written + 1
        end
    end

    return written, cleared
end

local function force_apply(rec_func)
    if not rec_func then return true, "No RecordFunc" end
    local ok, err = pcall(function() rec_func:call("ForceApply") end)
    if ok then return true, "ForceApply OK" end
    return false, tostring(err)
end

function M.import_from_file(path, options)
    ensure_dirs()
    options = options or {}

    local data = json.load_file(path or M.IMPORT_PATH)
    if not data then return false, "Import file not found: data/" .. (path or M.IMPORT_PATH) end

    local header_ok, header_err = validate_import_header(data, options)
    if not header_ok then return false, "Import rejected: " .. tostring(header_err) end

    local backup_ok, backup_msg, backup_path = M.backup_current()
    if not backup_ok then return false, "Backup failed before import: " .. tostring(backup_msg) end

    local slots, slots_err, _, rec_func = get_current_slots()
    if not slots then return false, "Import aborted after backup. " .. tostring(slots_err) end

    local plan, plan_errors = build_import_plan(data, slots, options)
    if not plan then
        return false, "Import aborted after backup. " .. table.concat(plan_errors, " | "), backup_path
    end

    local ok, write_result_or_err, clear_count_or_nil = pcall(function()
        local written, cleared = apply_import_plan(plan)
        return written, cleared
    end)
    if not ok then
        return false, "Import crashed after backup: " .. tostring(write_result_or_err), backup_path
    end

    local written = write_result_or_err or 0
    local cleared = clear_count_or_nil or 0
    local force_msg = "ForceApply skipped"
    if options.force_apply_after_import == true then
        local force_ok, force_err = force_apply(rec_func)
        force_msg = force_ok and "ForceApply OK" or ("ForceApply failed: " .. tostring(force_err))
    end

    return true,
        "Imported " .. tostring(written) .. " slot(s), cleared " .. tostring(cleared)
            .. ". Backup: data/" .. tostring(backup_path) .. ". " .. force_msg,
        backup_path
end

local function normalize_glob_path(path)
    if type(path) ~= "string" then return nil end
    local normalized = path:gsub("\\", "/")
    local data_prefix = "/data/"
    local prefix_pos = normalized:find(data_prefix, 1, true)
    if prefix_pos then
        normalized = normalized:sub(prefix_pos + #data_prefix)
    end
    normalized = normalized:gsub("^data/", "")
    return normalized
end

write_latest_backup_marker = function(path, timestamp)
    if type(path) ~= "string" or path == "" then return false, "empty backup path" end
    ensure_dirs()

    local normalized = normalize_glob_path(path)
    if not normalized or normalized == "" then return false, "invalid backup path" end

    M._last_backup_path = normalized
    local marker = {
        path = "data/" .. normalized,
        created_at = timestamp or now_stamp(),
    }

    local ok, write_result = pcall(json.dump_file, M.LATEST_BACKUP_PATH, marker)
    if not ok then return false, tostring(write_result) end
    if write_result == false then return false, "json.dump_file returned false" end
    return true, nil
end

local function try_read_backup_path(path, attempted, label)
    local normalized = normalize_glob_path(path)
    if not normalized or normalized == "" then
        attempted[#attempted + 1] = label .. ": empty path"
        return nil
    end

    local ok, data = pcall(json.load_file, normalized)
    if ok and data then return normalized end

    attempted[#attempted + 1] = label .. ": data/" .. normalized
        .. (ok and " unreadable" or (" error=" .. tostring(data)))
    return nil
end

local function read_latest_backup_marker(attempted)
    local ok, marker = pcall(json.load_file, M.LATEST_BACKUP_PATH)
    if not ok then
        attempted[#attempted + 1] = "marker: data/" .. M.LATEST_BACKUP_PATH
            .. " error=" .. tostring(marker)
        return nil
    end

    if type(marker) ~= "table" then
        attempted[#attempted + 1] = "marker: data/" .. M.LATEST_BACKUP_PATH .. " unreadable"
        return nil
    end

    return try_read_backup_path(marker.path, attempted, "marker.path")
end

function M.find_latest_backup()
    local attempted = {}

    if M._last_backup_path then
        local latest = try_read_backup_path(M._last_backup_path, attempted, "memory")
        if latest then return latest, nil end
    else
        attempted[#attempted + 1] = "memory: empty"
    end

    local marker_latest = read_latest_backup_marker(attempted)
    if marker_latest then return marker_latest, nil end

    if not fs or not fs.glob then
        attempted[#attempted + 1] = "glob: fs.glob unavailable"
        return nil, "No backup found. Tried: " .. table.concat(attempted, " | ")
    end

    local pattern = M.BACKUP_DIR .. "/records_backup_*.json"
    local ok, files = pcall(fs.glob, pattern)
    if not ok or type(files) ~= "table" then
        attempted[#attempted + 1] = "glob: " .. pattern .. " failed=" .. tostring(files)
        return nil, "No backup found. Tried: " .. table.concat(attempted, " | ")
    end

    local candidates = {}
    for _, path in ipairs(files) do
        local normalized = normalize_glob_path(path)
        local filename = normalized and normalized:match("([^/]+)$") or nil
        if filename and filename:match("^records_backup_%d%d%d%d%d%d%d%d_%d%d%d%d%d%d_?%d*%.json$") then
            candidates[#candidates + 1] = normalized
        end
    end

    table.sort(candidates)

    for index = #candidates, 1, -1 do
        local latest = try_read_backup_path(candidates[index], attempted, "glob")
        if latest then return latest, nil end
    end

    if #candidates == 0 then
        attempted[#attempted + 1] = "glob: " .. pattern .. " matched no backup files"
    end

    return nil, "No backup found. Tried: " .. table.concat(attempted, " | ")
end

function M.restore_latest_backup(options)
    local latest, err = M.find_latest_backup()
    if not latest then return false, err end
    local ok, msg, backup_path = M.import_from_file(latest, options)
    if not ok then return false, msg, backup_path end
    return true, "Restored from data/" .. latest .. ". " .. msg, backup_path
end

function M.paths_for_display()
    return {
        export = "data/" .. M.EXPORT_PATH,
        import = "data/" .. M.IMPORT_PATH,
        backups = "data/" .. M.BACKUP_DIR,
    }
end

return M
