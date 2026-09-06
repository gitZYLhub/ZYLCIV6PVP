-- Copyright 2016-2019, Firaxis Games
-- (Multiplayer) Drop Control By D. / Jack The Narrator

SDEvents = ExposedMembers.LuaEvents;
-- ===========================================================================
--	Variables
-- ===========================================================================
local m_ref_time = 0
local m_elapsed_time
local m_first_time = 3600
local m_remaining_time = 3600
local g_cached_playerIDs = {}
local m_tickRegistered = false
local m_lastBroadcastTurn = nil
local b_debug = false

local function DebugLog(...)
	if b_debug then print(...) end
end

local function SetTicking(enabled)
	if enabled and not m_tickRegistered then
		Events.GameCoreEventPublishComplete.Add(OnTimeTicks)
		m_tickRegistered = true
	elseif not enabled and m_tickRegistered then
		Events.GameCoreEventPublishComplete.Remove(OnTimeTicks)
		m_tickRegistered = false
	end
end

-- ===========================================================================
--	Timer 
-- ===========================================================================

function UpdateTimer()
	local localID = Network.GetLocalPlayerID()
	local hostID = Network.GetGameHostPlayerID()
	local remaining_time = 0
	local now = Automation.GetTime()
	m_elapsed_time = (now - m_ref_time) + m_elapsed_time
	m_ref_time = now
	remaining_time = math.floor(m_first_time-m_elapsed_time)
	m_remaining_time = tonumber(remaining_time)
	local minute = math.floor(remaining_time/60)
	local second = remaining_time-minute*60
	local str = ""
	if minute > 1 then
		str = tostring(minute).." Minutes and "..tostring(second).." Seconds"
		elseif minute == 1 then
		str = "[COLOR_Civ6Red]"..tostring(minute).." Minute and "..tostring(second).." Seconds[ENDCOLOR]"
		else
		str = "[COLOR_Civ6Red]"..tostring(second).." Seconds[ENDCOLOR]"
	end
	Controls.SuddenDeathLabel:SetText(tostring(str))
	
	local low_score = 1000000
	local low_id = -1
	for i, player in ipairs(g_cached_playerIDs) do
		if player.Status == 0 or player.Status == -2 then
			if Players[player.ID] == nil or Players[player.ID]:IsAlive() == false then
				player.Status = -3
			end
			if player.Status == 0 or player.Status == -2 then
				local score = Players[player.ID]:GetScore()
				if score < low_score then
					low_score = score
					low_id = player.ID
				end
			end
		end
	end
	
	if low_id >= 0 and PlayerConfigurations[low_id] ~= nil then
		Controls.SuddenDeathPlayer:SetText(Locale.Lookup(PlayerConfigurations[low_id]:GetPlayerName()))
	else
		Controls.SuddenDeathPlayer:SetText("")
		Controls.SuddenDeathLabel:SetText("[COLOR_Civ6Green]Sudden Death complete[ENDCOLOR]")
		SetTicking(false)
		return
	end
	
	if remaining_time == 0 or remaining_time < 0 then
		if localID == hostID then
			OnHostTimerExpires(low_id)
		end
		Controls.SuddenDeathLabel:SetText("[COLOR_Civ6Red]Blood for the Blood God![ENDCOLOR]")
	end
	
end

function OnTimeTicks()
	local localID = Network.GetLocalPlayerID()
	local hostID = Network.GetGameHostPlayerID()

	local currenttime = math.floor(Automation.GetTime())
	if currenttime > (m_ref_time + 1) or currenttime == m_ref_time + 1 then
		UpdateTimer()
	end
	
end
-- ===========================================================================
--	Sudden Death
-- ===========================================================================

function OnHostTimerExpires(playerID:number)

	local localID = Network.GetLocalPlayerID()
	local hostID = Network.GetGameHostPlayerID()
	local player_ids = GameConfiguration.GetMultiplayerPlayerIDs()
	
	if localID ~= hostID or playerID == nil or playerID < 0 or Players[playerID] == nil then
		return
	end
	
	for i, player in ipairs(g_cached_playerIDs) do
		if player.Status == 0 or player.Status == -2 then
			if playerID == player.ID then
				player.Status = -66
			end
		end
	end
	for i, iPlayer in ipairs(player_ids) do
		if Network.IsPlayerConnected(iPlayer) == true and iPlayer ~= hostID then
			Network.SendChat(".mph_ui_sudden_death_adjust_1200",-2,iPlayer)
			elseif iPlayer == hostID then
			OnHostAdjustDeathTimer(1200)
		end
	end
	
	if hostID == playerID then -- Host simply retire problem solved
		UI.RequestAction(ActionTypes.ACTION_RETIRE);
		elseif Network.IsPlayerConnected(playerID) == true then -- remotely ask for them to retire
		Network.SendChat(".mph_ui_sudden_death_mark",-2,playerID)
	end
	
	SDEvents.UISuddenDeathTimeExpireAI( playerID );
	for i, iPlayer in ipairs(player_ids) do
		if Network.IsPlayerConnected(iPlayer) == true and iPlayer ~= hostID then
			Network.SendChat(".mph_ui_terminate_ai_"..playerID,-2,iPlayer)
		end
	end
	
	--
	local  count = 0
	for i, player in ipairs(g_cached_playerIDs) do
		if player.Status == 0 or player.Status == -2 then
			count = count + 1
		end
	end
	if count == 1 then
		for i, player in ipairs(g_cached_playerIDs) do
			if (player.Status == 0 or player.Status == -7) and hostID ~= player.ID then
				Network.SendChat(".mph_ui_concede_win",-2,player.ID)
				elseif (player.Status == 0 or player.Status == -7) and hostID == player.ID then
				LuaEvents.MPHMenu_ConcedeWin("VICTORY_DEFAULT");
			end
		end
	end
end

function OnPlayerTurnActivated( playerID, bIsFirstTime )
	local hostID = Network.GetGameHostPlayerID()
	local player_ids = GameConfiguration.GetMultiplayerPlayerIDs()
	local localID = Network.GetLocalPlayerID()
	
	if localID ~= hostID then
		return
	end
	local currentTurn = Game.GetCurrentGameTurn()
	if m_lastBroadcastTurn == currentTurn then
		return
	end
	m_lastBroadcastTurn = currentTurn
	
	SDEvents.UISuddenDeathSavetime( m_remaining_time );
	
	for i, iPlayer in ipairs(player_ids) do
		if Network.IsPlayerConnected(iPlayer) == true and iPlayer ~= hostID then
			if m_remaining_time ~= 3600 and tonumber(m_remaining_time) ~= nil then
				Network.SendChat(".mph_ui_sudden_death_adjust_"..m_remaining_time,-2,iPlayer)
			end
		end
	end
end

function OnHostAdjustDeathTimer(time_adjust:number)
	local adjustedTime = tonumber(time_adjust)
	if adjustedTime == nil or adjustedTime <= 0 then
		DebugLog("Ignored invalid sudden-death timer adjustment", time_adjust)
		return
	end
	m_first_time = adjustedTime
	m_elapsed_time = 0
	m_ref_time = Automation.GetTime()
	m_lastBroadcastTurn = nil
end



-- ===========================================================================
--	Listening function
-- ===========================================================================

function OnMultiplayerChat( fromPlayer, toPlayer, text, eTargetType )
	DebugLog("SuddenDeath command", text, "From", fromPlayer,"To",toPlayer)
	local hostID = Network.GetGameHostPlayerID()
	local localID = Network.GetLocalPlayerID()
	local b_ishost = false
	if fromPlayer == Network.GetGameHostPlayerID() then
		b_ishost = true
	end
	
	-- Triggering a Sudden Death
	
	if b_ishost == true and string.lower(text) == ".mph_ui_sudden_death_mark" and toPlayer == localID  then
		UI.RequestAction(ActionTypes.ACTION_RETIRE);
		return
	end
	
	if b_ishost == true and (string.lower(string.sub(text,1,27)) == ".mph_ui_sudden_death_adjust")  then
		local tmp = tonumber(string.sub(text,29))
		if tmp ~= nil and tmp > 0 then
			OnHostAdjustDeathTimer(tmp)
		else
			DebugLog("Ignored malformed sudden-death adjustment", text)
		end
		return
	end	
	
	if b_ishost == true and (string.lower(string.sub(text,1,20)) == ".mph_ui_terminate_ai")  then
		local tmp_AI_ID = tonumber(string.sub(text,22))
		if tmp_AI_ID ~= nil and Players[tmp_AI_ID] ~= nil and Network.IsPlayerConnected(tmp_AI_ID) == false then
			SDEvents.UISuddenDeathTimeExpireAI( tmp_AI_ID );
		else
			DebugLog("Ignored malformed or connected terminate target", text)
		end
		return
	end	
end

-- ===========================================================================
function OnShutdown()
	SetTicking(false)
	Events.MultiplayerChat.Remove(OnMultiplayerChat)
	Events.PlayerTurnActivated.Remove(OnPlayerTurnActivated)
	LuaEvents.MPHMenu_OnHostRetime.Remove(OnHostAdjustDeathTimer)
end

function Initialize()
	ContextPtr:SetHide(true);
	ContextPtr:SetShutdown(OnShutdown);
	if GameConfiguration.GetValue("GAMEMODE_SUDDEN_DEATH") ~= true then
		return
	end
	ContextPtr:SetHide(false);
	Events.MultiplayerChat.Add( OnMultiplayerChat );
	if m_elapsed_time == nil then
		m_elapsed_time = 0
	end
	
	if m_ref_time == 0 then
		m_ref_time = math.floor(Automation.GetTime())
		m_ref_time = math.floor(m_ref_time)
	end
	
	if Game:GetProperty("MPH_SD_TIME_LEFT") ~= nil then
		if tonumber(Game:GetProperty("MPH_SD_TIME_LEFT")) > 0 then
			m_first_time = tonumber(Game:GetProperty("MPH_SD_TIME_LEFT"))
		end
	end

	local player_ids = PlayerManager.GetAliveMajorIDs()
	for i, iPlayer in ipairs(player_ids) do
		if Players[iPlayer] ~= nil then
			local tmp = {}
			local name = PlayerConfigurations[iPlayer]:GetPlayerName()
			local id = iPlayer
			local team = Players[iPlayer]:GetTeam()
			local status = -1
			if PlayerConfigurations[iPlayer]:GetLeaderTypeName() == "LEADER_SPECTATOR" then
			status = -7
			elseif Players[iPlayer]:IsAlive() == false then
			status = -3
			elseif Players[iPlayer]:IsMajor() == false then
			status = -4
			elseif Network.IsPlayerConnected(iPlayer) == false then
			status = -2
			else
			status = 0
			end
			local namestr = Locale.Lookup(name)
			if string.len(namestr) > 12 then
			namestr = string.sub(namestr,1,11).."."
			end
			tmp = { ID = id, Team = team, Status = status, Name = namestr, Executed = false }
			if status ~= -4 then
			table.insert(g_cached_playerIDs,tmp)	
			end
		end
	end
	DebugLog(m_ref_time,Automation.GetTime())
	SetTicking(true)
	Events.PlayerTurnActivated.Add( OnPlayerTurnActivated );
	
	LuaEvents.MPHMenu_OnHostRetime.Add( OnHostAdjustDeathTimer );
end
Initialize();
