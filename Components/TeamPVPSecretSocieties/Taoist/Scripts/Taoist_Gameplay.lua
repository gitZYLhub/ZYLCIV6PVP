-- Taoist_Gameplay
-- Author: pen
-- DateCreated: 2023/6/8 13:08:28
--------------------------------------------------------------
ExposedMembers.GameEvents = GameEvents
--------------------------------------------------------------
local ifPromotionSupplement = GameConfiguration.GetValue("Taoist_PromotionSupplement") == nil and false or GameConfiguration.GetValue("Taoist_PromotionSupplement")
local ifDisposable = GameConfiguration.GetValue("Taoist_Disposable") == nil and true or GameConfiguration.GetValue("Taoist_Disposable")
local MaxRecordActions = GameConfiguration.GetValue("Taoist_MaxRecordActions") or 1
--------------------------------------------------------------
local TaoistCreateLeyLineCharge = 1
local UnitTaoist = GameInfo.Units['UNIT_TAOIST'].Index
local TaoistPromotionTable = {
	PROMOTION_TAOIST_GRAVE_ROBBER = 2,
	PROMOTION_TAOIST_SHRINK_LAND = 1,--缩地成寸只+1
	PROMOTION_TAOIST_CONCEALMENT = 2,
	PROMOTION_TAOIST_SUMMON_WIND_RAIN = 2,
	PROMOTION_TAOIST_TAOISM_MAGIC = 3,
}

function Initilize ()
	if	GameConfiguration.GetValue("Taoist_Settings") == "SETTINGS_TAOIST_NORMAL" then
		ifPromotionSupplement = false--晋升树优先ban了，所以不需要额外处理
		ifDisposable = true
		--print("ifPromotionSupplement",ifPromotionSupplement)
	end
	--print("Taoist pvp Load")
end

function TaoistAddLeyLine(playerID, params)
	local pPlayer = Players[playerID]
	local iX, iY = params.X, params.Y
	local pPlot = Map.GetPlot(iX, iY)
	local leyLineTable = GameInfo.Resources['RESOURCE_LEY_LINE'].Index
	if leyLineTable ~= nil then
		ResourceBuilder.SetResourceType(pPlot, leyLineTable, 1)
		
		local messageData = {
			MessageType = 0;
			MessageText = Locale.Lookup('LOC_TAOIST_ADD_LEYLINE_TOOLTIP');
			PlotX = iX;
			PlotY = iY;
			Visibility = RevealedState.VISIBLE;
		}
		Game.AddWorldViewText(messageData);
		--买地刷新
		local pUnit = UnitManager.GetUnit(playerID, params.UnitID);
		if pPlot ~= nil and pPlot:GetOwner() >= 0 then
			local iTreasury = Players[playerID]:GetTreasury():GetGoldBalance();
			local pCity = Cities.GetPlotPurchaseCity(pPlot)
			if	pCity then
				local CityPlotIndex = Map.GetPlotIndex(pCity:GetX(), pCity:GetY())
				pPlayer:SetProperty("TaoistPlot",pPlot:GetIndex())
				pPlayer:SetProperty("TaoistGold",iTreasury)
				pPlayer:SetProperty("TaoistCity",CityPlotIndex)--放unit上可能代码执行不及时会丢包
				pPlayer:GetTreasury():ChangeGoldBalance( 375 )
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
			if pUnit and pUnit:GetActionCharges() == 0 and (not pPlayer:IsHuman() or ifDisposable) then
				UnitManager.Kill(pUnit)
			end
		end
	end
end
GameEvents.TaoistAddLeyLine.Add(TaoistAddLeyLine);

function TaoistNotAddLeyLine(playerID, params)
	local iX, iY = params.X, params.Y
	local pPlot = Map.GetPlot(iX, iY)
	local pUnit = UnitManager.GetUnit(playerID, params.UnitID);
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
	local iX, iY = params.X, params.Y
	local pPlot = Map.GetPlot(iX, iY)
	local leyLineTable = GameInfo.Resources['RESOURCE_LEY_LINE'].Index
	if leyLineTable ~= nil and pPlot:GetResourceType() == leyLineTable then
		ResourceBuilder.SetResourceType(pPlot, -1)
		
		local messageData = {
			MessageType = 0;
			MessageText = Locale.Lookup('LOC_ABILITY_TAOIST_REMOVE_LEYLINE');
			PlotX = iX;
			PlotY = iY;
			Visibility = RevealedState.VISIBLE;
		}
		Game.AddWorldViewText(messageData);

		local pUnit = UnitManager.GetUnit(playerID, params.UnitID);
		pUnit:ChangeActionCharges(TaoistCreateLeyLineCharge)
		UnitManager.FinishMoves(pUnit)
	end
end
GameEvents.TaoistRemoveLeyLine.Add(TaoistRemoveLeyLine);

function TaoistRemoveLeyLineToMax(playerID, params)
	local iX, iY = params.X, params.Y
	local pPlot = Map.GetPlot(iX, iY)
	local leyLineTable = GameInfo.Resources['RESOURCE_LEY_LINE'].Index
	if leyLineTable ~= nil and pPlot:GetResourceType() == leyLineTable then
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
	local pPlayer = Players[playerID]
	local UnitID = params.UnitID
	local PurchaseCost = params.PurchaseCost
	local pUnit = UnitManager.GetUnit(playerID, UnitID)
	if	pPlayer and pPlayer:GetProperty("TaoistGold") ~= nil then
		local iTreasury = pPlayer:GetTreasury():GetGoldBalance();
		local Treasury = pPlayer:GetProperty("TaoistGold")--params.Treasury
		--print("RecoverTaoistTreasury",iTreasury,Treasury)
		if	iTreasury and Treasury then
			pPlayer:GetTreasury():SetGoldBalance(math.min(Treasury, (iTreasury - 375 + PurchaseCost)))
			pPlayer:SetProperty("TaoistPlot",nil)
			pPlayer:SetProperty("TaoistGold",nil)
			pPlayer:SetProperty("TaoistCity",nil)
		end
	end
	if pUnit and pUnit:GetActionCharges() == 0 and (not pPlayer:IsHuman() or ifDisposable) then
		UnitManager.Kill(pUnit)
	end
end
GameEvents.RecoverTaoistTreasury.Add(RecoverTaoistTreasury);

function TaoistGetNewCharge (PlayerID, UnitID)
	local pUnit = UnitManager.GetUnit(PlayerID, UnitID)
	if pUnit ~= nil and pUnit:GetType() == UnitTaoist and ifPromotionSupplement then --and pUnit:GetProperty('TaoistCharge') == nil
		local pUnitExp : table = pUnit:GetExperience()
		print('TaoistGetNewCharge',pUnitExp:GetExperienceForNextLevel())
		TaoistCharge = 0
		for	PromotionType, ChargeChange in pairs(TaoistPromotionTable) do
			--print("TaoistMaxCharges",PromotionType, ChargeChange)
			if GameInfo.UnitPromotions[PromotionType] and pUnitExp:HasPromotion(GameInfo.UnitPromotions[PromotionType].Index) then
				pUnit:ChangeActionCharges(ChargeChange)
				TaoistCharge = TaoistCharge + ChargeChange
				pUnit:SetProperty(PromotionType,1)
			end
		end
		--print("Taoist Get Charge:",pUnit,TaoistCharge)
	end
end

Events.UnitPromoted.Add(TaoistGetNewCharge)

function AiTaoistAddLeyLineToMax(playerID:number, unitID:number)
	--print('AiTaoistAddLeyLineToMax',playerID,unitID)
	local pPlayer = Players[playerID]
	if pPlayer == nil then 
		return;
	end
	if pPlayer:IsHuman() or not pPlayer:IsAlive() or not pPlayer:IsMajor() then
		return;	-- Not For Human Player.
	end
	local playerUnits = pPlayer:GetUnits();
	for i, pUnit in playerUnits:Members() do
		local unitInfo = GameInfo.Units[pUnit:GetType()];
		if unitInfo then
			local unitTypeName = unitInfo.UnitType;
			if unitTypeName == "UNIT_TAOIST" then
				print("Ai Taoist try to add leyline!")
				local iX = pUnit:GetX();
				local iY = pUnit:GetY();
				local pPlot = Map.GetPlot(iX, iY);
				local leyLineTable = GameInfo.Resources['RESOURCE_LEY_LINE'].Index
				if leyLineTable ~= nil and not pPlot:IsWater() and pPlot:GetOwner() == -1 then
					if pUnit:GetActionCharges() == 0 then
						pUnit:ChangeActionCharges(TaoistCreateLeyLineCharge)--ai赠送地脉
					end
					if pUnit:GetActionCharges() > 0 and pPlot:GetResourceType() == -1 and GameInfo.Districts[pPlot:GetDistrictType()].HitPoints > 0 then--排除市中心等防御区域
						local tParameters = {};
						tParameters.X, tParameters.Y = iX, iY
						tParameters.UnitID = pUnit:GetID()
						TaoistAddLeyLine(playerID, tParameters)
						print("This plot is able to add leyline:",iX, iY)
					end
				end
			end
		end
	end
	
end

--GameEvents.PlayerTurnStarted.Add(AiTaoistAddLeyLineToMax);

Initilize();