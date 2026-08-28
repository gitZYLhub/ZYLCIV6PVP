local m_RangedAttackActionId = Input.GetActionId("RangedAttack");
local m_BaseOnShutdown_CSA = OnShutdown
function OnInputActionTriggered_CSA(actionId)
	if actionId == m_RangedAttackActionId then
		local pCity = UI.GetHeadSelectedCity()
		if CanRangeAttack(pCity) then
			UI.SetInterfaceMode(InterfaceModeTypes.CITY_RANGE_ATTACK);
		end
		return
	end
end
Events.InputActionTriggered.Add(OnInputActionTriggered_CSA)

function OnShutdown_CSA()
	Events.InputActionTriggered.Remove(OnInputActionTriggered_CSA)
	if m_BaseOnShutdown_CSA ~= nil then m_BaseOnShutdown_CSA() end
end

ContextPtr:SetShutdown(OnShutdown_CSA)
