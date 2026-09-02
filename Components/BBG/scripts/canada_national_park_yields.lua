local NATIONAL_PARK_PROPERTY = "ZYL_CANADA_NATIONAL_PARK"
local naturalistInfo = GameInfo.Units["UNIT_NATURALIST"]
local mountieInfo = GameInfo.Units["UNIT_CANADA_MOUNTIE"]
local NATURALIST_INDEX = naturalistInfo ~= nil and naturalistInfo.Index or -1
local MOUNTIE_INDEX = mountieInfo ~= nil and mountieInfo.Index or -1

local function IsCanadianPlayer(playerID)
	if playerID == nil or PlayerConfigurations == nil then
		return false
	end
	local playerConfig = PlayerConfigurations[playerID]
	return playerConfig ~= nil and playerConfig:GetCivilizationTypeName() == "CIVILIZATION_CANADA"
end

local function IsCanadaInGame()
	if PlayerManager == nil then
		return false
	end
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
		if IsCanadianPlayer(playerID) then
			return true
		end
	end
	return false
end

local function RefreshNationalParkPlots()
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex)
		if plot ~= nil then
			if plot:IsNationalPark() then
				if plot:GetProperty(NATIONAL_PARK_PROPERTY) ~= 1 then
					plot:SetProperty(NATIONAL_PARK_PROPERTY, 1)
				end
			elseif plot:GetProperty(NATIONAL_PARK_PROPERTY) ~= nil then
				plot:SetProperty(NATIONAL_PARK_PROPERTY, nil)
			end
		end
	end
end

local function OnUnitChargesChanged(playerID, unitID)
	if not IsCanadianPlayer(playerID) then
		return
	end
	local unit = UnitManager.GetUnit(playerID, unitID)
	if unit ~= nil and (unit:GetType() == NATURALIST_INDEX or unit:GetType() == MOUNTIE_INDEX) then
		RefreshNationalParkPlots()
	end
end

if Events ~= nil and IsCanadaInGame() then
	RefreshNationalParkPlots()

	if Events.NationalParkAdded ~= nil then
		Events.NationalParkAdded.Add(RefreshNationalParkPlots)
	end
	if Events.NationalParkRemoved ~= nil then
		Events.NationalParkRemoved.Add(RefreshNationalParkPlots)
	end
	-- Gameplay event availability varies between contexts; a Canadian unit spending
	-- a charge provides a narrow fallback for Naturalists and Mounties creating parks.
	if Events.UnitChargesChanged ~= nil then
		Events.UnitChargesChanged.Add(OnUnitChargesChanged)
	end
end
