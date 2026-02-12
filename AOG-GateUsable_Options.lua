-- AOG-GateUsable_Options.lua
local ui
local cbEnabled, cbLock
local slSize, slX, slY
local nudgeBtns = {}

local function GetDB()
  return _G.AOGGateUsable and _G.AOGGateUsable.GetDB and _G.AOGGateUsable.GetDB() or nil
end

local function Apply()
  if _G.AOGGateUsable and _G.AOGGateUsable.Apply then
    _G.AOGGateUsable.Apply()
  end
end

local function MakeCheckbox(parent, text, x, y, onClick)
  local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  c:SetPoint("TOPLEFT", x, y)
  c.Text:SetText(text)
  c:SetScript("OnClick", onClick)
  return c
end

local function MakeSlider(parent, name, x, y, minV, maxV, step, fmt)
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", x, y)
  s:SetMinMaxValues(minV, maxV)
  s:SetValueStep(step)
  s:SetObeyStepOnDrag(true)

  s.Text:SetText(name)
  s.Low:SetText(tostring(minV))
  s.High:SetText(tostring(maxV))

  local val = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  val:SetPoint("TOPLEFT", x + 170, y - 2)

  s._setValText = function(_, v)
    if fmt then val:SetText(string.format(fmt, v))
    else val:SetText(string.format("%.0f", v)) end
  end

  return s
end

local function MakeButton(parent, text, x, y, w, h, onClick)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetPoint("BOTTOMLEFT", x, y)
  b:SetSize(w, h)
  b:SetText(text)
  b:SetScript("OnClick", onClick)
  return b
end

local function PickerGetRGB()
  if ColorPickerFrame and ColorPickerFrame.GetColorRGB then
    return ColorPickerFrame:GetColorRGB()
  end
  local cp = ColorPickerFrame and ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker
  if cp and cp.GetColorRGB then
    return cp:GetColorRGB()
  end
  return 1, 1, 1
end

local function OpenColorPicker(getColor, setColor)
  local r, g, b = getColor()
  local pr, pg, pb = r, g, b

  if ColorPickerFrame and ColorPickerFrame.SetupColorPickerAndShow then
    ColorPickerFrame:SetupColorPickerAndShow({
      r = r, g = g, b = b,
      hasOpacity = false,
      swatchFunc = function()
        local nr, ng, nb = PickerGetRGB()
        setColor(nr, ng, nb)
        Apply()
      end,
      cancelFunc = function()
        setColor(pr, pg, pb)
        Apply()
      end,
    })
    return
  end

  ColorPickerFrame.hasOpacity = false
  ColorPickerFrame.func = function()
    local nr, ng, nb = PickerGetRGB()
    setColor(nr, ng, nb)
    Apply()
  end
  ColorPickerFrame.cancelFunc = function()
    setColor(pr, pg, pb)
    Apply()
  end
  if ColorPickerFrame.SetColorRGB then
    ColorPickerFrame:SetColorRGB(r, g, b)
  end
  ColorPickerFrame:Show()
end

local function SetMoveControlsEnabled(enabled)
  slX:EnableMouse(enabled); slX:SetAlpha(enabled and 1 or 0.35)
  slY:EnableMouse(enabled); slY:SetAlpha(enabled and 1 or 0.35)
  for _, b in ipairs(nudgeBtns) do
    b:SetEnabled(enabled)
    b:SetAlpha(enabled and 1 or 0.35)
  end
end

local function RefreshControls()
  local db = GetDB(); if not db then return end
  ui._refreshing = true

  cbEnabled:SetChecked(db.enabled)
  cbLock:SetChecked(db.lockPos)

  slSize:SetValue(db.fontSize); slSize:_setValText(db.fontSize)
  slX:SetValue(db.pos[1]);      slX:_setValText(db.pos[1])
  slY:SetValue(db.pos[2]);      slY:_setValText(db.pos[2])

  SetMoveControlsEnabled(not db.lockPos)
  ui._refreshing = false
end

local function Nudge(dx, dy)
  local db = GetDB(); if not db then return end
  if db.lockPos then return end
  db.pos[1] = (db.pos[1] or 0) + dx
  db.pos[2] = (db.pos[2] or 0) + dy
  Apply()
  RefreshControls()
end

local function EnsureUI()
  if ui then return end

  ui = CreateFrame("Frame", "AOGGateUsableConfigUI", UIParent, "BackdropTemplate")
  ui:SetSize(420, 260)
  ui:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
  ui:SetFrameStrata("DIALOG")
  ui:SetMovable(true)
  ui:EnableMouse(true)
  ui:RegisterForDrag("LeftButton")
  ui:SetClampedToScreen(true)

  ui:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  ui:Hide()

  -- FIX: sonst bleibt es "kleben"
  ui:SetScript("OnDragStart", function(self) self:StartMoving() end)
  ui:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  local title = ui:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Gate Usable Config")

  cbEnabled = MakeCheckbox(ui, "Enabled", 16, -52, function()
    local db = GetDB(); if not db then return end
    db.enabled = cbEnabled:GetChecked() and true or false
    Apply()
  end)

  cbLock = MakeCheckbox(ui, "Lock position", 120, -52, function()
    local db = GetDB(); if not db then return end
    db.lockPos = cbLock:GetChecked() and true or false
    SetMoveControlsEnabled(not db.lockPos)
    Apply()
  end)

  slSize = MakeSlider(ui, "Font size", 16, -95, 12, 120, 1)
  slSize:SetScript("OnValueChanged", function(_, v)
    slSize:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    db.fontSize = math.floor(v + 0.5)
    Apply()
  end)

  slX = MakeSlider(ui, "X Offset", 220, -95, -800, 800, 1)
  slX:SetScript("OnValueChanged", function(_, v)
    slX:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    if db.lockPos then return end
    db.pos[1] = math.floor(v + 0.5)
    Apply()
  end)

  slY = MakeSlider(ui, "Y Offset", 220, -145, -800, 800, 1)
  slY:SetScript("OnValueChanged", function(_, v)
    slY:_setValText(v)
    if ui._refreshing then return end
    local db = GetDB(); if not db then return end
    if db.lockPos then return end
    db.pos[2] = math.floor(v + 0.5)
    Apply()
  end)

  -- Nudge row X
  local function MakeNudgeRow(anchorSlider, axis)
    local row = CreateFrame("Frame", nil, ui)
    row:SetSize(160, 20)
    row:SetPoint("TOP", anchorSlider, "BOTTOM", 0, -10)

    local values = {-5, -1, 1, 5}
    local prev
    for _, val in ipairs(values) do
      local b = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
      b:SetSize(36, 20)
      b:SetText(val > 0 and ("+"..val) or tostring(val))
      b:SetScript("OnClick", function()
        if axis == "x" then Nudge(val, 0) else Nudge(0, val) end
      end)
      if not prev then b:SetPoint("LEFT", row, "LEFT", 0, 0)
      else b:SetPoint("LEFT", prev, "RIGHT", 4, 0) end
      prev = b
      table.insert(nudgeBtns, b)
    end
  end
  MakeNudgeRow(slX, "x")
  MakeNudgeRow(slY, "y")

  local btnColor = MakeButton(ui, "Color", 16, 16, 90, 24, function()
    local db = GetDB(); if not db then return end
    OpenColorPicker(function()
      local c = db.color or {1,1,1}
      return c[1], c[2], c[3]
    end, function(r, g, b)
      db.color = {r, g, b}
    end)
  end)

  MakeButton(ui, "Center", 112, 16, 90, 24, function()
    local db = GetDB(); if not db then return end
    if db.lockPos then return end
    db.pos[1], db.pos[2] = 0, 120
    Apply()
    RefreshControls()
  end)

  MakeButton(ui, "Reset", 208, 16, 90, 24, function()
    local db = GetDB(); if not db then return end
    db.enabled  = true
    db.fontSize = 40
    db.color    = {1, 0.82, 0}
    db.pos      = {0, 120}
    db.lockPos  = true
    Apply()
    RefreshControls()
  end)

  local btnClose = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
  btnClose:SetSize(70, 24)
  btnClose:SetText("Close")
  btnClose:SetPoint("BOTTOMRIGHT", ui, "BOTTOMRIGHT", -16, 16)
  btnClose:SetScript("OnClick", function() ui:Hide() end)

  ui:SetScript("OnShow", function()
    local db = GetDB(); if not db then return end
    db.pos = db.pos or {0, 120}
    db.color = db.color or {1, 1, 1}
    if db.lockPos == nil then db.lockPos = true end
    RefreshControls()
    Apply()
  end)
end

SLASH_AOGGATECFG1 = "/gate"
SlashCmdList["AOGGATECFG"] = function()
  EnsureUI()
  if ui:IsShown() then ui:Hide() else ui:Show() end
end
