-- TPT's original button is retained, but the old right-click path repeatedly
-- submitted end-turn requests every UI tick.  In this suite both the button
-- and Shift+F deliberately use one local request so they do not fight MPH's
-- host-side match controls.
local Show_FEB = true
local m_initialized = false
local SETTING_KEY = "ZYL_MPS_SETTING_ForcedEndButton_Show"

local function LoadSavedVisibility()
	local value = UserConfiguration.GetValue(SETTING_KEY)
	if value ~= nil then
		Show_FEB = value == true or value == 1 or value == "1"
	end
end

local function RequestForcedEndTurn()
	UI.RequestAction(ActionTypes.ACTION_ENDTURN, { REASON = "UserForced" })
	UI.PlaySound("Play_UI_Click")
end

function OnTPT_Settings_Toggle(ParameterId, Value)
	if ParameterId == "ForcedEndButton_Show" then
		Show_FEB = Value
		Controls.ForcedEnd_Button:SetHide(not Show_FEB)
		return
	end
end

function LateInitialize()
	if m_initialized then return end
	local ctr = ContextPtr:LookUpControl("/InGame/ActionPanel")
	if ctr == nil then return end
	m_initialized = true
	Controls.ForcedEnd_Button:ChangeParent(ctr)
	Controls.ForcedEnd_Button:SetToolTipString(Locale.Lookup("LOC_FORCEEND_TT"))
	Controls.ForcedEnd_Button:RegisterCallback(Mouse.eLClick, RequestForcedEndTurn)
	Controls.ForcedEnd_Button:SetHide(not Show_FEB)
end

function Initialize()
	LoadSavedVisibility()
	Events.LoadScreenClose.Add(LateInitialize)
	LuaEvents.TPT_Settings_Toggle.Add(OnTPT_Settings_Toggle)
	ContextPtr:SetShutdown(OnShutdown)
end

function OnShutdown()
	Events.LoadScreenClose.Remove(LateInitialize)
	LuaEvents.TPT_Settings_Toggle.Remove(OnTPT_Settings_Toggle)
end

Initialize()
