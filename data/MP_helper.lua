------------------------------------------------------------------------------
--	FILE:	 CPL_helper.lua
--	AUTHOR:  D. / Jack The Narrator
--	PURPOSE: Gameplay script - Lua Handling
-------------------------------------------------------------------------------
-- logs
-- v0.1 added CPL auto-pause
-- v0.2 added auto Freeze
--	added the Command logic
--	added the Trading logic
-- v0.3 trading logic should be working
-- v0.4 added the maximum friendship logic
-- v0.5 CC, Scrap, Irr Vote
--	Max Friendship
--	Max City States
--	Logging events
-- v0.6 Allies Trading
--	Restrict AI trading
--	Forced Turn command
-- v0.7 Fixed some bug
--	Change the commands to match the discord bot
-- 	Sudden-Death
--	Capturing captured CS does trigger an automatic raze
-- v0.8 Remapvote
--	Beef up free cities
-- v0.9 	Prevent unsolited friendship above threshold
--			Added The first move/last move debuff
-- v0.92	Nerfed Free Cities
-- v0.93	Introduce a Smart Timer	
-- v0.94	Dynamic timer
--			Added a mechanism to further prevent desync when a player lag excessively
--			Added a toogle to control free city flip in FFA
--			Nerfed free cities
--			Added .time command to modify the dynamic timer ingame
--			Improved the lua.log reporting to track the players ID better
-- v0.95		Cleaned up the code with one main teamer boolean
--				Modulated the turns better (+10% if it is a Teamer, +15% if at war)
--				Made a smart timer toogle
--				Free Cities now need to wait for turn 50 to get walls 
-- v0.96	Added Draft/Ban support in game
-- v0.97	Map Pool
--			Slightly quicker timer
-- v0.98	Clarify the draft mechanism with more visual clues
--			Remove the extra 10% time in Teamers when in Tournament
-- v0.99	Auto flag the doom Civ+ Player Name
--			Check player's mod version
--			More timers
-- v1.00 	Recoded the Staging Room
-- v1.01	New CWC slot draft
--		UI for MPH
--		Built in Game Video Support for Victory Screen
--		gg would trigger a concede victory
-- v1.02	Improved interface stability
--		Introduced a first Voting Draft interface
-- v1.03	Added Observer support for random compatibility
--		Added Draft pool
--		Added Anonymous Front End layer
--		Added No private chat Front End layer
--		Further exposed the localization for translation if needed
--		Only one video can be played
-- v1.04	Minor UI bug fixes and text
-- v1.06	Handle New Frontier Pass
--		Completely redesigned the code for an UI oriented interface
--		Currently support: Remap, vote remap, drop pause, smart timer, esport drafting
-- v1.08 	Added Casual timer
--		CWC new format
--		Bug fixes
-- v1.09
--		Alliance and Trading restrictions
--		Improved Front End
-- v1.10
--		World Congress timer no longer infinite
--		Added No Frienship, no surprise wars option
-- v1.2.5
--		Updated version number
--		Congress no longer can be skipped on lag
-- v1.3.2
-- 		Random leader picked
--		ConfigurationUpdate changes for CWC
-- v1.3.3
--		Added an event debug
--		Moved the timer codes to UI (no real reason to have it on the Core side for calculation as the implementation is UI anyway)
-- v1.3.4
--		Presets Updated
-- v1.3.5
--		OCC Updated
-- v1.3.6
--		Code Clean Up

-- ===========================================================================
--	NEW VARIABLES
-- ===========================================================================
ExposedMembers.LuaEvents = LuaEvents
local g_version = "ZYLPVPMOD v1.2.5"
local Drop_Data = {};
local b_debug = false

-- ===========================================================================
--	GLOBAL FLAGS
-- ===========================================================================


-- =========================================================================== 
--	NEW EVENTS
-- =========================================================================== 

function OnGameTurnStarted(turn)
	-- local time
	g_turn_start_time = os.date('%Y-%m-%d %H:%M:%S')
	b_clean = false
	b_debuff = false
	local seed = Game.GetRandNum(100, "MPH Track Local State")
	print("OnGameTurnStarted: Turn",turn,"Local State:",seed,g_turn_start_time)
	
end

-- =========================================================================== 
--	REMOTE EVENTS (UI -> SCRIPT)
-- ===========================================================================
-- Drop/Restore Mechanics

function OnDrop(playerID:number)
	print("Ondrop: Saving Player",playerID,"'s data")
	-- Drop_Player Table
	local Drop_P = {}
	-- Units
	local pPlayer = Players[playerID];
	if pPlayer == nil or pPlayer:GetUnits() == nil then
		Drop_Data[playerID] = { unit = { count = 0 } }
		return
	end
	local pPlayerUnits = pPlayer:GetUnits();
	local tmp_unit = {}
	local counter = 0
	for i, unit in pPlayerUnits:Members() do
		counter = counter + 1
		tmp_unit[counter] = { ID = unit:GetID(), moves = unit:GetMovesRemaining()}
		print("unit:GetMovesRemaining()",unit:GetMovesRemaining())
		UnitManager.ChangeMovesRemaining(unit, -99)
		print("unit:GetMovesRemaining()",unit:GetMovesRemaining())
		print("counter",counter,"tmp_unit[counter] ",tmp_unit[counter] ,"tmp_unit[counter].ID",tmp_unit[counter].ID,"tmp_unit[counter].moves",tmp_unit[counter].moves) 
	end
	tmp_unit["count"] = counter
	Drop_P = { unit = tmp_unit }
	Drop_Data[playerID] = Drop_P
end

LuaEvents.UICPLPlayerDrop.Add( OnDrop );

function RestoreUnits(unit_table:table,playerID:number)
	print("RestoreUnits", playerID)
	if type(unit_table) ~= "table" or (tonumber(unit_table["count"]) or 0) < 1 then
		return
	end

	
	local pPlayer = Players[playerID];
	if pPlayer == nil or pPlayer:GetUnits() == nil then return end
	local pPlayerUnits = pPlayer:GetUnits();
	-- Restore all the units
	local counter = 0
	for i, unit in pPlayerUnits:Members() do
		local unit_ID = unit:GetID()
		for k = 1, unit_table["count"] do
			local savedUnit = unit_table[k]
			if savedUnit ~= nil and unit_ID == savedUnit.ID then
				UnitManager.ChangeMovesRemaining(unit, tonumber(savedUnit.moves) or 0)
				print(unit:GetID(),unit:GetMovesRemaining())
				counter = counter + 1
				break
			end
		end
		if counter == unit_table["count"] then
			break
		end
	end
	
end

function OnConnect(playerID:number)
	print("OnConnect", playerID)
	local dropData = Drop_Data[playerID]
	if dropData == nil or dropData.unit == nil then
		print("OnConnect: no frozen-unit snapshot for player", playerID)
		return
	end
	RestoreUnits(dropData.unit,playerID)
	Drop_Data[playerID] = nil
end


LuaEvents.UICPLPlayerConnect.Add( OnConnect );

--	Sudden Death

function OnTimerExpires(playerID:number)
	print("OnTimerExpires Script", playerID)
	local pPlayer = Players[playerID];
	if pPlayer == nil then return end
	local pPlayerUnits:table = pPlayer:GetUnits();	
	local pPlayerCities:table = pPlayer:GetCities();
	local units = {}
	local cities = {}
	if pPlayerUnits ~= nil then for _, pUnit in pPlayerUnits:Members() do table.insert(units, pUnit) end end
	if pPlayerCities ~= nil then for _, pCity in pPlayerCities:Members() do table.insert(cities, pCity) end end
	for _, pUnit in ipairs(units) do pPlayerUnits:Destroy(pUnit) end
	for _, pCity in ipairs(cities) do CityManager.DestroyCity(pCity) end
end

LuaEvents.UISuddenDeathTimeExpireAI.Add( OnTimerExpires );

function OnTimeSaved(timeleft:number)
	Game:SetProperty("MPH_SD_TIME_LEFT", timeleft );	
end

LuaEvents.UISuddenDeathSavetime.Add( OnTimeSaved );

-- =========================================================================== 
--	Utils
-- ===========================================================================
function Tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

function FindTableIndex(t,val)
    for k,v in ipairs(t) do 
        if v == val then return k end
    end
end


-- Event Debugging

-- Player
function Debug_OnGameTurnStarted(arg1,arg2)
	print("Debug_OnGameTurnStarted",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_PlayerTurnStarted(arg1,arg2)
	print("Debug_PlayerTurnStarted",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_PlayerTurnStartComplete(arg1,arg2)
	print("Debug_PlayerTurnStartComplete",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_OnPlayerTurnEnded(arg1,arg2)
	print("Debug_PlayerTurnEnded",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_PlayerTurnActivated(arg1,arg2)
	print("Debug_PlayerTurnActivated",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_LocalPlayerTurnBegin(arg1,arg2)
	print("Debug_LocalPlayerTurnBegin",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_LocalPlayerTurnEnd(arg1,arg2)
	print("Debug_LocalPlayerTurnEnd",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_RemotePlayerTurnBegin(arg1,arg2)
	print("Debug_RemotePlayerTurnBegin",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_RemotePlayerTurnEnd(arg1,arg2)
	print("Debug_RemotePlayerTurnEnd",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_TurnEnd(arg1,arg2)
	print("Debug_TurnEnd",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_PlayerDefeat( player, defeat, eventID)
	print("Debug_PlayerDefeat",os.date('%Y-%m-%d %H:%M:%S'),"player",player,"defeat",defeat,"eventID",eventID)
end




-- Connect
function Debug_ConnectedToNetSessionHost(arg1,arg2)
	print("Debug_ConnectedToNetSessionHost",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_MultiplayerPlayerConnected(arg1,arg2)
	print("Debug_MultiplayerPlayerConnected",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_MultiplayerPrePlayerDisconnected(arg1,arg2)
	print("Debug_MultiplayerPrePlayerDisconnected",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_MultiplayerSnapshotRequested(arg1,arg2)
	print("Debug_MultiplayerSnapshotRequested",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_MultiplayerSnapshotProcessed(arg1,arg2)
	print("Debug_MultiplayerSnapshotProcessed",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_MultiplayerHostMigrated(arg1,arg2)
	print("Debug_MultiplayerHostMigrated",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_MultiplayerMatchHostMigrated(arg1,arg2)
	print("Debug_MultiplayerMatchHostMigrated",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_SteamServersDisconnected(arg1,arg2)
	print("Debug_SteamServersDisconnected",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_PlayerInfoChanged(arg1,arg2)
	print("Debug_PlayerInfoChanged",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_GameConfigChanged(arg1,arg2)
	print("Debug_PlayerInfoChanged",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2)
end

function Debug_OnUnitInitialized(iPlayerID : number, iUnitID : number)
	print("Debug_OnUnitInitialized",os.date('%Y-%m-%d %H:%M:%S'),"iPlayerID",iPlayerID,"iUnitID",iUnitID)
end

function Debug_OnUnitCreated(iPlayerID : number, iUnitID : number)
	print("Debug_OnUnitCreated",os.date('%Y-%m-%d %H:%M:%S'),"iPlayerID",iPlayerID,"iUnitID",iUnitID)
end

function Debug_OnImprovementPillaged(iPlotIndex :number, eImprovement :number)
	print("Debug_OnImprovementPillaged",os.date('%Y-%m-%d %H:%M:%S'),"iPlotIndex",iPlotIndex,"eImprovement",eImprovement)
end

-- city
function Debug_OnCityBuilt( playerID: number, cityID : number, cityX : number, cityY : number )	
	print("Debug_OnCityBuilt",os.date('%Y-%m-%d %H:%M:%S'),"playerID",playerID,"cityID",cityID,"cityX",cityX,"cityY",cityY)
end

function Debug_OnCityConquered(capturerID,  ownerID, cityID , cityX, cityY)
	print("Debug_OnCityConquered",os.date('%Y-%m-%d %H:%M:%S'),"capturerID",capturerID,"ownerID,",ownerID,"cityID",cityID,"cityX",cityX,"cityY",cityY)
end

function Debug_OnCombatOccurred(attackerPlayerID :number, attackerUnitID :number, defenderPlayerID :number, defenderUnitID :number)
	print("Debug_OnCombatOccurred",os.date('%Y-%m-%d %H:%M:%S'),"attackerPlayerID",attackerPlayerID,"defenderPlayerID",defenderPlayerID,"defenderUnitID",defenderUnitID)
end

-- spy
function Debug_OnSpyMissionUpdated(arg1, arg2, arg3, arg4)
	print("Debug_OnSpyMissionUpdated",os.date('%Y-%m-%d %H:%M:%S'),"arg1",arg1,"arg2",arg2,"arg3",arg3,"arg4",arg4)
end

function Debug_OnSpyMissionCompleted(playerID:number, missionID:number, arg3, arg4)
	print("Debug_OnSpyMissionCompleted",os.date('%Y-%m-%d %H:%M:%S'),"playerID",playerID,"missionID",missionID,"arg3",arg3,"arg4",arg4)
end

-------------------------------------------------------
-------------------------------------------------------
-------------------------------------------------------

function Initialize()
	print("-- Init D. CPL Helper Gameplay Script"..g_version.." --");
	
	if b_debug == true then
		-- Player
		GameEvents.OnGameTurnStarted.Add(Debug_OnGameTurnStarted);
		GameEvents.PlayerTurnStarted.Add(Debug_PlayerTurnStarted);
		GameEvents.PlayerTurnStartComplete.Add(Debug_PlayerTurnStartComplete);
		GameEvents.OnPlayerTurnEnded.Add(Debug_OnPlayerTurnEnded);
		
		Events.PlayerTurnActivated.Add(Debug_PlayerTurnActivated);
		Events.LocalPlayerTurnBegin.Add(Debug_LocalPlayerTurnBegin );
		Events.LocalPlayerTurnEnd.Add(Debug_LocalPlayerTurnEnd );
		Events.RemotePlayerTurnBegin.Add( Debug_RemotePlayerTurnBegin);
		Events.RemotePlayerTurnEnd.Add( Debug_RemotePlayerTurnEnd );
		Events.TurnEnd.Add(Debug_TurnEnd)
		Events.PlayerDefeat.Add( Debug_PlayerDefeat );	
		-- Connection
		Events.ConnectedToNetSessionHost.Add ( Debug_ConnectedToNetSessionHost );
		Events.MultiplayerPlayerConnected.Add( Debug_MultiplayerPlayerConnected );
		Events.MultiplayerPrePlayerDisconnected.Add( Debug_MultiplayerPrePlayerDisconnected );
		Events.MultiplayerSnapshotRequested.Add(Debug_MultiplayerSnapshotRequested);
		Events.MultiplayerSnapshotProcessed.Add(Debug_MultiplayerSnapshotProcessed);
		Events.MultiplayerHostMigrated.Add(Debug_MultiplayerHostMigrated);
		Events.MultiplayerMatchHostMigrated.Add(Debug_MultiplayerMatchHostMigrated);
		Events.SteamServersDisconnected.Add( Debug_SteamServersDisconnected)
		Events.PlayerInfoChanged.Add(Debug_PlayerInfoChanged);
		Events.GameConfigChanged.Add(Debug_GameConfigChanged);
		-- Unit
		GameEvents.UnitInitialized.Add(Debug_OnUnitInitialized)
		GameEvents.UnitCreated.Add(Debug_OnUnitCreated);
		GameEvents.OnCombatOccurred.Add(Debug_OnCombatOccurred)
		-- Improvement
		GameEvents.OnImprovementPillaged.Add(Debug_OnImprovementPillaged);
		-- City
		GameEvents.CityBuilt.Add(Debug_OnCityBuilt);
		GameEvents.CityConquered.Add(Debug_OnCityConquered);
		-- Spy
		Events.SpyMissionUpdated.Add( Debug_OnSpyMissionUpdated );
		Events.SpyMissionCompleted.Add(	Debug_OnSpyMissionCompleted );
	end

	GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted);
	for _, i in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if Players[i] ~= nil and Players[i]:IsAlive() == true then
			if Players[i]:GetTeam() ~= i then
				b_teamer = true
			end
		end
	end

end


Initialize();
