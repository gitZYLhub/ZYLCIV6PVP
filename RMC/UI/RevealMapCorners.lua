-- ======================================
-- 地图角落自动地图钉，以便小地图以全球比例显示。
-- ======================================
function OnLoadScreenClose()
	local noPinsValue = GameConfiguration.GetValue("CPL_NO_PINS")
	if noPinsValue == true or noPinsValue == 1 or noPinsValue == "1" then return end
	local plot_Fist = Map.GetPlotByIndex(0);
	local plot_Last = Map.GetPlotByIndex(Map.GetPlotCount() - 1);
	if plot_Fist == nil or plot_Last == nil then return end
	LuaEvents.MapPinPopup_RequestMapPin(plot_Fist:GetX(), plot_Fist:GetY());
	LuaEvents.MapPinPopup_RequestMapPin(plot_Last:GetX(), plot_Last:GetY());
	local Ctr = ContextPtr:LookUpControl("/InGame/MapPinPopup")
	if Ctr ~= nil then UIManager:DequeuePopup(Ctr); end
end
Events.LoadScreenClose.Add(OnLoadScreenClose)
