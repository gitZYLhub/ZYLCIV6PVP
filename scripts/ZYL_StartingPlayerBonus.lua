-- Grants an optional one-time starting-unit bonus to a human participant by
-- lobby order. Empty, AI and observer rows are skipped.

local PLAYER_OPTION = "ZYL_STARTING_BONUS_PLAYER";
local BONUS_OPTION = "ZYL_STARTING_BONUS_TYPE";
local APPLIED_PROPERTY = "ZYL_STARTING_BONUS_APPLIED";

local BONUS_BUILDER = 1;
local BONUS_SCOUT = 2;
local BONUS_BUILDER_AND_SCOUT = 3;

local function IsValidSpawnPlot(plot, playerID)
	if plot == nil or plot:IsWater() or plot:IsImpassable() or plot:GetUnitCount() > 0 then
		return false;
	end

	local ownerID = plot:GetOwner();
	return ownerID == -1 or ownerID == playerID;
end

local function FindNearestSpawnPlots(startPlot, playerID, count)
	local candidates = {};
	local startX = startPlot:GetX();
	local startY = startPlot:GetY();

	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		if IsValidSpawnPlot(plot, playerID) then
			table.insert(candidates, {
				Plot = plot,
				Distance = Map.GetPlotDistance(startX, startY, plot:GetX(), plot:GetY()),
				Index = plotIndex
			});
		end
	end

	table.sort(candidates, function(a, b)
		if a.Distance == b.Distance then
			return a.Index < b.Index;
		end
		return a.Distance < b.Distance;
	end);

	local result = {};
	for i = 1, math.min(count, #candidates) do
		table.insert(result, candidates[i].Plot);
	end
	return result;
end

local function TryGrantStartingBonus()
	local selectedPlayerNumber = tonumber(GameConfiguration.GetValue(PLAYER_OPTION)) or 0;
	local selectedBonus = tonumber(GameConfiguration.GetValue(BONUS_OPTION)) or 0;
	if selectedPlayerNumber < 1 or selectedPlayerNumber > 12 or selectedBonus < BONUS_BUILDER or selectedBonus > BONUS_BUILDER_AND_SCOUT then
		return;
	end

	if Game.GetCurrentGameTurn() ~= GameConfiguration.GetStartTurn() then
		return;
	end

	local eligiblePlayerIDs = {};
	for _, candidatePlayerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local candidateConfig = PlayerConfigurations[candidatePlayerID];
		if candidateConfig ~= nil and candidateConfig:IsHuman()
				and candidateConfig:GetLeaderTypeName() ~= "LEADER_SPECTATOR" then
			table.insert(eligiblePlayerIDs, candidatePlayerID);
		end
	end
	table.sort(eligiblePlayerIDs);

	local playerID = eligiblePlayerIDs[selectedPlayerNumber];
	if playerID == nil then
		print("ZYL starting bonus: selected lobby player number does not exist", selectedPlayerNumber, #eligiblePlayerIDs);
		return;
	end

	local player = Players[playerID];
	local playerConfig = PlayerConfigurations[playerID];
	if player == nil or playerConfig == nil or not player:IsAlive() or not player:IsMajor() then
		print("ZYL starting bonus: selected lobby player is not a living major civilization", selectedPlayerNumber, playerID);
		return;
	end

	if player:GetProperty(APPLIED_PROPERTY) ~= nil then
		return;
	end

	local requestedUnits = {};
	if selectedBonus == BONUS_BUILDER or selectedBonus == BONUS_BUILDER_AND_SCOUT then
		table.insert(requestedUnits, "UNIT_BUILDER");
	end
	if selectedBonus == BONUS_SCOUT or selectedBonus == BONUS_BUILDER_AND_SCOUT then
		table.insert(requestedUnits, "UNIT_SCOUT");
	end

	local startPlot = player:GetStartingPlot();
	if startPlot == nil then
		print("ZYL starting bonus: selected player has no starting plot yet", selectedPlayerNumber, playerID);
		return;
	end

	local spawnPlots = FindNearestSpawnPlots(startPlot, playerID, #requestedUnits);
	if #spawnPlots < #requestedUnits then
		print("ZYL starting bonus: not enough valid land plots", selectedPlayerNumber, playerID, #spawnPlots, #requestedUnits);
		return;
	end

	-- Set the persisted marker before creating units so a save/reload or a
	-- repeated start-turn callback cannot duplicate a partially applied bonus.
	player:SetProperty(APPLIED_PROPERTY, selectedBonus);
	local playerUnits = player:GetUnits();
	for i, baseUnitType in ipairs(requestedUnits) do
		local unitType = GameInfo.Units[baseUnitType];
		local unitTypeIndex = unitType ~= nil and unitType.Index or nil;
		local spawnPlot = spawnPlots[i];
		if unitTypeIndex ~= nil then
			local createdUnit = playerUnits:Create(unitTypeIndex, spawnPlot:GetX(), spawnPlot:GetY());
			print("ZYL starting bonus: unit granted", selectedPlayerNumber, playerID, baseUnitType, unitTypeIndex,
				spawnPlot:GetX(), spawnPlot:GetY(), createdUnit ~= nil);
		else
			print("ZYL starting bonus: unit type is unavailable", selectedPlayerNumber, playerID, baseUnitType);
		end
	end
end

TryGrantStartingBonus();
GameEvents.OnGameTurnStarted.Add(TryGrantStartingBonus);
