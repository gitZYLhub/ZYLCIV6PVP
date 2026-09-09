-- Taoist_Gameplay
-- Author: pen
-- DateCreated: 2023/6/8 13:08:28
--------------------------------------------------------------
ExposedMembers.GameEvents = GameEvents
--------------------------------------------------------------
local function GetTaoistConfigurationValue(optionId, defaultValue)
	local value = GameConfiguration.GetValue(optionId)
	if value == nil then
		return defaultValue
	end
	return value
end

local ifPromotionSupplement = GetTaoistConfigurationValue("Taoist_PromotionSupplement", false)
local ifDisposable = GetTaoistConfigurationValue("Taoist_Disposable", true)
--------------------------------------------------------------
local TaoistCreateLeyLineCharge = 1
local taoistUnitInfo = GameInfo.Units['UNIT_TAOIST']
local UnitTaoist = taoistUnitInfo and taoistUnitInfo.Index or -1
local leyLineResourceInfo = GameInfo.Resources['RESOURCE_LEY_LINE']
local LeyLineResource = leyLineResourceInfo and leyLineResourceInfo.Index or -1
local TaoistPromotionTable = {
	PROMOTION_TAOIST_GRAVE_ROBBER = 2,
	PROMOTION_TAOIST_SHRINK_LAND = 1,--缩地成寸只+1
	PROMOTION_TAOIST_CONCEALMENT = 2,
	PROMOTION_TAOIST_SUMMON_WIND_RAIN = 2,
	PROMOTION_TAOIST_TAOISM_MAGIC = 3,
}

local function GetTaoistRequestContext(playerID, params)
	local numericPlayerID = tonumber(playerID)
	if numericPlayerID == nil or params == nil then
		return nil
	end
	local pPlayer = Players[numericPlayerID]
	local iX = tonumber(params.X)
	local iY = tonumber(params.Y)
	local unitID = tonumber(params.UnitID)
	if pPlayer == nil or iX == nil or iY == nil or unitID == nil then
		return nil
	end
	local pPlot = Map.GetPlot(iX, iY)
	local pUnit = UnitManager.GetUnit(numericPlayerID, unitID)
	if pPlot == nil or pUnit == nil or UnitTaoist < 0 or
			pUnit:GetType() ~= UnitTaoist or
			pUnit:GetX() ~= iX or pUnit:GetY() ~= iY then
		return nil
	end
	return pPlayer, pUnit, pPlot, iX, iY, unitID
end

function Initilize ()
	if	GameConfiguration.GetValue("Taoist_Settings") == "SETTINGS_TAOIST_NORMAL" then
		ifPromotionSupplement = false--晋升树优先ban了，所以不需要额外处理
		ifDisposable = true
		--print("ifPromotionSupplement",ifPromotionSupplement)
	end
	--print("Taoist pvp Load")
end

function TaoistAddLeyLine(playerID, params)
	local pPlayer, pUnit, pPlot, iX, iY, unitID = GetTaoistRequestContext(playerID, params)
	if pPlayer == nil or LeyLineResource < 0 or
			pUnit:GetActionCharges() < TaoistCreateLeyLineCharge or
			pPlot:GetResourceType() ~= -1 then
		return
	end
	ResourceBuilder.SetResourceType(pPlot, LeyLineResource, 1)
		
	local messageData = {
		MessageType = 0;
		MessageText = Locale.Lookup('LOC_TAOIST_ADD_LEYLINE_TOOLTIP');
		PlotX = iX;
		PlotY = iY;
		Visibility = RevealedState.VISIBLE;
	}
	Game.AddWorldViewText(messageData);
	--买地刷新
	if pPlot:GetOwner() >= 0 then
		local pTreasury = pPlayer:GetTreasury()
		local pCity = Cities.GetPlotPurchaseCity(pPlot)
		if pTreasury ~= nil and pCity ~= nil then
			local iTreasury = pTreasury:GetGoldBalance()
			local CityPlotIndex = Map.GetPlotIndex(pCity:GetX(), pCity:GetY())
			pPlayer:SetProperty("TaoistPlot", pPlot:GetIndex())
			pPlayer:SetProperty("TaoistGold", iTreasury)
			pPlayer:SetProperty("TaoistCity", CityPlotIndex)--放unit上可能代码执行不及时会丢包
			pPlayer:SetProperty("TaoistUnit", unitID)
			pTreasury:ChangeGoldBalance(375)
			pPlot:SetOwner(-1)
		end
	end
	--
	pUnit:ChangeActionCharges(-TaoistCreateLeyLineCharge)
	UnitManager.FinishMoves(pUnit)
	if	pUnit:GetProperty("TaoistHasUse") then
		pUnit:SetProperty("TaoistHasUse",pUnit:GetProperty("TaoistHasUse")+1)
	else
		pUnit:SetProperty("TaoistHasUse",1)
	end
	if	pPlayer:GetProperty("TaoistPlot") == nil then--境外
		if pUnit:GetActionCharges() == 0 and (not pPlayer:IsHuman() or ifDisposable) then
			UnitManager.Kill(pUnit)
		end
	end
end
GameEvents.TaoistAddLeyLine.Add(TaoistAddLeyLine);

function TaoistNotAddLeyLine(playerID, params)
	local pPlayer, pUnit, pPlot, iX, iY = GetTaoistRequestContext(playerID, params)
	if pPlayer == nil then
		return
	end
	local Tooltip = ""
	if	pUnit:GetActionCharges() > 0 then
		Tooltip = Locale.Lookup("LOC_ABILITY_TAOIST_NOT_ADD_LEYLINE")
		
	else
		Tooltip = Locale.Lookup("LOC_ABILITY_TAOIST_REMOVE_LEYLINE_TO_MAX")
	end
	if	Tooltip ~= "" then
		local messageData = {
			MessageType = 0;
			MessageText = Tooltip;
			PlotX = iX;
			PlotY = iY;
			Visibility = RevealedState.VISIBLE;
		}
		Game.AddWorldViewText(messageData);
	end
end
GameEvents.TaoistNotAddLeyLine.Add(TaoistNotAddLeyLine);

function TaoistRemoveLeyLine(playerID, params)
	local pPlayer, pUnit, pPlot, iX, iY = GetTaoistRequestContext(playerID, params)
	if pPlayer ~= nil and LeyLineResource >= 0 and
			pPlot:GetResourceType() == LeyLineResource then
		ResourceBuilder.SetResourceType(pPlot, -1)
		
		local messageData = {
			MessageType = 0;
			MessageText = Locale.Lookup('LOC_ABILITY_TAOIST_REMOVE_LEYLINE');
			PlotX = iX;
			PlotY = iY;
			Visibility = RevealedState.VISIBLE;
		}
		Game.AddWorldViewText(messageData);

		pUnit:ChangeActionCharges(TaoistCreateLeyLineCharge)
		UnitManager.FinishMoves(pUnit)
	end
end
GameEvents.TaoistRemoveLeyLine.Add(TaoistRemoveLeyLine);

function TaoistRemoveLeyLineToMax(playerID, params)
	local pPlayer, pUnit, pPlot, iX, iY = GetTaoistRequestContext(playerID, params)
	if pPlayer ~= nil and LeyLineResource >= 0 and
			pPlot:GetResourceType() == LeyLineResource then
		local messageData = {
			MessageType = 0;
			MessageText = Locale.Lookup('LOC_ABILITY_TAOIST_REMOVE_LEYLINE_TO_MAX');
			PlotX = iX;
			PlotY = iY;
			Visibility = RevealedState.VISIBLE;
		}
		Game.AddWorldViewText(messageData);
	end
end
GameEvents.TaoistRemoveLeyLineToMax.Add(TaoistRemoveLeyLineToMax);

function RecoverTaoistTreasury(playerID, params)
	local numericPlayerID = tonumber(playerID)
	local unitID = params and tonumber(params.UnitID)
	local purchaseCost = params and tonumber(params.PurchaseCost)
	if numericPlayerID == nil or unitID == nil or purchaseCost == nil then
		return
	end
	local pPlayer = Players[numericPlayerID]
	if pPlayer == nil or
			tonumber(pPlayer:GetProperty("TaoistUnit")) ~= unitID or
			tonumber(pPlayer:GetProperty("TaoistPlot")) == nil or
			tonumber(pPlayer:GetProperty("TaoistCity")) == nil then
		return
	end
	local pTreasury = pPlayer:GetTreasury()
	local currentTreasury = pTreasury and tonumber(pTreasury:GetGoldBalance())
	local storedTreasury = tonumber(pPlayer:GetProperty("TaoistGold"))
	if currentTreasury == nil or storedTreasury == nil then
		return
	end
	pTreasury:SetGoldBalance(math.min(
		storedTreasury,
		currentTreasury - 375 + math.max(0, purchaseCost)
	))
	pPlayer:SetProperty("TaoistPlot", nil)
	pPlayer:SetProperty("TaoistGold", nil)
	pPlayer:SetProperty("TaoistCity", nil)
	pPlayer:SetProperty("TaoistUnit", nil)

	local pUnit = UnitManager.GetUnit(numericPlayerID, unitID)
	if pUnit ~= nil and pUnit:GetActionCharges() == 0 and
			(not pPlayer:IsHuman() or ifDisposable) then
		UnitManager.Kill(pUnit)
	end
end
GameEvents.RecoverTaoistTreasury.Add(RecoverTaoistTreasury);

function TaoistGetNewCharge (PlayerID, UnitID)
	local pUnit = UnitManager.GetUnit(PlayerID, UnitID)
	if pUnit ~= nil and pUnit:GetType() == UnitTaoist and ifPromotionSupplement then --and pUnit:GetProperty('TaoistCharge') == nil
		local pUnitExp : table = pUnit:GetExperience()
		local chargeChange = 0
		for	PromotionType, ChargeChange in pairs(TaoistPromotionTable) do
			--print("TaoistMaxCharges",PromotionType, ChargeChange)
			local promotionInfo = GameInfo.UnitPromotions[PromotionType]
			if promotionInfo ~= nil and pUnitExp:HasPromotion(promotionInfo.Index) and
					pUnit:GetProperty(PromotionType) == nil then
				chargeChange = chargeChange + ChargeChange
				pUnit:SetProperty(PromotionType, 1)
			end
		end
		if chargeChange > 0 then
			pUnit:ChangeActionCharges(chargeChange)
		end
	end
end

Events.UnitPromoted.Add(TaoistGetNewCharge)

Initilize();
