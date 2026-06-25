-- =========================================================
-- Training_Hotkeys.lua - Shared keyboard hotkey registry.
-- Modules register actions; ScriptManager draws one global menu.
-- Defaults are intentionally disabled and unbound.
-- =========================================================

local json = json
local fs = fs
local imgui = imgui
local reframework = reframework

local M = {}

local CONFIG_FILE = "Training_ScriptManager_data/TrainingHotkeys_Config.json"

local MODIFIER_VKS = { 0x10, 0x11, 0x12, 0x5B, 0x5C }
local MOD_SET = {}
for _, vk in ipairs(MODIFIER_VKS) do MOD_SET[vk] = true end

local VK_NAMES = {
    [0x08]="BACKSPACE",[0x09]="TAB",[0x0D]="ENTER",[0x10]="SHIFT",[0x11]="CTRL",[0x12]="ALT",
    [0x14]="CAPS",[0x1B]="ESC",[0x20]="SPACE",
    [0x21]="PGUP",[0x22]="PGDN",[0x23]="END",[0x24]="HOME",[0x25]="LEFT",[0x26]="UP",[0x27]="RIGHT",[0x28]="DOWN",
    [0x2D]="INSERT",[0x2E]="DELETE",
    [0x30]="0",[0x31]="1",[0x32]="2",[0x33]="3",[0x34]="4",[0x35]="5",[0x36]="6",[0x37]="7",[0x38]="8",[0x39]="9",
    [0x41]="A",[0x42]="B",[0x43]="C",[0x44]="D",[0x45]="E",[0x46]="F",[0x47]="G",[0x48]="H",[0x49]="I",
    [0x4A]="J",[0x4B]="K",[0x4C]="L",[0x4D]="M",[0x4E]="N",[0x4F]="O",[0x50]="P",[0x51]="Q",[0x52]="R",
    [0x53]="S",[0x54]="T",[0x55]="U",[0x56]="V",[0x57]="W",[0x58]="X",[0x59]="Y",[0x5A]="Z",
    [0x60]="NUM0",[0x61]="NUM1",[0x62]="NUM2",[0x63]="NUM3",[0x64]="NUM4",
    [0x65]="NUM5",[0x66]="NUM6",[0x67]="NUM7",[0x68]="NUM8",[0x69]="NUM9",
    [0x70]="F1",[0x71]="F2",[0x72]="F3",[0x73]="F4",[0x74]="F5",[0x75]="F6",
    [0x76]="F7",[0x77]="F8",[0x78]="F9",[0x79]="F10",[0x7A]="F11",[0x7B]="F12",
    [0xBA]=";",[0xBB]="=",[0xBC]=",",[0xBD]="-",[0xBE]=".",[0xBF]="/",[0xC0]="`",
}

local registry = {}
local scope_order = {}
local config = { scopes = {} }
local loaded = false
local capture = nil
local capture_release_wait = false
local last_down = {}

local function safe_load_json(path)
    if _G.safe_load_json then return _G.safe_load_json(path) end
    local ok, data = pcall(json.load_file, path)
    return ok and data or nil
end

local function save_config()
    if fs and fs.create_dir then pcall(fs.create_dir, "Training_ScriptManager_data") end
    json.dump_file(CONFIG_FILE, config)
end

local function load_config()
    if loaded then return end
    loaded = true
    local data = safe_load_json(CONFIG_FILE)
    if type(data) == "table" then
        if type(data.scopes) == "table" then config.scopes = data.scopes end
    end
end

local function ensure_scope_config(scope_id, enabled_default)
    load_config()
    if type(config.scopes[scope_id]) ~= "table" then
        config.scopes[scope_id] = {
            enabled = enabled_default == true,
            bindings = {},
        }
        save_config()
    end
    local scope_cfg = config.scopes[scope_id]
    if type(scope_cfg.bindings) ~= "table" then scope_cfg.bindings = {} end
    if scope_cfg.enabled == nil then scope_cfg.enabled = enabled_default == true end
    return scope_cfg
end

local function read_key(vk)
    if not reframework or not reframework.is_key_down then return false end
    local ok, down = pcall(reframework.is_key_down, reframework, vk)
    return ok and down == true
end

function M.vk_name(vk)
    return VK_NAMES[vk] or string.format("0x%02X", tonumber(vk) or 0)
end

local function sort_mods(mods)
    table.sort(mods, function(a, b) return (tonumber(a) or 0) < (tonumber(b) or 0) end)
    return mods
end

function M.combo_name(binding)
    if type(binding) ~= "table" or not binding.vk then return "未绑定" end
    local parts = {}
    for _, m in ipairs(binding.mods or {}) do parts[#parts + 1] = M.vk_name(m) end
    parts[#parts + 1] = M.vk_name(binding.vk)
    return table.concat(parts, " + ")
end

local function binding_key(binding)
    if type(binding) ~= "table" or not binding.vk then return nil end
    local mods = {}
    for _, m in ipairs(binding.mods or {}) do mods[#mods + 1] = tonumber(m) or m end
    sort_mods(mods)
    return table.concat(mods, "+") .. "|" .. tostring(binding.vk)
end

local function binding_down(binding)
    if type(binding) ~= "table" or not binding.vk then return false end
    if not read_key(binding.vk) then return false end
    local required = {}
    for _, m in ipairs(binding.mods or {}) do
        required[m] = true
        if not read_key(m) then return false end
    end
    for _, m in ipairs(MODIFIER_VKS) do
        if not required[m] and read_key(m) then return false end
    end
    return true
end

local function scan_binding()
    if read_key(0x1B) then return "cancel" end
    local mods = {}
    for _, mk in ipairs(MODIFIER_VKS) do
        if read_key(mk) then mods[#mods + 1] = mk end
    end
    for vk = 0x08, 0xC0 do
        if not MOD_SET[vk] and read_key(vk) then
            return { vk = vk, mods = sort_mods(mods) }
        end
    end
    return nil
end

local function any_binding_key_down()
    for vk = 0x08, 0xC0 do
        if read_key(vk) then return true end
    end
    return false
end

function M.register_scope(scope_id, spec)
    if type(scope_id) ~= "string" or scope_id == "" then return false end
    spec = spec or {}
    local scope = registry[scope_id]
    if not scope then
        scope = {
            id = scope_id,
            title = spec.title or scope_id,
            order = spec.order or (#scope_order + 1),
            actions = {},
            action_order = {},
            enabled_default = spec.enabled_default == true,
        }
        registry[scope_id] = scope
        scope_order[#scope_order + 1] = scope_id
    else
        scope.title = spec.title or scope.title
        scope.order = spec.order or scope.order
        scope.enabled_default = spec.enabled_default == true
    end

    ensure_scope_config(scope_id, scope.enabled_default)

    for _, action in ipairs(spec.actions or {}) do
        if type(action) == "table" and type(action.id) == "string" then
            if not scope.actions[action.id] then
                scope.action_order[#scope.action_order + 1] = action.id
            end
            scope.actions[action.id] = action
        end
    end
    table.sort(scope_order, function(a, b)
        return (registry[a].order or 0) < (registry[b].order or 0)
    end)
    return true
end

function M.is_scope_enabled(scope_id)
    local scope_cfg = config.scopes[scope_id]
    return type(scope_cfg) == "table" and scope_cfg.enabled == true
end

function M.get_binding(scope_id, action_id)
    local scope_cfg = config.scopes[scope_id]
    if type(scope_cfg) ~= "table" or type(scope_cfg.bindings) ~= "table" then return nil end
    return scope_cfg.bindings[action_id]
end

function M.get_label(scope_id, action_id)
    return M.combo_name(M.get_binding(scope_id, action_id))
end

local function find_conflicts(scope_id, action_id)
    local target = binding_key(M.get_binding(scope_id, action_id))
    if not target then return nil end
    local hits = {}
    for _, sid in ipairs(scope_order) do
        local scope = registry[sid]
        local scope_cfg = config.scopes[sid]
        if scope and scope_cfg and type(scope_cfg.bindings) == "table" then
            for _, aid in ipairs(scope.action_order) do
                if not (sid == scope_id and aid == action_id) and binding_key(scope_cfg.bindings[aid]) == target then
                    local action = scope.actions[aid]
                    hits[#hits + 1] = (scope.title or sid) .. " / " .. ((action and action.label) or aid)
                end
            end
        end
    end
    return #hits > 0 and table.concat(hits, ", ") or nil
end

function M.is_input_blocked()
    return capture ~= nil or capture_release_wait
end

function M.update(suspended)
    load_config()

    if suspended then return end

    if capture_release_wait then
        if not any_binding_key_down() then capture_release_wait = false end
        return
    end

    if capture then
        local binding = scan_binding()
        if binding == "cancel" then
            capture = nil
            capture_release_wait = true
            return
        elseif type(binding) == "table" then
            local scope_cfg = ensure_scope_config(capture.scope_id, false)
            scope_cfg.bindings[capture.action_id] = binding
            save_config()
            capture = nil
            capture_release_wait = true
            return
        end
        return
    end

    for _, scope_id in ipairs(scope_order) do
        local scope = registry[scope_id]
        local scope_cfg = config.scopes[scope_id]
        if scope and scope_cfg and scope_cfg.enabled == true then
            for _, action_id in ipairs(scope.action_order) do
                local action = scope.actions[action_id]
                local binding = scope_cfg.bindings and scope_cfg.bindings[action_id]
                local key = scope_id .. "." .. action_id
                local is_down = binding_down(binding)
                if is_down and not last_down[key] then
                    local allowed = true
                    if type(action.enabled) == "function" then
                        local ok, result = pcall(action.enabled)
                        allowed = ok and result ~= false
                    end
                    if allowed and type(action.run) == "function" then pcall(action.run) end
                end
                last_down[key] = is_down
            end
        end
    end
end

local function draw_scope(scope)
    local scope_cfg = ensure_scope_config(scope.id, scope.enabled_default)
    local changed, enabled = imgui.checkbox("启用 " .. scope.title .. " 快捷键##hk_enabled_" .. scope.id, scope_cfg.enabled == true)
    if changed then
        scope_cfg.enabled = enabled == true
        save_config()
    end
    imgui.text_colored("默认无绑定；只在这里启用并绑定后才响应。", 0xFF888888)

    for _, action_id in ipairs(scope.action_order) do
        local action = scope.actions[action_id]
        if action then
            imgui.separator()
            imgui.text(action.label or action_id)
            imgui.same_line(230)
            imgui.text_colored(M.combo_name(scope_cfg.bindings[action_id]), 0xFF00FFFF)

            local cap = capture and capture.scope_id == scope.id and capture.action_id == action_id
            if cap then
                imgui.text_colored("请按下要绑定的键；ESC 取消。", 0xFF00A5FF)
            else
                if imgui.button("绑定##hk_bind_" .. scope.id .. "_" .. action_id) then
                    capture = { scope_id = scope.id, action_id = action_id }
                end
                imgui.same_line()
                if imgui.button("清除##hk_clear_" .. scope.id .. "_" .. action_id) then
                    scope_cfg.bindings[action_id] = nil
                    save_config()
                end
            end

            local conflict = find_conflicts(scope.id, action_id)
            if conflict then
                imgui.text_colored("冲突: " .. conflict, 0xFF0000FF)
            end
        end
    end
end

function M.draw_menu()
    load_config()
    if #scope_order == 0 then
        imgui.text_colored("暂无模块注册快捷键动作。", 0xFF888888)
        return
    end
    for _, scope_id in ipairs(scope_order) do
        local scope = registry[scope_id]
        if scope and imgui.tree_node(scope.title .. "##hotkeys_" .. scope_id) then
            draw_scope(scope)
            imgui.tree_pop()
        end
    end
end

return M
