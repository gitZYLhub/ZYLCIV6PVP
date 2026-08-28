-- Copyright 2016-2019, Firaxis Games
-- (Multiplayer) Turn Processing By D. / Jack The Narrator
print("ZYLPVPMOD Turn Processing")
include( "Civ6Common" );
include( "Colors") ;
include( "SupportFunctions" ); --DarkenLightenColor
include( "InputSupport" );
include( "InstanceManager" );


-- ===========================================================================
--	Variables
-- ===========================================================================

local m_isRetired		: boolean = false;
local m_isClosing 		: boolean = false;

local g_timeshift = 0
local g_currenttimer = 0
local g_playertime = {}
local b_settimer = false
local b_setprocess = false
local b_teamer = false
local g_timeCommandUsed = false
local g_reduceCommandUsed = false
local g_temporaryNoTimer = false
local g_turnTimer = { ElapsedTime = 0, MaxTurnTime = 0, TimeRemaining = 0 }
local g_lastWarningSecond = -1
local g_tickRegistered = false

local function IsHost()
	local localID = Network.GetLocalPlayerID()
	local hostID = Network.GetGameHostPlayerID()
	return localID ~= nil and hostID ~= nil and localID >= 0 and localID == hostID
end

local function CommandsEnabled()
	local value = GameConfiguration.GetValue("TOOLS_COMMAND")
	return value == true or value == 1
end

local function ApplyHostTimer(timeValue, timerType, playSound)
	if not IsHost() then
		return false
	end
	if timeValue ~= nil then
		GameConfiguration.SetValue("TURN_TIMER_TIME", timeValue)
	end
	if timerType ~= nil then
		GameConfiguration.SetTurnTimerType(timerType)
	end
	Network.BroadcastGameConfig()
	if playSound then
		UI.PlaySound("Play_MP_Game_Launch_Timer_Beep")
	end
	return true
end

local function SetTicking(enabled)
	if enabled and not g_tickRegistered then
		Events.GameCoreEventPublishComplete.Add(OnTick)
		g_tickRegistered = true
	elseif not enabled and g_tickRegistered then
		Events.GameCoreEventPublishComplete.Remove(OnTick)
		g_tickRegistered = false
	end
end

-- TPT p+/p++ convenience commands are handled here so the suite has exactly
-- one timer owner. Commands are public-chat only and authoritative on the host.
function OnMultiplayerChat(fromPlayer, toPlayer, text, eTargetType)
	if not IsHost() or not CommandsEnabled() or toPlayer ~= -1 or type(text) ~= "string" then
		return
	end

	local command = string.lower(string.match(text, "^%s*(.-)%s*$") or text)
	if command == "p+" or command == "p++" then
		if g_timeCommandUsed then return end
		local current = tonumber(GameConfiguration.GetValue("TURN_TIMER_TIME")) or g_turnTimer.MaxTurnTime or 0
		local extra = (g_turnTimer.MaxTurnTime > 0 and g_turnTimer.TimeRemaining < 8) and 24 or 20
		local adjusted = math.max(0, current) + extra
		ApplyHostTimer(adjusted, nil, true)
		g_currenttimer = adjusted
		g_timeCommandUsed = true
		return
	end

	if command == "p+++" or command == "p++++" then
		ApplyHostTimer(nil, "TURNTIMER_NONE", true)
		g_temporaryNoTimer = true
		return
	end

	if command == "p-" or command == "p--" then
		if g_reduceCommandUsed then return end
		local current = tonumber(GameConfiguration.GetValue("TURN_TIMER_TIME")) or g_turnTimer.MaxTurnTime or 40
		local reduced = math.max(40, current - 10)
		ApplyHostTimer(reduced, nil, true)
		g_currenttimer = reduced
		g_reduceCommandUsed = true
	end
end

function OnTurnTimerUpdated(elapsedTime:number, maxTurnTime:number)
	g_turnTimer.ElapsedTime = elapsedTime or 0
	g_turnTimer.MaxTurnTime = maxTurnTime or 0
	g_turnTimer.TimeRemaining = math.max(0, g_turnTimer.MaxTurnTime - g_turnTimer.ElapsedTime)
	local warningEnabled = GameConfiguration.GetValue("TOOLS_15_TIME")
	local rounded = math.floor(g_turnTimer.TimeRemaining + 0.5)
	if (warningEnabled == true or warningEnabled == 1) and rounded <= 15 and rounded > 7 and rounded ~= g_lastWarningSecond then
		g_lastWarningSecond = rounded
		UI.PlaySound("Play_MP_Game_Launch_Timer_Beep")
	end
end

-- ===========================================================================
--	Timing Function
-- ===========================================================================
function Refresh_Data()
	g_playertime = {}
	b_teamer = false
	if GameConfiguration.IsNetworkMultiplayer() ~= true or GameConfiguration.GetValue("CPL_SYNCTURN") ~= true or GameConfiguration.GetValue("CPL_SMARTTIMER") == 1 then
		return
	end
	local player_ids = GameConfiguration.GetMultiplayerPlayerIDs()
	for i, iPlayer in ipairs(player_ids) do
		local playerConfig = PlayerConfigurations[iPlayer]
		local player = Players[iPlayer]
		if playerConfig ~= nil and player ~= nil
			and playerConfig:GetLeaderTypeName() ~= "LEADER_SPECTATOR" 
			and player:IsAlive() then
			local tmp = {id = iPlayer, turn_length = 60, lag = 0, last = 0, status = 0, t_0 = 0, t_1 = 0, t_start = 0, t_end = 0}
			table.insert(g_playertime,tmp)
			if player:GetTeam() ~= iPlayer then
				b_teamer = true
			end
		end
	end	
end



function CheckReady()
	if g_playertime == nil then
		return false
	end
	local bready = true 
	for i, Player in ipairs(g_playertime) do
		if Player.id ~= nil and Players[Player.id] ~= nil then
			if Player.status ~= 1 and (Players[Player.id]:IsHuman() == true )then
				bready = false
			end
		end
	end		
	return bready

end


function RefreshStatus()
	if g_playertime == nil then
		return 
	end
	local text = ""
	for i, Player in ipairs(g_playertime) do
		local player = Player.id ~= nil and Players[Player.id] or nil
		local playerConfig = Player.id ~= nil and PlayerConfigurations[Player.id] or nil
		if player ~= nil then
			local name = ""
			if player:IsHuman() and playerConfig ~= nil then
				name = playerConfig:GetPlayerName()
				else
				name = "AI #"..Player.id
			end
			if name ~= nil then
				name = Locale.Lookup(name)
				else
				name = "Player #"..Player.id
			end
			text = text..name.." - "
			if Player.status ~= 1 then
				text = text.." [COLOR_Civ6Red]PROCESSING[ENDCOLOR][NEWLINE]"
				else
				text = text.." [COLOR_Civ6Green]READY[ENDCOLOR][NEWLINE]"
			end
		end
	end		
	
	Controls.Player_Status:SetText(text)
end

function SmartTimer()
	-- 0: Competitive
	-- 1: None
	-- 2: Lege
	-- 3: CWC 2025
	-- 4: Sephis
	-- 5: Casual
	-- 6: Phyphy
	-- 7: 2vi2 (Flashy)
	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 1 then
		return
	end

	local tot_cities = 0
	local tot_units = 0
	local tot_humans = 0
	local b_war = false
	local currentTurn = Game.GetCurrentGameTurn()
	for _, i in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local player = Players[i]
		if player ~= nil and player:IsAlive() == true then
			if player:IsHuman() == true then
				tot_humans = tot_humans + 1
				tot_cities = tot_cities + player:GetCities():GetCount()
				tot_units = tot_units + player:GetUnits():GetCount()
				if player:GetDiplomacy():IsAtWarWithHumans() == true then
					b_war = true
				end
			end
		end
	end
	local avg_cities = 0
	local avg_units = 0
	if tot_humans > 0 then
		avg_cities = math.floor( tot_cities / tot_humans )
		avg_units = math.floor( tot_units / tot_humans )
	end

	local timer = 0
	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 0 then
		timer = 30 + avg_cities * 4 + avg_units * 1  + g_timeshift
	

	if currentTurn > 5 and currentTurn < 11 then
		timer = timer + 5
	end	
	if currentTurn > 10 and currentTurn < 21 then
		timer = timer + 15
	end	
	if currentTurn > 20 and currentTurn < 31 then
		timer = timer + 35
	end
	if currentTurn > 30 and currentTurn < 51 then
		timer = timer + 40
	end
	if currentTurn > 50 and currentTurn < 76 then
		timer = timer + 45
	end
	if currentTurn > 75 and currentTurn < 101 then
		timer = timer + 50
	end
	if currentTurn > 100 then
		timer = timer + 55
	end
	if b_teamer == true then
		if GameConfiguration.GetValue("CPL_BAN_FORMAT") ~= 3 then
			print("More time: Teamer!")
			timer = math.floor(timer * 1.1)
		end
	end
	if b_war == true then
		if GameConfiguration.GetValue("CPL_BAN_FORMAT") ~= 3 then
			print("More time: War!")
			timer = math.floor(timer * 1.15)
			else
			print("More time: War!")
			timer = math.floor(timer * 1.05)			
		end
	end
	end

	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 2 then

	if currentTurn < 16 then
		timer = 15 + g_timeshift
	end	
	if currentTurn > 15 and currentTurn < 71 then
		timer = 45 + g_timeshift
	end	
	if currentTurn > 70 then
		timer = 75 + g_timeshift
	end

	end

	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 3 then
    timer = 30 + avg_cities * 4 + avg_units * 1 + g_timeshift

    if currentTurn >= 1 and currentTurn <= 5 then
        timer = math.floor(timer * 0.90)
    end

    if currentTurn > 5 and currentTurn <= 10 then
        timer = math.floor((timer + 5) * 0.90)
    end

    if currentTurn > 10 and currentTurn <= 20 then
        timer = math.floor((timer + 15) * 0.90)
    end

    if currentTurn > 20 and currentTurn <= 30 then
        timer = math.floor((timer + 35) * 0.90)
    end

    if currentTurn > 30 and currentTurn <= 50 then
        timer = math.floor((timer + 40) * 0.90)
    end

    if currentTurn > 50 and currentTurn <= 75 then
        timer = timer + 45
    end

    if currentTurn > 75 and currentTurn <= 100 then
        timer = timer + 50
    end

    if currentTurn > 100 then
        timer = timer + 55
    end
	end

	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 5 then


	timer = 95 + avg_cities * 4 + avg_units * 1  + g_timeshift
	
	if currentTurn > -1 and currentTurn < 10 then
		timer = timer - 25
	end	
	if currentTurn > 44 and currentTurn < 90 then
		timer = timer + 30
	end	
	if currentTurn > 89 then
		timer = timer + 20
	end	
	
	end


	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 4 then


	timer = 30 + currentTurn + g_timeshift
	

	end

	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 6 then

	if currentTurn <= 15 then
		timer = 15
	end
	if currentTurn > 15 and currentTurn <= 30 then
		timer = 30
	end
	if currentTurn > 30 and currentTurn < 50 then
		timer = 45
	end
	if currentTurn >= 50 and currentTurn < 70 then
		timer = 65
	end
	if currentTurn >= 70 then
		timer = 80
	end

	end
	
	if GameConfiguration.GetValue("CPL_SMARTTIMER") == 7 then

	if currentTurn<8 then
		timer = 20
	end

	if currentTurn>=8 and currentTurn<=15 then
		timer = 30
	end

	if currentTurn>=16 and currentTurn<=23 then
		timer = 40
	end

	if currentTurn >=24 and currentTurn<=31 then
		timer = 50
	end

	if currentTurn >= 32 and currentTurn<= 39 then
		timer = 60
	end

	if currentTurn>=40 and currentTurn<=68 then
		timer = 60+2*(currentTurn-39)
	end
	
	if currentTurn>=69 and currentTurn<=88 then
		timer = 120
	end

	if currentTurn>=89 then
		timer = 150
	end
	end

	local turnSegment = Game.GetCurrentTurnSegment();
	if GameConfiguration.GetValue("CPL_SMARTTIMER") ~= 1 then
		if turnSegment == WORLD_CONGRESS_STAGE_1 then
			timer = 240
			elseif turnSegment == WORLD_CONGRESS_STAGE_2 then			
				timer = 240	
		end
	end
	
	
	g_currenttimer = timer
end

-- ===========================================================================
--	NEW EVENTS
-- ===========================================================================
function OnLoadScreenClose()
	Refresh_Data()	
	SmartTimer()
end



function OnTurnEnd(turn)
	g_timeCommandUsed = false
	g_reduceCommandUsed = false
	g_lastWarningSecond = -1
	SmartTimer()
	if GameConfiguration.GetValue("CPL_SMARTTIMER") ~= 1 and g_currenttimer ~= nil and IsHost() then
		ApplyHostTimer(g_currenttimer, "TURNTIMER_STANDARD", false)
		g_temporaryNoTimer = false
	end
	
	if GameConfiguration.IsNetworkMultiplayer() ~= true or GameConfiguration.GetValue("CPL_SYNCTURN") ~= true or GameConfiguration.GetValue("CPL_SMARTTIMER") == 1  then
		return
	end
	for i, Player in ipairs(g_playertime) do
		if Player.id ~= nil then 
			local player = Players[Player.id]
			if player == nil or player:IsAlive() == false then
				Player.id = nil 
			else
				Player.status = 0
				Player.t_end = os.time()
			end
		end
	end	
	b_settimer = false
	SetTicking(true)
	RefreshStatus()
end


-- End

function OnLocalPlayerTurnEnd(playerID)
	if GameConfiguration.IsNetworkMultiplayer() ~= true or GameConfiguration.GetValue("CPL_SYNCTURN") ~= true or GameConfiguration.GetValue("CPL_SMARTTIMER") == 1 then
		return
	end
	local localID = Network.GetLocalPlayerID()
	for i, Player in ipairs(g_playertime) do
		if localID == Player.id then
			Player.t_1 = os.time()
			Player.last = Player.t_1 - Player.t_0
		end
	end	
end



function OnRemotePlayerTurnEnd(playerID)
	if GameConfiguration.IsNetworkMultiplayer() ~= true or GameConfiguration.GetValue("CPL_SYNCTURN") ~= true or GameConfiguration.GetValue("CPL_SMARTTIMER") == 1 then
		return
	end
	for i, Player in ipairs(g_playertime) do
		if playerID == Player.id then
			Player.t_1 = os.time()
		end
	end	
end




-- Start
function OnRemotePlayerTurnBegin(playerID)
	if GameConfiguration.IsNetworkMultiplayer() ~= true or GameConfiguration.GetValue("CPL_SYNCTURN") ~= true or GameConfiguration.GetValue("CPL_SMARTTIMER") == 1  then
		return
	end
	for i, Player in ipairs(g_playertime) do
		if playerID == Player.id then
			Player.status = 1
			Player.t_0 = os.time()
		end
	end	
	RefreshStatus()
end


function OnLocalPlayerTurnBegin()

	
	local localID = Network.GetLocalPlayerID()
	for i, Player in ipairs(g_playertime) do
		if localID == Player.id then
			Player.status = 1
			Player.t_0 = os.time()
		end
	end	
	RefreshStatus()
end



-----------------------------------------------------------------------------------------------

function OnTick()
	if GameConfiguration.IsNetworkMultiplayer() ~= true or GameConfiguration.GetValue("CPL_SYNCTURN") ~= true or GameConfiguration.GetValue("CPL_SMARTTIMER") == 1  then
		if b_setprocess then
			LuaEvents.InGame_CloseTurnProcessing()
			b_setprocess = false
		end
		SetTicking(false)
		return
	end

	if CheckReady() == false then
		if( b_setprocess == false  ) then
			ApplyHostTimer(60, nil, false)
			LuaEvents.InGame_OpenTurnProcessing()
			b_setprocess = true
		end
		return
		else
		if b_settimer == false then
			SmartTimer()
			if GameConfiguration.GetValue("CPL_SMARTTIMER") ~= 1 then
				if (g_currenttimer ~= nil) then
					ApplyHostTimer(g_currenttimer, "TURNTIMER_STANDARD", false)
					LuaEvents.InGame_CloseTurnProcessing()
					b_setprocess = false
				end
			end
			b_settimer = true
			SetTicking(false)
		end
	end
	


end



function OnAdjustTime(time_value:number)
	if not IsHost() then
		return
	end
	g_timeshift = time_value
	SmartTimer()
	if GameConfiguration.GetValue("CPL_SMARTTIMER") ~= 1 and (g_currenttimer ~= nil) then
		ApplyHostTimer(g_currenttimer, "TURNTIMER_STANDARD", false)
	end
	
end





-- ===========================================================================
--	Screen Handling
-- ===========================================================================
-- ===========================================================================
function KeyHandler( key:number )
	local bHandled:boolean = false;
	if key == Keys.U then
		if (not ContextPtr:IsHidden() ) then
			Close();
		end
		bHandled = true;
	end
	return bHandled;
end

-- ===========================================================================
--	If this is receiving input (e.g., is visible) then do not let any input
--	fall past it.  Forge will send input to popups and children first before
--	this context gets a crack at it.
-- ===========================================================================
function OnInput( pInputStruct:table )
	local uiMsg:number = pInputStruct:GetMessageType();
	local key:number = pInputStruct:GetKey();

	if uiMsg == KeyEvents.KeyUp then 
		return KeyHandler( pInputStruct:GetKey() ); 
	elseif uiMsg == KeyEvents.KeyDown and not (key == Keys.VK_ALT or key == Keys.VK_CONTROL or key == Keys.VK_SHIFT) then 
		-- Don't consume Alt, Control, or Shift so those can be used for keybindings
		return true;
	end

	return false;
end


-- ===========================================================================
--	Callback
-- ===========================================================================

-- ===========================================================================
--	Raised (typically) from InGame since when this is hidden it will not
--	receive input from ForgeUI.
-- ===========================================================================
function OnShow()
	if m_isClosing then
		print("Show was requested on menu that is in the midst of closing.");
		return;
	end

	-- Stop any particle effects from drawing on top of the menu.
	EffectsManager:PauseAllEffects();	
	Controls.AlphaIn:SetToBeginning();
	Controls.AlphaIn:Play();
end


function OnOpen()
	local turn = "Turn #"..Game.GetCurrentGameTurn()
	Controls.Processing_Text_Number:SetText(turn)
	-- Don't show pause menu if the player has retired (forfeit) from the game - fixes TTP 20129
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end
	if not m_isRetired then 
		UI.PlaySound("Play_UI_Click");
		ContextPtr:SetHide(false);
	end	
end


-- ===========================================================================
function Close()
	if(m_isClosing) then
		print("Menu is already closing.");
		return;
	end
	
	m_isClosing = true;
	
	EffectsManager:ResumeAllEffects();	-- Resume any continous particle effects.

	if(Controls.AlphaIn:IsStopped()) then
		-- Animation is good for a nice clean animation out..
		Controls.AlphaIn:Reverse();
	else
		-- Animation is not in an expected state, just reset all...
		Controls.AlphaIn:SetToBeginning();
		ShutdownAfterClose();
		UI.DataError("Forced closed() of the in game top options menu.  (Okay if someone was spamming ESC.)");
	end

	CloseImmediately()
end

function CloseImmediately()	
	ContextPtr:SetHide(true);	
	m_isClosing = false;	
end

-- ===========================================================================
function ShutdownAfterClose()
	print("ShutdownAfterClose()")
	m_isClosing = false;
	ContextPtr:SetHide(true);
end

-- ===========================================================================
--	Dervive off this in a MOD file for adding additional functionality
-- ===========================================================================
function LateInitialize()

end

-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
	if isReload then
		if not ContextPtr:IsHidden() then
			OnShow();
		end
	end
end


function OnShutdown()
	SetTicking(false)
	LuaEvents.InGame_OpenTurnProcessing.Remove( OnOpen );
	LuaEvents.InGame_CloseTurnProcessing.Remove( Close );
	
	LuaEvents.UITimeAdjust.Remove( OnAdjustTime )
	Events.LocalPlayerTurnBegin.Remove( OnLocalPlayerTurnBegin )
	Events.RemotePlayerTurnBegin.Remove( OnRemotePlayerTurnBegin )
	Events.RemotePlayerTurnEnd.Remove( OnRemotePlayerTurnEnd );
	Events.LocalPlayerTurnEnd.Remove(OnLocalPlayerTurnEnd );
	Events.TurnEnd.Remove(OnTurnEnd)
	Events.MultiplayerChat.Remove(OnMultiplayerChat)
	Events.TurnTimerUpdated.Remove(OnTurnTimerUpdated)
		
	Events.LoadScreenClose.Remove(OnLoadScreenClose);
	
end

	


-- ===========================================================================
function Initialize()
	Refresh_Data()
	SmartTimer()
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInput, true );
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetShutdown( OnShutdown );
	LuaEvents.InGame_OpenTurnProcessing.Add( OnOpen );
	LuaEvents.InGame_CloseTurnProcessing.Add( Close );
	
	LuaEvents.UITimeAdjust.Add( OnAdjustTime )
	Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin )
	Events.RemotePlayerTurnBegin.Add( OnRemotePlayerTurnBegin )
	Events.RemotePlayerTurnEnd.Add( OnRemotePlayerTurnEnd );
	Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd );
	Events.TurnEnd.Add(OnTurnEnd)
	Events.MultiplayerChat.Add(OnMultiplayerChat)
	Events.TurnTimerUpdated.Add(OnTurnTimerUpdated)
		
	Events.LoadScreenClose.Add(OnLoadScreenClose);
end
Initialize();
