local function IsNoPinsEnabled()
	local value = GameConfiguration.GetValue("CPL_NO_PINS")
	return value == true or value == 1 or value == "1"
end

local function RefreshMapPinListButton()
	local mapPinListButton = ContextPtr:LookUpControl("/InGame/MinimapPanel/MapPinListButton")
	if mapPinListButton ~= nil then
		mapPinListButton:SetHide(IsNoPinsEnabled())
	end
end

function OnShutdown()
	Events.LoadScreenClose.Remove(RefreshMapPinListButton)
	Events.GameConfigChanged.Remove(RefreshMapPinListButton)
end

ContextPtr:SetShutdown(OnShutdown)
Events.LoadScreenClose.Add(RefreshMapPinListButton)
Events.GameConfigChanged.Add(RefreshMapPinListButton)
