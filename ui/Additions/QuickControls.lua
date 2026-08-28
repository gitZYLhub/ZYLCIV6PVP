print("ZYLPVPMOD Quick Controls")

local m_initialized = false
local m_addAction = Input.GetActionId("HotKey_TPT_TurnTimeAdd")
local m_reduceAction = Input.GetActionId("HotKey_TPT_TurnTimeReduce")
local m_endTurnAction = Input.GetActionId("HotKey_TPT_ForcedTurnEnd")

local function CommandsEnabled()
	local value = GameConfiguration.GetValue("TOOLS_COMMAND")
	return value == true or value == 1
end

local function SendCommand(command)
	if not CommandsEnabled() or not GameConfiguration.IsNetworkMultiplayer() then return end
	Network.SendChat(command, -2, -1)
	UI.PlaySound("Play_MP_Game_Launch_Timer_Beep")
end

function OnInputActionTriggered(actionId)
	if actionId == m_addAction then
		SendCommand("p++")
	elseif actionId == m_reduceAction then
		SendCommand("p--")
	elseif actionId == m_endTurnAction then
		-- A single local request is deliberate. The old TPT implementation retried
		-- every UI tick and could fight the game state or the MPH host controls.
		UI.RequestAction(ActionTypes.ACTION_ENDTURN, { REASON = "UserForced" })
		UI.PlaySound("Play_UI_Click")
	end
end

function RefreshVisibility()
	local show = CommandsEnabled() and GameConfiguration.IsNetworkMultiplayer()
	Controls.AddTimeButton:SetHide(not show)
	Controls.ReduceTimeButton:SetHide(not show)
end

function Initialize()
	if m_initialized then return end
	m_initialized = true
	local parent = ContextPtr:LookUpControl("/InGame/WorldTracker/ChatPanelContainer")
	if parent ~= nil then
		Controls.AddTimeButton:ChangeParent(parent)
		Controls.ReduceTimeButton:ChangeParent(parent)
		Controls.BlackListButton:ChangeParent(parent)
	end
	Controls.AddTimeButton:RegisterCallback(Mouse.eLClick, function() SendCommand("p++") end)
	Controls.ReduceTimeButton:RegisterCallback(Mouse.eLClick, function() SendCommand("p--") end)
	Controls.BlackListButton:RegisterCallback(Mouse.eLClick, function() LuaEvents.Open_BlackListOanel() end)
	Events.InputActionTriggered.Add(OnInputActionTriggered)
	Events.GameConfigChanged.Add(RefreshVisibility)
	RefreshVisibility()
end

function OnShutdown()
	Events.LoadScreenClose.Remove(Initialize)
	if not m_initialized then return end
	Events.InputActionTriggered.Remove(OnInputActionTriggered)
	Events.GameConfigChanged.Remove(RefreshVisibility)
end

ContextPtr:SetShutdown(OnShutdown)
Events.LoadScreenClose.Add(Initialize)
