-- Copyright 2016-2019, Firaxis Games
-- (Multiplayer) Drop Control By D. / Jack The Narrator
include("InstanceManager");
include("PopupDialog");

-- ===========================================================================
--	Variables
-- ===========================================================================
local UIEvents = ExposedMembers.LuaEvents;
local _kPopupDialog = {}
local g_dropped_player_list = {};
local m_visible = false
local m_last_update = 0
local m_tick_registered = false
local m_suite_requested_pause = false
local UpdateData

local function IsHost()
	local localID = Network.GetLocalPlayerID()
	local hostID = Network.GetGameHostPlayerID()
	return localID ~= nil and hostID ~= nil and localID >= 0 and localID == hostID
end

local function HasDroppedPlayers()
	for _, player in ipairs(g_dropped_player_list) do
		if player.IsDropped == true then return true end
	end
	return false
end

local function SetTicking(enabled)
	if enabled and not m_tick_registered then
		Events.GameCoreEventPublishComplete.Add(OnTimeTicks)
		m_tick_registered = true
	elseif not enabled and m_tick_registered then
		Events.GameCoreEventPublishComplete.Remove(OnTimeTicks)
		m_tick_registered = false
	end
end

local function RestoreHostPauseState()
	if not IsHost() or not m_suite_requested_pause then return end
	local config = PlayerConfigurations[Network.GetLocalPlayerID()]
	if config ~= nil and config:GetWantsPause() then
		config:SetWantsPause(false)
		Network.BroadcastPlayerInfo()
	end
	m_suite_requested_pause = false
end

-- ===========================================================================
--	New Functions
-- ===========================================================================
function OnMultiplayerPrePlayerDisconnected( playerID )
	if type(playerID) ~= "number" or playerID < 0 or not UpdateData(playerID, true) then
		return
	end
	ContextPtr:SetHide(false);
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	m_visible = true
	if localID == hostID then
		Controls.HostLabel:SetText(Locale.Lookup("LOC_MPH_DROP_HOST_WARNING_TEXT"))
		Controls.Button_Resume:RegisterCallback( Mouse.eLClick, OnHostResume );
		Controls.Button_Resume:SetText(Locale.Lookup("LOC_MPH_DROP_HOST_BUTTON_TEXT"))
		else
		Controls.HostLabel:SetText("")
		Controls.Button_Resume:RegisterCallback( Mouse.eLClick, OnClose );
		Controls.Button_Resume:SetText(Locale.Lookup("LOC_MPH_DROP_NORMAL_BUTTON_TEXT"))
	end
	
	if (localID == hostID and GameConfiguration.IsPaused() == false) then
		local localPlayerID = localID;
		local localPlayerConfig = PlayerConfigurations[localPlayerID];
		if localPlayerConfig ~= nil and not localPlayerConfig:GetWantsPause() then
			localPlayerConfig:SetWantsPause(true);
			Network.BroadcastPlayerInfo();
			m_suite_requested_pause = true
		end
	end
	
	UIEvents.UICPLPlayerDrop( playerID );
end


function OnMultplayerPlayerConnected( playerID )
	if type(playerID) == "number" and playerID >= 0 and UpdateData(playerID, false) then
		UIEvents.UICPLPlayerConnect( playerID );
	end
end

UpdateData = function(playerID:number,disconnected:boolean)
	if disconnected == true then
		local now = math.floor(Automation.GetTime())
		for _, player in ipairs(g_dropped_player_list) do
			if player.ID == playerID then
				if player.IsDropped == true then
					return false
				end
				player.RefTime = now
				player.ElapsedTime = 0
				player.IsDropped = true
				SetTicking(true)
				return true
			end
		end
		table.insert(g_dropped_player_list, {
			ID = playerID,
			RefTime = now,
			ElapsedTime = 0,
			IsDropped = true
		})
		SetTicking(true)
		return true
	else
		for _, player in ipairs(g_dropped_player_list) do
			if player.ID == playerID and player.IsDropped == true then
				player.IsDropped = false
				if not HasDroppedPlayers() then
					SetTicking(false)
					if IsHost() then
						Controls.HostLabel:SetText("All players are connected. Resume when everyone is ready.")
					else
						OnClose()
					end
				end
				return true
			end	
		end
	end
	return false
end

function OnTimeTicks()
	local currentTime = math.floor(Automation.GetTime())
	local b_everyoneisingame = true
	for i, player in ipairs(g_dropped_player_list) do
		if player.IsDropped == true then
			b_everyoneisingame = false
			if currentTime > player.RefTime then
				player.ElapsedTime = player.ElapsedTime + currentTime - player.RefTime
				player.RefTime = currentTime
			end
		end
	end	
	if m_visible == true and currentTime >= m_last_update + 1 then
		m_last_update = currentTime
		UpdateText()
	end
	if b_everyoneisingame == true then
		SetTicking(false)
	end
end

function UpdateText()
	local str = ""
	for i, player in ipairs(g_dropped_player_list) do
		if player.IsDropped == true then
			local playerConfig = PlayerConfigurations[player.ID]
			local playerName = playerConfig ~= nil and Locale.Lookup(playerConfig:GetPlayerName()) or ("Player #" .. tostring(player.ID))
			str = str..tostring(playerName).."  -  "
			if player.ElapsedTime > 600 then
				str = str.."[COLOR_Civ6Red]"..tostring(player.ElapsedTime).."[ENDCOLOR][NEWLINE]"
				else
				str = str.."[COLOR_Civ6Green]"..tostring(player.ElapsedTime).."[ENDCOLOR][NEWLINE]"
			end
		end
	end	
	Controls.DropPlayerList:SetText(tostring(str))
end

-- ===========================================================================
--	Callback
-- ===========================================================================
function OnShutdown()
	ContextPtr:SetHide(true);
	SetTicking(false)
	RestoreHostPauseState()
	Events.MultiplayerPlayerConnected.Remove ( OnMultplayerPlayerConnected )
	Events.MultiplayerPrePlayerDisconnected.Remove ( OnMultiplayerPrePlayerDisconnected )
end

function OnHostResume()
	m_visible = false
	ConfirmResume()
end

function ConfirmResume()
	if IsHost() then
		if _kPopupDialog == nil then
		_kPopupDialog = PopupDialog:new( "VotePanel" );
		end

		if (not _kPopupDialog:IsOpen()) then
			_kPopupDialog:AddTitle("Resume Game");
			_kPopupDialog:AddText("Are you sure to resume the game?");
			_kPopupDialog:AddButton( "Yes", OnYesResume, nil, nil, "PopupButtonInstanceRed" );
			_kPopupDialog:AddButton( "No", OnNoResume );
			_kPopupDialog:Open();
		end
	end
end


function OnYesResume( )
	ContextPtr:SetHide(true);
	for i, player in ipairs(g_dropped_player_list) do
		if player.IsDropped == true then
			player.IsDropped = false
			player.RefTime =  math.floor(Automation.GetTime())
			UIEvents.UICPLPlayerConnect( player.ID );
		end
	end	
	SetTicking(false)
	m_visible = false
	RestoreHostPauseState()
	_kPopupDialog:Close();
	ContextPtr:SetHide(true);
end

function OnNoResume( )
	_kPopupDialog:Close();
	ContextPtr:SetHide(false);
	m_visible = true
end


function OnClose()
	ContextPtr:SetHide(true);
	m_visible = false
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetHide(true);
	ContextPtr:SetShutdown( OnShutdown );
	Controls.DropTitle:SetText(Locale.Lookup("LOC_MPH_DROP_TITLE_TEXT"))
	Controls.DropLabel:SetText(Locale.Lookup("LOC_MPH_DROP_LABEL_TEXT"))
	_kPopupDialog = PopupDialog:new( "DropControl" );
	Events.MultiplayerPlayerConnected.Add( OnMultplayerPlayerConnected );
	Events.MultiplayerPrePlayerDisconnected.Add( OnMultiplayerPrePlayerDisconnected );
end
Initialize();
