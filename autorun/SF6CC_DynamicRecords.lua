-- SF6CC_DynamicRecords.lua
-- Independent ImGui panel for SF6 native training dynamic record slots.

local imgui = imgui
local re = re

require("func/SharedHooks")
local DynamicRecords = require("func/DynamicRecords")

local options = {
    only_import_valid = true,
    clear_empty_slots = false,
    reject_fighter_mismatch = true,
    force_apply_after_import = true,
}

local status_msg = "Ready."
local status_ok = true
local last_slots = nil
local last_snapshot = nil
local last_fighter_id = nil

local function set_status(ok, msg)
    status_ok = ok == true
    status_msg = tostring(msg or "")
end

local function refresh_slots(silent)
    local ok, slots_or_err, err_or_nil, snapshot_or_nil = pcall(function()
        local slots, err, snapshot = DynamicRecords.get_slot_summaries()
        return slots, err, snapshot
    end)

    if not ok then
        set_status(false, "Refresh failed: " .. tostring(slots_or_err))
        return false
    end

    local slots = slots_or_err
    local err = err_or_nil
    local snapshot = snapshot_or_nil
    if not slots then
        last_slots = nil
        last_snapshot = nil
        set_status(false, "Refresh failed: " .. tostring(err))
        return false
    end

    last_slots = slots
    last_snapshot = snapshot
    if not silent then set_status(true, "Refreshed") end
    return true
end

local function run_action(label, fn)
    local ok, success, msg = pcall(fn)
    if not ok then
        set_status(false, label .. " crashed: " .. tostring(success))
        return
    end
    set_status(success == true, msg)
    refresh_slots(true)
end

local function status_color()
    if status_ok then return 0xFF00FF00 end
    return 0xFF0000FF
end

local function draw_paths()
    local paths = DynamicRecords.paths_for_display()
    imgui.text("Export: " .. paths.export)
    imgui.text("Import: " .. paths.import)
    imgui.text("Backups: " .. paths.backups)
end

local function draw_actions()
    if imgui.button("刷新") then
        refresh_slots(false)
    end
    imgui.same_line()

    if imgui.button("导出当前 8 槽") then
        run_action("Export", function()
            return DynamicRecords.export_current(DynamicRecords.EXPORT_PATH)
        end)
    end
    imgui.same_line()

    if imgui.button("导入 JSON") then
        run_action("Import", function()
            return DynamicRecords.import_from_file(DynamicRecords.IMPORT_PATH, options)
        end)
    end
    imgui.same_line()

    if imgui.button("备份当前 8 槽") then
        run_action("Backup", function()
            return DynamicRecords.backup_current()
        end)
    end
    imgui.same_line()

    if imgui.button("恢复最近备份") then
        run_action("Restore", function()
            return DynamicRecords.restore_latest_backup(options)
        end)
    end
end

local function draw_options()
    local changed

    changed, options.only_import_valid = imgui.checkbox("只导入有效槽", options.only_import_valid)
    imgui.same_line()
    changed, options.clear_empty_slots = imgui.checkbox("清空空槽", options.clear_empty_slots)
    imgui.same_line()
    changed, options.reject_fighter_mismatch = imgui.checkbox("角色 ID 不匹配时拒绝", options.reject_fighter_mismatch)
    imgui.same_line()
    changed, options.force_apply_after_import = imgui.checkbox("导入后 ForceApply", options.force_apply_after_import)
end

local function draw_slots_table(slots)
    if not slots then
        imgui.text_colored("没有可显示的槽位数据。", 0xFF888888)
        return
    end

    if imgui.begin_table("SF6CCDynamicRecordsSlots", 6, 1 << 0) then
        imgui.table_setup_column("槽", 0, 30)
        imgui.table_setup_column("有效", 0, 50)
        imgui.table_setup_column("启用", 0, 50)
        imgui.table_setup_column("帧数", 0, 60)
        imgui.table_setup_column("权重", 0, 60)
        imgui.table_setup_column("输入帧", 0, 70)
        imgui.table_headers_row()

        for _, slot in ipairs(slots) do
            imgui.table_next_row()

            imgui.table_next_column()
            imgui.text(tostring(slot.slot or "-"))

            imgui.table_next_column()
            imgui.text_colored(slot.is_valid and "yes" or "no", slot.is_valid and 0xFF00FF00 or 0xFF888888)

            imgui.table_next_column()
            imgui.text_colored(slot.is_active and "on" or "off", slot.is_active and 0xFF00FF00 or 0xFF888888)

            imgui.table_next_column()
            imgui.text(tostring(slot.frame or 0))

            imgui.table_next_column()
            imgui.text(tostring(slot.weight or 0))

            imgui.table_next_column()
            imgui.text(tostring(slot.input_num or 0))
        end

        imgui.end_table()
    end
end

local function draw_panel()
    local ctx = DynamicRecords.get_context()
    local fighter_id = ctx.fighter_id
    local fighter_name = ctx.fighter_name or ""
    local source_player = ctx.source_player or "P2"

    if fighter_id ~= last_fighter_id then
        last_fighter_id = fighter_id
        last_slots = nil
        last_snapshot = nil
    end

    imgui.text("当前角色: " .. tostring(fighter_name)
        .. " / fighter_id=" .. tostring(fighter_id or "?")
        .. " / source=" .. tostring(source_player))

    if ctx.error and fighter_id == nil then
        imgui.text_colored("Context: " .. tostring(ctx.error), 0xFF0000FF)
    end

    draw_actions()
    draw_options()
    imgui.separator()
    draw_paths()
    imgui.separator()

    if not last_slots then refresh_slots(true) end
    draw_slots_table(last_slots)

    imgui.separator()
    imgui.text("状态: ")
    imgui.same_line()
    imgui.text_colored(status_msg, status_color())
end

re.on_draw_ui(function()
    if imgui.tree_node("SF6CC 动态记录") then
        draw_panel()
        imgui.tree_pop()
    end
end)
