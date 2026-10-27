-- Run the actual communication and existing selector code without a realm or graphical client.
-- luacheck: std lua51
local addon = arg[1] or "."
local function source(path, mutation)
  local file = assert(io.open(addon .. "/" .. path, "r"))
  local text = file:read("*a"); file:close()
  if mutation and mutation[1] == path then
    local first, last = assert(text:find(mutation[2], 1, true), "mutation needle missing: " .. mutation[2])
    text = text:sub(1, first - 1) .. mutation[3] .. text:sub(last + 1)
  end
  return assert(loadstring(text, "@" .. addon .. "/" .. path))()
end

local function scenario(locale, mutation)
  local methods = {}
  local function object()
    local frame, fields = newproxy(true), { shown = true, scripts = {}, hooks = {} }
    getmetatable(frame).__index = function(_, key) return methods[key] or fields[key] end
    getmetatable(frame).__newindex = function(_, key, value) fields[key] = value end
    return frame
  end
  for _, name in ipairs({"SetFrameStrata", "SetPoint", "SetAllPoints", "ClearAllPoints", "SetBackdrop", "SetBackdropColor",
      "SetMovable", "EnableMouse", "RegisterForDrag", "SetClampedToScreen", "StartMoving", "StopMovingOrSizing",
      "RegisterForClicks", "SetPushedTexture", "SetHighlightTexture", "SetDesaturated"}) do
    methods[name] = function() end
  end
  function methods:SetSize(w, h) self.width, self.height = w, h end
  function methods:SetWidth(w) self.width = w end
  function methods:SetHeight(h) self.height = h end
  function methods:SetAlpha(alpha) self.alpha = alpha end
  function methods:SetParent(parent) self.parent = parent end
  function methods:SetFrameLevel(level) self.level = level end
  function methods:GetFrameLevel() return self.level or 1 end
  function methods:GetCenter() return 0, 0 end
  function methods:SetText(text) self.text = text end
  function methods:SetScript(key, callback) self.scripts[key] = callback end
  function methods:GetScript(key) return self.scripts[key] end
  function methods:HookScript(key, callback) self.hooks[key] = callback end
  function methods:Show() self.shown = true end
  function methods:Hide() self.shown = false end
  function methods:IsShown() return self.shown end
  function methods:CreateFontString() return object() end
  function methods:SetNormalTexture(path) self.normal = object(); self.normal.path = path end
  function methods:SetDisabledTexture(path) self.disabled = object(); self.disabled.path = path end
  function methods:GetNormalTexture() return self.normal end
  CreateFrame = function() return object() end
  UIParent = object()
  GameTooltip = { SetOwner = function() end, SetText = function(_, text) GameTooltip.text = text end,
      Show = function() end, Hide = function() end }
  GameTooltip_Hide = GameTooltip.Hide
  GetLocale = function() return locale end
  UnitName = function(unit) return unit == "player" and "Owner" or unit end
  GetRealmName = function() return "Fixture" end
  local now, timers, notices, sent = 20, {}, {}, {}
  GetTime = function() return now end
  strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
  wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
  tinsert = table.insert
  DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) notices[#notices + 1] = text end }
  SendChatMessage = function() error("combat profiles must not use legacy chat commands") end
  SendAddonMessage = function() error("the fixture captures Comm.Send below") end

  local locales, defaultLocale, windows = {}, {}, {}
  local aceLocale = {}
  function aceLocale:NewLocale(_, language, default)
    if default then defaultLocale = {}; locales[language] = defaultLocale; return defaultLocale end
    if language == locale then locales[language] = {}; return locales[language] end
  end
  function aceLocale:GetLocale() return locales[locale] or defaultLocale end
  local aceGUI = {}
  function aceGUI.Create(_, kind)
    assert(kind == "Window")
    local widget = { frame = object(), content = object() }
    function widget:SetTitle(title) self.title = title end
    function widget:SetWidth(width) self.width = width end
    function widget:SetHeight(height) self.height = height end
    function widget:EnableResize() end
    function widget:SetCallback(_, callback) self.onClose = callback end
    function widget:Release() self.frame:Hide() end
    windows[#windows + 1] = widget
    return widget
  end
  LibStub = setmetatable({ GetLibrary = function(_, name)
    if name == "AceGUI-3.0" then return aceGUI end
    if name == "AceLocale-3.0" then return aceLocale end
  end }, { __call = function(_, name) if name == "AceLocale-3.0" then return aceLocale end end })
  MultiBotSave = nil
  MultiBot = { db = { profile = {} }, GetProfileMigrationStore = function() return {} end,
      ShouldSyncLegacyState = function() return false end,
      TimerAfter = function(delay, callback) timers[#timers + 1] = { at = now + delay, callback = callback } end }
  source("Core/MultiBotLocale.lua", mutation)
  source("Locales/MultiBotAceLocale-enUS.lua", mutation)
  source("Locales/MultiBotAceLocale-deDE.lua", mutation)
  source("Core/MultiBotComm.lua", mutation)
  source("UI/MultiBotSpecUI.lua", mutation)
  StaticPopupDialogs = {}
  MultiBot.hasStrategy = function(strategies, name) return strategies:find(name, 1, true) ~= nil end
  MultiBot.IsFavorite = function() return false end
  source("Core/MultiBotEvery.lua", mutation)
  local function toolbar(name)
    local frame = {buttons = {}, frames = {}, getName = function() return name end}
    function frame:Hide() self.shown = false end
    function frame:Show() self.shown = true end
    frame.getButton = function(key) return frame.buttons[key] end
    frame.addButton = function(key)
      local button = {frame = object(), scripts = {}, getName = frame.getName, getClass = function() return "Warrior" end}
      button.setEnable = function() button.state = true; return button end
      button.setDisable = function() button.state = false; return button end
      button.doShow = function() button.shown = true; return button end
      button.doHide = function() button.shown = false; return button end
      function button:GetScript(event) return self.scripts[event] end
      function button:SetScript(event, callback) self.scripts[event] = callback end
      function button:Show() self.shown = true end
      function button:Hide() self.shown = false end
      frame.buttons[key] = button
      return button
    end
    frame.addFrame = function(key)
      local child = toolbar(name)
      frame.frames[key] = child
      return child
    end
    return frame
  end
  local selfToolbar, botToolbar = toolbar("Owner"), toolbar("Altbot")
  MultiBot.addEvery(selfToolbar, "focus", "food loot")
  MultiBot.addEvery(botToolbar, "", "")
  local selfProfile = assert(selfToolbar.buttons.SetTalents, "SelfBot toolbar has no combat-profile selector")
  local botProfile = assert(botToolbar.buttons.SetTalents)
  assert(not selfToolbar.buttons.Talent and not selfToolbar.buttons.Inventory, "SelfBot gained bot-only tools")
  local comm, spec = MultiBot.Comm, MultiBot.spec
  comm.Send = function(opcode, payload)
    assert(not payload:find("TALENT_SPEC_APPLY", 1, true), "profile mode wrote talent templates")
    sent[#sent + 1] = { opcode = opcode, payload = payload }
    return true
  end
  local refreshed
  local nativeRequestState = comm.RequestState
  comm.RequestState = function(bot) refreshed = bot end
  local function deliver(opcode, payload, sender)
    comm.HandleAddonMessage("MBOT", opcode .. "~" .. payload, "WHISPER", sender or "Owner")
  end
  local function connect(selfBot)
    MultiBot.bridge.connected = true
    deliver("CAPS_BEGIN", "")
    deliver("CAPS", "COMBAT_PROFILE_V1")
    if selfBot then deliver("CAPS", "SELF_BOT_V1,SELF_STRATEGY_V1,STATE_FRAMING_V1") end
    deliver("CAPS_END", "")
    if selfBot then
      local token = assert(comm.RequestSelfBotState())
      deliver("SELF_BOT_STATE", token .. "~OK~1~OK")
      assert(MultiBot.bridge.selfBotLastActive, "SelfBot state was not authoritative")
    end
  end
  local function expire()
    now = now + 6
    local old = timers; timers = {}
    for _, timer in ipairs(old) do if timer.at <= now then timer.callback() else timers[#timers + 1] = timer end end
  end
  local function wrapper(class)
    return { frame = object(), getClass = function() return class or "Warrior" end,
        setDisable = function(self) self.disabled = true end }
  end
  local function request(bot, class)
    spec:RequestList(bot or "Altbot", wrapper(class))
    local packet = sent[#sent]
    assert(packet.opcode == "GET" and packet.payload:match("^COMBAT_PROFILES~"), "chooser did not request profiles")
    return assert(packet.payload:match("~([^~]+)$"))
  end
  local function listing(token, bot, selected, effective, choices)
    deliver("COMBAT_PROFILES", token .. "~" .. (bot or "Altbot") .. "~" .. (selected or "auto") .. "~"
        .. (effective or "fury") .. "~" .. (choices or "auto,arms,fury,prot"))
  end
  local function ack(token, bot, status, reason, selected, effective)
    deliver("COMBAT_PROFILE_RESULT", table.concat({ token, bot, status, reason, selected, effective }, "~"))
  end

  for _, reason in ipairs({ "BAD_REQUEST", "NO_BOT", "BOT_UNAVAILABLE", "NO_AI", "FORBIDDEN", "RATE_LIMIT",
      "IN_COMBAT", "DEAD", "BAD_PROFILE", "TOO_LARGE", "PROTOCOL_ERROR", "TIMEOUT", "DISCONNECTED", "BRIDGE_UNAVAILABLE" }) do
    assert(MultiBot.L("combat.profile.reason." .. reason, reason) ~= reason, "profile failure is not localized: " .. reason)
  end
  connect()
  assert(comm.IsCombatProfileCapable(), "bridge capability was not registered")
  assert(not comm.RunCombatProfile("Altbot", "fury~bad"), "invalid profile id was sent")
  local token = request()
  listing(token, "Otherbot")
  assert(not spec.dropdown and MultiBot.bridge.combatProfileCommands[token], "wrong-bot list was accepted")
  deliver("COMBAT_PROFILES", token .. "~Altbot~auto~fury~auto,arms,fury,prot", "Unrelated")
  assert(not spec.dropdown, "a non-bridge sender opened the menu")
  listing(token)
  assert(spec.dropdown:IsShown() and #spec.buttons == 4, "profile choices were not rendered")
  assert(windows[#windows].title == (locale == "deDE" and "Kampfprofil auswählen" or "Select combat profile"))
  assert(spec.buttons[3].profileLabel.text == (locale == "deDE" and "Furor" or "Fury"), "profile label is not localized")
  assert(spec.buttons[3].width == 210 and spec.buttons[3]:GetNormalTexture().width == 32,
      "profile row stretched its icon")
  assert(spec.buttons[1]:GetScript("OnClick"), "selected automatic profile must remain applicable")
  spec.buttons[1]:GetScript("OnEnter")(spec.buttons[1])
  assert(GameTooltip.text:find(locale == "deDE" and "Furor" or "Fury", 1, true), "automatic profile omitted effective spec")
  local fury = spec.buttons[3]
  fury:GetScript("OnClick")(fury, "RightButton")
  local applied = sent[#sent]
  assert(applied.opcode == "RUN" and applied.payload:match("^COMBAT_PROFILE~.*~Altbot~fury$"),
      "right-click did not apply a combat profile without a spec slot")
  local applyToken = applied.payload:match("^COMBAT_PROFILE~([^~]+)")
  assert(spec.busy and #notices == 0, "profile was announced before server confirmation")
  ack(applyToken, "Otherbot", "OK", "OK", "fury", "fury")
  assert(spec.busy and MultiBot.bridge.combatProfileCommands[applyToken], "wrong-bot acknowledgement was accepted")
  ack(applyToken, "Altbot", "OK", "OK", "prot", "prot")
  assert(spec.busy, "wrong profile acknowledgement was accepted")
  ack(applyToken, "Altbot", "OK", "OK", "fury", "fury")
  assert(not spec.busy and refreshed == "Altbot" and #notices == 1, "confirmed profile did not refresh strategy state")
  assert(notices[1]:find(locale == "deDE" and "Furor" or "Fury", 1, true))

  token = request()
  listing(token, "Altbot", "fury")
  assert(spec.buttons[3]:GetScript("OnClick"), "selected manual profile must remain applicable for gear refresh")
  local auto = spec.buttons[1]
  auto:GetScript("OnClick")(auto, "LeftButton")
  applyToken = sent[#sent].payload:match("^COMBAT_PROFILE~([^~]+)")
  ack(applyToken, "Altbot", "OK", "OK", "auto", "prot")
  assert(not spec.busy and notices[#notices]:find(locale == "deDE" and "Schutz" or "Protection", 1, true))

  token = request("Magebot", "Mage")
  listing(token, "Magebot", "auto", "frostfire", "auto,arcane,fire,frost")
  assert(spec.dropdown:IsShown(), "automatic frostfire requires no separate manual profile")
  spec:HideDropdown()
  token = request()
  listing(token, "Altbot", "auto", "fury", "auto,arms,fury,fury")
  assert(not spec.dropdown and MultiBot.bridge.combatProfileCommands[token], "duplicate profiles were accepted")
  listing(token, "Altbot", "auto", "fury", "auto,a,b,c,d,e,f,g,h")
  assert(not spec.dropdown and MultiBot.bridge.combatProfileCommands[token], "unbounded profile list was accepted")
  deliver("COMBAT_PROFILES", token .. "~Altbot~auto~fury~auto,arms%0A,fury")
  assert(not spec.dropdown and MultiBot.bridge.combatProfileCommands[token], "malformed profile id was accepted")
  expire()
  assert(not spec.pending and notices[#notices]:find(locale == "deDE" and "nicht geantwortet" or "did not reply", 1, true),
      "list timeout left the selector pending")

  local oldToken = request("Oldbot")
  local newToken = request("Newbot")
  listing(oldToken, "Oldbot")
  assert(not spec.dropdown and spec.pending.bot == "Newbot", "late old-target reply replaced the current menu")
  listing(newToken, "Newbot")
  assert(spec.dropdown:IsShown())
  spec:HideDropdown()
  token = request()
  spec:HideDropdown()
  listing(token)
  assert(not spec.dropdown, "a reply reopened a closed selector")

  token = request()
  ack(token, "Altbot", "ERR", "FORBIDDEN", "auto", "")
  assert(not spec.pending and notices[#notices]:find(locale == "deDE" and "kontrollierst" or "control", 1, true),
      "list denial did not clear pending UI")
  token = request()
  listing(token)
  fury = spec.buttons[3]
  fury:GetScript("OnClick")(fury, "LeftButton")
  applyToken = sent[#sent].payload:match("^COMBAT_PROFILE~([^~]+)")
  ack(applyToken, "Altbot", "ERR", "IN_COMBAT", "auto", "fury")
  assert(not spec.busy and notices[#notices]:find(locale == "deDE" and "Kampf verlassen" or "leave combat", 1, true),
      "server rejection was displayed as a successful profile")

  token = request()
  listing(token)
  fury = spec.buttons[3]
  fury:GetScript("OnClick")(fury, "LeftButton")
  applyToken = sent[#sent].payload:match("^COMBAT_PROFILE~([^~]+)")
  expire()
  assert(not spec.busy and not MultiBot.bridge.combatProfileCommands[applyToken],
      "application timeout left profile controls locked")

  token = request()
  deliver("ERR", "GET~COMBAT_PROFILES~" .. token .. "~BAD_REQUEST")
  assert(not spec.pending and MultiBot.bridge.combatProfileCommands[token] == nil,
      "protocol rejection left the selector pending")
  token = request()
  deliver("ERR", "GET~COMBAT_PROFILES~" .. token .. "~TOO_LARGE")
  assert(not spec.pending and notices[#notices]:find(locale == "deDE" and "Nachrichtengrenze" or "message limit", 1, true),
      "oversized response did not release the selector with a localized error")
  for _, reason in ipairs({ "BAD_REQUEST", "TOO_LARGE" }) do
    token = request()
    listing(token)
    fury = spec.buttons[3]
    fury:GetScript("OnClick")(fury, "LeftButton")
    applyToken = sent[#sent].payload:match("^COMBAT_PROFILE~([^~]+)")
    deliver("ERR", "RUN~COMBAT_PROFILE~" .. applyToken .. "~" .. reason)
    assert(not spec.busy and not MultiBot.bridge.combatProfileCommands[applyToken],
        "protocol rejection left application controls locked")
  end
  request()
  comm.MarkDisconnected("fixture")
  assert(not spec.pending and not spec.busy and next(MultiBot.bridge.combatProfileCommands) == nil,
      "disconnect left profile requests pending")
  assert(not comm.IsCombatProfileCapable())

  connect(true)
  selfProfile.doLeft(selfProfile)
  local selfToken = assert(sent[#sent].payload:match("^COMBAT_PROFILES~Owner~(.+)$"), "SelfBot selector targeted an altbot")
  listing(selfToken, "Owner")
  assert(selfProfile.state and spec.dropdown:IsShown(), "SelfBot profile button did not follow its own menu")
  spec.buttons[3]:GetScript("OnClick")(spec.buttons[3], "LeftButton")
  local ownApply = assert(sent[#sent].payload:match("^COMBAT_PROFILE~([^~]+)~Owner~fury$"), "SelfBot profile used the wrong target")
  local captureRequestState = comm.RequestState
  comm.RequestState = nativeRequestState
  ack(ownApply, "Owner", "OK", "OK", "fury", "fury")
  assert(not selfProfile.state and not spec.busy, "SelfBot profile acknowledgement left stale UI")
  assert(sent[#sent].payload:match("^SELF_STRATEGY_STATE~"), "SelfBot profile refresh used ordinary bot state")
  comm.RequestState = captureRequestState
  assert(nativeRequestState("Altbot") and sent[#sent].payload:match("^STATE~Altbot~"),
      "ordinary bot strategy refresh was redirected to SelfBot")
  local inactiveToken = assert(comm.RequestSelfBotState())
  deliver("SELF_BOT_STATE", inactiveToken .. "~OK~0~OK")
  local beforeInactive = #sent
  assert(not nativeRequestState("Owner") and #sent == beforeInactive,
      "inactive human character fell through to ordinary bot state")

  botProfile.doLeft(botProfile)
  listing(assert(sent[#sent].payload:match("~([^~]+)$")))
  assert(botProfile.state and spec.dropdown:IsShown())
  selfProfile.doLeft(selfProfile)
  assert(not botProfile.state and selfProfile.state and spec.pending.bot == "Owner", "switching profile targets did not move the pressed button")
  listing(assert(sent[#sent].payload:match("~([^~]+)$")), "Owner")
  selfProfile.doLeft(selfProfile)
  assert(not selfProfile.state and not spec.dropdown, "SelfBot profile button did not close its own menu")

  local beforeUnsupported = #sent
  MultiBot.bridge.combatProfileCapable = false
  MultiBot.allowLegacyChatFallback = true
  selfProfile.doLeft(selfProfile)
  assert(#sent == beforeUnsupported and not selfProfile.state and not spec.pending,
      "unsupported SelfBot profile fell through to legacy talent commands")
  MultiBot.allowLegacyChatFallback = nil
  MultiBot.bridge.combatProfileCapable = true
  local realSend = comm.Send
  comm.Send = function() return false end
  selfProfile.doLeft(selfProfile)
  assert(not selfProfile.state and not spec.activeWrapper, "failed SelfBot profile request left its button pressed")
  comm.Send = realSend

  local before = #sent
  for _ = 1, 8 do assert(comm.RequestCombatProfiles("Altbot")) end
  assert(not comm.RequestCombatProfiles("Altbot") and #sent == before + 8, "request bound was removed")
  comm.MarkDisconnected("fixture")
  connect()
  MultiBot.bridge.combatProfileCapable = false
  token = comm.RequestTalentSpecList("Altbot")
  assert(token and sent[#sent].payload:match("^TALENT_SPEC_LIST~"), "legacy server talent selector was removed")
end

scenario("enUS")
scenario("deDE")
local mutations = {
  { "Core/MultiBotComm.lua", '  ["COMBAT_PROFILE_V1"] = "combatProfileCapable",', '' },
  { "Core/MultiBotComm.lua", 'string.lower(botName) ~= pending.botNameKey', 'false' },
  { "Core/MultiBotComm.lua", 'or #profiles >= 8', '' },
  { "Core/MultiBotComm.lua", 'fields[5] ~= pending.profile', 'false' },
  { "Core/MultiBotComm.lua", '#fields ~= 6 or not botName or string.lower(botName) ~= pending.botNameKey',
      '#fields ~= 6 or not botName' },
  { "Core/MultiBotComm.lua", 'if Comm.HandleCombatProfileProtocolError(requestType, token, reason) then', 'if false then' },
  { "UI/MultiBotSpecUI.lua", '            if self.pending ~= pending then return end', '' },
  { "Core/MultiBotEvery.lua", '\t\taddSpecButton(pFrame, everyActionStartX + 120, true)\n', '' },
  { "Core/MultiBotEvery.lua", 'if selfOnly and not (comm and comm.IsCombatProfileCapable and comm.IsCombatProfileCapable()) then', 'if false then' },
  { "Core/MultiBotEvery.lua", 'and spec.activeWrapper == self then', 'then' },
  { "Core/MultiBotEvery.lua", 'if spec.activeWrapper == self then self:setEnable() end', 'self:setEnable()' },
  { "Core/MultiBotComm.lua", '    return Comm.RequestSelfStrategyState()\n', '    return false\n' },
}
for _, mutation in ipairs(mutations) do
  local ok, errorText = pcall(scenario, "enUS", mutation)
  assert(not ok, "unsafe combat profile mutation passed: " .. mutation[2])
  assert(tostring(errorText):find("test_combat_profiles.lua:", 1, true),
      "mutation failed outside fixture assertions: " .. tostring(errorText))
end
print("Combat profile selector: real communication/menu, locales, authority, lifecycle and mutations passed")
