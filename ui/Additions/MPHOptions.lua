-- ===========================================================================
--	MPH Options
-- ===========================================================================
include("Civ6Common");
include("InstanceManager");
include("PopupDialog");
print("MPH very own In Game option menu")

-- ===========================================================================
--	Variable
-- ===========================================================================
local m_active = false
local b_admin = false
local m_extraTime
local _kPopupDialog:table;
local m_hostResyncPending = {}
local m_hostResyncStartedAt = nil
local m_hostPausedForResync = false
local m_clientResyncInProgress = false
local m_clientResyncReason = nil
local m_targetedResyncRequested = {}
local RESYNC_PAUSE_TIMEOUT_SECONDS = 30


-- Quick utility function to determine if Rise and Fall is installed.
function HasExpansion1()
	local xp1ModId = "1B28771A-C749-434B-9053-D1380C553DE9";
	return Modding.IsModInstalled(xp1ModId);
end

-- Quick utility function to determine if Rise and Fall is installed.
function HasExpansion2()
	local xpModId = "4873eb62-8ccc-4574-b784-dda455e74e68";
	return Modding.IsModInstalled(xpModId);
end

function IsInGame()
	if(GameConfiguration ~= nil) then
		return GameConfiguration.GetGameState() ~= GameStateTypes.GAMESTATE_PREGAME;
	end
	return false;
end

function OnShow()
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	m_active = true
	ContextPtr:SetHide(false);
	
	b_admin = (hostID == localID)
	if b_admin then
		Controls.WindowTitle:SetText(Locale.Lookup("LOC_MPH_ADMIN_OPTIONS"))
		else
		Controls.WindowTitle:SetText(Locale.Lookup("LOC_MPH_PLAYER_OPTIONS"))
	end
	
	SetupButtons()
end

function SetupButtons()
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	local currentTurn = Game.GetCurrentGameTurn()
	local startingTurn = GameConfiguration.GetStartTurn()
	Controls.RemapButton:SetHide(not b_admin)
	Controls.RetimeButton:SetHide(not b_admin)
	Controls.ResyncButton:SetHide(not b_admin)
	Controls.ForceEndButton:SetHide(not b_admin)
	if GameConfiguration.GetValue("GAMEMODE_SUDDEN_DEATH") ~= true then
		Controls.RetimeButton:SetDisabled(true)
	end

	if b_admin == true then
		Controls.RemapButton:RegisterCallback( Mouse.eLClick, OnHostRemap )
		Controls.RetimeButton:RegisterCallback( Mouse.eLClick, OnHostRetime )
	end

	Controls.IrrVoteButton:SetDisabled(true)
	Controls.RemapVoteButton:SetDisabled(true)

	if hostID == localID then
		Controls.RemapVoteButton:RegisterCallback( Mouse.eLClick, OnVoteRemap )
		Controls.RemapVoteButton:SetDisabled(false)
		Controls.ResyncButton:RegisterCallback( Mouse.eLClick, OnHostResync )
		Controls.ResyncButton:SetDisabled(false)
		Controls.ForceEndButton:RegisterCallback( Mouse.eLClick, OnHostForceEnd )
		Controls.ForceEndButton:SetDisabled(false)

		else
		Controls.RemapVoteButton:RegisterCallback( Mouse.eLClick, OnRequestVoteRemap )
		if currentTurn < (GameConfiguration.GetStartTurn()+8) then
			Controls.RemapVoteButton:SetDisabled(false)
		end
		if PlayerConfigurations[localID] ~= nil then
			if PlayerConfigurations[localID]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
				Controls.RemapVoteButton:SetDisabled(false)
			end
		end
	end
	Controls.UIRefreshButton:SetHide(false)
	Controls.UIRefreshButton:RegisterCallback( Mouse.eLClick, OnLocalUIRefresh )
end

-- ===========================================================================
--	Functions
-- ===========================================================================

function OnLocalUIRefresh()
		_kPopupDialog:Close();
		_kPopupDialog:AddTitle(	  Locale.Lookup("LOC_GAME_MENU_UI_REFRESH_TITLE"));
		_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_UI_REFRESH_LABEL"));
		_kPopupDialog:AddButton( Locale.Lookup("LOC_GAME_MENU_UI_REFRESH_BUTTON"), OnLocalUIRefreshValidate );
		_kPopupDialog:AddButton( Locale.Lookup("LOC_CANCEL_BUTTON"), nil );
		_kPopupDialog:Open();
end

function OnLocalUIRefreshValidate()
	print("OnLocalUIRefreshValidate()")
	LuaEvents.InGame_OnLocalUIRefresh()
	OnReturn()
	
end

function OnHostRemap()
	if Network.GetLocalPlayerID() ~= Network.GetGameHostPlayerID() then
		return
	end
	LuaEvents.MPHMenu_OnHostRemap()
	OnReturn()
end

function OnHostForceEnd()
	if Network.GetLocalPlayerID() ~= Network.GetGameHostPlayerID() then
		return
	end
		_kPopupDialog:Close();
		_kPopupDialog:AddTitle(	  Locale.Lookup("LOC_GAME_MENU_FORCEEND_TITLE"));
		_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_FORCEEND_LABEL"));
		_kPopupDialog:AddButton( Locale.Lookup("LOC_GAME_MENU_FORCEEND_BUTTON"), OnHostForceEndValidate );
		_kPopupDialog:AddButton( Locale.Lookup("LOC_CANCEL_BUTTON"), nil );
		_kPopupDialog:Open();
end

function OnHostForceEndValidate()
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID ~= hostID then
		return
	end
	local player_ids = GameConfiguration.GetMultiplayerPlayerIDs()
	for i, iPlayer in ipairs(player_ids) do
		if Network.IsPlayerConnected(iPlayer) == true and iPlayer ~= hostID then
			Network.SendChat(".mph_ui_forceend_now",-2,iPlayer)
		end
	end
	UI.RequestAction(ActionTypes.ACTION_ENDTURN, { REASON = "UserForced" } );
end

function OnRequestHostForceEnd()
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID ~= hostID then
		Network.SendChat(".mph_ui_log_received_general_request_to_force_endturn",-2,hostID)	
		UI.RequestAction(ActionTypes.ACTION_ENDTURN, { REASON = "UserForced" } );
		print("Turn was force-ended by host")
	end
	OnReturn()
end

function OnHostResync()
	if Network.GetLocalPlayerID() ~= Network.GetGameHostPlayerID() then
		return
	end
		_kPopupDialog:Close();
		_kPopupDialog:AddTitle(	  Locale.Lookup("LOC_GAME_MENU_RESYNC_TITLE"));
		_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_RESYNC_LABEL"));
		_kPopupDialog:AddButton( Locale.Lookup("LOC_GAME_MENU_RESYNC_BUTTON"), OnHostResyncValidate );
		_kPopupDialog:AddButton( Locale.Lookup("LOC_CANCEL_BUTTON"), nil );
		_kPopupDialog:Open();
end

function OnHostResyncValidate()
	print("OnHostResyncValidate()")
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID ~= hostID then
		return
	end

	local alreadyOwnsPause = m_hostPausedForResync
	m_hostResyncPending = {}
	m_hostResyncStartedAt = os.time()
	m_hostPausedForResync = alreadyOwnsPause
	if GameConfiguration.IsPaused() == false then
		local localPlayerID = localID;
		local localPlayerConfig = PlayerConfigurations[localPlayerID];
		if localPlayerConfig ~= nil and localPlayerConfig:GetWantsPause() == false then
			localPlayerConfig:SetWantsPause(true);
			Network.BroadcastPlayerInfo();
			m_hostPausedForResync = true
		end
	end

	local requestCount = 0
	local player_ids = GameConfiguration.GetMultiplayerPlayerIDs()
	for i, iPlayer in ipairs(player_ids) do
		if Network.IsPlayerConnected(iPlayer) == true and iPlayer ~= hostID then
			m_hostResyncPending[iPlayer] = true
			requestCount = requestCount + 1
			Network.SendChat(".mph_ui_resync_now",-2,iPlayer)
		end
	end
	print("MPH general resync requested for",requestCount,"client(s)")
	if requestCount == 0 then
		FinishHostResyncPause("no connected clients")
	end
end

function FinishHostResyncPause(reason)
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID == hostID and m_hostPausedForResync == true then
		local localPlayerConfig = PlayerConfigurations[localID]
		if localPlayerConfig ~= nil and localPlayerConfig:GetWantsPause() == true then
			localPlayerConfig:SetWantsPause(false)
			Network.BroadcastPlayerInfo()
		end
	end
	print("MPH general resync pause finished:",tostring(reason))
	m_hostResyncPending = {}
	m_hostResyncStartedAt = nil
	m_hostPausedForResync = false
end

function ExecuteHostRequestedResync(reason)
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID ~= hostID then
		m_clientResyncInProgress = true
		if reason == "general" or m_clientResyncReason == nil then
			m_clientResyncReason = tostring(reason)
		end
		Network.SendChat(".mph_ui_resync_started_"..tostring(reason),-2,hostID)
		local snapshotResult = Network.RequestSnapshot()
		local syncResult = Network.TriggerTestSync()
		print("MPH host-requested resync:",tostring(reason),"RequestSnapshot:",snapshotResult,"TriggerTestSync:",syncResult)
	end
	OnReturn()
end

function OnRequestHostResync()
	ExecuteHostRequestedResync("general")
end

function OnRequestHostResyncSeed()
	ExecuteHostRequestedResync("state_mismatch")
end

function OnHostRetime()
	if Network.GetLocalPlayerID() ~= Network.GetGameHostPlayerID() then
		return
	end
		_kPopupDialog:Close();
		_kPopupDialog:AddTitle(	  Locale.Lookup("LOC_GAME_MENU_RETIME_TITLE"));
		_kPopupDialog:AddText(	  Locale.Lookup("LOC_GAME_MENU_RETIME_LABEL"));
		_kPopupDialog:AddEditBox( Locale.Lookup("LOC_GAME_MENU_RETIME_BOX"), nil, OnHostRetimeEditBox, nil)
		_kPopupDialog:AddButton( Locale.Lookup("LOC_GAME_MENU_RETIME_BUTTON"), OnHostRetimeValidate );
		_kPopupDialog:AddButton( Locale.Lookup("LOC_CANCEL_BUTTON"), nil );
		_kPopupDialog:Open();
end

function OnHostRetimeEditBox(editBox :table)
	m_extraTime = editBox:GetText();
end

function OnHostRetimeValidate()
	print("OnHostRetimeValidate")
	print(m_extraTime)
	if Network.GetLocalPlayerID() ~= Network.GetGameHostPlayerID() then
		return
	end
	if tonumber(m_extraTime) ~= nil then
		if tonumber(m_extraTime) > 0 then
			LuaEvents.MPHMenu_OnHostRetime(tonumber(m_extraTime))
			local hostID = Network.GetGameHostPlayerID()
			local player_ids = GameConfiguration.GetMultiplayerPlayerIDs()
			for i, iPlayer in ipairs(player_ids) do
				if Network.IsPlayerConnected(iPlayer) == true and iPlayer ~= hostID then
					Network.SendChat(".mph_ui_sudden_death_adjust_"..tonumber(m_extraTime),-2,iPlayer)
				end
			end
		end
	end
end

function OnRequestVoteRemap()
	print("OnRequestVoteRemap()")
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	Network.SendChat(".mph_ui_vote_remap_request",-2,-1)
	OnReturn()
end

function OnVoteRemap()
	Network.SendChat(".mph_ui_vote_remap",-2,-1)
	OnReturn()
end

function OnRequestHostVoteRemap()
	print("OnRequestHostVoteRemap()")
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID ~= hostID then
		return
	end
	Network.SendChat(".mph_ui_vote_remap",-2,-1)
	OnReturn()
end

function OnRequestHostSeedCheck(text,sender_id)
	-- prefix is m for Map and g for Game
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	local map_seed = MapConfiguration.GetValue("RANDOM_SEED")
	local game_seed = GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED")
	
	if hostID ~= localID then
		return
	end
	local seed_type = string.sub(string.lower(text),1,1)
	
	if seed_type == "m" then
		local check_seed = tonumber(string.sub(string.lower(text),2))
		print("Map seed from player "..sender_id.." is: "..tostring(check_seed))
		if check_seed ~= tonumber(map_seed) then
			RequestTargetedResync(sender_id,"map_seed")
			else
			return
		end
	end
	
	if seed_type == "g" then
		local check_seed = tonumber(string.sub(string.lower(text),2))
		print("Game seed from player "..sender_id.." is: "..tostring(check_seed))
		if check_seed ~= tonumber(game_seed) then
			RequestTargetedResync(sender_id,"game_seed")
			else
			return
		end
	end
end

function RequestTargetedResync(playerID,reason)
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if playerID == nil or localID ~= hostID or playerID == hostID or Network.IsPlayerConnected(playerID) ~= true then
		return
	end
	local existingRequest = m_targetedResyncRequested[playerID]
	if existingRequest ~= nil then
		if os.time() - existingRequest.RequestedAt < RESYNC_PAUSE_TIMEOUT_SECONDS then
			print("MPH targeted resync already requested for player",playerID,"first reason:",existingRequest.Reason,"additional reason:",reason)
			return
		end
	end
	m_targetedResyncRequested[playerID] = { Reason = reason, RequestedAt = os.time() }
	print("MPH targeted resync requested for player",playerID,"reason:",reason)
	Network.SendChat(".mph_ui_resync_seed",-2,playerID)
end

function ComputeMapFingerprint()
	local modulus = 2147483647
	local hash = 104729
	local plotCount = Map.GetPlotCount()
	for plotIndex = 0, plotCount - 1 do
		local plot = Map.GetPlotByIndex(plotIndex)
		if plot ~= nil then
			local riverFlags = 0
			if plot:IsWOfRiver() then riverFlags = riverFlags + 1 end
			if plot:IsNWOfRiver() then riverFlags = riverFlags + 2 end
			if plot:IsNEOfRiver() then riverFlags = riverFlags + 4 end
			local cliffFlags = 0
			if plot:IsWOfCliff() then cliffFlags = cliffFlags + 1 end
			if plot:IsNWOfCliff() then cliffFlags = cliffFlags + 2 end
			if plot:IsNEOfCliff() then cliffFlags = cliffFlags + 4 end
			local value = (plot:GetTerrainType() + 2)
				+ (plot:GetFeatureType() + 2) * 31
				+ (plot:GetResourceType() + 2) * 131
				+ plot:GetResourceCount() * 521
				+ riverFlags * 2089
				+ cliffFlags * 8191
				+ (plot:GetImprovementType() + 2) * 32771
				+ (plot:GetRouteType() + 2) * 131101
			hash = (hash * 65599 + value + plotIndex) % modulus
		end
	end

	local majorIDs = {}
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
		table.insert(majorIDs, playerID)
	end
	table.sort(majorIDs)
	for _, playerID in ipairs(majorIDs) do
		local player = Players[playerID]
		local startPlot = nil
		if player ~= nil and player.GetStartingPlot ~= nil then
			startPlot = player:GetStartingPlot()
		end
		local startIndex = startPlot ~= nil and startPlot:GetIndex() or -1
		hash = (hash * 65599 + playerID * 257 + startIndex + 2) % modulus
	end
	return tostring(math.floor(hash))
end

function OnRequestHostMapFingerprint(fingerprint,senderID)
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID ~= hostID then
		return
	end
	local hostFingerprint = ComputeMapFingerprint()
	print("MPH map fingerprint: host",hostFingerprint,"player",senderID,tostring(fingerprint))
	if tostring(fingerprint) ~= hostFingerprint then
		RequestTargetedResync(senderID,"map_fingerprint")
	end
end

function OnMultiplayerSnapshotProcessed()
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID ~= hostID and m_clientResyncInProgress == true then
		m_clientResyncInProgress = false
		Network.SendChat(".mph_ui_resync_complete_"..(m_clientResyncReason or "unknown"),-2,hostID)
		print("MPH host-requested snapshot processed")
		m_clientResyncReason = nil
	end
end

function OnResyncTick()
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	if localID == hostID and m_hostResyncStartedAt ~= nil and os.time() - m_hostResyncStartedAt >= RESYNC_PAUSE_TIMEOUT_SECONDS then
		FinishHostResyncPause("timeout safeguard")
	end
end

-- ===========================================================================
--	Listening function
-- ===========================================================================

function OnMultiplayerChat( fromPlayer, toPlayer, text, eTargetType )
	print(text)
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	local b_ishost = false
	if fromPlayer == Network.GetGameHostPlayerID() then
		b_ishost = true
	end
	
	-- Requesting a VoteMap
	if (string.lower(text) == ".mph_ui_vote_remap_request" and localID == hostID)  then
		OnRequestHostVoteRemap()
		return
	end
	
	-- Requesting a Kick
	
	if ( (string.sub(string.lower(text),1,13) == ".mph_ui_kick_") and localID == hostID and fromPlayer == hostID)  then
		local kick_id = string.sub(text,14)
		if kick_id ~= nil then
			kick_id = tonumber(kick_id)
			print("Kick UI: Player",kick_id)
			if hostID ~= kick_id then
				Network.KickPlayer(kick_id);
			end
		end
		return
	end
	
	-- Receiving a Seed Check
	
	if ((string.sub(string.lower(text),1,20) == ".mph_ui_checkseed_id") and localID == hostID)  then
		-- Network.SendChat(".mph_ui_checkseed_id_"..tostring(playerID).."_turn_"..g_local_turn.."_seed_"..g_local_seed,-2,hostID)
		-- .mph_ui_checkseed_id_5_turn_2_seed_66
		local indexTurns, indexTurne = string.find(text,"_turn_")
		local indexSeeds, indexSeede = string.find(text,"_seed_")
		if indexTurns == nil or indexTurne == nil or indexSeeds == nil or indexSeede == nil then
			print("Seed Check: ignored malformed message from player",fromPlayer,text)
			return
		end
		local sender_id = string.sub(text,22,indexTurns-1)
		local turn_checked = string.sub(text,indexTurne+1,indexSeeds-1)
		local seed_checked = string.sub(text, indexSeede+1)
		if g_local_turn ~= nil and tostring(turn_checked) == tostring(g_local_turn) then
			if tostring(seed_checked) == tostring(g_local_seed) then
				print("Seed Check: Player "..tostring(sender_id).." is in sync. State:"..tostring(seed_checked).." Turn:"..tostring(turn_checked))
			else
				print("Seed Check: ERROR Player "..tostring(sender_id).." is out-of-sync. Local State:"..tostring(g_local_seed).." Player State:"..tostring(seed_checked).." Turn:"..tostring(turn_checked))
				local name = PlayerConfigurations[tonumber(sender_id)]
				if name == nil then
					name = "Player "..tostring(sender_id)
					else
					name = tostring(PlayerConfigurations[tonumber(sender_id)]:GetPlayerName())
				end
				Network.SendChat(name.." is out of sync with the host!",-2,-1)
				RequestTargetedResync(tonumber(sender_id),"turn_state")
			end
			
		end
		return
	end
	
	-- Requesting a General Resync
	
	if (string.lower(text) == ".mph_ui_resync_now" and fromPlayer == hostID)  then
		OnRequestHostResync()
		return
	end

	if (string.sub(string.lower(text),1,22) == ".mph_ui_resync_started" and localID == hostID) then
		print("MPH client accepted resync request:",fromPlayer,text)
		return
	end

	if (string.sub(string.lower(text),1,23) == ".mph_ui_resync_complete" and localID == hostID) then
		local completionReason = string.sub(text,25)
		print("MPH client completed resync:",fromPlayer,"reason:",completionReason)
		if completionReason == "general" then
			m_hostResyncPending[fromPlayer] = nil
			local stillPending = false
			for _, pending in pairs(m_hostResyncPending) do
				if pending == true then
					stillPending = true
					break
				end
			end
			if stillPending == false then
				FinishHostResyncPause("all clients completed")
			end
		else
			m_targetedResyncRequested[fromPlayer] = nil
		end
		return
	end
	
	-- Requesting a General Force End Turn
	
	if (string.lower(text) == ".mph_ui_forceend_now" and fromPlayer == hostID)  then
		OnRequestHostForceEnd()
		return
	end
	
	-- Requesting a Seed Resync
	
	if (string.lower(text) == ".mph_ui_resync_seed" and fromPlayer == hostID)  then
		OnRequestHostResyncSeed()
		return
	end
	
	-- Logging Information
	
	if (string.sub(string.lower(text),1,11) == ".mph_ui_log")  then
		local tmp = tostring(string.sub(text,12))
		print(tmp,"fromPlayer ID: ",fromPlayer)
		return
	end
	
	-- Requesting a Seed Check
	
	if (string.sub(string.lower(text),1,12)== ".mph_ui_seed" and localID == hostID)  then
		local tmp = tostring(string.sub(text,14))
		OnRequestHostSeedCheck(tmp,fromPlayer)
		return
	end

	if (string.sub(string.lower(text),1,14) == ".mph_ui_mapfp_" and localID == hostID) then
		local fingerprint = tostring(string.sub(text,15))
		OnRequestHostMapFingerprint(fingerprint,fromPlayer)
		return
	end
	
	-- Test
	
	if (string.lower(text)== ".mph_ui_requestsnap" and localID == fromPlayer)  then
		print("Network.RequestSnapshot()",Network.RequestSnapshot())
		return
	end
	
	if (string.lower(text)== ".mph_ui_triggertest" and localID == fromPlayer)  then
		print("Network.TriggerTestSync()",Network.TriggerTestSync())
		return
	end	
	
	if (string.lower(text)== ".mph_ui_forceresync" and localID == fromPlayer)  then
		print("Network.ForceResync()",Network.ForceResync())
		return
	end		
	
	
end

function OnLoadScreenClose()
	print("OnLoadScreenClose()")
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	local map_seed = MapConfiguration.GetValue("RANDOM_SEED")
	local game_seed = GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED")
	local mapFingerprint = ComputeMapFingerprint()
	local generatedFingerprint = Game ~= nil and Game.GetProperty ~= nil and Game.GetProperty("ZYLRM_MAP_FINGERPRINT") or nil
	print("MPH initial sync state: map seed",map_seed,"game seed",game_seed,"map fingerprint",mapFingerprint,"generated fingerprint",generatedFingerprint)
	if hostID ~= localID then
		Network.SendChat(".mph_ui_seed_m"..tostring(map_seed),-2,hostID)
		Network.SendChat(".mph_ui_seed_g"..tostring(game_seed),-2,hostID)
		Network.SendChat(".mph_ui_mapfp_"..mapFingerprint,-2,hostID)
	end
end

-- ===========================================================================
--	Callback
-- ===========================================================================
function OnShutdown()
	ContextPtr:SetHide(true);
	m_active = false
	LuaEvents.MPHMenu_Click.Remove( OnShow );
	LuaEvents.EscMenu_Show.Remove( OnReturn );
	Events.MultiplayerChat.Remove( OnMultiplayerChat );
	Events.LoadScreenClose.Remove( OnLoadScreenClose );
	Events.MultiplayerSnapshotProcessed.Remove( OnMultiplayerSnapshotProcessed );
	Events.GameCoreEventPublishComplete.Remove( OnResyncTick );
	Events.SystemUpdateUI.Remove( OnResyncTick );
	
end

function OnReturn()
	ContextPtr:SetHide(true);
	m_active = false
end


-- ===========================================================================
function Initialize()
	ContextPtr:SetShutdown( OnShutdown );
	m_active = false
	ContextPtr:SetHide(true);
	Controls.ReturnButton:RegisterCallback( Mouse.eLClick, OnReturn );
	Controls.ReturnButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	_kPopupDialog = PopupDialog:new( "MPHOptions" );

	LuaEvents.MPHMenu_Click.Add( OnShow );
	LuaEvents.EscMenu_Show.Add( OnReturn );
	Events.MultiplayerChat.Add( OnMultiplayerChat );
	Events.LoadScreenClose.Add( OnLoadScreenClose );
	Events.MultiplayerSnapshotProcessed.Add( OnMultiplayerSnapshotProcessed );
	Events.GameCoreEventPublishComplete.Add( OnResyncTick );
	Events.SystemUpdateUI.Add( OnResyncTick );

end
Initialize();
