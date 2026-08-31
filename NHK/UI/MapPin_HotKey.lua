local m_AddMapMessageId:number = Input.GetActionId("AddMapMessage");

local g_mapPinStr = nil;
local g_X = nil;
local g_Y = nil;

local function IsNoPinsEnabled()
	local value = GameConfiguration.GetValue("CPL_NO_PINS");
	return value == true or value == 1 or value == "1";
end

function OnInputActionTriggered(actionId:number)
	if IsNoPinsEnabled() then
		return
	end
	if actionId == m_AddMapMessageId then
		AddMapMessage();
	end
end

function AddMapMessage()
	local localPlayerID = Game.GetLocalPlayer();
	if localPlayerID == nil or localPlayerID < 0 then return end
	local plotX, plotY = UI.GetCursorPlotCoord();
	if plotX ~= nil and plotY ~= nil then
		LuaEvents.MapPinPopup_RequestMapPin(plotX, plotY);
		local Ctr = ContextPtr:LookUpControl("/InGame/MapPinPopup")
		if Ctr ~= nil then UIManager:DequeuePopup( Ctr ); end

		local pPlayerCfg = PlayerConfigurations[localPlayerID];
		if pPlayerCfg == nil then return end
		local pMapPin = pPlayerCfg:GetMapPin(plotX, plotY);
		if pMapPin ~= nil then
			LuaEvents.MapPinPopup_SendPinToChat(localPlayerID, pMapPin:GetID());
			g_mapPinStr = "[pin:" .. localPlayerID .. "," .. pMapPin:GetID() .. "]";
			g_X, g_Y = plotX, plotY;
		end
	end
end

function OnMultiplayerChat( fromPlayer, toPlayer, text, eTargetType )
	if fromPlayer == Game.GetLocalPlayer() and text == g_mapPinStr then
		DeleteMapPinAtPlot(Game.GetLocalPlayer(), g_X, g_Y);
	end
end

function DeleteMapPinAtPlot(playerID, plotX, plotY)
    local playerCfg = PlayerConfigurations[playerID];
    local mapPin = playerCfg and playerCfg:GetMapPin(plotX, plotY);
    if mapPin then
        -- Update map pin yields.
        LuaEvents.DMT_MapPinRemoved(mapPin);
        -- Delete the pin.
        playerCfg:DeleteMapPin(mapPin:GetID());
        Network.BroadcastPlayerInfo();
        UI.PlaySound("Map_Pin_Remove");
    end
end

function OnShutdown()
	Events.InputActionTriggered.Remove(OnInputActionTriggered);
	Events.MultiplayerChat.Remove(OnMultiplayerChat);
end

function Initialize()
	ContextPtr:SetShutdown(OnShutdown)
	Events.InputActionTriggered.Add(OnInputActionTriggered);
	Events.MultiplayerChat.Add( OnMultiplayerChat )
end
Initialize()
