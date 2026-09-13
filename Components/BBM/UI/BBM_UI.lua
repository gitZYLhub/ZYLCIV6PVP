local g_version = "1.39.1" --TODO fix get version from modinfo
-------------------------------------------------------------------------------
print("-------------- BBM UI v"..g_version.." -D- Init --------------")
-------------------------------------------------------------------------------

-- A strict player-distance policy cannot be repaired by accepting Firaxis'
-- fallback starts: that would violate the selected minimum.  The map assigner
-- marks such a candidate for regeneration, and the host performs one normal
-- multiplayer restart with fresh map/game seeds.  Non-host clients simply wait
-- for the host's restart and do not display the fallback notification.
local function ZYL_RVC_AutoRegeneratePlayerDistanceMap()
	if Game:GetProperty("ZYLRM_PLAYER_DISTANCE_REGEN_REQUIRED") ~= true then
		return false;
	end
	if Game:GetProperty("ZYLRM_PLAYER_DISTANCE_REGEN_REQUESTED") == true then
		return true;
	end

	local hostID = Network.GetGameHostPlayerID();
	local localID = Network.GetLocalPlayerID();
	if hostID == nil or localID == nil or hostID < 0 or localID ~= hostID then
		return true;
	end

	Game:SetProperty("ZYLRM_PLAYER_DISTANCE_REGEN_REQUESTED", true);
	local mapSeedValue = MapConfiguration.GetValue("RANDOM_SEED");
	local mapSeed = tonumber(mapSeedValue) or 0;
	local seedDelta = math.floor(math.random() * 100000) + 1;
	local nextMapSeed = mapSeed + seedDelta;
	local nextGameSeed = nextMapSeed - 1;
	GameConfiguration.SetValue("GAME_SYNC_RANDOM_SEED", nextGameSeed);
	MapConfiguration.SetValue("RANDOM_SEED", nextMapSeed);
	GameConfiguration.SetValue("GAME_HOST_IS_JUST_RELOADING", "Y");
	Network.BroadcastGameConfig();

	-- Match the existing MPH host-remap handshake so all clients resync after
	-- the automatic regeneration just as they do after a manual remap.
	if GameConfiguration.IsPaused() == false then
		local localPlayerConfig = PlayerConfigurations[localID];
		if localPlayerConfig ~= nil then
			localPlayerConfig:SetWantsPause(not localPlayerConfig:GetWantsPause());
			Network.BroadcastPlayerInfo();
		end
	end
	print("ZYL RVC strict player-distance placement failed; host is regenerating the map",
		"with map seed", nextMapSeed, "and game seed", nextGameSeed)
	Network.RestartGame();
	return true;
end

function OnLocalPlayerTurnBegin()

	if Game.GetLocalPlayer() == -1 then
		return
	end
	if Game.GetCurrentGameTurn() == GameConfiguration.GetStartTurn() then
		print("BBM UI Welcome ", g_version)
		local message = "BBM #"..g_version.." :";
		if ZYL_RVC_AutoRegeneratePlayerDistanceMap() then
			return;
		end
		local unsupportedMap = Game:GetProperty("BBM_SUPPORTEDMAP") == false or Game:GetProperty("BBM_SUPPORTEDMAP") == nil;
		if unsupportedMap then
			message = message.."This map is not supported by BBM.";
			NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, message);
			return;
		end

		message = message.." loaded succesfully!";

		print("BBM_ACTUALMINDIST == ", Game:GetProperty("BBM_ACTUALMINDIST"))
		-- Notification for teamers if only 1 continent settled for one team
		--if Game:GetProperty("BBS_TEAMERCONTINENTCHECK") ~= nil and Game:GetProperty("BBS_TEAMERCONTINENTCHECK") then
		--	print("BBS_TEAMERCONTINENTCHECK - ", Game:GetProperty("BBS_TEAMERCONTINENTCHECK"))
		--	NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.USER_CONTCHECK, "WARNING - Teamer setting - Could not place a team on at least two continents.")
		--end

		if (Game:GetProperty("BBM_RESPAWN") == false) then
			message = message.." Firaxis Placement Algorithm has been used."
			NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.BARBARIANS_SIGHTED, message);
		else
			message = message.." BBM Placement Algorithm successful."
			if Game:GetProperty("BBM_MAJOR_DISTANCE") ~= nil then
				-- For some reason, notification go full uppercase if min distance is a single digit, so adding 0 (need more investigation)
				local minDist=  Game:GetProperty("BBM_MAJOR_DISTANCE")
				local txtMinDist = tostring(minDist)
				if minDist < 10 then
					txtMinDist = "0"..tostring(minDist)
				end
				message = message.." Minimum Distance is "..txtMinDist
			end
			print("message BBM UI")
			print(message)
			NotificationManager.SendNotification(Game.GetLocalPlayer(), NotificationTypes.USER_DEFINED_5, message);
		end
	end
	
	
end


Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin);


-- ===========================================================================
function GetLocalModVersion(id)
	if id == nil then
		return nil
	end
	
	local mods = Modding.GetInstalledMods();
	if(mods == nil or #mods == 0) then
		print("No mods locally installed!")
		return nil
	end
	
	local handle = -1
	for i,mod in ipairs(mods) do
		if mod.Id == id then
			handle = mod.Handle
			break
		end
	end
	if handle ~= -1 then
		local version = Modding.GetModProperty(handle, "Version");
		print("id",id,version)
		return version
		else
		return nil
	end
	
	
end
