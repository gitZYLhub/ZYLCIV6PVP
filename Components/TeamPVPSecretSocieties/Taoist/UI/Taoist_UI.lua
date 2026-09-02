-- Taoist_UI
-- Author: pen
-- DateCreated: 2023/6/8 11:18:20
--------------------------------------------------------------
local ifRigidTerrain = GameConfiguration.GetValue("Taoist_RigidTerrain") == nil and true or GameConfiguration.GetValue("Taoist_RigidTerrain")
local ifSeaLeyline = GameConfiguration.GetValue("Taoist_SeaLeyline") == nil and true or GameConfiguration.GetValue("Taoist_SeaLeyline")
local ifNoDistrict = GameConfiguration.GetValue("Taoist_NoDistrict") == nil and true or GameConfiguration.GetValue("Taoist_NoDistrict")
local ifNoImprovement = GameConfiguration.GetValue("Taoist_NoImprovement") == nil and true or GameConfiguration.GetValue("Taoist_NoImprovement")
local ifDisposable = GameConfiguration.GetValue("Taoist_Disposable") == nil and true or GameConfiguration.GetValue("Taoist_Disposable")
local ifOutBorder = GameConfiguration.GetValue("Taoist_OutBorder") == nil and false or GameConfiguration.GetValue("Taoist_OutBorder")

local MaxRecordActions = GameConfiguration.GetValue("Taoist_MaxRecordActions") or 1
--------------------------------------------------------------
local TaoistPromotionTable = {
	PROMOTION_TAOIST_GRAVE_ROBBER = 2,
	PROMOTION_TAOIST_SHRINK_LAND = 1,--缩地成寸只+1
	PROMOTION_TAOIST_CONCEALMENT = 2,
	PROMOTION_TAOIST_SUMMON_WIND_RAIN = 2,
	PROMOTION_TAOIST_TAOISM_MAGIC = 3,
}

function OnTaoistButtonClicked()
	local pUnit = UI.GetHeadSelectedUnit();
	if pUnit ~= nil then
		local iPlayer = pUnit:GetOwner()
		local iX = pUnit:GetX();
		local iY = pUnit:GetY();
		local unitID = pUnit:GetID();
		local pPlot = Map.GetPlot(iX, iY);
		local pCity = Cities.GetPlotPurchaseCity(pPlot);
		local TaoistCharge = pUnit:GetActionCharges()
		--print("TaoistHasUse",pUnit:GetProperty("TaoistHasUse"))
		if	IsPlotLeyLine(pPlot) then--有地脉直接收
			local pUnitType = GameInfo.Units[pUnit:GetUnitType()].UnitType
			local TaoistBaseCharge = GameInfo.Units_MODE[pUnitType].ActionCharges
			--print("Taoist has charge:",TaoistCharge)
			--print("Taoist attach max charge:",TaoistCharge,TaoistMaxCharges(iPlayer,unitID,TaoistBaseCharge))
			if TaoistCharge < TaoistMaxCharges(iPlayer,unitID,TaoistBaseCharge) then
				local tParameters = {};
				tParameters.X, tParameters.Y = pUnit:GetX(), pUnit:GetY()
				tParameters.UnitID = unitID
				tParameters.OnStart = 'TaoistRemoveLeyLine'
				SimUnitSystem.SetAnimationState(pUnit,"SPAWN")
				UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters)
			else
				local tParameters = {};
				tParameters.X, tParameters.Y = pUnit:GetX(), pUnit:GetY()
				tParameters.UnitID = unitID
				tParameters.OnStart = 'TaoistRemoveLeyLineToMax'
				UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters)
			end
		else
			local disabled, reason = IsButtonTurnDisabled(pPlot)
			--print(disabled, reason)
			if	not disabled and TaoistCharge > 0 then
				local tParameters = {};
				tParameters.X, tParameters.Y = pUnit:GetX(), pUnit:GetY()
				tParameters.UnitID = unitID
				tParameters.OnStart = 'TaoistAddLeyLine'
				UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters)
				SimUnitSystem.SetAnimationState(pUnit,"DEATH_3")
			else
				local tParameters = {};
				tParameters.X, tParameters.Y = pUnit:GetX(), pUnit:GetY()
				tParameters.UnitID = unitID
				tParameters.OnStart = 'TaoistNotAddLeyLine'
				UI.RequestPlayerOperation(iPlayer, PlayerOperations.EXECUTE_SCRIPT, tParameters)
			end
		end
		Controls.TaoistGrid:SetHide(true)
	end
end

function TaoistMaxCharges(PlayerID,UnitID,pTaoistBaseCharge)
	local pUnit = UnitManager.GetUnit(PlayerID, UnitID)
	if pUnit ~= nil then
		local TaoistMaxCharge = 3
		local TaoistHasUse = pUnit:GetProperty("TaoistHasUse") or 0
		if	TaoistHasUse then
			local pUnitExp : table = pUnit:GetExperience()
			if	ifDisposable then
				TaoistMaxCharge = 1
			else
				for	PromotionType, ChargeChange in pairs(TaoistPromotionTable) do
					--print("TaoistMaxCharges",PromotionType, ChargeChange)
					if GameInfo.UnitPromotions[PromotionType] and pUnitExp:HasPromotion(GameInfo.UnitPromotions[PromotionType].Index) then
						TaoistMaxCharge = TaoistMaxCharge + ChargeChange
					end
				end
			end
			if	ifFixCharge then
				TaoistMaxCharge = TaoistMaxCharge - TaoistHasUse
			end
		end
		return TaoistMaxCharge
	end
end

function IsPlotOutBorder(pPlot)
	--print("IsPlotNoDistrict",pPlot:GetDistrictType())
	local pUnit = UI.GetHeadSelectedUnit()
	if	pPlot:GetOwner() == -1 or pUnit:GetOwner() == pPlot:GetOwner() then
		return true;
	end
	return false;
end

function IsPlotNoDistrict(pPlot)
	--print("IsPlotNoDistrict",pPlot:GetDistrictType())
	if pPlot:GetDistrictType() == -1 then
		return true;
	end
	return false;
end

function IsPlotNoImprovement(pPlot)
	--print("IsPlotNoImprovement",pPlot:GetDistrictType())
	if pPlot:GetImprovementType() == -1 then
		return true;
	end
	return false;
end

function IsPlotNoResource(pPlot)
	--print(pPlot:GetResourceType())
	if pPlot:GetResourceType() == -1 then
		return true;
	end
	return false;
end

local LeyLineResource = GameInfo.Resources['RESOURCE_LEY_LINE'].Index
function IsPlotLeyLine(pPlot)
	--print(LeyLineResource)
	if pPlot:GetResourceType() == LeyLineResource then
		return true;
	end
	return false;
end

function IsPlotTerrainValid(pPlot)
	--ANY条件（参考象牙）
	--先地貌
	local able = false
	local tResults: table = DB.Query("SELECT * FROM Resource_ValidFeatures WHERE ResourceType = ?", "RESOURCE_LEY_LINE")
	if tResults and #tResults > 0 then
		for	_,row in ipairs(tResults) do
			if	GameInfo.Features[pPlot:GetFeatureType()].FeatureType == row.FeatureType then
				able = true
				break;
			end
		end
	end
	if	pPlot:GetFeatureType() > -1 then 
		return able
	else
		--able = true
	end
	--再地形
	local tResults: table = DB.Query("SELECT * FROM Resource_ValidTerrains WHERE ResourceType = ?", "RESOURCE_LEY_LINE")
	if tResults and #tResults > 0 then
		for	_,row in ipairs(tResults) do
			if	GameInfo.Terrains[pPlot:GetTerrainType()].TerrainType  == row.TerrainType then
				--print("IsPlotTerrainValid",pPlot:GetTerrainType(),row.TerrainType)
				able = true
				break;
			end
		end
	end
	if	pPlot:GetTerrainType() > -1 then 
		return able
	end
	return able--理论上走不到这里
end

function IsButtonTurnDisabled(pPlot)
	if pPlot == nil then
		return true, ''
	end
	if IsPlotLeyLine(pPlot) then--收取逻辑
		if	not ifOutBorder then 
			--print(ifOutBorder,IsPlotOutBorder(pPlot))
			if	IsPlotOutBorder(pPlot) then
				--return false, ''
			else
				return true, '[NEWLINE][COLOR:Red]'..Locale.Lookup('LOC_ABILITY_TAOIST_NOT_ADD_LEYLINE')..'[ENDCOLOR]'
			end
		end
		return false, ''
	else--放置逻辑
		local Disabled = nil 
		local tooltip = ""
		if	IsPlotNoResource(pPlot) then
			--return false, ''
		else
			Disabled = true
			tooltip = '[NEWLINE][COLOR:Red]'..Locale.Lookup('LOC_ABILITY_TAOIST_NOT_ADD_LEYLINE')..'[ENDCOLOR]'
		end
		if	pPlot:IsWater() then
			if	ifSeaLeyline then
				Disabled = false
			else
				Disabled = true
				tooltip = '[NEWLINE][COLOR:Red]'..Locale.Lookup('LOC_ABILITY_TAOIST_NOT_ADD_LEYLINE')..'[ENDCOLOR]'
			end
		end
		--print("ifNoDistrict",ifNoDistrict)
		if	ifNoDistrict then
			if	IsPlotNoDistrict(pPlot) then
				--return false, ''
			else
				Disabled = true
				tooltip = '[NEWLINE][COLOR:Red]'..Locale.Lookup('LOC_TAOIST_NO_DISTRICT_TOOLTIP')..'[ENDCOLOR]'
			end
		end
		--print("ifNoImprovement",ifNoImprovement)
		if	ifNoImprovement then
			if	IsPlotNoImprovement(pPlot) then
				--return false, ''
			else
				Disabled = true
				tooltip = '[NEWLINE][COLOR:Red]'..Locale.Lookup('LOC_TAOIST_NO_IMPROVEMENT_TOOLTIP')..'[ENDCOLOR]'
			end
		end
		--print("ifRigidTerrain",ifRigidTerrain)
		if	ifRigidTerrain then
			if	IsPlotTerrainValid(pPlot) then
				--return false, ''
			else
				Disabled = true
				tooltip = '[NEWLINE][COLOR:Red]'..Locale.Lookup('LOC_ABILITY_TAOIST_NOT_ADD_LEYLINE')..'[ENDCOLOR]'
			end
		end
		return Disabled, tooltip
	end
end

function OnUnitChargesChanged(playerID, unitID, newCharges, oldCharges)
	local pPlayer = Players[playerID]
	--local pUnit = UnitManager.GetUnit(playerID, unitID)
	--print('FireflyUnitChargesChanged',playerID, unitID,pUnit)
	--if pUnit ~= nil then
		--local sUnit = GameInfo.Units[pUnit:GetType()]
		--if	sUnit.UnitType ~= "UNIT_TAOIST" then
		--	return
		--end
	if	pPlayer:GetProperty("TaoistPlot") ~= nil then
		local pPlot = Map.GetPlotByIndex(pPlayer:GetProperty("TaoistPlot"))
		if pPlot ~= nil and pPlot:GetOwner() < 0 then
			if	newCharges <= oldCharges then
				--print(pPlayer:GetProperty("TaoistCity"))
				if	pPlayer:GetProperty("TaoistCity") ~= nil then
					local pCity = Cities.GetCityInPlot(pPlayer:GetProperty("TaoistCity"))
					--print(pCity)
					if	pCity then
						--买地刷新(由于Request会依次执行，所以购买时一定是无主且有钱的状态)
						print(pCity:GetGold():GetPlotPurchaseCost(pPlot:GetIndex()))
						local tParameters = {};
						tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
						tParameters[CityCommandTypes.PARAM_X] = pPlot:GetX();
						tParameters[CityCommandTypes.PARAM_Y] = pPlot:GetY();
						--print(CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, tParameters))
						CityManager.RequestCommand( pCity, CityCommandTypes.PURCHASE, tParameters);	
						
						--把钱调回去
						UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, { OnStart = 'RecoverTaoistTreasury', UnitID = unitID, PurchaseCost = pCity:GetGold():GetPlotPurchaseCost(pPlot:GetIndex())})
					end
				end
			end
		end
	end
end

function OnUnitDamageChanged(playerID, unitID, newDamage, prevDamage)
	--print("OnUnitCaptured",playerID, unitID, newDamage, prevDamage)
	local pUnit = UnitManager.GetUnit(playerID, unitID)
	--print(pUnit)--已经抓不到哩
	if	pUnit then
		local sUnit = GameInfo.Units[pUnit:GetType()]
		if sUnit.UnitType ~= "UNIT_TAOIST" and newDamage == 100 then
			--print(pUnit:GetProperty("TaoistHasUse"),pUnit:GetActionCharges())
		end
	end
end

function Refresh()
	local pUnit = UI.GetHeadSelectedUnit()
	if pUnit ~= nil then
        local sUnit = GameInfo.Units[pUnit:GetType()]
		local pPlot = Map.GetPlot(pUnit:GetX(), pUnit:GetY())
		if sUnit.UnitType ~= "UNIT_TAOIST" or pUnit:GetMovementMovesRemaining() == 0 then
			Controls.TaoistGrid:SetHide(true)
		else 
			Controls.TaoistGrid:SetHide(false)
			local tooltip = Locale.Lookup('LOC_ABILITY_TAOIST_ADD_LEYLINE')

			local PlayerID = pUnit:GetOwner()
			local UnitID = pUnit:GetID()
			local TaoistBaseCharge = GameInfo.Units_MODE[sUnit.UnitType].ActionCharges
			local TaoistCharge = pUnit:GetActionCharges()
			local TaoistMaxCharge = TaoistMaxCharges(PlayerID, UnitID,TaoistBaseCharge)
			tooltip = tooltip .. '[NEWLINE]' .. Locale.Lookup('LOC_TAOIST_MAX_LEYLINE',TaoistCharge,TaoistMaxCharge)
			
			--local disabled, reason = IsButtonTurnDisabled(pPlot)
			
			if	ifOutBorder or IsPlotOutBorder(pPlot) then--由于先前代码，会对无奢侈资源格输出nil，所以不能直接not disabled
				Controls.TaoistButton:SetToolTipString(tooltip)
				Controls.TaoistButton:SetDisabled(false)
			else
				tooltip = tooltip .. '[NEWLINE]' .. Locale.Lookup('LOC_TAOIST_NO_BORDER_TOOLTIP')
				Controls.TaoistButton:SetToolTipString(tooltip)
				Controls.TaoistButton:SetDisabled(true)
			end
		end
	end
end
--Move
function OnUnitMoveComplete(PlayerID, unitID, iX, iY)
	if PlayerID ~= Game.GetLocalPlayer() then return; end
	--print("OnUnitMoveComplete")
	Refresh()
end
--Select
function OnUnitSelectionChanged(PlayerID, UnitID, plotX, plotY, plotZ, bSelected, bEditable)
	if PlayerID ~= Game.GetLocalPlayer() then return; end
    if bSelected then
        Refresh()
    end
end

function Initialize()
	local pContext = ContextPtr:LookUpControl("/InGame/UnitPanel/StandardActionsStack")
	if pContext ~= nil then
		Controls.TaoistGrid:ChangeParent(pContext);
		Controls.TaoistButton:RegisterCallback(Mouse.eLClick, OnTaoistButtonClicked);
	end
	if	GameConfiguration.GetValue("Taoist_Settings") == "SETTINGS_TAOIST_NORMAL" then
		--print(GameConfiguration.GetValue("Taoist_Settings"))
		ifRigidTerrain = true
		ifNoDistrict = true
		ifNoImprovement = true
		ifDisposable = true
	end
	--print("Taoist pvp Load")
	Events.UnitChargesChanged.Add(OnUnitChargesChanged)
	--Events.UnitDamageChanged.Add(OnUnitDamageChanged)
	
	Events.UnitMoveComplete.Add(OnUnitMoveComplete)
	Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
end

Events.LoadGameViewStateDone.Add(Initialize);
