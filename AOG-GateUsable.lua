-- AOG-GateUsable.lua
-- Shows "GATE USABLE" when Gateway Control Shard (188152) is usable.

local ADDON = ...
local f = CreateFrame("Frame")

-- ===== CONFIG =====
local ITEM_ID = 188152 -- Gateway Control Shard
local TEXT = "GATE USABLE"

local DEFAULTS = {
  enabled  = true,
  fontSize = 40,
  color    = { 1, 0.82, 0 }, -- gold-ish
  pos      = { 0, 120 },
  lockPos  = true,
}
-- ==================

AOGGateUsableDB = AOGGateUsableDB or {}

local configOpen = false -- Preview: wenn true => Text immer anzeigen (für Config)

local textFS
local lastShown = nil


local function CopyDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = dst[k] or {}
      CopyDefaults(dst[k], v)
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
end

local function HasShard()
  return (GetItemCount(ITEM_ID, false, false) or 0) > 0
end

local function IsShardUsable()
  if not C_Item or not C_Item.IsUsableItem then return false end
  local usable, noMana = C_Item.IsUsableItem(ITEM_ID)
  return usable == true and noMana ~= true
end

local function IsShardOffCooldown()
  if not C_Item or not C_Item.GetItemCooldown then return true end
  local start, duration, enable = C_Item.GetItemCooldown(ITEM_ID)
  if enable == 0 then return false end
  if not start or start == 0 then return true end
  if not duration or duration == 0 then return true end
  return (start + duration - GetTime()) <= 0.05
end

local function ShouldShow()
  local db = AOGGateUsableDB

  if not db.enabled then
    return false
  end

  -- PREVIEW: wenn Config offen ist, Text immer zeigen (ohne Gate nötig)
  if configOpen then
    return true
  end

  -- Normalbetrieb:
  if not HasShard() then return false end
  if not IsShardUsable() then return false end
  if not IsShardOffCooldown() then return false end

  return true
end


local function ApplyTextStyle()
  if not textFS then return end
  local db = AOGGateUsableDB

  textFS:ClearAllPoints()
  textFS:SetPoint("CENTER", UIParent, "CENTER", db.pos[1], db.pos[2])

  local fontPath, _, fontFlags = textFS:GetFont()
  textFS:SetFont(fontPath, db.fontSize, fontFlags)

  local c = db.color or {1,1,1}
  textFS:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, 1)
end

local function Update()
  if not textFS then return end

  local show = ShouldShow()
  if show == lastShown then return end
  lastShown = show

  if show then
    textFS:Show()
  else
    textFS:Hide()
  end
end


local function CreateUI()
  textFS = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  textFS:SetText(TEXT)
  textFS:Hide()
  ApplyTextStyle()
end

-- API für Options.lua
_G.AOGGateUsable = _G.AOGGateUsable or {}
_G.AOGGateUsable.GetDB = function() return AOGGateUsableDB end
_G.AOGGateUsable.Apply = function()
  ApplyTextStyle()
  Update()
end
_G.AOGGateUsable.SetConfigOpen = function(open)
  configOpen = open and true or false
  Update()
end


f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("SPELL_UPDATE_USABLE")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")

f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 ~= ADDON then return end

  if event == "ADDON_LOADED" then
    AOGGateUsableDB = AOGGateUsableDB or {}
    CopyDefaults(AOGGateUsableDB, DEFAULTS)
    if not textFS then CreateUI() end
    Update()
    return
  end

  if event == "PLAYER_LOGIN" then
    if not textFS then CreateUI() end
    _G.AOGGateUsable.Apply()
    return
  end

  Update()
end)

-- Debug
SLASH_AOGGATE1 = "/aoggate"
SlashCmdList["AOGGATE"] = function(msg)
  msg = (msg or ""):lower()
  if msg == "dump" then
    print("HasShard:", HasShard())
    local usable, noMana = C_Item.IsUsableItem(ITEM_ID)
    print("IsUsableItem:", usable, "noMana:", noMana)
    local s, d, e = C_Item.GetItemCooldown(ITEM_ID)
    print("Cooldown:", s, d, e)
    return
  end
  print("/aoggate dump")
end
