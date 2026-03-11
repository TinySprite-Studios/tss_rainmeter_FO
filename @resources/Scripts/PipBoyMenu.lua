local MAX_ROWS = 12

local state = {
  tab = "STAT",
  menu = "STAT_ROOT",
  visibleItems = {},
  awaitingAddResult = false,
  addPendingPath = "",
  addPendingUntil = 0,
  netTestRunning = false,
  netTestResultPath = "",
  netTestUntil = 0,
  telemetryNextPoll = 0
}

local cfg = nil
local tabs = {}
local menuMap = {}
local userMenuStore = {}
local userItemsPath = ""

local function readFile(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local data = f:read("*a")
  f:close()
  return data
end

local function writeFile(path, data)
  local f = io.open(path, "wb")
  if not f then return false end
  f:write(data or "")
  f:close()
  return true
end

local function escapeLuaString(s)
  s = tostring(s or "")
  s = s:gsub("\\", "\\\\")
  s = s:gsub("\r", "\\r")
  s = s:gsub("\n", "\\n")
  s = s:gsub("'", "\\'")
  return s
end

local function serializeLuaValue(v)
  local t = type(v)
  if t == "string" then
    return "'" .. escapeLuaString(v) .. "'"
  end
  if t == "number" then
    return tostring(v)
  end
  if t == "boolean" then
    return v and "true" or "false"
  end
  return "nil"
end

local function serializeUserItem(it)
  local ordered = {"type", "text", "target", "status", "mode", "menu", "submenu", "refresh"}
  local parts = {}
  for _, k in ipairs(ordered) do
    if it[k] ~= nil then
      parts[#parts + 1] = string.format("%s = %s", k, serializeLuaValue(it[k]))
    end
  end
  for k, v in pairs(it) do
    if type(k) == "string" and k:sub(1, 2) ~= "__" then
      local known = false
      for _, ok in ipairs(ordered) do
        if ok == k then known = true break end
      end
      if not known and type(v) ~= "table" and type(v) ~= "function" then
        parts[#parts + 1] = string.format("%s = %s", k, serializeLuaValue(v))
      end
    end
  end
  return "{ " .. table.concat(parts, ", ") .. " }"
end

local function serializeUserItemsLua(menus)
  local out = {
    "return {",
    "  menus = {"
  }

  for menuId, items in pairs(menus or {}) do
    out[#out + 1] = string.format("    ['%s'] = {", escapeLuaString(menuId))
    if type(items) == "table" then
      for _, it in ipairs(items) do
        if type(it) == "table" then
          out[#out + 1] = "      " .. serializeUserItem(it) .. ","
        end
      end
    end
    out[#out + 1] = "    },"
  end

  out[#out + 1] = "  }"
  out[#out + 1] = "}"
  out[#out + 1] = ""
  return table.concat(out, "\n")
end

local function loadLuaTable(path)
  local chunk, err = loadfile(path)
  if not chunk then return nil, err end
  local ok, result = pcall(chunk)
  if not ok then return nil, result end
  if type(result) ~= "table" then return nil, "Expected Lua table return" end
  return result, nil
end

local function readConfig(path)
  local chunk, err = loadfile(path)
  if not chunk then return nil, err end
  local ok, result = pcall(chunk)
  if not ok then return nil, result end
  if type(result) ~= "table" then return nil, "Config.lua must return a table" end
  return result, nil
end

local function loadUserItemsFromLua(path)
  local tbl = loadLuaTable(path)
  if type(tbl) ~= "table" then return nil end
  if type(tbl.menus) ~= "table" then return nil end
  return tbl.menus
end

local function saveUserItemsLua(path, menus)
  local content = serializeUserItemsLua(menus or {})
  return writeFile(path, content)
end

local function normalizeLaunchItem(it)
  if type(it) ~= "table" then return nil end
  if (it.type or "launch") ~= "launch" then return nil end
  local text = tostring(it.text or "")
  local target = tostring(it.target or "")
  if text == "" or target == "" then return nil end
  local status = tostring(it.status or ("OPEN " .. text))
  return { type = "launch", text = text, target = target, status = status }
end

local function normalizeSubmenuName(name)
  local n = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if n == "" then return nil end
  return n
end

local function buildMenuId(parentMenu, name, baseMenus, userMenus)
  local p = tostring(parentMenu or "MENU"):upper():gsub("[^A-Z0-9_]", "_")
  local n = tostring(name or "SUBMENU"):upper():gsub("[^A-Z0-9_]", "_")
  n = n:gsub("_+", "_")
  n = n:gsub("^_+", ""):gsub("_+$", "")
  if n == "" then n = "SUBMENU" end
  local base = p .. "_USR_" .. n
  local candidate = base
  local i = 2
  while (baseMenus and baseMenus[candidate]) or (userMenus and userMenus[candidate]) do
    candidate = base .. "_" .. tostring(i)
    i = i + 1
  end
  return candidate
end

local function inheritedAddEntries(parentMenuId, newMenuId, baseMenus, userMenus)
  local src = nil
  if type(userMenus[parentMenuId]) == "table" then
    src = userMenus[parentMenuId]
  elseif type(baseMenus[parentMenuId]) == "table" then
    src = baseMenus[parentMenuId]
  else
    src = {}
  end
  local out = {}
  for _, it in ipairs(src) do
    if type(it) == "table" and it.type == "add_entry" then
      out[#out + 1] = {
        type = "add_entry",
        text = it.text,
        mode = it.mode,
        menu = newMenuId,
        status = it.status
      }
    end
  end
  return out
end

local function createSubmenuFromPending(pending, baseMenus, userMenus)
  local parentMenu = tostring(pending.menu or "")
  local displayName = normalizeSubmenuName(pending.name)
  if parentMenu == "" or not displayName then return false end
  local newMenuId = buildMenuId(parentMenu, displayName, baseMenus, userMenus)

  if type(userMenus[parentMenu]) ~= "table" then userMenus[parentMenu] = {} end
  userMenus[parentMenu][#userMenus[parentMenu] + 1] = {
    type = "submenu",
    text = displayName,
    menu = newMenuId,
    status = "OPEN " .. displayName
  }

  local submenuItems = inheritedAddEntries(parentMenu, newMenuId, baseMenus, userMenus)
  submenuItems[#submenuItems + 1] = {
    type = "submenu",
    text = "Back",
    menu = parentMenu,
    status = "BACK"
  }
  userMenus[newMenuId] = submenuItems
  return true
end

local function consumePendingAdd(pendingPath, userLuaPath, userMenus, baseMenus)
  local pending, _ = loadLuaTable(pendingPath)
  if type(pending) ~= "table" then return end
  if pending.op == "create_submenu" then
    createSubmenuFromPending(pending, baseMenus or {}, userMenus)
    saveUserItemsLua(userLuaPath, userMenus)
    os.remove(pendingPath)
    return
  end
  local menuId = pending.menu
  local item = normalizeLaunchItem(pending.item)
  if type(menuId) ~= "string" or menuId == "" or not item then
    os.remove(pendingPath)
    return
  end

  if type(userMenus[menuId]) ~= "table" then userMenus[menuId] = {} end
  table.insert(userMenus[menuId], item)
  saveUserItemsLua(userLuaPath, userMenus)
  os.remove(pendingPath)
end

local function mergeUserItems(baseMenus, userMenus)
  for menuId, additions in pairs(userMenus) do
    if type(additions) == "table" then
      if type(baseMenus[menuId]) ~= "table" then
        baseMenus[menuId] = {}
      end

      local backIndex = nil
      for i, it in ipairs(baseMenus[menuId]) do
        if it.type == "submenu" and (it.text or "") == "Back" then
          backIndex = i
          break
        end
      end

      if backIndex then
        local offset = 0
        for j, add in ipairs(additions) do
          if type(add) == "table" then
            add.__user = true
            add.__userMenu = menuId
            add.__userIndex = j
          end
          table.insert(baseMenus[menuId], backIndex + offset, add)
          offset = offset + 1
        end
      else
        for j, add in ipairs(additions) do
          if type(add) == "table" then
            add.__user = true
            add.__userMenu = menuId
            add.__userIndex = j
          end
          table.insert(baseMenus[menuId], add)
        end
      end
    end
  end
end

local function isEditMode()
  return tonumber(SKIN:GetVariable("EditMode", "0")) == 1
end

local function setEditMode(enabled)
  local v = enabled and "1" or "0"
  SKIN:Bang("!SetVariable", "EditMode", v)
  SKIN:Bang("!WriteKeyValue", "Variables", "EditMode", v, "#@#Variables.inc")
end

local function currentVisibleItems()
  return state.visibleItems or {}
end

local function isNonEmptyVar(name)
  local v = tostring(SKIN:GetVariable(name, "") or "")
  return v:match("%S") ~= nil
end

local function isVarEnabled(name, onValue)
  local v = tostring(SKIN:GetVariable(name, "") or "")
  local expected = tostring(onValue or "1")
  if expected == "" then
    return v ~= ""
  end
  return v == expected
end

local function isScanlinesEnabled()
  return isNonEmptyVar("Scanlines")
end

local function isSoundsEnabled()
  return isNonEmptyVar("Key1")
end

local function writeSkinVar(key, value)
  local val = tostring(value or "")
  SKIN:Bang("!SetVariable", key, val)
  SKIN:Bang("!WriteKeyValue", "Variables", key, val, "#@#Variables.inc")
end

local function setSoundsEnabled(enabled)
  if enabled then
    writeSkinVar("Key1", "#@#Sounds\\key1.wav")
    writeSkinVar("Key2", "#@#Sounds\\key2.wav")
    writeSkinVar("Key3", "#@#Sounds\\key3.wav")
    writeSkinVar("Key4", "#@#Sounds\\key4.wav")
    writeSkinVar("Key5", "#@#Sounds\\key5.wav")
    writeSkinVar("PowerOn", "#@#Sounds\\poweron.wav")
    writeSkinVar("PowerOff", "#@#Sounds\\poweroff.wav")
  else
    writeSkinVar("Key1", "")
    writeSkinVar("Key2", "")
    writeSkinVar("Key3", "")
    writeSkinVar("Key4", "")
    writeSkinVar("Key5", "")
    writeSkinVar("PowerOn", "")
    writeSkinVar("PowerOff", "")
  end
end

local function playHoverSound(index)
  if not isSoundsEnabled() then return end
  local i = tonumber(index) or 1
  local key = "Key" .. tostring(((i - 1) % 5) + 1)
  local snd = tostring(SKIN:GetVariable(key, "") or "")
  if snd == "" then snd = tostring(SKIN:GetVariable("Key1", "") or "") end
  if snd ~= "" then
    SKIN:Bang('Play "' .. snd .. '"')
  end
end

local function isClickableItem(item)
  if type(item) ~= "table" then return false end
  local t = item.type or "none"
  return t == "submenu"
    or t == "launch"
    or t == "add_entry"
    or t == "reload_config"
    or t == "toggle_edit"
    or t == "toggle_scanlines"
    or t == "toggle_sounds"
    or t == "edit_name"
    or t == "toggle_var"
    or t == "run_network_test"
    or t == "writes"
    or t == "open_variables"
    or t == "refresh_app"
end

local function currentEmployeeName()
  local line2 = tostring(SKIN:GetVariable("TitleLine2", "") or "")
  local name = line2:match("[Ee]mployee:%s*(.+)$")
  if name and name ~= "" then return name end
  return line2
end

local function loadConfig()
  local configPath = SKIN:GetVariable("MenuConfig", "")
  local parsed, err = readConfig(configPath)
  if not parsed then
    SKIN:Bang("!SetVariable", "StatusText", "CONFIG ERROR // " .. tostring(err))
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return false
  end

  cfg = parsed
  tabs = cfg.tabs or {}
  menuMap = cfg.menus or {}

  local userPath = SKIN:ReplaceVariables(SKIN:GetVariable("UserItemsConfig", "#@#Config\\UserItems.lua"))
  local pendingPath = SKIN:ReplaceVariables(SKIN:GetVariable("UserItemsPendingConfig", "#@#Config\\UserItems.pending.lua"))

  local userMenus = loadUserItemsFromLua(userPath)
  if type(userMenus) ~= "table" then
    userMenus = {}
  end
  consumePendingAdd(pendingPath, userPath, userMenus, menuMap)
  userMenuStore = userMenus
  userItemsPath = userPath
  mergeUserItems(menuMap, userMenus)

  if cfg.title then
    if cfg.title.line1 and tostring(SKIN:GetVariable("TitleLine1", "") or "") == "" then
      SKIN:Bang("!SetVariable", "TitleLine1", cfg.title.line1)
    end
    if cfg.title.line2 and tostring(SKIN:GetVariable("TitleLine2", "") or "") == "" then
      SKIN:Bang("!SetVariable", "TitleLine2", cfg.title.line2)
    end
  end

  for _, id in ipairs({"STAT","DATA","INV","RADIO","SET"}) do
    SKIN:Bang("!SetOption", "MeterTab" .. id, "Text", id)
  end
  for _, t in ipairs(tabs) do
    if t.id and t.label then
      SKIN:Bang("!SetOption", "MeterTab" .. t.id, "Text", t.label)
    end
  end

  return true
end

local function tabById(id)
  for _, t in ipairs(tabs) do if t.id == id then return t end end
  return nil
end

local function currentItems()
  return menuMap[state.menu] or {}
end

local function setStatus(text)
  SKIN:Bang("!SetVariable", "StatusText", text or "")
end

local function launch(target)
  if not target or target == "" then return end
  if target:lower() == "shell:recyclebinfolder" then
    SKIN:Bang('["explorer.exe" "shell:RecycleBinFolder"]')
  else
    SKIN:Bang('["' .. target .. '"]')
  end
end

local function applyTabColors()
  local textColor = SKIN:GetVariable("TextColor", "0,255,0,255")
  local accentColor = SKIN:GetVariable("AccentColor", "95,255,95,255")
  for _, id in ipairs({"STAT","DATA","INV","RADIO","SET"}) do
    local color = (id == state.tab) and accentColor or textColor
    SKIN:Bang("!SetOption", "MeterTab" .. id, "FontColor", color)
  end
end

local function isUserDeletable(item)
  if type(item) ~= "table" then return false end
  if not item.__user then return false end
  if item.type == "launch" then return true end
  if item.type == "submenu" and (item.text or "") ~= "Back" then return true end
  return false
end

local function refreshRows()
  local editMode = isEditMode()
  local items = currentItems()
  local visible = {}
  for _, item in ipairs(items) do
    local hiddenForEdit = (item.type == "add_entry" and not editMode) or (item.type == "edit_name" and not editMode)
    local hiddenByVar = false
    if type(item.show_if_var) == "string" and item.show_if_var ~= "" then
      hiddenByVar = not isVarEnabled(item.show_if_var, item.show_if_value or "1")
    end
    if not hiddenForEdit and not hiddenByVar then
      visible[#visible + 1] = item
    end
  end
  state.visibleItems = visible

  for i = 1, MAX_ROWS do
    local meter = "MeterRow" .. i
    local varName = "Row" .. i .. "Text"
    local item = visible[i]
    if item and item.text and item.text ~= "" then
      local rowText = item.text
      local canDelete = editMode and isUserDeletable(item)
      if item.type == "toggle_edit" then
        rowText = "Edit Mode: " .. (editMode and "ON" or "OFF")
      elseif item.type == "toggle_scanlines" then
        rowText = "Scanlines: " .. (isScanlinesEnabled() and "ON" or "OFF")
      elseif item.type == "toggle_sounds" then
        rowText = "Sounds: " .. (isSoundsEnabled() and "ON" or "OFF")
      elseif item.type == "edit_name" then
        rowText = "Employee Name: " .. currentEmployeeName()
      elseif item.type == "toggle_var" then
        local onText = tostring(item.on_text or "ON")
        local offText = tostring(item.off_text or "OFF")
        rowText = tostring(item.text or "Toggle") .. ": " .. (isVarEnabled(item.var, item.on_value or "1") and onText or offText)
      end
      if canDelete then
        SKIN:Bang("!SetVariable", "Row" .. i .. "DelText", "[DEL]")
        SKIN:Bang("!SetOption", "MeterRowDel" .. i, "Hidden", "0")
        rowText = "     " .. rowText
      else
        SKIN:Bang("!SetVariable", "Row" .. i .. "DelText", "")
        SKIN:Bang("!SetOption", "MeterRowDel" .. i, "Hidden", "1")
      end
      SKIN:Bang("!SetVariable", varName, "> " .. rowText)
      SKIN:Bang("!SetOption", meter, "Hidden", "0")
    else
      SKIN:Bang("!SetVariable", varName, "")
      SKIN:Bang("!SetOption", meter, "Hidden", "1")
      SKIN:Bang("!SetVariable", "Row" .. i .. "DelText", "")
      SKIN:Bang("!SetOption", "MeterRowDel" .. i, "Hidden", "1")
    end
  end
  applyTabColors()
  SKIN:Bang("!UpdateMeterGroup", "Rows")
  SKIN:Bang("!UpdateMeterGroup", "DelRows")
  SKIN:Bang("!UpdateMeter", "MeterStatus")
  SKIN:Bang("!UpdateMeter", "MeterTitle")
  SKIN:Bang("!UpdateMeter", "MeterDate")
  SKIN:Bang("!Redraw")
end

local function setTabInternal(id)
  local t = tabById(id)
  if not t then return end
  state.tab = id
  state.menu = t.root or (id .. "_ROOT")
  setStatus(t.status or (id .. " // READY"))
  refreshRows()
end

local function writeKeyValues(writes)
  if type(writes) ~= "table" then return end
  for _, w in ipairs(writes) do
    SKIN:Bang("!WriteKeyValue", w.section or "Variables", w.key or "", tostring(w.value or ""), w.file or "#@#Variables.inc")
  end
end

local function startNetworkTest()
  local script = SKIN:ReplaceVariables("#@#Scripts\\NetworkSpeedTest.ps1")
  local resultPath = SKIN:ReplaceVariables(SKIN:GetVariable("NetworkTestPendingConfig", "#@#Config\\NetworkTest.pending.lua"))
  os.remove(resultPath)

  local cmd = string.format(
    '["powershell.exe" "-NoProfile" "-ExecutionPolicy" "Bypass" "-WindowStyle" "Hidden" "-File" "%s" "-OutputPath" "%s"]',
    script,
    resultPath
  )
  SKIN:Bang(cmd)

  state.netTestRunning = true
  state.netTestResultPath = resultPath
  state.netTestUntil = os.time() + 180
  SKIN:Bang("!SetVariable", "NetTestDown", "TESTING")
  SKIN:Bang("!SetVariable", "NetTestUp", "TESTING")
  setStatus("SET // RUNNING NETWORK TEST")
  SKIN:Bang("!UpdateMeterGroup", "Rows")
  SKIN:Bang("!UpdateMeter", "MeterStatus")
  SKIN:Bang("!Redraw")
end

local function updateNetworkTest()
  if not state.netTestRunning then return end
  local resultPath = state.netTestResultPath or ""
  if resultPath ~= "" and readFile(resultPath) then
    local result = loadLuaTable(resultPath)
    state.netTestRunning = false
    os.remove(resultPath)
    if type(result) == "table" and result.ok then
      local downText = tostring(result.down or "N/A")
      local upText = tostring(result.up or "N/A")
      writeSkinVar("NetTestDown", downText)
      writeSkinVar("NetTestUp", upText)
      setStatus("SET // NET TEST COMPLETE D:" .. downText .. " U:" .. upText .. " Mbps")
    else
      writeSkinVar("NetTestDown", "ERR")
      writeSkinVar("NetTestUp", "ERR")
      setStatus("SET // NET TEST FAILED")
    end
    refreshRows()
    return
  end

  if os.time() >= (state.netTestUntil or 0) then
    state.netTestRunning = false
    writeSkinVar("NetTestDown", "TIMEOUT")
    writeSkinVar("NetTestUp", "TIMEOUT")
    setStatus("SET // NET TEST TIMEOUT")
    refreshRows()
  end
end

local function updateRuntimeTelemetry()
  local now = os.time()
  if now < (state.telemetryNextPoll or 0) then return end
  state.telemetryNextPoll = now + 1

  local mUptime = SKIN:GetMeasure("MeasureUptimeSeconds")
  local uptime = mUptime and tonumber(mUptime:GetValue()) or 0
  uptime = math.max(0, math.floor(uptime or 0))
  local days = math.floor(uptime / 86400)
  local hours = math.floor((uptime % 86400) / 3600)
  local mins = math.floor((uptime % 3600) / 60)
  SKIN:Bang("!SetVariable", "UptimeText", string.format("%dd %dh %dm", days, hours, mins))

  if state.tab == "STAT" then
    SKIN:Bang("!UpdateMeasure", "MeasureUptimeText")
    SKIN:Bang("!UpdateMeterGroup", "Rows")
    SKIN:Bang("!Redraw")
  end
end

local function deleteUserItem(item)
  local menuId = item.__userMenu
  local idx = tonumber(item.__userIndex)
  if type(menuId) ~= "string" or not idx then
    setStatus("EDIT MODE // CANNOT DELETE STATIC ITEM")
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end

  local list = userMenuStore[menuId]
  if type(list) ~= "table" or not list[idx] then
    setStatus("EDIT MODE // DELETE FAILED")
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end

  local removedName = tostring(list[idx].text or item.text or "Item")
  table.remove(list, idx)
  saveUserItemsLua(userItemsPath, userMenuStore)
  setStatus("EDIT MODE // REMOVED " .. removedName)
  Rebuild()
end

local function runAddEntry(mode, menuId)
  local script = SKIN:ReplaceVariables("#@#Scripts\\AddEntry.ps1")
  local pendingCfg = SKIN:ReplaceVariables(SKIN:GetVariable("UserItemsPendingConfig", "#@#Config\\UserItems.pending.lua"))
  local cmd = string.format(
    '["powershell.exe" "-NoProfile" "-ExecutionPolicy" "Bypass" "-STA" "-File" "%s" "-Mode" "%s" "-Menu" "%s" "-PendingConfig" "%s"]',
    script,
    mode,
    menuId,
    pendingCfg
  )
  SKIN:Bang(cmd)
  state.awaitingAddResult = true
  state.addPendingPath = pendingCfg
  state.addPendingUntil = os.time() + 600
  setStatus("ADDED ITEM // Reloading...")
  SKIN:Bang("!UpdateMeter", "MeterStatus")
  SKIN:Bang("!Redraw")
  SKIN:Bang("!Delay", "1200", "!CommandMeasure MeasureMenu Rebuild()")
end

function Initialize()
  SKIN:Bang("!DisableDrag", SKIN:GetVariable("CURRENTCONFIG"))
  if not loadConfig() then return end
  setTabInternal("STAT")
end

function SetTab(id)
  setTabInternal(tostring(id or "STAT"))
end

function SetDisplayName(name)
  local n = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if n == "" then
    setStatus("SET // NAME NOT CHANGED")
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end
  local line2 = "BUNKER TEC // Employee: " .. n
  writeSkinVar("TitleLine2", line2)
  setStatus("SET // EMPLOYEE NAME UPDATED")
  SKIN:Bang("!UpdateMeter", "MeterTitle")
  SKIN:Bang("!UpdateMeter", "MeterStatus")
  SKIN:Bang("!Redraw")
end

function ApplyDisplayNameFromVar()
  SetDisplayName(SKIN:GetVariable("TempEmployeeName", ""))
end

function HoverRow(index, entering)
  local i = tonumber(index)
  if not i then return end
  local item = currentVisibleItems()[i]
  if not item then return end

  local meter = "MeterRow" .. i
  local hover = tostring(entering or "0") == "1"
  local color = SKIN:GetVariable("TextColor", "0,255,0,255")
  if hover and isClickableItem(item) then
    color = SKIN:GetVariable("HoverColor", "255,140,0,255")
    playHoverSound(i)
  end
  SKIN:Bang("!SetOption", meter, "FontColor", color)
  SKIN:Bang("!UpdateMeter", meter)
  SKIN:Bang("!Redraw")
end

function HoverTab(id, entering)
  local tabId = tostring(id or "")
  if tabId == "" then return end

  local meter = "MeterTab" .. tabId
  local hover = tostring(entering or "0") == "1"
  if hover then
    SKIN:Bang("!SetOption", meter, "FontColor", SKIN:GetVariable("HoverColor", "255,140,0,255"))
  else
    applyTabColors()
  end
  SKIN:Bang("!UpdateMeter", "MeterTabSTAT")
  SKIN:Bang("!UpdateMeter", "MeterTabDATA")
  SKIN:Bang("!UpdateMeter", "MeterTabINV")
  SKIN:Bang("!UpdateMeter", "MeterTabRADIO")
  SKIN:Bang("!UpdateMeter", "MeterTabSET")
  SKIN:Bang("!Redraw")
end

function Click(index)
  local i = tonumber(index)
  if not i then return end
  local item = currentVisibleItems()[i]
  if not item then return end

  local t = item.type or "none"

  if t == "launch" then
    launch(item.target)
    setStatus(item.status or ("OPEN " .. (item.text or "")))
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end

  if t == "add_entry" then
    runAddEntry(item.mode or "folder", item.menu or state.menu)
    return
  end

  if t == "submenu" then
    state.menu = item.menu or item.submenu or state.menu
    setStatus(item.status or "")
    refreshRows()
    return
  end

  if t == "reload_config" then
    Rebuild()
    setStatus(item.status or "RELOADED CONFIG")
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end

  if t == "toggle_edit" then
    local nextMode = not isEditMode()
    setEditMode(nextMode)
    if nextMode then
      setStatus("EDIT MODE // ON (CLICK [DEL] ITEMS TO REMOVE)")
    else
      setStatus("EDIT MODE // OFF")
    end
    refreshRows()
    return
  end

  if t == "toggle_scanlines" then
    local nextOn = not isScanlinesEnabled()
    writeSkinVar("Scanlines", nextOn and "#@#Images\\scanlines.png" or " ")
    setStatus(nextOn and "SET // SCANLINES ENABLED" or "SET // SCANLINES DISABLED")
    SKIN:Bang("!Refresh", SKIN:GetVariable("CURRENTCONFIG"))
    return
  end

  if t == "toggle_sounds" then
    local nextOn = not isSoundsEnabled()
    setSoundsEnabled(nextOn)
    setStatus(nextOn and "SET // SOUNDS ENABLED" or "SET // SOUNDS DISABLED")
    refreshRows()
    return
  end

  if t == "edit_name" then
    local current = currentEmployeeName()
    SKIN:Bang("!SetOption", "MeasureEditNameInput", "DefaultValue", current)
    SKIN:Bang("!CommandMeasure", "MeasureEditNameInput", "ExecuteBatch 1")
    return
  end

  if t == "toggle_var" then
    local varName = tostring(item.var or "")
    if varName == "" then
      setStatus("SET // INVALID TOGGLE")
      SKIN:Bang("!UpdateMeter", "MeterStatus")
      SKIN:Bang("!Redraw")
      return
    end
    local onValue = tostring(item.on_value or "1")
    local offValue = tostring(item.off_value or "0")
    local nextValue = isVarEnabled(varName, onValue) and offValue or onValue
    local targetFile = tostring(item.file or "#@#Variables.inc")
    SKIN:Bang("!SetVariable", varName, nextValue)
    SKIN:Bang("!WriteKeyValue", "Variables", varName, nextValue, targetFile)
    setStatus(item.status or ("SET // TOGGLED " .. varName))
    if item.refresh == "skin" then
      SKIN:Bang("!Refresh", SKIN:GetVariable("CURRENTCONFIG"))
      return
    end
    if item.refresh == "app" then
      SKIN:Bang("!RefreshApp")
      return
    end
    refreshRows()
    return
  end

  if t == "run_network_test" then
    startNetworkTest()
    return
  end

  if t == "writes" then
    writeKeyValues(item.writes)
    setStatus(item.status or (item.text or "SETTINGS UPDATED"))
    if item.refresh == "skin" then
      SKIN:Bang("!Refresh", SKIN:GetVariable("CURRENTCONFIG"))
      return
    end
    if item.refresh == "app" then
      SKIN:Bang("!RefreshApp")
      return
    end
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end

  if t == "open_variables" then
    launch("#@#Variables.inc")
    setStatus(item.status or "OPEN VARIABLES")
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end

  if t == "refresh_app" then
    SKIN:Bang("!RefreshApp")
    return
  end
end

function Delete(index)
  local i = tonumber(index)
  if not i then return end
  local item = currentVisibleItems()[i]
  if not item then return end
  if not (isEditMode() and isUserDeletable(item)) then
    setStatus("EDIT MODE // SELECT [DEL] ON USER ITEMS")
    SKIN:Bang("!UpdateMeter", "MeterStatus")
    SKIN:Bang("!Redraw")
    return
  end
  deleteUserItem(item)
end

function Rebuild()
  if not loadConfig() then return end
  local t = tabById(state.tab)
  if not t then
    state.tab = "STAT"
    state.menu = "STAT_ROOT"
  elseif not menuMap[state.menu] then
    state.menu = t.root or (state.tab .. "_ROOT")
  end
  refreshRows()
end

function Update()
  pcall(updateRuntimeTelemetry)
  pcall(updateNetworkTest)
  if state.awaitingAddResult then
    if state.addPendingPath ~= "" and readFile(state.addPendingPath) then
      state.awaitingAddResult = false
      Rebuild()
      return 0
    end
    if os.time() >= (state.addPendingUntil or 0) then
      state.awaitingAddResult = false
    end
  end
  return 0
end
