-- Taoist_UI
-- Author: pen
-- DateCreated: 2023/6/8 11:18:20
--------------------------------------------------------------
local function GetTaoistConfigurationValue(optionId, defaultValue)
	local value = GameConfiguration.GetValue(optionId)
	if value == nil then
		return defaultValue
	end
	return value
end

local ifRigidTerrain = GetTaoistConfigurationValue("Taoist_RigidTerrain", true)
local ifSeaLeyline = GetTaoistConfigurationValue("Taoist_SeaLeyline", true)
local ifNoDistrict = GetTaoistConfigurationValue("Taoist_NoDistrict", true)
local ifNoImprovement = GetTaoistConfigurationValue("Taoist_NoImprovement", true)
local ifDisposable = GetTaoistConfigurationValue("Taoist_Disposable", true)
local ifOutBorder = GetTaoistConfigurationValue("Taoist_OutBorder", false)
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
		local TaoistCharge = pUnit:GetActionCharges()
		--print("TaoistHasUse",pUnit:GetProperty("TaoistHasUse"))
		if	IsPlotLeyLine(pPlot) then--有地脉直接收
			--print("Taoist has charge:",TaoistCharge)
			--print("Taoist attach max charge:",TaoistCharge,TaoistMaxCharges(iPlayer,unitID))
			if TaoistCharge < TaoistMaxCharges(iPlayer,unitID) then
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
			local disabled = IsButtonTurnDisabled(pPlot)
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

function TaoistMaxCharges(PlayerID,UnitID)
	local pUnit = UnitManager.GetUnit(PlayerID, UnitID)
	if pUnit ~= nil then
		local TaoistMaxCharge = 3
		if	ifDisposable then
			TaoistMaxCharge = 1
		else
			local pUnitExp : table = pUnit:GetExperience()
			for	PromotionType, ChargeChange in pairs(TaoistPromotionTable) do
				--print("TaoistMaxCharges",PromotionType, ChargeChange)
				if GameInfo.UnitPromotions[PromotionType] and pUnitExp:HasPromotion(GameInfo.UnitPromotions[PromotionType].Index) then
					TaoistMaxCharge = TaoistMaxCharge + ChargeChange
				end
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

local leyLineResourceInfo = GameInfo.Resources['RESOURCE_LEY_LINE']
local LeyLineResource = leyLineResourceInfo and leyLineResourceInfo.Index or -1
function IsPlotLeyLine(pPlot)
	--print(LeyLineResource)
	if LeyLineResource >= 0 and pPlot:GetResourceType() == LeyLineResource then
		return true;
	end
	return false;
end

function IsPlotTerrainValid(pPlot)
	--ANY条件（参考象牙）
	--先地貌
	local able = false
	local featureType = pPlot:GetFeatureType()
	if featureType > -1 then
		local featureInfo = GameInfo.Features[featureType]
		if featureInfo == nil then
			return false
		end
		local tResults: table = DB.Query("SELECT * FROM Resource_ValidFeatures WHERE ResourceType = ?", "RESOURCE_LEY_LINE")
		if tResults and #tResults > 0 then
			for	_,row in ipairs(tResults) do
				if	featureInfo.FeatureType == row.FeatureType then
					able = true
					break;
				end
			end
		end
		return able
	end
	--再地形
	local terrainType = pPlot:GetTerrainType()
	local terrainInfo = GameInfo.Terrains[terrainType]
	if terrainInfo == nil then
		return false
	end
	local tResults: table = DB.Query("SELECT * FROM Resource_ValidTerrains WHERE ResourceType = ?", "RESOURCE_LEY_LINE")
	if tResults and #tResults > 0 then
		for	_,row in ipairs(tResults) do
			if	terrainInfo.TerrainType == row.TerrainType then
				--print("IsPlotTerrainValid",pPlot:GetTerrainType(),row.TerrainType)
				able = true
				break;
			end
		end
	end
	return able
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
	if playerID ~= Game.GetLocalPlayer() then
		return
	end
	local pPlayer = Players[playerID]
	if pPlayer == nil or newCharges > oldCharges then
		return
	end
	local taoistPlot = tonumber(pPlayer:GetProperty("TaoistPlot"))
	local taoistCity = tonumber(pPlayer:GetProperty("TaoistCity"))
	local taoistUnit = tonumber(pPlayer:GetProperty("TaoistUnit"))
	if taoistPlot == nil or taoistCity == nil or taoistUnit ~= tonumber(unitID) then
		return
	end
	local pPlot = Map.GetPlotByIndex(taoistPlot)
	local pCity = Cities.GetCityInPlot(taoistCity)
	if pPlot == nil or pPlot:GetOwner() >= 0 or pCity == nil then
		return
	end
	--买地刷新(由于Request会依次执行，所以购买时一定是无主且有钱的状态)
	local tParameters = {};
	tParameters[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE);
	tParameters[CityCommandTypes.PARAM_X] = pPlot:GetX();
	tParameters[CityCommandTypes.PARAM_Y] = pPlot:GetY();
	CityManager.RequestCommand(pCity, CityCommandTypes.PURCHASE, tParameters);

	--把钱调回去
	UI.RequestPlayerOperation(playerID, PlayerOperations.EXECUTE_SCRIPT, {
		OnStart = 'RecoverTaoistTreasury',
		UnitID = unitID,
		PurchaseCost = pCity:GetGold():GetPlotPurchaseCost(pPlot:GetIndex())
	})
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
			local TaoistCharge = pUnit:GetActionCharges()
			local TaoistMaxCharge = TaoistMaxCharges(PlayerID, UnitID)
			tooltip = tooltip .. '[NEWLINE]' .. Locale.Lookup('LOC_TAOIST_MAX_LEYLINE',TaoistCharge,TaoistMaxCharge)
			
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

local isInitialized = false

function Initialize()
	if isInitialized then
		return
	end
	isInitialized = true
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
	
	Events.UnitMoveComplete.Add(OnUnitMoveComplete)
	Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
end

function OnShutdown()
	Events.LoadGameViewStateDone.Remove(Initialize)
	if isInitialized then
		Events.UnitChargesChanged.Remove(OnUnitChargesChanged)
		Events.UnitMoveComplete.Remove(OnUnitMoveComplete)
		Events.UnitSelectionChanged.Remove(OnUnitSelectionChanged)
	end
end

ContextPtr:SetShutdown(OnShutdown)
Events.LoadGameViewStateDone.Add(Initialize);
