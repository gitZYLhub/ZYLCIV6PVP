include("Civ6Common")

-- Read-only in-game viewer for the roles dealt in the staging room. This UI
-- never writes gameplay properties, teams, diplomacy, wars or victory state.
local DEAL_CONFIG = "ZYL_IDENTITY_DEAL"
local DEAL_VERSION = 1

local ROLE_LORD = 1
local ROLE_LOYALIST = 2
local ROLE_REBEL = 3
local ROLE_SPY = 4

local ROLE_TEXT = {
  [ROLE_LORD] = { Name = "LOC_ZYL_IDENTITY_ROLE_LORD", Description = "LOC_ZYL_IDENTITY_ROLE_LORD_DESC" },
  [ROLE_LOYALIST] = { Name = "LOC_ZYL_IDENTITY_ROLE_LOYALIST", Description = "LOC_ZYL_IDENTITY_ROLE_LOYALIST_DESC" },
  [ROLE_REBEL] = { Name = "LOC_ZYL_IDENTITY_ROLE_REBEL", Description = "LOC_ZYL_IDENTITY_ROLE_REBEL_DESC" },
  [ROLE_SPY] = { Name = "LOC_ZYL_IDENTITY_ROLE_SPY", Description = "LOC_ZYL_IDENTITY_ROLE_SPY_DESC" }
}

local m_initialized = false
local m_autoOpened = false
local m_currentDeal = nil
local m_viewReady = false

local function IsEnabled()
  local value = GameConfiguration.GetValue("ZYL_IDENTITY_MODE")
  return value == true or tonumber(value) == 1
end

local function ReadConfigInteger(parameterID)
  local value = tonumber(GameConfiguration.GetValue(parameterID))
  if value == nil or value ~= math.floor(value) then return nil end
  return value
end

local function CampFor(role, playerID)
  if role == ROLE_LORD or role == ROLE_LOYALIST then return "lord-camp" end
  if role == ROLE_REBEL then return "rebel-camp" end
  return "independent-" .. tostring(playerID)
end

local function SettingsSignature(loyalistCount, rebelCount, spyCount, firstSelected, secondSelected)
  return table.concat({
    tostring(loyalistCount),
    tostring(rebelCount),
    tostring(spyCount),
    tostring(firstSelected),
    tostring(secondSelected)
  }, ",")
end

local function ParseLobbyDeal()
  local loyalistCount = ReadConfigInteger("ZYL_IDENTITY_LOYALIST_COUNT")
  local rebelCount = ReadConfigInteger("ZYL_IDENTITY_REBEL_COUNT")
  local spyCount = ReadConfigInteger("ZYL_IDENTITY_SPY_COUNT")
  local firstSelected = ReadConfigInteger("ZYL_IDENTITY_SEPARATE_PLAYER_1")
  local secondSelected = ReadConfigInteger("ZYL_IDENTITY_SEPARATE_PLAYER_2")
  if loyalistCount == nil or loyalistCount < 0
      or rebelCount == nil or rebelCount < 1
      or spyCount == nil or spyCount < 0
      or firstSelected == nil or secondSelected == nil then
    return nil
  end

  local payload = GameConfiguration.GetValue(DEAL_CONFIG)
  if type(payload) ~= "string" or payload == "" then return nil end
  local versionText, nonceText, signature, entriesText =
    string.match(payload, "^(%d+)|(%d+)|([%d,]+)|([%d:,]+)$")
  local version = tonumber(versionText)
  local nonce = tonumber(nonceText)
  if version ~= DEAL_VERSION
      or nonce == nil or nonce < 1 or nonce ~= math.floor(nonce)
      or signature ~= SettingsSignature(
        loyalistCount, rebelCount, spyCount, firstSelected, secondSelected) then
    return nil
  end

  local players = {}
  local playerIndex = {}
  local assignments = {}
  local counts = {
    [ROLE_LORD] = 0,
    [ROLE_LOYALIST] = 0,
    [ROLE_REBEL] = 0,
    [ROLE_SPY] = 0
  }
  local lordID = nil
  for entry in string.gmatch(entriesText, "[^,]+") do
    local playerIDText, roleText = string.match(entry, "^(%d+):(%d+)$")
    local playerID = tonumber(playerIDText)
    local role = tonumber(roleText)
    if playerID == nil or role == nil or assignments[playerID] ~= nil or counts[role] == nil then
      return nil
    end
    table.insert(players, playerID)
    playerIndex[playerID] = #players
    assignments[playerID] = role
    counts[role] = counts[role] + 1
    if role == ROLE_LORD then lordID = playerID end
  end

  if #players < 3 or #players > 12
      or 1 + loyalistCount + rebelCount + spyCount ~= #players
      or counts[ROLE_LORD] ~= 1
      or counts[ROLE_LOYALIST] ~= loyalistCount
      or counts[ROLE_REBEL] ~= rebelCount
      or counts[ROLE_SPY] ~= spyCount
      or lordID == nil
      or (firstSelected == 0) ~= (secondSelected == 0)
      or (firstSelected > 0 and firstSelected == secondSelected)
      or firstSelected < 0 or firstSelected > #players
      or secondSelected < 0 or secondSelected > #players then
    return nil
  end
  if firstSelected > 0 then
    local firstPlayerID = players[firstSelected]
    local secondPlayerID = players[secondSelected]
    if CampFor(assignments[firstPlayerID], firstPlayerID)
        == CampFor(assignments[secondPlayerID], secondPlayerID) then
      return nil
    end
  end

  return {
    Players = players,
    PlayerIndex = playerIndex,
    Assignments = assignments,
    LordID = lordID
  }
end

local function GetPlayerName(playerID)
  local config = PlayerConfigurations[playerID]
  if config == nil then return tostring(playerID) end
  local name = config:GetPlayerName()
  if name == nil or tostring(name) == "" then return tostring(playerID) end
  return Locale.Lookup(name)
end

local function ResetHiddenState()
  Controls.RoleButtonContainer:SetHide(true)
  Controls.Overlay:SetHide(true)
  Controls.PlayerOrder:SetHide(true)
  Controls.MaskContainer:SetHide(true)
  Controls.IdentityContainer:SetHide(true)
  Controls.ErrorContainer:SetHide(true)
end

local function Close()
  Controls.Overlay:SetHide(true)
end

local function ShowInvalid()
  Controls.RoleButtonContainer:SetHide(true)
  Controls.PlayerOrder:SetHide(true)
  Controls.MaskContainer:SetHide(true)
  Controls.IdentityContainer:SetHide(true)
  Controls.ErrorContainer:SetHide(false)
  Controls.ErrorText:SetText(Locale.Lookup("LOC_ZYL_IDENTITY_ERROR_DATA"))
  Controls.Overlay:SetHide(false)
end

local function PopulateLocalRole(deal, localPlayerID)
  local role = deal.Assignments[localPlayerID]
  local roleText = ROLE_TEXT[role]
  if roleText == nil then return false end

  Controls.PlayerOrder:SetText(Locale.Lookup(
    "LOC_ZYL_IDENTITY_PLAYER_ORDER", deal.PlayerIndex[localPlayerID]))
  Controls.RoleName:SetText(Locale.Lookup(roleText.Name))
  Controls.RoleDescription:SetText(Locale.Lookup(roleText.Description))
  Controls.LordName:SetText(GetPlayerName(deal.LordID))
  Controls.TeamLabel:SetHide(role ~= ROLE_REBEL)
  Controls.TeamNames:SetHide(role ~= ROLE_REBEL)
  if role == ROLE_REBEL then
    local teammates = {}
    for _, playerID in ipairs(deal.Players) do
      if playerID ~= localPlayerID and deal.Assignments[playerID] == ROLE_REBEL then
        table.insert(teammates, GetPlayerName(playerID))
      end
    end
    if #teammates == 0 then
      Controls.TeamNames:SetText(Locale.Lookup("LOC_ZYL_IDENTITY_NO_TEAMMATE"))
    else
      Controls.TeamNames:SetText(table.concat(
        teammates, Locale.Lookup("LOC_ZYL_IDENTITY_NAME_SEPARATOR")))
    end
  end
  return true
end

local function OpenMasked()
  if m_currentDeal == nil then return end
  Controls.PlayerOrder:SetHide(false)
  Controls.ErrorContainer:SetHide(true)
  Controls.MaskContainer:SetHide(false)
  Controls.IdentityContainer:SetHide(true)
  Controls.Overlay:SetHide(false)
end

local function Reveal()
  if m_currentDeal == nil then return end
  Controls.MaskContainer:SetHide(true)
  Controls.IdentityContainer:SetHide(false)
end

local function HideAgain()
  OpenMasked()
end

local function RefreshIdentity()
  if not IsEnabled() then
    m_currentDeal = nil
    ResetHiddenState()
    return
  end

  local deal = ParseLobbyDeal()
  if deal == nil then
    -- The UI context can initialize before the saved GameConfiguration has
    -- finished loading. Do not flash a false corruption warning in that gap.
    if not m_viewReady then return end
    if not m_autoOpened then
      m_autoOpened = true
      ShowInvalid()
    end
    return
  end

  local localPlayerID = Game.GetLocalPlayer()
  if deal.PlayerIndex[localPlayerID] == nil then
    m_currentDeal = nil
    ResetHiddenState()
    return
  end
  if not PopulateLocalRole(deal, localPlayerID) then
    if not m_autoOpened then
      m_autoOpened = true
      ShowInvalid()
    end
    return
  end

  m_currentDeal = deal
  Controls.ErrorContainer:SetHide(true)
  Controls.RoleButtonContainer:SetHide(false)
  if not m_autoOpened then
    m_autoOpened = true
    OpenMasked()
  end
end

local function OnGameViewReady()
  m_viewReady = true
  if m_currentDeal == nil then m_autoOpened = false end
  RefreshIdentity()
end

local function OnLocalPlayerChanged()
  m_autoOpened = false
  m_currentDeal = nil
  ResetHiddenState()
  RefreshIdentity()
end

local function OnInputHandler(input)
  if input:GetMessageType() == KeyEvents.KeyUp
      and input:GetKey() == Keys.VK_ESCAPE
      and not Controls.Overlay:IsHidden() then
    Close()
    return true
  end
  return false
end

local function Initialize()
  if m_initialized then return end
  m_initialized = true
  ContextPtr:SetHide(false)
  ResetHiddenState()
  Controls.RoleButton:RegisterCallback(Mouse.eLClick, OpenMasked)
  Controls.RevealButton:RegisterCallback(Mouse.eLClick, Reveal)
  Controls.HideButton:RegisterCallback(Mouse.eLClick, HideAgain)
  Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close)
  ContextPtr:SetInputHandler(OnInputHandler, true)
  Events.LoadGameViewStateDone.Add(OnGameViewReady)
  Events.LocalPlayerChanged.Add(OnLocalPlayerChanged)
  RefreshIdentity()
end

local function OnShutdown()
  Events.LoadGameViewStateDone.Remove(OnGameViewReady)
  Events.LocalPlayerChanged.Remove(OnLocalPlayerChanged)
end

ContextPtr:SetShutdown(OnShutdown)
Initialize()
