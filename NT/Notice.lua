local function IsEnabled(configurationId)
	local value = GameConfiguration.GetValue(configurationId)
	return value == true or value == 1 or value == "1"
end

local function SendLocalNotice(notificationType, messageTag, summaryTag)
	local localPlayerId = Game.GetLocalPlayer()
	local localPlayer = localPlayerId ~= nil and localPlayerId >= 0 and Players[localPlayerId] or nil
	if localPlayer == nil then return end
	NotificationManager.SendNotification(
		localPlayer,
		notificationType,
		Locale.Lookup(messageTag),
		Locale.Lookup(summaryTag)
	)
end

function OnLoadScreenClose()
	if IsEnabled("NEW_HOTKEYS") then
		SendLocalNotice(
			NotificationTypes.REBELLION,
			"LOC_TPT_NOTIFICATION_NEW_HOTKEYS_MESSAGE",
			"LOC_TPT_NOTIFICATION_NEW_HOTKEYS_SUMMARY"
		)
	end
	if IsEnabled("CPL_NO_PINS") then
		SendLocalNotice(
			NotificationTypes.SPY_ENEMY_CAPTURED,
			"LOC_TPT_NOTIFICATION_NO_PINS_MESSAGE",
			"LOC_TPT_NOTIFICATION_NO_PINS_SUMMARY"
		)
	end
end

Events.LoadScreenClose.Add(OnLoadScreenClose)
