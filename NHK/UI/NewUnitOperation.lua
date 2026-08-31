-- Safe subset of Team PVP Tools' NewUnitOperation module.
--
-- The original file also contained an anti-cheat probe and a path that could
-- repeatedly call the Workshop update API.  Those unrelated side effects are
-- intentionally omitted; this script only implements the advertised random
-- promotion shortcut.

local m_FastPromoteActionId = Input.GetActionId("HotKey_TPT_FastPromote")

local function OnInputActionTriggered(actionId)
	if actionId ~= m_FastPromoteActionId then return end

	local selectedUnit = UI.GetHeadSelectedUnit()
	if selectedUnit == nil then return end
	local unitInfo = GameInfo.Units[selectedUnit:GetType()]
	if unitInfo == nil or unitInfo.UnitType == "UNIT_SPY" then return end

	local canPromote, results = UnitManager.CanStartCommand(
		selectedUnit,
		UnitCommandTypes.PROMOTE,
		true,
		true
	)
	if not canPromote or results == nil then return end

	local promotions = results[UnitCommandResults.PROMOTIONS]
	if promotions == nil or #promotions == 0 then return end

	-- Match TPT's behavior: cancel an automation first, then select one of the
	-- currently legal promotions at random.
	if UnitManager.CanStartCommand(selectedUnit, UnitCommandTypes.CANCEL) then
		UnitManager.RequestCommand(selectedUnit, UnitCommandTypes.CANCEL)
	end

	local promotionType = promotions[math.random(1, #promotions)]
	UnitManager.RequestCommand(selectedUnit, UnitCommandTypes.PROMOTE, {
		[UnitCommandTypes.PARAM_PROMOTION_TYPE] = promotionType
	})
end

Events.InputActionTriggered.Add(OnInputActionTriggered)

local function OnShutdown()
	Events.InputActionTriggered.Remove(OnInputActionTriggered)
end

if ContextPtr ~= nil then
	ContextPtr:SetShutdown(OnShutdown)
end
