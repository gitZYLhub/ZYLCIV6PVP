include("InstanceManager")

local m_checkBoxIM = InstanceManager:new("CheckboxInstance", "ButtonRoot", Controls.CheckBoxStack)
local m_controls = {}
local m_settings = {}
local KEY_PREFIX = "ZYL_MPS_SETTING_"

local function AsBoolean(value)
	return value == true or value == 1 or value == "1"
end

local function SaveSetting(parameterId, value)
	UserConfiguration.SetValue(KEY_PREFIX .. parameterId, value and 1 or 0)
	UserConfiguration.CommitToOptions()
end

local function ApplyAllSettings()
	for _, setting in ipairs(m_settings) do
		LuaEvents.TPT_Settings_Toggle(setting.ParameterId, setting.Value)
	end
end

local function OnCheckBox(index)
	local setting = m_settings[index]
	local control = m_controls[index]
	if setting == nil or control == nil then return end
	setting.Value = not setting.Value
	control.Settings_Box:SetSelected(setting.Value)
	SaveSetting(setting.ParameterId, setting.Value)
	LuaEvents.TPT_Settings_Toggle(setting.ParameterId, setting.Value)
end

local function BuildControls()
	m_checkBoxIM:ResetInstances()
	m_controls = {}
	for index, setting in ipairs(m_settings) do
		local control = m_checkBoxIM:GetInstance()
		m_controls[index] = control
		control.Settings_Box:SetText(Locale.Lookup(setting.String))
		if setting.ToolTip ~= nil then control.Settings_Box:SetToolTipString(Locale.Lookup(setting.ToolTip)) end
		control.Settings_Box:SetSelected(setting.Value)
		control.Settings_Box:SetVoid1(index)
		control.Settings_Box:RegisterCallback(Mouse.eLClick, OnCheckBox)
	end
	Controls.CheckBoxStack:CalculateSize()
	Controls.Listings:CalculateSize()
end

function OnShow() ContextPtr:SetHide(false) end
function OnClose() ContextPtr:SetHide(true) end
function OnSettingButton()
	if ContextPtr:IsHidden() then OnShow() else OnClose() end
end

function LateInitialize()
	local header = ContextPtr:LookUpControl("/InGame/WorldTracker/WorldTrackerHeader")
	if header ~= nil then Controls.TPTSettingButton:ChangeParent(header) end
	Controls.TPTSettingButton:RegisterCallback(Mouse.eLClick, OnSettingButton)
	Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, OnClose)
	Controls.ConfirmButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	ApplyAllSettings()
end

function Initialize()
	ContextPtr:SetHide(true)
	ContextPtr:SetShutdown(OnShutdown)
	for row in GameInfo.TPT_Settings() do
		local stored = UserConfiguration.GetValue(KEY_PREFIX .. row.ParameterId)
		local value = stored == nil and AsBoolean(row.DefaultValue) or AsBoolean(stored)
		table.insert(m_settings, { ParameterId = row.ParameterId, Value = value, String = row.String, ToolTip = row.ToolTip })
	end
	BuildControls()
	Events.LoadScreenClose.Add(LateInitialize)
end

function OnShutdown()
	Events.LoadScreenClose.Remove(LateInitialize)
end

Initialize()
