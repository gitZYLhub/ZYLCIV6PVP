include("InstanceManager")

local g_playerList = {}
local g_localBlackList = {}
local m_playerListIM = InstanceManager:new("PlayerListEntry", "RootContainer", Controls.PlayerListStack)
local m_blackListIM = InstanceManager:new("BlackListEntry", "RootContainer", Controls.BlackListStack)
local IDS_KEY = "ZYL_MPS_BLACKLIST_IDS"
local DESC_PREFIX = "ZYL_MPS_BLACKLIST_DESC_"

local function IsSteamID(value)
	return type(value) == "string" and #value == 17 and tonumber(value) ~= nil
end

local function ReadBlackList()
	local result = {}
	local ids = UserConfiguration.GetValue(IDS_KEY) or ""
	for steamID in string.gmatch(ids, "[^|]+") do
		if IsSteamID(steamID) then
			table.insert(result, { SteamID = steamID, Desc = UserConfiguration.GetValue(DESC_PREFIX .. steamID) or "" })
		end
	end
	return result
end

local function SaveBlackList()
	local ids = {}
	for _, data in ipairs(g_localBlackList) do
		if IsSteamID(data.SteamID) then
			table.insert(ids, data.SteamID)
			UserConfiguration.SetValue(DESC_PREFIX .. data.SteamID, data.Desc or "")
		end
	end
	UserConfiguration.SetValue(IDS_KEY, table.concat(ids, "|"))
	UserConfiguration.CommitToOptions()
end

local function CopyBlackListToClipboard()
	local lines = { Locale.Lookup("{1_Time : datetime full}", os.time()), "", "SteamID\t" .. Locale.Lookup("LOC_TPT_INPUT_DESC_NAME") }
	for _, data in ipairs(ReadBlackList()) do
		table.insert(lines, data.SteamID .. "\t" .. (data.Desc or ""))
	end
	UIManager:SetClipboardString(table.concat(lines, "\n"))
	Controls.CopyBlackListButton:SetToolTipString(Locale.Lookup("LOC_COPY_BLACKLIST_TITLE"))
	UI.PlaySound("Play_UI_Click")
end

local function FindBlackListEntry(steamID)
	for index, data in ipairs(g_localBlackList) do
		if data.SteamID == steamID then return index, data end
	end
	return nil, nil
end

local function IsMet(localPlayer, otherPlayerID)
	return localPlayer ~= nil and localPlayer:GetDiplomacy() ~= nil and localPlayer:GetDiplomacy():HasMet(otherPlayerID)
end

local function AddPlayer(playerID)
	local localID = Game.GetLocalPlayer()
	if playerID == localID then return end
	local config = PlayerConfigurations[playerID]
	if config == nil or not config:IsHuman() then return end
	local networkID = config:GetNetworkIdentifer()
	for _, data in ipairs(g_playerList) do
		if data.PlayerID == playerID or (IsSteamID(networkID) and data.SteamID == networkID) then return end
	end
	local _, black = FindBlackListEntry(networkID)
	table.insert(g_playerList, {
		PlayerID = playerID,
		SteamID = IsSteamID(networkID) and networkID or nil,
		Name = Locale.Lookup(config:GetPlayerName()),
		IsMet = IsMet(Players[localID], playerID),
		IsBan = black ~= nil,
		BanTT = black and black.Desc or "",
		Icon = "[ICON_ICON_" .. tostring(config:GetLeaderTypeName()) .. "]"
	})
end

function RefreshPlayerList()
	local localID = Game.GetLocalPlayer()
	for _, data in ipairs(g_playerList) do
		local _, black = FindBlackListEntry(data.SteamID)
		data.IsMet = IsMet(Players[localID], data.PlayerID)
		data.IsBan = black ~= nil
		data.BanTT = black and black.Desc or ""
	end
	m_playerListIM:ResetInstances()
	for index, data in ipairs(g_playerList) do
		local control = m_playerListIM:GetInstance()
		control.PlayerNameLen:SetText(data.Name)
		control.PlayerName:SetText(data.Name)
		control.ConnectionLabel:SetText(data.SteamID == nil and "无法获取 ID[icon_Exclamation]" or (data.IsBan and "黑名单[icon_CheckFail]" or "正常[icon_CheckmarkBlue]"))
		control.LeaderIcon:SetText(data.IsMet and data.Icon or "[ICON_ICON_LEADER_DEFAULT]")
		control.PlayerListPull:SetToolTipString(data.BanTT or "")
		control.AddBlackListButton:SetVoid1(index)
		control.AddBlackListButton:RegisterCallback(Mouse.eLClick, OnAddBlackList)
	end
	Controls.PlayerListStack:CalculateSize()
end

function RefreshBlackList()
	g_localBlackList = ReadBlackList()
	m_blackListIM:ResetInstances()
	for index, data in ipairs(g_localBlackList) do
		local control = m_blackListIM:GetInstance()
		control.BlackListPlayerLabel:SetText(data.SteamID)
		control.DescLen:SetText(data.Desc or "")
		control.DescLabel:SetText(data.Desc or "")
		control.BlackListPlayerButton:SetVoid1(index)
		control.BlackListPlayerButton:RegisterCallback(Mouse.eLClick, OnRemoveBlackList)
	end
	if #g_localBlackList == 0 then
		local control = m_blackListIM:GetInstance()
		control.BlackListPlayerLabel:SetText("")
		control.DescLen:SetText("添加黑名单")
		control.DescLabel:SetText("添加黑名单")
		control.BlackListPlayerButton:SetVoid1(-1)
		control.BlackListPlayerButton:RegisterCallback(Mouse.eLClick, OnRemoveBlackList)
	end
	Controls.BlackListStack:CalculateSize()
end

function OnAddBlackListButton()
	Controls.DescInputEditBox:SetText("")
	Controls.SteamIDInputEditBox:SetText("")
	Controls.CreateModGroupButton:SetDisabled(true)
	Controls.NameModGroupPopup:SetHide(false)
	Controls.NameModGroupPopupAlpha:SetToBeginning()
	Controls.NameModGroupPopupAlpha:Play()
	Controls.NameModGroupPopupSlide:SetToBeginning()
	Controls.NameModGroupPopupSlide:Play()
	Controls.SteamIDInputEditBox:TakeFocus()
end

function OnAddBlackList(index)
	OnAddBlackListButton()
	local data = g_playerList[index]
	if data ~= nil and data.SteamID ~= nil then Controls.SteamIDInputEditBox:SetText(data.SteamID) end
end

function OnRemoveBlackList(index)
	OnAddBlackListButton()
	local data = g_localBlackList[index]
	if data ~= nil then
		Controls.SteamIDInputEditBox:SetText(data.SteamID or "")
		Controls.DescInputEditBox:SetText(data.Desc or "")
	end
end

function Open() RefreshPlayerList(); ContextPtr:SetHide(false) end
function Close() ContextPtr:SetHide(true) end
function OnMultiplayerPlayerConnected(playerID) AddPlayer(playerID); RefreshPlayerList() end

function Initialize()
	ContextPtr:SetHide(true)
	RefreshBlackList()
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do AddPlayer(playerID) end
	RefreshPlayerList()
	Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close)
	Controls.CopyBlackListButton:RegisterCallback(Mouse.eLClick, CopyBlackListToClipboard)
	Controls.CancelBindingButton:RegisterCallback(Mouse.eLClick, function() Controls.NameModGroupPopup:SetHide(true) end)
	Controls.SteamIDInputEditBox:RegisterStringChangedCallback(function()
		local value = Controls.SteamIDInputEditBox:GetText() or ""
		if #value > 17 then value = string.sub(value, 1, 17); Controls.SteamIDInputEditBox:SetText(value) end
		local valid = IsSteamID(value)
		Controls.CreateModGroupButton:SetDisabled(not valid)
		local _, existing = FindBlackListEntry(value)
		Controls.RemoveGroupButton:SetHide(not valid or existing == nil)
		Controls.SteamHomePageButton:SetHide(not valid)
	end)
	Controls.SteamHomePageButton:RegisterCallback(Mouse.eLClick, function()
		local steamID = Controls.SteamIDInputEditBox:GetText()
		if IsSteamID(steamID) then Steam.ActivateGameOverlayToUrl("https://steamcommunity.com/profiles/" .. steamID) end
	end)
	Controls.CreateModGroupButton:RegisterCallback(Mouse.eLClick, function()
		local steamID = Controls.SteamIDInputEditBox:GetText()
		if not IsSteamID(steamID) then return end
		local index = FindBlackListEntry(steamID)
		if index ~= nil then table.remove(g_localBlackList, index) end
		table.insert(g_localBlackList, { SteamID = steamID, Desc = Controls.DescInputEditBox:GetText() or "" })
		SaveBlackList(); Controls.NameModGroupPopup:SetHide(true); RefreshBlackList(); RefreshPlayerList()
	end)
	Controls.RemoveGroupButton:RegisterCallback(Mouse.eLClick, function()
		local steamID = Controls.SteamIDInputEditBox:GetText()
		local index = FindBlackListEntry(steamID)
		if index ~= nil then table.remove(g_localBlackList, index) end
		UserConfiguration.SetValue(DESC_PREFIX .. tostring(steamID), "")
		SaveBlackList(); Controls.NameModGroupPopup:SetHide(true); RefreshBlackList(); RefreshPlayerList()
	end)
	Events.MultiplayerPlayerConnected.Add(OnMultiplayerPlayerConnected)
	LuaEvents.Open_BlackListOanel.Add(Open)
end

function OnShutdown()
	Events.MultiplayerPlayerConnected.Remove(OnMultiplayerPlayerConnected)
	LuaEvents.Open_BlackListOanel.Remove(Open)
end

ContextPtr:SetShutdown(OnShutdown)
Initialize()
