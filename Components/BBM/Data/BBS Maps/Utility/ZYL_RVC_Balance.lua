------------------------------------------------------------------------------
--	FILE:	 BBS_Balance.lua 1.4.1
--	AUTHOR:  D. / Jack The Narrator
--	PURPOSE: Rebalance the map spawn post placement 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ExposedMembers.LuaEvents = LuaEvents

include "MapEnums"
include "SupportFunctions"

local bBiasFail = false;
local world_age = 2
--资源补贴计数
local stonesCounts = 0;
local addRiceCount = 0;
local addFoodSheepCount = 0;
local resourcesFishCount = 0;
local addJungleCount = 0;
local addForestCount = 0;
local addHuntCount = 0;
local addBananaCount = 0;
local RichNum;

local function ZYL_RVC_GetResourceIndex(resourceType)
    local resource = GameInfo.Resources[resourceType];
    return resource ~= nil and resource.Index or -1;
end

local RESOURCE_ALUMINUM_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_ALUMINUM");
local RESOURCE_COAL_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_COAL");
local RESOURCE_DEER_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_DEER");
local RESOURCE_FURS_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_FURS");
local RESOURCE_HORSES_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_HORSES");
local RESOURCE_IVORY_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_IVORY");
local RESOURCE_IRON_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_IRON");
local RESOURCE_NITER_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_NITER");
local RESOURCE_OIL_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_OIL");
local RESOURCE_TRUFFLES_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_TRUFFLES");
local RESOURCE_URANIUM_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_URANIUM");
local RESOURCE_FISH_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_FISH");
local RESOURCE_LEY_LINE_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_LEY_LINE");
local RESOURCE_SHEEP_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_SHEEP");
local RESOURCE_WHEAT_INDEX = ZYL_RVC_GetResourceIndex("RESOURCE_WHEAT");

local MALI_CIVILIZATION_TYPE = "CIVILIZATION_MALI";
local TERRAIN_GRASS_INDEX = GameInfo.Terrains["TERRAIN_GRASS"].Index;
local TERRAIN_GRASS_HILLS_INDEX = GameInfo.Terrains["TERRAIN_GRASS_HILLS"].Index;
local TERRAIN_GRASS_MOUNTAIN_INDEX = GameInfo.Terrains["TERRAIN_GRASS_MOUNTAIN"].Index;
local TERRAIN_PLAINS_INDEX = GameInfo.Terrains["TERRAIN_PLAINS"].Index;
local TERRAIN_PLAINS_HILLS_INDEX = GameInfo.Terrains["TERRAIN_PLAINS_HILLS"].Index;
local TERRAIN_PLAINS_MOUNTAIN_INDEX = GameInfo.Terrains["TERRAIN_PLAINS_MOUNTAIN"].Index;
local TERRAIN_DESERT_INDEX = GameInfo.Terrains["TERRAIN_DESERT"].Index;
local TERRAIN_DESERT_HILLS_INDEX = GameInfo.Terrains["TERRAIN_DESERT_HILLS"].Index;
local TERRAIN_DESERT_MOUNTAIN_INDEX = GameInfo.Terrains["TERRAIN_DESERT_MOUNTAIN"].Index;
local TERRAIN_TUNDRA_INDEX = GameInfo.Terrains["TERRAIN_TUNDRA"].Index;
local TERRAIN_TUNDRA_HILLS_INDEX = GameInfo.Terrains["TERRAIN_TUNDRA_HILLS"].Index;
local TERRAIN_TUNDRA_MOUNTAIN_INDEX = GameInfo.Terrains["TERRAIN_TUNDRA_MOUNTAIN"].Index;
local TERRAIN_SNOW_INDEX = GameInfo.Terrains["TERRAIN_SNOW"].Index;
local TERRAIN_SNOW_HILLS_INDEX = GameInfo.Terrains["TERRAIN_SNOW_HILLS"].Index;
local TERRAIN_SNOW_MOUNTAIN_INDEX = GameInfo.Terrains["TERRAIN_SNOW_MOUNTAIN"].Index;

local DESERT_TERRAIN_BY_SOURCE = {
    [TERRAIN_GRASS_INDEX] = TERRAIN_DESERT_INDEX,
    [TERRAIN_GRASS_HILLS_INDEX] = TERRAIN_DESERT_HILLS_INDEX,
    [TERRAIN_GRASS_MOUNTAIN_INDEX] = TERRAIN_DESERT_MOUNTAIN_INDEX,
    [TERRAIN_PLAINS_INDEX] = TERRAIN_DESERT_INDEX,
    [TERRAIN_PLAINS_HILLS_INDEX] = TERRAIN_DESERT_HILLS_INDEX,
    [TERRAIN_PLAINS_MOUNTAIN_INDEX] = TERRAIN_DESERT_MOUNTAIN_INDEX,
    [TERRAIN_DESERT_INDEX] = TERRAIN_DESERT_INDEX,
    [TERRAIN_DESERT_HILLS_INDEX] = TERRAIN_DESERT_HILLS_INDEX,
    [TERRAIN_DESERT_MOUNTAIN_INDEX] = TERRAIN_DESERT_MOUNTAIN_INDEX,
    [TERRAIN_TUNDRA_INDEX] = TERRAIN_DESERT_INDEX,
    [TERRAIN_TUNDRA_HILLS_INDEX] = TERRAIN_DESERT_HILLS_INDEX,
    [TERRAIN_TUNDRA_MOUNTAIN_INDEX] = TERRAIN_DESERT_MOUNTAIN_INDEX,
    [TERRAIN_SNOW_INDEX] = TERRAIN_DESERT_INDEX,
    [TERRAIN_SNOW_HILLS_INDEX] = TERRAIN_DESERT_HILLS_INDEX,
    [TERRAIN_SNOW_MOUNTAIN_INDEX] = TERRAIN_DESERT_MOUNTAIN_INDEX,
};

local MALI_DESERT_LUXURIES = {};
do
    local registeredLuxuries = {};
    for row in GameInfo.Resource_ValidTerrains() do
        if row.TerrainType == "TERRAIN_DESERT" or row.TerrainType == "TERRAIN_DESERT_HILLS" then
            local resource = GameInfo.Resources[row.ResourceType];
            if resource ~= nil
                and resource.ResourceClassType == "RESOURCECLASS_LUXURY"
                and not registeredLuxuries[resource.Index] then
                registeredLuxuries[resource.Index] = true;
                table.insert(MALI_DESERT_LUXURIES, resource.Index);
            end
        end
    end
end

local function ZYL_RVC_IsStrategicResource(resourceIndex)
    if resourceIndex == nil or resourceIndex < 0 then
        return false;
    end

    local resource = GameInfo.Resources[resourceIndex];
    return resource ~= nil and resource.ResourceClassType == "RESOURCECLASS_STRATEGIC";
end

local function ZYL_RVC_IsLeyLine(resourceIndex)
    return RESOURCE_LEY_LINE_INDEX >= 0 and resourceIndex == RESOURCE_LEY_LINE_INDEX;
end

local function ZYL_RVC_IsMinorMarkedFailing(playerId)
    local failureCount = Game:GetProperty("BBS_MINOR_FAILING_TOTAL") or 0;
    for failureIndex = 1, failureCount do
        if Game:GetProperty("BBS_MINOR_FAILING_ID_" .. failureIndex) == playerId then
            return true;
        end
    end
    return false;
end

local function ZYL_RVC_RecordMinorFailure(playerId)
    if ZYL_RVC_IsMinorMarkedFailing(playerId) then
        return false;
    end

    local failureCount = (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") or 0) + 1;
    Game:SetProperty("BBS_MINOR_FAILING_TOTAL", failureCount);
    Game:SetProperty("BBS_MINOR_FAILING_ID_" .. failureCount, playerId);
    return true;
end

local function ZYL_RVC_IsPreservedTundraResource(resourceIndex)
    return resourceIndex == RESOURCE_DEER_INDEX
        or resourceIndex == RESOURCE_FURS_INDEX
        or resourceIndex == RESOURCE_TRUFFLES_INDEX
        or resourceIndex == RESOURCE_IVORY_INDEX;
end

local function ZYL_RVC_TundraResourceRequiresForest(resourceIndex)
    return resourceIndex == RESOURCE_DEER_INDEX
        or resourceIndex == RESOURCE_TRUFFLES_INDEX
        or resourceIndex == RESOURCE_IVORY_INDEX;
end

local function ZYL_RVC_RestoreTundraResource(plot, originalResourceIndex, resourcePool)
    if originalResourceIndex == nil or originalResourceIndex < 0 then
        return;
    end

    local preserveOriginal = ZYL_RVC_IsPreservedTundraResource(originalResourceIndex);
    local resourceIndex = originalResourceIndex;
    if not preserveOriginal then
        resourceIndex = resourcePool[TerrainBuilder.GetRandomNumber(#resourcePool, "Get Random Resource") + 1];
    end

    ResourceBuilder.SetResourceType(plot, -1);
    if preserveOriginal and ZYL_RVC_TundraResourceRequiresForest(resourceIndex) then
        TerrainBuilder.SetFeatureType(plot, g_FEATURE_FOREST);
    elseif not preserveOriginal and resourceIndex ~= RESOURCE_DEER_INDEX and resourceIndex ~= RESOURCE_FURS_INDEX then
        TerrainBuilder.SetFeatureType(plot, -1);
    end
    ResourceBuilder.SetResourceType(plot, resourceIndex, 1);
end

local function ZYL_RVC_ShufflePlots(plots, label)
    for i = #plots, 2, -1 do
        local j = TerrainBuilder.GetRandomNumber(i, label) + 1;
        plots[i], plots[j] = plots[j], plots[i];
    end
end

local function ZYL_RVC_GetPlotsAtRadius(startPlot, targetRadius)
    if startPlot == nil or targetRadius < 1 then
        return {};
    end

    local visited = {
        [startPlot:GetIndex()] = true,
    };
    local frontier = { startPlot };
    for radius = 1, targetRadius do
        local nextFrontier = {};
        for _, plot in ipairs(frontier) do
            for direction = 0, 5 do
                local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
                if adjacentPlot ~= nil and not visited[adjacentPlot:GetIndex()] then
                    visited[adjacentPlot:GetIndex()] = true;
                    table.insert(nextFrontier, adjacentPlot);
                end
            end
        end
        frontier = nextFrontier;
    end
    return frontier;
end

local function ZYL_RVC_ConvertPlotToDesert(plot)
    if plot == nil or plot:IsWater() or plot:IsNaturalWonder() then
        return false;
    end

    local terrainType = plot:GetTerrainType();
    local desertTerrainType = DESERT_TERRAIN_BY_SOURCE[terrainType];
    if desertTerrainType == nil then
        return false;
    end
    if terrainType == desertTerrainType then
        return true;
    end

    local preserveVolcano = plot:GetFeatureType() == g_FEATURE_VOLCANO;
    ResourceBuilder.SetResourceType(plot, -1);
    TerrainBuilder.SetTerrainType(plot, desertTerrainType);
    if not preserveVolcano then
        TerrainBuilder.SetFeatureType(plot, -1);
        if desertTerrainType == TERRAIN_DESERT_INDEX
            and plot:IsRiver()
            and TerrainBuilder.CanHaveFeature(plot, g_FEATURE_FLOODPLAINS) then
            TerrainBuilder.SetFeatureType(plot, g_FEATURE_FLOODPLAINS);
        end
    end
    return true;
end

local function ZYL_RVC_ExpandMaliDesertStart(startPlot)
    local scopePlots = { startPlot };
    local registeredPlots = {
        [startPlot:GetIndex()] = true,
    };

    for radius = 1, 5 do
        for _, plot in ipairs(ZYL_RVC_GetPlotsAtRadius(startPlot, radius)) do
            if not registeredPlots[plot:GetIndex()] then
                registeredPlots[plot:GetIndex()] = true;
                table.insert(scopePlots, plot);
            end
            ZYL_RVC_ConvertPlotToDesert(plot);
        end
    end
    ZYL_RVC_ConvertPlotToDesert(startPlot);

    local sixthRingCandidates = {};
    for _, plot in ipairs(ZYL_RVC_GetPlotsAtRadius(startPlot, 6)) do
        if not plot:IsWater()
            and not plot:IsNaturalWonder()
            and DESERT_TERRAIN_BY_SOURCE[plot:GetTerrainType()] ~= nil then
            table.insert(sixthRingCandidates, plot);
        end
    end
    ZYL_RVC_ShufflePlots(sixthRingCandidates, "ZYL RVC Desert Sixth Ring");

    local sixthRingPlaced = math.min(10, #sixthRingCandidates);
    for i = 1, sixthRingPlaced do
        local plot = sixthRingCandidates[i];
        if ZYL_RVC_ConvertPlotToDesert(plot) then
            if not registeredPlots[plot:GetIndex()] then
                registeredPlots[plot:GetIndex()] = true;
                table.insert(scopePlots, plot);
            end
        end
    end

    print(
        "ZYL RVC desert start expansion",
        "FullRadius", 5,
        "SixthRing", sixthRingPlaced,
        "ScopePlots", #scopePlots
    );
    return scopePlots;
end

local function ZYL_RVC_GetMaliPlots(startPlot, includeCenter, maxIndex)
    local plots = {};
    if includeCenter then
        table.insert(plots, startPlot);
    end
    for i = 0, maxIndex do
        local plot = GetAdjacentTiles(startPlot, i);
        if plot ~= nil then
            table.insert(plots, plot);
        end
    end
    return plots;
end

local function ZYL_RVC_PlaceMaliResource(startPlot, resourceIndex, targetCount, label, predicate, scopePlots)
    if resourceIndex == nil or resourceIndex < 0 or targetCount < 1 or scopePlots == nil then
        return 0;
    end

    local candidates = {};
    for _, plot in ipairs(scopePlots) do
        if plot:GetIndex() ~= startPlot:GetIndex()
            and plot:GetResourceType() == -1
            and not plot:IsNaturalWonder()
            and (predicate == nil or predicate(plot))
            and ResourceBuilder.CanHaveResource(plot, resourceIndex) then
            table.insert(candidates, plot);
        end
    end

    ZYL_RVC_ShufflePlots(candidates, label);
    local placed = math.min(targetCount, #candidates);
    for i = 1, placed do
        ResourceBuilder.SetResourceType(candidates[i], resourceIndex, 1);
    end
    return placed;
end

local function ZYL_RVC_PrepareMaliStart(startPlot, maliPlots)
    if startPlot == nil then
        return;
    end

    maliPlots = maliPlots or ZYL_RVC_GetMaliPlots(startPlot, true, 89);
    local floodplainsPlaced = 0;
    for _, plot in ipairs(maliPlots) do
        if plot:GetTerrainType() == TERRAIN_DESERT_INDEX
            and plot:IsRiver()
            and not plot:IsNaturalWonder() then
            ResourceBuilder.SetResourceType(plot, -1);
            TerrainBuilder.SetFeatureType(plot, -1);
            if TerrainBuilder.CanHaveFeature(plot, g_FEATURE_FLOODPLAINS) then
                TerrainBuilder.SetFeatureType(plot, g_FEATURE_FLOODPLAINS);
                floodplainsPlaced = floodplainsPlaced + 1;
            end
        end
    end

    local smallResourceCount = math.max(1, math.floor((RichNum + 3) / 5));
    local oasisCandidates = {};
    for _, plot in ipairs(maliPlots) do
        if plot:GetIndex() ~= startPlot:GetIndex()
            and plot:GetTerrainType() == TERRAIN_DESERT_INDEX
            and not plot:IsRiver()
            and plot:GetFeatureType() == -1
            and plot:GetResourceType() == -1
            and not plot:IsNaturalWonder()
            and TerrainBuilder.CanHaveFeature(plot, g_FEATURE_OASIS) then
            table.insert(oasisCandidates, plot);
        end
    end
    ZYL_RVC_ShufflePlots(oasisCandidates, "ZYL RVC Mali Oasis");
    local oasesPlaced = 0;
    for _, plot in ipairs(oasisCandidates) do
        if oasesPlaced >= smallResourceCount then
            break;
        end
        if TerrainBuilder.CanHaveFeature(plot, g_FEATURE_OASIS) then
            TerrainBuilder.SetFeatureType(plot, g_FEATURE_OASIS);
            oasesPlaced = oasesPlaced + 1;
        end
    end

    local sheepPlaced = ZYL_RVC_PlaceMaliResource(
        startPlot,
        RESOURCE_SHEEP_INDEX,
        smallResourceCount,
        "ZYL RVC Mali Sheep",
        function(plot)
            return plot:GetTerrainType() == TERRAIN_DESERT_HILLS_INDEX
                and plot:GetFeatureType() == -1;
        end,
        maliPlots
    );
    local wheatPlaced = ZYL_RVC_PlaceMaliResource(
        startPlot,
        RESOURCE_WHEAT_INDEX,
        smallResourceCount,
        "ZYL RVC Mali Wheat",
        function(plot)
            return plot:GetTerrainType() == TERRAIN_DESERT_INDEX
                and plot:GetFeatureType() == g_FEATURE_FLOODPLAINS;
        end,
        maliPlots
    );

    local luxuryCopies = math.max(1, math.ceil((RichNum - 1) / 3));
    local luxuryPool = {};
    for _, resourceIndex in ipairs(MALI_DESERT_LUXURIES) do
        table.insert(luxuryPool, resourceIndex);
    end
    ZYL_RVC_ShufflePlots(luxuryPool, "ZYL RVC Mali Luxury Types");

    local selectedLuxuries = 0;
    local luxuriesPlaced = 0;
    for _, resourceIndex in ipairs(luxuryPool) do
        local placed = ZYL_RVC_PlaceMaliResource(
            startPlot,
            resourceIndex,
            luxuryCopies,
            "ZYL RVC Mali Luxury Placement",
            nil,
            maliPlots
        );
        if placed > 0 then
            selectedLuxuries = selectedLuxuries + 1;
            luxuriesPlaced = luxuriesPlaced + placed;
            if selectedLuxuries >= 2 then
                break;
            end
        end
    end

    print(
        "ZYL RVC Mali terrain and resources",
        "Floodplains", floodplainsPlaced,
        "Oases", oasesPlaced,
        "Sheep", sheepPlaced,
        "Wheat", wheatPlaced,
        "LuxuryTypes", selectedLuxuries,
        "Luxuries", luxuriesPlaced
    );
end
--静态变量
local functionResultFalse = "false";
local functionResultSuccess = "success";
local functionResultFail = "fail";
local functionResultTrue = "true";
local iBalancingOneDeviationNumber = 0;
local addBonusOneRingIsDeleteResource = false;

-- 提供冻土随机资源
local TERRAIN_TUNDRA_RESOURCE = {}
for row in GameInfo.Resource_ValidTerrains() do
    if row.TerrainType == 'TERRAIN_TUNDRA' then
        table.insert(TERRAIN_TUNDRA_RESOURCE, GameInfo.Resources[row.ResourceType].Index)
        --print('TERRAIN_TUNDRA_RESOURCE',GameInfo.Resources[row.ResourceType].Index)
    end
end
local TERRAIN_TUNDRA_HILLS_RESOURCE = {}
for row in GameInfo.Resource_ValidTerrains() do
    if row.TerrainType == 'TERRAIN_TUNDRA_HILLS' then
        table.insert(TERRAIN_TUNDRA_HILLS_RESOURCE, GameInfo.Resources[row.ResourceType].Index)
        --print('TERRAIN_TUNDRA_HILLS_RESOURCE',GameInfo.Resources[row.ResourceType].Index)
    end
end

-----------------------------------------------------------------------------------------------------------------------------------

function ZYL_RVC_Balance(args)
    print("地图平衡脚本启动。系统时间：", os.date("%c"))

    local currentTurn = Game.GetCurrentGameTurn();
    args = args or {}
    eContinents = {};

    if currentTurn == GameConfiguration.GetStartTurn() then
        --[[ Corrupted legacy log text retained only as a comment.
        print("开始读取游戏配置")
        ]]
        print("Reading game configuration")
        print("Init: Map Seed", MapConfiguration.GetValue("RANDOM_SEED"));
        print("Init: Game Seed", GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED"));
        print("Init: Number of Major Civs", PlayerManager.GetAliveMajorsCount());
        print("Init: Local Player Id", Game.GetLocalPlayer());
        print("Init: Number of City-States", PlayerManager.GetAliveMinorsCount());
        local mapName = MapConfiguration.GetValue("MAP_SCRIPT")
        local cityStatePlacement = tonumber(MapConfiguration.GetValue("ZYL_RVC_CityStatePlacement")) or 1
        print("Init: Loading " .. tostring(mapName) .. " script");
		print("Init: City-State Placement:", cityStatePlacement == 0 and "Single Player" or "Multiplayer");
        local startTemp = MapConfiguration.GetValue("temperature")
        local mapSize = ZYL_RVC_GetNormalizedMapSize();
        local sea_level = MapConfiguration.GetValue("sea_level")
        local rainfall = MapConfiguration.GetValue("rainfall");
        world_age = MapConfiguration.GetValue("world_age");
        local ridge = MapConfiguration.GetValue("BBSRidge");
        print("Init: Map Size: ", mapSize, "2 = Small, 5 = Huge");
        local gridWidth, gridHeight = Map.GetGridSize();
        print("Init: gridWidth", gridWidth, "gridHeight", gridHeight)
        print("Init: Climate: ", startTemp, "1 = Hot, 2 = Standard, 3 = Cold");
        local BBS_temp = false;
        if (GameConfiguration.GetValue("BBStemp") ~= nil) then
            if (GameConfiguration.GetValue("BBStemp") == true) then
                BBS_temp = true;
                print("Init: BBS Temperature: On");
            else
                BBS_temp = false;
                print("Init: BBS Temperature: Off")
            end
        else
            BBS_temp = false;
            print("Init: BBS Temperature: Off")
        end
        print("Init: Rainfall: ", rainfall, "1 = Dry, 2 = Standard, 3 = Humid");
        print("Init: World Age: ", world_age, "1 = New, 2 = Standard 3 = Old");
        print("Init: Ridge: ", ridge, "1 = Standard 2 = Large Open 4 = Flat Earth");
        print("Init: Sea Level: ", sea_level, "1 = Low Sea Level, 2 = Standard, 3 = High Sea Level");
        print("Init: Strategic Resources:", MapConfiguration.GetValue("BBSStratRes"))
        local resourcesConfig = MapConfiguration.GetValue("resources");
        print("Init: Resources: ", resourcesConfig, "1 = Sparse, 2 = Standard, 3 = Abundant");
        local startConfig = MapConfiguration.GetValue("start")
        print("Init: Spawntype: ", startConfig, "1 = Standard, 2 = Balanced, 3 = Legendary");

        RichNum = args.RichNum or 5;

        local iBalancingOne = 2;
        local iBalancingTwo = 0;
        local iBalancingThree = -1;
        local force_remap = true;
        local majList = {}
        local tempEval = {}
        local minFood = 5 + math.floor(RichNum * 0.3);
        local avgFood = 0;
        local maxFood = 0;
        local minProd = 6 + math.floor(RichNum * 0.3);
        local avgProd = 0;
        local maxProd = 0;
        local avgHill = 0;
        local dispersion = 0.1 * RichNum; --override later
        local dispersion_2 = 0.05 * RichNum;
        local count = 0;
        local debug_balancing = false

        if (GameConfiguration.GetValue("DEBUG_BALANCING") ~= nil) then
            if (GameConfiguration.GetValue("DEBUG_BALANCING") == true) then
                debug_balancing = true
            end
        end
        if (GameConfiguration.GetValue("AutoRemap") ~= nil) then
            if (GameConfiguration.GetValue("AutoRemap") == true) then
                force_remap = true;
                print("Init: Forced Remap: On");
            else
                force_remap = false;
            end
        else
            force_remap = false;
        end
        -- iBalancing are the legacy sliders now set in place

        print("开始计算开局资源补偿")
        if resourcesConfig ~= nil then
            if (resourcesConfig == 1 or resourcesConfig == 2) then
                iBalancingTwo = math.max(math.floor(RichNum * 0.3), 1);
                minFood = minFood + resourcesConfig;
                iBalancingOneDeviationNumber = math.floor(RichNum * 0.4);--贫瘠\普通
            elseif (resourcesConfig == 3) then
                iBalancingTwo = 2;
                minFood = minFood + 3;
                minProd = minProd + 3;
                iBalancingOneDeviationNumber = math.floor(RichNum * 0.6);--富有
            else
                minFood = 7 + math.floor(RichNum * 0.5);
                iBalancingOneDeviationNumber = math.floor(RichNum * 0.4);--普通
            end
        end
        print("iBalancingOneDeviationNumber:", iBalancingOneDeviationNumber);
        if (startConfig == 3) then
            iBalancingTwo = iBalancingTwo + 3;
        end

        if (Game:GetProperty("BBS_RESPAWN") ~= nil) then
            if (Game:GetProperty("BBS_RESPAWN") == false) then
                bBiasFail = true;
            else
                bBiasFail = false;
            end
        else
            bBiasFail = true;
        end

        iBalancingThree = math.floor(RichNum * 0.4);
        iBalancingFour = 0;

        print("地图平衡脚本：初始化完毕");
        print("Init: ", Game:GetProperty("BBS_INIT_COUNT"), " time.")
        print("Init: Global Parameters: Natural Wonder Buffer:", GlobalParameters.START_DISTANCE_MAJOR_NATURAL_WONDER)
        print("Init: Global Parameters: City-State Buffer:", GlobalParameters.START_DISTANCE_MINOR_MAJOR_CIVILIZATION)
        print("Init: Global Parameters: Major Civs Buffer:", GlobalParameters.START_DISTANCE_MAJOR_CIVILIZATION - GlobalParameters.START_DISTANCE_RANGE_MAJOR)


        -------------------------------------------------------------------------------------
        -- Settings: Importing Map Variables
        -------------------------------------------------------------------------------------

        -- Firaxis Defaults from SetDefaultAssignedStartingPlots.lua
        local bTerraformingSpawn = true;

        --Find Default Number
		local mapRow = ZYL_RVC_GetMapRow();
		local iDefaultNumberPlayers = mapRow and mapRow.DefaultPlayers or 8;
        iDefaultNumberMajor = iDefaultNumberPlayers;
        iDefaultNumberMinor = math.floor(iDefaultNumberPlayers * 1.5);


        -------------------------------------------------------------------------------------
        -- Settings: Importing Player Variables
        -------------------------------------------------------------------------------------
        local iNumMinCivs = 0;
        tempMajorList = PlayerManager.GetAliveMajorIDs();


        -- Creating Player Table
        local major_table = {}
        local minor_table = {}
        local major_count = 0
        local minor_count = 0
        for i = 0, 60 do
            local tmp_civ = Players[i]
            if Players[i] ~= nil then
                if tmp_civ:IsMajor() == true and tmp_civ:IsAlive() == true then
                    major_count = major_count + 1
                    major_table[major_count] = i
                end
                if tmp_civ:IsMajor() == false and tmp_civ:IsAlive() == true then
                    minor_count = minor_count + 1
                    minor_table[minor_count] = i
                end
            end
        end

        print("载入冻土资源补偿配置")
        Tundra_Resource_Pick()

        -- Check for Minor placement failure

        --[[ Corrupted legacy log text retained only as a comment.
        print("检查城邦出生点是否已分配")
        ]]
        print("Checking city-state starting plots")
        if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") ~= nil) then
            -- BBS placement true
            if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") > 0) then
                __Debug("Minor failure module:", Game:GetProperty("BBS_MINOR_FAILING_TOTAL"), " Minor Civs are failing.")
                for j = 1, Game:GetProperty("BBS_MINOR_FAILING_TOTAL") do
                    if (Game:GetProperty("BBS_MINOR_FAILING_ID_" .. j) ~= nil) then
                        local playerUnits;
                        if (Players[Game:GetProperty("BBS_MINOR_FAILING_ID_" .. j)] ~= nil) then
                            if (Players[Game:GetProperty("BBS_MINOR_FAILING_ID_" .. j)]:GetUnits() ~= nil) then
                                playerUnits = Players[Game:GetProperty("BBS_MINOR_FAILING_ID_" .. j)]:GetUnits();
                                for k, unit in playerUnits:Members() do
                                    playerUnits:Destroy(unit)
                                end
                                --[[ Corrupted legacy log text retained only as a comment.
                                print("城邦玩家", Game:GetProperty("BBS_MINOR_FAILING_ID_" .. j), "因未能安排合适出生点而被移除。")
                                ]]
                                print("Removing city-state player", Game:GetProperty("BBS_MINOR_FAILING_ID_" .. j), "because no valid starting plot was found")
                            end
                        end
                    end
                end
            else
                __Debug("Minor failure module: All Minor Civs have been placed.")
            end
        else
            __Debug("Minor failure module: Firaxis placement only check if minimum distance are met")
        end


        -- Check Distances if Firaxis Placement Algo has been used
        local bError_proximity = false;

        if bBiasFail == true or bBiasFail == false then
            print("BBS分配出生点失败。地图脚本正在检查F社分配出生点脚本是否存在错误")
            for i = 1, major_count do
                if (PlayerConfigurations[major_table[i]]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770 and (not IsSeaStartCiv(PlayerConfigurations[major_table[i]]:GetLeaderTypeName()))) then
                    local pStartPlot_i = Players[major_table[i]]:GetStartingPlot()
                    for j = 1, major_count do
                        if (PlayerConfigurations[major_table[j]]:GetLeaderTypeName() ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[j]]:GetHandicapTypeID() ~= 2021024770 and (not IsSeaStartCiv(PlayerConfigurations[major_table[i]]:GetLeaderTypeName())) and major_table[i] ~= major_table[j]) then
                            local pStartPlot_j = Players[major_table[j]]:GetStartingPlot()
                            local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(), pStartPlot_j:GetIndex())
                            __Debug("I:", i, "J:", j, "Distance:", distance)
                            if (distance < 9) then
                                print("Init: Minimum CPL distance rule breached");
                                if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") == nil) then
                                    Game:SetProperty("BBS_MINOR_FAILING_TOTAL", 0)
                                end
                                bError_proximity = true;
                                Game:SetProperty("BBS_DISTANCE_ERROR", "Two Players are only " .. distance .. " tiles away from each other and allowed to remap as per CPL rules.")
                            end
                        end
                    end
					if cityStatePlacement ~= 0 then
						for j = 1, minor_count do
							if Players[minor_table[j]]:IsAlive() == true
								and not ZYL_RVC_IsMinorMarkedFailing(minor_table[j]) then
								local pStartPlot_j = Players[minor_table[j]]:GetStartingPlot()
								local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(), pStartPlot_j:GetIndex())
								__Debug("I:", i, "J:", j, "Distance:", distance)
								if (distance < 6) or pStartPlot_i == pStartPlot_j then
									print("Init: Minimum CPL distance rule breached");
									if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") == nil) then
										Game:SetProperty("BBS_MINOR_FAILING_TOTAL", 0)
									end
									-- Let's kill a CS to ensure the game is within CPL rules
									local playerUnits;
									playerUnits = Players[minor_table[j]]:GetUnits();
									for k, unit in playerUnits:Members() do
										playerUnits:Destroy(unit)
									end
									print("Minor failure module: Firaxis Placement: Minor Player", minor_table[j], " has been eliminated (too close to major).", distance)
									ZYL_RVC_RecordMinorFailure(minor_table[j])
								end
							end
						end
					end
                else
                    if (PlayerConfigurations[major_table[i]]:GetLeaderTypeName() == "LEADER_SPECTATOR" or PlayerConfigurations[major_table[i]]:GetHandicapTypeID() == 2021024770) then
                        print("Init: Spectator Player Id:", major_table[i]);
                    else
                        print("Init: Maori Player Id:", major_table[i]);
                    end
                end
            end
			if cityStatePlacement ~= 0 then
				-- Minor Minor
				local bmin = false
				for i = 1, minor_count do
					local pStartPlot_i = Players[minor_table[i]]:GetStartingPlot()
					for j = 1, minor_count do
						local pStartPlot_j = Players[minor_table[j]]:GetStartingPlot()
						if (minor_table[i] ~= minor_table[j]) then
							bmin = ZYL_RVC_IsMinorMarkedFailing(minor_table[i])
								or ZYL_RVC_IsMinorMarkedFailing(minor_table[j])
							if bmin == false then
								local distance = Map.GetPlotDistance(pStartPlot_i:GetIndex(), pStartPlot_j:GetIndex())
								__Debug("I:", minor_table[i], "J:", minor_table[j], "Distance:", distance)
								if (distance < 7) or pStartPlot_i == pStartPlot_j then
									if (Game:GetProperty("BBS_MINOR_FAILING_TOTAL") == nil) then
										Game:SetProperty("BBS_MINOR_FAILING_TOTAL", 0)
									end
									-- Let's kill a CS to avoid a CS settler roaming and breaking CPL rules
									local playerUnits;
									playerUnits = Players[minor_table[j]]:GetUnits();
									for k, unit in playerUnits:Members() do
										playerUnits:Destroy(unit)
									end
									print("Minor failure module: Firaxis Placement: Minor Player", minor_table[j], " has been eliminated (too close to minor).", distance)
									ZYL_RVC_RecordMinorFailure(minor_table[j])
								end
							else
								bmin = false
							end
						end
					end
				end
			end
        end



        -- 强制重开
        tempMajorList = PlayerManager.GetAliveMajorIDs();
        if (force_remap == true and bError_proximity == true) then
            print("Init: Defeat all players");
            for i = 1, major_count do
                local pPlayer = Players[major_table[i]]
                local playerUnits;
                local startPlot;
                playerUnits = pPlayer:GetUnits()

                for j, unit in playerUnits:Members() do
                    playerUnits:Destroy(unit)
                end
            end
            Game:SetProperty("BBS_DISTANCE_ERROR", "Minimum distances between civilizations could not be met. You must remap as per CPL rules.");
            print("Init: Exit");
            return
        end

        print("地图平衡脚本：所有平衡前初始化已全部完成", os.date("%c"))


        --------------------------------------------------------------------------------------
        -- Terrain Balancing - Init
        --------------------------------------------------------------------------------------

        print("地图平衡脚本：出生点地形平衡")
        -- 创建主玩家数据表，从 EvaluateStartingLocation 函数分配数据
        -- 然后 majList [i] 对象将在代码的其余部分用于存储每个玩家的平衡信息
        -- EvalType = {不可通行地形，水域，雪地，沙漠...}

        for i = 1, major_count do
            local sPlayerLeaderName = PlayerConfigurations[major_table[i]]:GetLeaderTypeName()
            local sPlayerCivName = PlayerConfigurations[major_table[i]]:GetCivilizationTypeName()
            local pPlayer = Players[major_table[i]]
            local playerUnits;
            local startPlot;
            SpawnTurn = 1;
            startPlot = pPlayer:GetStartingPlot()
            if (startPlot ~= nil) then
                tempEval = EvaluateStartingLocation(startPlot)
                majList[i] = {
                    leader = sPlayerLeaderName,
                    civ = sPlayerCivName,
                    plotX = startPlot:GetX(),
                    plotY = startPlot:GetY(),
                    food_spawn_start = tempEval[5], -- 出生点食物值
                    prod_spawn_start = tempEval[6], -- 出生点生产力值
                    culture_spawn_start = tempEval[7], -- 出生点文化值
                    faith_spawn_start = tempEval[8], -- 出生点信仰值
                    impassable_start = tempEval[9], -- 出生点不可通行地形
                    water_start = tempEval[10], --出生点水域
                    snow_start = tempEval[11], -- 出生点雪地
                    desert_start = tempEval[12], -- 出生点沙漠
                    impassable_inner = tempEval[13], -- 内层不可通行地形
                    water_inner = tempEval[14], -- 内层水域
                    snow_inner = tempEval[15], -- 内层雪地
                    desert_inner = tempEval[16], -- 内层沙漠
                    impassable_outer = tempEval[17], -- 外层不可通行地形
                    water_outer = tempEval[18], -- 外层水域
                    snow_outer = tempEval[19], -- 外层雪地
                    desert_outer = tempEval[20], -- 外层沙漠
                    flood = tempEval[21], -- 洪水
                    hill_start = tempEval[22], -- 出生点丘陵
                    hill_inner = tempEval[23], -- 内层丘陵
                    prod_adjust = tempEval[6],
                    food_adjust = tempEval[5],
                    best_tile = tempEval[24], -- 最佳地块
                    best_tile_2 = tempEval[25], -- 次佳地块
                    food_spawn_inner = tempEval[26],
                    prod_spawn_inner = tempEval[27],
                    best_tile_inner = tempEval[28],
                    best_tile_inner_2 = tempEval[29],
                    plains = tempEval[30] }
                __Debug("Major Start X: ", majList[i].plotX, "Major Start Y: ", majList[i].plotY, "Player: ", major_table[i], " ", majList[i].leader, majList[i].civ);
            end
        end

        --------------------------------------------------------------------------------------
        -- Terraforming
        --------------------------------------------------------------------------------------
        --[[ Corrupted legacy log text retained only as a comment.
        print("地图平衡脚本：使地图看起来更像地球")
        ]]
        print("Map balancing: applying terrain adjustments")
        if debug_balancing == false then
            __Debug("Terraforming Starts")

            -- 移除过多的泛滥平原
            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        -- 不移除沙漠和埃及的泛滥平原单元格
                        if ((majList[i].flood >= 100) and majList[i].civ ~= "CIVILIZATION_EGYPT" and (not IsDesertCiv(majList[i].civ))) then
                            print("TeamPVP Check for Floodplains Start:", majList[i].civ);
                            __Debug("Floodplains Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                            Terraforming_Flood(Map.GetPlot(majList[i].plotX, majList[i].plotY), iBalancingThree);
                        end
                    end
                end
            end

            -- 修复文明可能在奢侈品上生成的错误（当富饶系数小于7时）
            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        local start_plot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
                        if (start_plot ~= nil) then
                            -- 非传奇开局移除可可/香料/糖
                            if (startConfig ~= 3) then
                                __Debug("Luxury balancing: Check for Banned Luxury on Spawn");
                                Terraforming_BanLux(start_plot);
                            end
                            if (start_plot:GetResourceCount() > 0) and RichNum < 7 then
                                ResourceBuilder.SetResourceType(start_plot, -1);
                            end
                        end
                    end
                end
            end

            -- 检查玩家选择的样式选项，默认值 = 1

            if (bTerraformingSpawn == true) then
                -- 循环浏览文明以找到开局奇怪的文明
                for i = 1, major_count do
                    if (majList[i] ~= nil) then
                        if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                            -- 平衡地脉
                            __AddLeyLine(Map.GetPlot(majList[i].plotX, majList[i].plotY));
                            -- 移除开局冻土
                            Terraforming_Polar_Start(Map.GetPlot(majList[i].plotX, majList[i].plotY));
                            print("TeamPVP 文明:", majList[i].civ);
                            if (IsDesertCiv(majList[i].civ) == true) then
                                -- 现在强制改造沙漠文明以平衡地图上沙漠数量较少的问题
                                print("TeamPVP 沙漠化 Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                                local desertStartPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
                                Terraforming(desertStartPlot, iBalancingThree, 2);
                                if majList[i].civ == MALI_CIVILIZATION_TYPE then
                                    local desertScopePlots = ZYL_RVC_ExpandMaliDesertStart(desertStartPlot);
                                    ZYL_RVC_PrepareMaliStart(desertStartPlot, desertScopePlots);
                                end
                            elseif (IsTundraCiv(majList[i].civ) == true) then
                                -- 现在强制改造冻土文明
                                print("TeamPVP 冻土化 Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                                Terraforming(Map.GetPlot(majList[i].plotX, majList[i].plotY), iBalancingThree, 1);
                                -- 非冻土文明三环内不允许有冻土、非沙漠文明三环内沙漠不得多于1个
                            elseif ((majList[i].snow_start + majList[i].snow_inner + majList[i].snow_outer > 0) or (majList[i].desert_outer + majList[i].desert_inner + majList[i].desert_start > 1)) then
                                print("TeamPVP 开局平衡 Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                                Terraforming(Map.GetPlot(majList[i].plotX, majList[i].plotY), iBalancingThree, 0);
                            end
                        end
                    end
                end
            else
                __Debug("地球化: Terrain Update Not Required (Use Original Civ 6 Map)");
            end

            -- 修复自然奇观与山脉相邻的问题
            for iPlotIndex = 0, Map.GetPlotCount() - 1 do
                local natPlot = Map.GetPlotByIndex(iPlotIndex)
                if (natPlot ~= nil) then
                    if (natPlot:IsNaturalWonder() == true and natPlot:GetFeatureType() ~= 29) then
                        for i = 0, 5 do
                            local adjacentPlot = GetAdjacentTiles(natPlot, i);
                            if (adjacentPlot ~= nil) then
                                if (adjacentPlot:IsImpassable() == true and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:IsNaturalWonder() == false) then
                                    TerrainBuilder.SetTerrainType(adjacentPlot, adjacentPlot:GetTerrainType() - 1);
                                elseif (adjacentPlot:GetFeatureType() == g_FEATURE_VOLCANO) then
                                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                                end
                            end
                        end
                    end
                end
            end

            -- 修复极端山脉开局
            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    -- 印加以外检查山脉过多的问题
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770 and not IsMountainCiv(majList[i].leader)) then
                        if (((majList[i].impassable_start + majList[i].impassable_inner + majList[i].impassable_outer) >= 12)
                                or ((majList[i].impassable_start + majList[i].impassable_inner + majList[i].impassable_outer) >= 8
                                and (majList[i].water_start + majList[i].water_inner + majList[i].water_outer) >= 4)) then
                            __Debug("山脉化改造 Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                            Terraforming_Mountain(Map.GetPlot(majList[i].plotX, majList[i].plotY), 0)
                        end
                    end
                    -- 印加、文美检查山脉过少的问题
                    if (IsMountainCiv(majList[i].leader) and (majList[i].impassable_start + majList[i].impassable_inner + majList[i].impassable_outer) < 6) then
                        __Debug("山脉化改造 Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                        Terraforming_Mountain(Map.GetPlot(majList[i].plotX, majList[i].plotY), 3)
                    end
                end
            end

            -- 修复一环极端山脉开局
            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        if (((majList[i].impassable_start + majList[i].water_start) > 4) and not IsMountainCiv(majList[i].leader)) then
                            __Debug("Walled-In Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                            Terraforming_Nuke_Mountain(Map.GetPlot(majList[i].plotX, majList[i].plotY))
                        end
                    end
                end
            end

            -- 倾斜轴线以外的地图修复平原森林缺失
            -- 在温带，无地貌的平坦单元格将有15%概率生长丘陵树（平原为33%）
            if string.lower(mapName) ~= "tilted_axis.lua" then
                for iPlotIndex = 0, Map.GetPlotCount() - 1, 1 do
                    local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    local pPlot = Map.GetPlotByIndex(iPlotIndex)
                    if (pPlot:GetY() > gridHeight / 6 and pPlot:GetY() < gridHeight * 4 / 9) or (pPlot:GetY() > 5 * gridHeight / 9 and pPlot:GetY() < gridHeight * 5 / 6) then
                        if rng < 0.33 then
                            if pPlot:IsImpassable() == false and pPlot:IsWater() == false and pPlot:GetResourceType() == -1 and pPlot:GetFeatureType() == -1 and pPlot:GetTerrainType() ~= 6 and pPlot:GetTerrainType() ~= 7 and pPlot:GetTerrainType() ~= 12 and pPlot:GetTerrainType() ~= 13 then
                                if rng < 0.15 or pPlot:GetTerrainType() == 3 then
                                    TerrainBuilder.SetFeatureType(pPlot, 3)
                                    if not pPlot:IsHills() then
                                        TerrainBuilder.SetTerrainType(pPlot, pPlot:GetTerrainType() + 1)
                                    end
                                end
                            end
                        end
                    end
                end
            end

            --[[ Corrupted legacy log text retained only as a comment.

            __Debug("完成地形改造")
            print("完成地形改造", os.date("%c"))

            ]]
            __Debug("Terrain adjustments complete")
            print("Terrain adjustments complete", os.date("%c"))

            ---------------------------------------------------------------------------------------------------------------
            -- 分三个阶段开始资源再平衡：战略、粮食和生产
            ---------------------------------------------------------------------------------------------------------------
            ---------------------------------------------------------------------------------------------------------------
            -- 第 1 阶段：战略资源平衡 / 来自 AddBalancedResources() 的原始 Firaxis 代码已重新编写
            ---------------------------------------------------------------------------------------------------------------

            --[[ Corrupted legacy log text retained only as a comment.
            __Debug("第 1 阶段：战略资源平衡")

            ]]
            __Debug("Phase 1: strategic resource balancing")

            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        if (Map.GetPlot(majList[i].plotX, majList[i].plotY):IsWater() == false) then
                            BalanceStrategic(Map.GetPlot(majList[i].plotX, majList[i].plotY), majList[i].leader);
                        end
                    end
                end
            end
            print("战略资源平衡 - Completed", os.date("%c"))

            ---------------------------------------------------------------------------------------------------------------
            -- 第二阶段：食物资源平衡/ 原始 Firaxis 代码来自 AddBalancedResources() 重新编写
            ---------------------------------------------------------------------------------------------------------------
            --丘陵
            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR") then
                        local functionCount = 0;
                        local successCount = 0;
                        local isLucky = false;
                        local isLuckyRng = TerrainBuilder.GetRandomNumber(100, "test");
                        if (isLuckyRng <= 25 + RichNum * 8) then
                            isLucky = true
                        end
                        print("majList[i].leader:", majList[i].leader);
                        while (functionCount <= 20) do
                            local functionResult = civAddHillTeamPVP(Map.GetPlot(majList[i].plotX, majList[i].plotY), majList[i].leader, majList[i].civ, isLucky, functionCount);
                            if (functionResult == functionResultFalse) then
                                functionCount = functionCount + 1;
                            elseif functionResult == functionResultTrue then
                                functionCount = functionCount + 1;
                                successCount = successCount + 1;
                            elseif functionResult == functionResultSuccess or functionResult == functionResultFail then
                                print("successCount:", successCount);
                                break ;
                            end
                        end
                        print("functionCount:", functionCount);
                    end
                end
            end


            --食物
            for i = 1, major_count do
                addRiceCount = 0;
                addFoodSheepCount = 0;
                resourcesFishCount = 0;
                addJungleCount = 0;
                addForestCount = 0;
                addHuntCount = 0;
                addBananaCount = 0;
                addBonusOneRingIsDeleteResource = false;
                local PlotRice = Map.GetPlot(majList[i].plotX, majList[i].plotY);
                for ii = 0, 18 do
                    local adjacentPlotRice = GetAdjacentTiles(PlotRice, ii);
                    if (adjacentPlotRice ~= nil) then
                        if (adjacentPlotRice:GetResourceCount() > 0) then
                            -- 牛麦子大米玉米
                            if (1 == adjacentPlotRice:GetResourceType() or 6 == adjacentPlotRice:GetResourceType() or 9 == adjacentPlotRice:GetResourceType() or 52 == adjacentPlotRice:GetResourceType()) then
                                addRiceCount = addRiceCount + 1;
                            end
                            -- 羊
                            if (7 == adjacentPlotRice:GetResourceType()) then
                                addFoodSheepCount = addFoodSheepCount + 1;
                            end
                            -- 鱼
                            if (adjacentPlotRice:IsWater() == true and adjacentPlotRice:GetResourceCount() > 0 and adjacentPlotRice:GetResourceType() ~= RESOURCE_OIL_INDEX) then
                                resourcesFishCount = resourcesFishCount + 1;
                            end
                            -- 鹿
                            if (4 == adjacentPlotRice:GetResourceType()) then
                                addHuntCount = addHuntCount + 1;
                            end
                            -- 香蕉
                            if (0 == adjacentPlotRice:GetResourceType()) then
                                addBananaCount = addBananaCount + 1;
                            end

                        end

                        -- 雨林森林
                        if (adjacentPlotRice:GetFeatureType() == 2) then
                            addJungleCount = addJungleCount + 1;
                        end
                        if (adjacentPlotRice:GetFeatureType() == 3) then
                            addForestCount = addForestCount + 1;
                        end

                    end

                end
                print("teamPVP start addRiceCount:", addRiceCount);
                print("teamPVP start addFoodSheepCount:", addFoodSheepCount);
                print("teamPVP start resourcesFishCount:", resourcesFishCount);
                print("teamPVP start addJungleCount:", addJungleCount);
                print("teamPVP start addForestCount:", addForestCount);
                print("teamPVP start addHuntCount:", addHuntCount);
                print("teamPVP start addBananaCount:", addBananaCount);

                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        local functionCount = 0;
                        local successCount = 0;
                        local isLucky = false;
                        local isLuckyRng = TerrainBuilder.GetRandomNumber(100, "test");
                        if (isLuckyRng <= 25 + RichNum * 8) then
                            isLucky = true
                        end
                        local functionResult = functionResultFail;--此部分公用
                        -- 先补一次1环内
                        local isMust = false;
                        while (functionCount <= 20) do
                            local functionResult = civAddOneRingFloorsTeamPVP(Map.GetPlot(majList[i].plotX, majList[i].plotY), majList[i].leader, majList[i].civ, isMust);
                            if (functionResult == functionResultFalse) then
                                functionCount = functionCount + 1;
                                if (functionCount >= 10) then
                                    isMust = true;
                                end
                            elseif functionResult == functionResultTrue then
                                functionCount = functionCount + 1;
                                successCount = successCount + 1;
                            elseif functionResult == functionResultSuccess or functionResult == functionResultFail then
                                print("OneRingFloors majList[i].leader:", majList[i].leader);
                                print("OneRingFloors functionCount:", functionCount);
                                print("OneRingFloors successCount:", successCount);
                                print("OneRingFloors isMust:", isMust);
                                break ;
                            end
                        end
                        functionCount = 0;
                        while (functionCount <= 20) do
                            local functionResult = civAddFoodTeamPVP(Map.GetPlot(majList[i].plotX, majList[i].plotY), majList[i].leader, majList[i].civ, successCount, isLucky);
                            if (functionResult == functionResultFalse) then
                                functionCount = functionCount + 1;
                            elseif functionResult == functionResultTrue then
                                functionCount = functionCount + 1;
                                successCount = successCount + 1;
                            elseif functionResult == functionResultSuccess or functionResult == functionResultFail then
                                print("majList[i].leader:", majList[i].leader);
                                print("functionCount:", functionCount);
                                print("successCount:", successCount);
                                break ;
                            end
                        end
                        if (functionResult == functionResultSuccess or functionResult == functionResultFail) then
                            --获取文明标签 0普通文明，1冻土文明，2沙漠文明，3山脉文明
                            local civFlag = 0;
                            if (IsDesertCiv(majList[i].civ) and majList[i].desert_start > 0) then
                                civFlag = 2;
                            elseif (IsTundraCiv(majList[i].civ) and majList[i].snow_start > 0) then
                                civFlag = 1;
                            elseif (IsMountainCiv(majList[i].leader) or IsMountainCiv(majList[i].civ)) then
                                civFlag = 3;
                            end
                            local bindFunctionCount = 0;
                            while (bindFunctionCount <= 20) do
                                functionResult = AddBonusBind(Map.GetPlot(majList[i].plotX, majList[i].plotY), iBalancingThree, civFlag, majList[i].civ);
                                if (functionResult == functionResultSuccess or functionResult == functionResultFail) then
                                    print("AddBonusBind majList[i].leader:", majList[i].leader);
                                    print("AddBonusBind functionCount:", functionCount);
                                    print("AddBonusBind successCount:", successCount);
                                    break ;
                                end
                            end
                        end
                    end
                end
            end

            -- 非传奇开局移除过多食物
            if (startConfig ~= 3 and RichNum < 5) then
                for i = 1, major_count do
                    if (majList[i] ~= nil) then
                        if (majList[i].leader ~= "LEADER_SPECTATOR" and majList[i].civ ~= "CIVILIZATION_EGYPT") then
                            civRemoveFoodTeamPVP(Map.GetPlot(majList[i].plotX, majList[i].plotY), majList[i].leader, majList[i].civ);
                        end
                    end
                end
            end

            --产出
            for i = 1, major_count do
                stonesCounts = 0;
                local PlotStones = Map.GetPlot(majList[i].plotX, majList[i].plotY);
                for ii = 0, 18 do
                    local adjacentPlotStones = GetAdjacentTiles(PlotStones, ii);
                    if (adjacentPlotStones ~= nil) then
                        if (adjacentPlotStones:GetResourceCount() > 0) then
                            if (8 == adjacentPlotStones:GetResourceType()) then
                                stonesCounts = stonesCounts + 1;
                            end
                        end
                    end
                end
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR") then
                        local functionCount = 0;
                        local successCount = 0;
                        local isLucky = false;
                        local isLuckyRng = TerrainBuilder.GetRandomNumber(100, "test");
                        if (isLuckyRng <= 25 + RichNum * 8) then
                            isLucky = true
                        end
                        while (functionCount <= 20) do
                            local functionResult = civAddProdTeamPVP(Map.GetPlot(majList[i].plotX, majList[i].plotY), majList[i].leader, majList[i].civ, successCount, isLucky);
                            if (functionResult == functionResultFalse) then
                                functionCount = functionCount + 1;
                            elseif functionResult == functionResultTrue then
                                functionCount = functionCount + 1;
                                successCount = successCount + 1;
                            elseif functionResult == functionResultSuccess or functionResult == functionResultFail then
                                print("majList[i].leader:", majList[i].leader);
                                print("functionCount:", functionCount);
                                print("successCount:", successCount);
                                break ;
                            end
                        end
                    end
                end
            end

            -- 第三阶段减少正异常值
            -- 检查主要文明是否低于阈值
            if (startConfig ~= 3 and RichNum < 5) then
                for i = 1, major_count do
                    if (majList[i] ~= nil) then
                        if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                            civRemoveProdTeamPVP(Map.GetPlot(majList[i].plotX, majList[i].plotY), majList[i].leader, majList[i].civ);
                        end
                    end
                end
            end

            print("产能平衡 - Completed", os.date("%c"))
            ---------------------------------------------------------------------------------------------------------------------------------------------------------
            -- Phase 4: 最佳瓷砖平衡：查看古代和古典开局的 2 个最佳瓷砖
            ----------------------------------------------------------------------------------------------------------------------------------------------------------;

            local iStartEra = GameInfo.Eras[GameConfiguration.GetStartEra()];
            local iStartIndex = 1;
            if iStartEra ~= nil then
                iStartIndex = iStartEra.ChronologyIndex;
            end
            if (iStartIndex == 1 or iStartIndex == 2) then

                -- Let's get the averages
                local avg_best_tile_1 = 0;
                local avg_best_tile_2 = 0;
                local max_best_tile_1 = 0;
                local max_best_tile_2 = 0;
                local best_civ_1 = nil
                local best_civ_2 = nil
                count = 0;
                for i = 1, major_count do
                    if (majList[i] == nil or majList[i].leader == "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        count = count + 1;
                    else
                        startPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY);
                        tempEval = EvaluateStartingLocation(startPlot)
                        majList[i].best_tile = math.max(tempEval[24], tempEval[28] * 0.9);
                        majList[i].best_tile_2 = math.max(tempEval[25], tempEval[29] * .9);
                        if (majList[i].civ == "CIVILIZATION_RUSSIA") and tempEval[11] > 4 then
                            majList[i].best_tile = math.max(tempEval[24], tempEval[28]) + 1;
                            majList[i].best_tile_2 = math.max(tempEval[25], tempEval[29]) + 1;
                        elseif (IsTundraCiv(majList[i].civ)) and tempEval[11] > 4 then
                            majList[i].best_tile = math.max(tempEval[24], tempEval[28] * 0.9) + 1;
                            majList[i].best_tile_2 = math.max(tempEval[25], tempEval[29] * 0.9) + 1;
                        elseif (IsDesertCiv(majList[i].civ)) and tempEval[12] > 4 then
                            majList[i].best_tile = math.max(tempEval[24], tempEval[28] * 0.9) + 0.75;
                            majList[i].best_tile_2 = math.max(tempEval[25], tempEval[29] * 0.9) + 0.75;
                        elseif (IsSeaStartCiv(majList[i].leader)) then
                            -- so Maori doesn't penalized other.
                            majList[i].best_tile = math.max(majList[i].best_tile, 4)
                            majList[i].best_tile_2 = math.max(majList[i].best_tile_2, 4)
                        end
                        __Debug(majList[i].civ, "S1-S2-I1-I2:", tempEval[24], tempEval[25], tempEval[28], tempEval[29], "Best", majList[i].best_tile, "Second", majList[i].best_tile_2)
                        -- 记录最大开局
                        if majList[i].best_tile > max_best_tile_1 then
                            max_best_tile_1 = majList[i].best_tile
                            max_best_tile_2 = majList[i].best_tile_2
                            best_civ_2 = majList[i].leader
                            best_civ_1 = majList[i].leader
                        end
                        -- 考虑到我们有一个基础的 2:2 城市地块，而不是 2:1
                        if startPlot:GetTerrainType() == 4 then
                            majList[i].best_tile = majList[i].best_tile + 1
                        end
                        avg_best_tile_1 = avg_best_tile_1 + majList[i].best_tile;
                        avg_best_tile_2 = avg_best_tile_2 + majList[i].best_tile_2;
                    end

                end

                avg_best_tile_1 = avg_best_tile_1 / (major_count - count);
                avg_best_tile_2 = avg_best_tile_2 / (major_count - count);

                __Debug("第四阶段：最佳单元格平衡：平均得分：", avg_best_tile_1 + avg_best_tile_2, "Average Best tile:", avg_best_tile_1, "Second Avg. Best:", avg_best_tile_2, "Top", max_best_tile_1, best_civ_1, "Second", max_best_tile_2, best_civ_2)

                -- Check for Major Civ below threshold
                for i = 1, major_count do
                    if (majList[i] ~= nil) then
                        if (majList[i].leader ~= "LEADER_SPECTATOR") then
                            if RichNum >= 5 and ((avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2) > 1.0) then
                                __Debug("Tile balancing: Need to adjust: ", majList[i].leader, "Score:", (majList[i].best_tile + majList[i].best_tile_2), "Missing score:", (avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2))
                                if (IsMountainCiv(majList[i].leader)) then
                                    Terraforming_Best(Map.GetPlot(majList[i].plotX, majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 3)
                                elseif (majList[i].civ == "CIVILIZATION_EGYPT") then
                                    Terraforming_Best(Map.GetPlot(majList[i].plotX, majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 4)
                                elseif IsDesertCiv(majList[i].civ) then
                                    Terraforming_Best(Map.GetPlot(majList[i].plotX, majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 2)
                                elseif (IsTundraCiv(majList[i].civ)) then
                                    Terraforming_Best(Map.GetPlot(majList[i].plotX, majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 1)
                                else
                                    Terraforming_Best(Map.GetPlot(majList[i].plotX, majList[i].plotY), avg_best_tile_1, avg_best_tile_2, avg_best_tile_1 + avg_best_tile_2 - majList[i].best_tile - majList[i].best_tile_2, 0)
                                end
                            elseif RichNum < 5 and ((majList[i].best_tile + majList[i].best_tile_2) > ((avg_best_tile_1 + avg_best_tile_2) * (1 + dispersion_2))) then
                                __Debug("Tile balancing: Need to adjust Positive Outliers: ", majList[i].leader, "Score:", (majList[i].best_tile + majList[i].best_tile_2), "Need to Adjust:", math.max(math.floor(majList[i].best_tile + majList[i].best_tile_2 - avg_best_tile_1 - avg_best_tile_2), 1))
                                for k = 1, math.max(math.floor(majList[i].best_tile + majList[i].best_tile_2 - avg_best_tile_1 - avg_best_tile_2), 1) do
                                    local sPlot = Map.GetPlot(majList[i].plotX, majList[i].plotY)
                                    TerrainBuilder.SetFeatureType(sPlot, -1)
                                    if (sPlot:GetTerrainType() == 4) then
                                        TerrainBuilder.SetTerrainType(sPlot, sPlot:GetTerrainType() - 1);
                                        __Debug("Tile balancing: Need to adjust: ", majList[i].leader, "Start too strong: Remove Plain Hills on Starting Tile")
                                    else
                                        if RemoveFood(Map.GetPlot(majList[i].plotX, majList[i].plotY)) == true then
                                            __Debug("Tile balancing: Need to adjust: ", majList[i].leader, "Start too strong: Remove One Food")
                                        else
                                            __Debug("Tile balancing: Need to adjust: ", majList[i].leader, "Start too strong: Remove One Prod")
                                            RemoveProd(Map.GetPlot(majList[i].plotX, majList[i].plotY))
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                print("最佳单元格平衡 - Completed", os.date("%c"))
            end
            ---------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 完成
            ----------------------------------------------------------------------------------------------------------------------------------------------------------
            -- 一环港口位检查
            for i = 1, major_count do
                -- Added Spectator mod handling if a major player isn't detected
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        if (Map.GetPlot(majList[i].plotX, majList[i].plotY):IsCoastalLand() == true) then
                            __Debug("Coastal Terraforming Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                            Terraforming_Coastal(Map.GetPlot(majList[i].plotX, majList[i].plotY), iBalancingThree, true)
                        end
                    end
                end
            end

            -- 绿洲山？嗯，没有
            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    if IsDesertCiv(majList[i].civ) then
                        for j = 0, 60 do
                            local mali_plot = GetAdjacentTiles(Map.GetPlot(majList[i].plotX, majList[i].plotY), j) -- forgot the j!
                            if mali_plot ~= nil then
                                if (mali_plot:GetTerrainType() == 7 and mali_plot:GetFeatureType() == 4) then
                                    print("Oasis on Hills -----> Die")
                                    TerrainBuilder.SetTerrainType(mali_plot, 6);
                                    ResourceBuilder.SetResourceType(mali_plot, -1);
                                end
                            end
                        end
                    end
                end
            end

            -- 为所有人开局添加水源
            for i = 1, major_count do
                if (majList[i] ~= nil) then
                    if (majList[i].leader ~= "LEADER_SPECTATOR" and PlayerConfigurations[major_table[i]]:GetHandicapTypeID() ~= 2021024770) then
                        -- Check for freshwater
                        local wplot = Map.GetPlot(majList[i].plotX, majList[i].plotY)
                        if (wplot:IsCoastalLand() == false and wplot:IsWater() == false and wplot:IsRiver() == false and wplot:IsFreshWater() == false) then
                            print("添加淡水 Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ);
                            Terraforming_Water(Map.GetPlot(majList[i].plotX, majList[i].plotY));
                            -- 富饶系数如果大于5，所有人开局获得淡水
                        elseif (RichNum >= 5 and wplot:IsWater() == false and wplot:IsRiver() == false) then
                            print("TeamPVP 添加淡水 Start X: ", majList[i].plotX, "Start Y: ", majList[i].plotY, "Player: ", i, " ", majList[i].leader, majList[i].civ); -- put a print to catch the error in non debug mode
                            Terraforming_Water(Map.GetPlot(majList[i].plotX, majList[i].plotY));
                        end
                    end
                end
            end

            if (bBiasFail == true) then
                Game:SetProperty("BBS_SAFE_MODE", true)
            else
                Game:SetProperty("BBS_SAFE_MODE", false)
            end
        else
            print("BBS Script - Completed - Debug", os.date("%c"));
        end

        -- 重新绘制模型
        TerrainBuilder.AnalyzeChokepoints()
        -- 海岸 -> 湖泊
        AreaBuilder.Recalculate();
        -- UI 的标志
        Game:SetProperty("BBS_PLOT_HIDDEN", false)
        -- 修复火山错误
        for iPlotIndex = 0, Map.GetPlotCount() - 1, 1 do
            local pPlot = Map.GetPlotByIndex(iPlotIndex)
            if (pPlot:GetFeatureType() == g_FEATURE_VOLCANO) then
                local iPlotTerrain = pPlot:GetTerrainType()
                if GameInfo.Terrains[iPlotTerrain].Mountain == 1 then
                    TerrainBuilder.SetFeatureType(pPlot, 5)
                    ResourceBuilder.SetResourceType(pPlot, -1)
                end
            end
        end
    else
        __Debug("D TURN STARTING: Any other turn");
    end
end


-----------------------------------------------------------------------------------------------------------------------------------
-- 确保冻土补正只会补偿地图上已有的资源
-- 确保冻土补正只会补偿至多4种奢侈资源
function Tundra_Resource_Pick()
    TERRAIN_TUNDRA_RESOURCE = GetShuffledCopyOfTable(TERRAIN_TUNDRA_RESOURCE)
    TERRAIN_TUNDRA_HILLS_RESOURCE = GetShuffledCopyOfTable(TERRAIN_TUNDRA_HILLS_RESOURCE)
    for i = #TERRAIN_TUNDRA_RESOURCE, 1, -1 do
        if not MapHasResource(TERRAIN_TUNDRA_RESOURCE[i]) then
            table.remove(TERRAIN_TUNDRA_RESOURCE, i)
        end
    end
    for i = #TERRAIN_TUNDRA_HILLS_RESOURCE, 1, -1 do
        if not MapHasResource(TERRAIN_TUNDRA_HILLS_RESOURCE[i]) then
            table.remove(TERRAIN_TUNDRA_HILLS_RESOURCE, i)
        end
    end
    local LuxNum = 0
    for i = #TERRAIN_TUNDRA_RESOURCE, 1, -1 do
        if GameInfo.Resources[TERRAIN_TUNDRA_RESOURCE[i]].ResourceClassType == 'RESOURCECLASS_LUXURY' then
            if LuxNum >= 4 then
                table.remove(TERRAIN_TUNDRA_RESOURCE, i)
            else
                LuxNum = LuxNum + 1
            end
        end
    end
    LuxNum = 0
    for i = #TERRAIN_TUNDRA_HILLS_RESOURCE, 1, -1 do
        if GameInfo.Resources[TERRAIN_TUNDRA_HILLS_RESOURCE[i]].ResourceClassType == 'RESOURCECLASS_LUXURY' then
            if LuxNum >= 4 then
                table.remove(TERRAIN_TUNDRA_HILLS_RESOURCE, i)
            else
                LuxNum = LuxNum + 1
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------------------------
function EvaluateStartingLocation(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    local impassable = 0;
    local snow = 0;
    local water = 0;
    local desert = 0;
    local flood = 0;
    local hill = 0;
    local plains = 0;
    local flood_start = 0;
    local flood_inner = 0;
    local flood_outer = 0;
    local food_spawn_start = 0;
    local prod_spawn_start = 0;
    local food_spawn_inner = 0;
    local prod_spawn_inner = 0;
    local culture_spawn_start = 0;
    local faith_spawn_start = 0;
    local best_yield_start = 0;
    local impassable_start = 0;
    local snow_start = 0;
    local water_start = 0;
    local desert_start = 0;
    local hill_start = 0;
    local impassable_inner = 0;
    local snow_inner = 0;
    local water_inner = 0;
    local desert_inner = 0;
    local hill_inner = 0;
    local impassable_outer = 0;
    local snow_outer = 0;
    local water_outer = 0;
    local desert_outer = 0
    local type = "Standard"
    local gridWidth, gridHeight = Map.GetGridSize();
    local terrainType = plot:GetTerrainType();
    local iResourcesInDB = 0;
    local bCulture = false;
    local bFaith = false;
    local direction = 0;
    eResourceType = {};
    eResourceClassType = {};
    eRevealedEra = {};
    local count = 0;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local temp_tile = 0;
    local best_tile = 0;
    local second_best_tile = 0;
    local best_tile_inner = 0;
    local second_best_tile_inner = 0;

    -- EvalType 是结果表，将用作后续平衡操作的基础

    local EvalType = { impassable, water, snow, desert, food_spawn_start, prod_spawn_start, culture_spawn_start, faith_spawn_start, impassable_start, water_start, snow_start, desert_start, impassable_inner, water_inner, snow_inner, desert_inner, impassable_outer, water_outer, snow_outer, desert_outer }

    for row in GameInfo.Resources() do
        eResourceType[iResourcesInDB] = row.Hash;
        eResourceClassType[iResourcesInDB] = row.ResourceClassType;
        eRevealedEra[iResourcesInDB] = row.RevealedEra;
        iResourcesInDB = iResourcesInDB + 1;
    end
    -- Starting plot:
    -- Tile #-1
    for i = -1, 35 do
        --35
        adjacentPlot = GetAdjacentTiles(plot, i)
        if (adjacentPlot ~= nil) then
            terrainType = adjacentPlot:GetTerrainType();
            if (i == -1) then
                if (adjacentPlot:IsImpassable() == true) then
                    impassable = impassable + 1;
                end

                -- Checks to see if the plot is water
                if (adjacentPlot:IsWater() == true) then
                    water = water + 1;
                end

                -- Add to the Snow counter if snow shows up
                if (terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
                    snow = snow + 1;
                end

                -- Add to the hills counter if Hill shows up
                if adjacentPlot:IsHills() then
                    hill = hill + 1;
                end

                -- Add to the plains counter if Plain shows up
                if (terrainType == 3 or terrainType == 4) then
                    plains = plains + 1;
                end

                -- Add to the Desert counter if desert shows up
                if (terrainType == 6 or terrainType == 7) then
                    desert = desert + 1;
                end

                -- Add to Floodplains if they are showing up
                if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
                    flood = flood + 1;
                end
                -- Gets the food and production counts
                if (adjacentPlot:GetYield(g_YIELD_FOOD) >= 3
                        or (adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3
                        + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5) >= 2) then
                    food_spawn_start = food_spawn_start + adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                end

                if (adjacentPlot:GetYield(g_YIELD_FOOD) >= 4
                        or (adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3
                        + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5) >= 3) then
                    food_spawn_start = food_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                end

                bCulture = false;
                bFaith = false;
                for row = 0, iResourcesInDB do
                    if (eResourceClassType[row] == "RESOURCECLASS_LUXURY") then
                        if (adjacentPlot:GetResourceCount() > 0) then
                            -- Check for Coffee, Jade, Marble, Incense, dyes and clams
                            if (adjacentPlot:GetResourceType() == 12 or adjacentPlot:GetResourceType() == 20 or adjacentPlot:GetResourceType() == 21 or adjacentPlot:GetResourceType() == 49) then
                                bCulture = true;
                            elseif (adjacentPlot:GetResourceType() == 15 or adjacentPlot:GetResourceType() == 18 or adjacentPlot:GetResourceType() == 23) then
                                bFaith = true;
                            end
                        end
                    end
                end
                if (bCulture == true) then
                    culture_spawn_start = culture_spawn_start + 1;
                end
                if (bFaith == true) then
                    faith_spawn_start = faith_spawn_start + 1;
                end
                -- Starting ring
                -- Tiles #0 #5
            elseif (i > -1 and i < 6) then

                temp_tile = 0;

                if (adjacentPlot:IsImpassable() == true) then
                    impassable_start = impassable_start + 1;
                end

                -- Checks to see if the plot is water
                if (adjacentPlot:IsWater() == true) then
                    water_start = water_start + 1;
                end

                -- Add to the Snow counter if snow shows up
                if (terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
                    snow_start = snow_start + 1;
                end

                -- Add to the Desert counter if desert shows up
                if (terrainType == 6 or terrainType == 7) then
                    desert_start = desert_start + 1;
                end

                -- Add to the hills counter if Hill shows up
                if (terrainType == 1 or terrainType == 7 or terrainType == 4 or terrainType == 10) then
                    hill_start = hill_start + 1;
                end

                -- Add to the plains counter if Plain shows up
                if (terrainType == 3 or terrainType == 4) then
                    plains = plains + 1;
                end

                -- Add to Floodplains if they are showing up
                if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
                    flood_start = flood_start + 1;
                end

                -- Gets the food and production counts
                food_spawn_start = food_spawn_start + adjacentPlot:GetYield(g_YIELD_FOOD);
                prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_SCIENCE);
                prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_CULTURE);
                prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                prod_spawn_start = prod_spawn_start + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67

                temp_tile = adjacentPlot:GetYield(g_YIELD_FOOD)
                if temp_tile > 1 then
                    temp_tile = temp_tile + adjacentPlot:GetYield(g_YIELD_PRODUCTION) * 1.5 + adjacentPlot:GetYield(g_YIELD_GOLD) * 0.5;
                else
                    -- not enough food to value those tiles fully
                    temp_tile = temp_tile + adjacentPlot:GetYield(g_YIELD_PRODUCTION) * 0.75 + adjacentPlot:GetYield(g_YIELD_GOLD) * 0.25;
                end

                -- Adjust for non discovered resources
                if (adjacentPlot:GetResourceType() ~= -1) then
                    if (adjacentPlot:GetResourceType() == RESOURCE_COAL_INDEX or adjacentPlot:GetResourceType() == RESOURCE_URANIUM_INDEX or adjacentPlot:GetResourceType() == RESOURCE_IRON_INDEX) then
                        temp_tile = temp_tile - 2 * 1.5
                        food_spawn_start = food_spawn_start - adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    elseif (adjacentPlot:GetResourceType() == RESOURCE_HORSES_INDEX or adjacentPlot:GetResourceType() == RESOURCE_NITER_INDEX) then
                        temp_tile = temp_tile - 1 * 1.5 - 1
                        food_spawn_start = food_spawn_start - adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    elseif (adjacentPlot:GetResourceType() == RESOURCE_OIL_INDEX) then
                        temp_tile = temp_tile - 3 * 1.5
                        food_spawn_start = food_spawn_start - adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    elseif (RESOURCE_LEY_LINE_INDEX >= 0 and adjacentPlot:GetResourceType() == RESOURCE_LEY_LINE_INDEX) then
                        --地脉
                        food_spawn_start = food_spawn_start - 1.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_start = prod_spawn_start - 1.1 * adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_start = prod_spawn_start - 1.1 * adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_start = prod_spawn_start - 1.1 * adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_start = prod_spawn_start - 1.1 * adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_start = prod_spawn_start - 1.1 * adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    end
                end
                --陆地食物+产出大于等于4
                if (adjacentPlot:GetYield(g_YIELD_FOOD) >= 4 and adjacentPlot:GetTerrainType() ~= 15) then
                    food_spawn_start = food_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                end
                --陆地食物+产出小于等于3.5 不计入总分
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3
                        + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5) <= 3.5 and adjacentPlot:GetTerrainType() ~= 15) then
                    --food_spawn_start=food_spawn_start-0.1;
                    food_spawn_start = food_spawn_start - adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                end
                --海洋单元格
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) <= 3 and adjacentPlot:GetTerrainType() == 15) then
                    food_spawn_start = food_spawn_start - adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_start = prod_spawn_start - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    --prod_spawn_start = prod_spawn_start - 0.5;--产出补算
                end

                --产出大于等于5
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3
                        + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5) >= 5 and adjacentPlot:GetTerrainType() ~= 15) then
                    food_spawn_start = food_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                end

                --海洋单元格
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) >= 4 and adjacentPlot:GetTerrainType() == 15) then
                    food_spawn_start = food_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_start = prod_spawn_start + 0.1 * adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    prod_spawn_start = prod_spawn_start + 0.5;--产出补算 锤
                end
                --
                --海洋单元格 产出补算
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) > 3 and
                        (adjacentPlot:GetYield(g_YIELD_FOOD)
                                + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                                + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                                + adjacentPlot:GetYield(g_YIELD_CULTURE)
                                + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) < 4 and adjacentPlot:GetTerrainType() == 15) then
                    prod_spawn_start = prod_spawn_start + 0.5;--产出补算 锤
                end
                bCulture = false;
                bFaith = false;
                if (adjacentPlot:GetResourceType() ~= -1) then
                    -- Check for Coffee, Jade, Marble, Incense, Silk, dyes and clams
                    if (adjacentPlot:GetResourceType() == 12 or adjacentPlot:GetResourceType() == 20 or adjacentPlot:GetResourceType() == 21 or adjacentPlot:GetResourceType() == 25 or adjacentPlot:GetResourceType() == 49) then
                        bCulture = true;
                    elseif (adjacentPlot:GetResourceType() == 15 or adjacentPlot:GetResourceType() == 18 or adjacentPlot:GetResourceType() == 23) then
                        bFaith = true;
                    end
                end

                if (bCulture == true) then
                    culture_spawn_start = culture_spawn_start + 1;
                    if adjacentPlot:GetYield(g_YIELD_PRODUCTION) > 0 then
                        temp_tile = temp_tile + 2;
                    else
                        temp_tile = temp_tile + 1;
                    end
                end
                if (bFaith == true) then
                    faith_spawn_start = faith_spawn_start + 1;
                    if adjacentPlot:GetYield(g_YIELD_PRODUCTION) > 0 then
                        temp_tile = temp_tile + 1.5;
                    else
                        temp_tile = temp_tile + 0.5;
                    end
                end
                if (temp_tile > best_tile or temp_tile == best_tile) then
                    second_best_tile = best_tile
                    best_tile = temp_tile
                else
                    if (temp_tile > second_best_tile and temp_tile < best_tile) then
                        second_best_tile = temp_tile
                    end
                end
                temp_tile = 0
                -- Inner ring
                -- Tiles #6 to #17
            elseif (i > 5 and i < 18) then

                -- Checks to see if the plot is impassable
                if (adjacentPlot:IsImpassable() == true) then
                    impassable_inner = impassable_inner + 1;
                end

                -- Checks to see if the plot is water
                if (adjacentPlot:IsWater() == true) then
                    water_inner = water_inner + 1;
                end

                -- Add to the Snow counter if snow shows up
                if (terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
                    snow_inner = snow_inner + 1;
                end

                -- Add to the hills counter if Hill shows up
                if (terrainType == 1 or terrainType == 7 or terrainType == 4 or terrainType == 10) then
                    hill_inner = hill_inner + 1;
                end

                -- Add to the plains counter if Plain shows up
                if (terrainType == 3 or terrainType == 4) then
                    plains = plains + 1;
                end

                -- Add to Floodplains if they are showing up
                if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
                    flood_inner = flood_inner + 1;
                end

                -- Add to the Desert counter if desert shows up
                if (terrainType == 6 or terrainType == 7) then
                    desert_inner = desert_inner + 1;
                end

                -- Gets the food and production counts
                food_spawn_inner = food_spawn_inner + adjacentPlot:GetYield(g_YIELD_FOOD);
                prod_spawn_inner = prod_spawn_inner + adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                prod_spawn_inner = prod_spawn_inner + adjacentPlot:GetYield(g_YIELD_SCIENCE);
                prod_spawn_inner = prod_spawn_inner + adjacentPlot:GetYield(g_YIELD_CULTURE);
                prod_spawn_inner = prod_spawn_inner + adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                prod_spawn_inner = prod_spawn_inner + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                temp_tile = adjacentPlot:GetYield(g_YIELD_FOOD)

                if temp_tile > 1 then
                    temp_tile = temp_tile + adjacentPlot:GetYield(g_YIELD_PRODUCTION) * 1.5 + adjacentPlot:GetYield(g_YIELD_GOLD) * 0.5;
                else
                    -- not enough food to value those tiles fully
                    temp_tile = temp_tile + adjacentPlot:GetYield(g_YIELD_PRODUCTION) * 0.75 + adjacentPlot:GetYield(g_YIELD_GOLD) * 0.25;
                end

                -- Adjust for non discovered resources
                if (adjacentPlot:GetResourceType() ~= -1) then
                    if (adjacentPlot:GetResourceType() == RESOURCE_COAL_INDEX or adjacentPlot:GetResourceType() == RESOURCE_URANIUM_INDEX or adjacentPlot:GetResourceType() == RESOURCE_IRON_INDEX) then
                        temp_tile = temp_tile - 2 * 1.5
                        food_spawn_inner = food_spawn_inner - adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    elseif (adjacentPlot:GetResourceType() == RESOURCE_HORSES_INDEX or adjacentPlot:GetResourceType() == RESOURCE_NITER_INDEX) then
                        temp_tile = temp_tile - 1 * 1.5 - 1
                        food_spawn_inner = food_spawn_inner - adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    elseif (adjacentPlot:GetResourceType() == RESOURCE_OIL_INDEX) then
                        temp_tile = temp_tile - 3 * 1.5
                        food_spawn_inner = food_spawn_inner - adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    elseif (RESOURCE_LEY_LINE_INDEX >= 0 and adjacentPlot:GetResourceType() == RESOURCE_LEY_LINE_INDEX) then
                        --地脉
                        food_spawn_inner = food_spawn_inner - 1.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                        prod_spawn_inner = prod_spawn_inner - 1.1 * adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                        prod_spawn_inner = prod_spawn_inner - 1.1 * adjacentPlot:GetYield(g_YIELD_SCIENCE);
                        prod_spawn_inner = prod_spawn_inner - 1.1 * adjacentPlot:GetYield(g_YIELD_CULTURE);
                        prod_spawn_inner = prod_spawn_inner - 1.1 * adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                        prod_spawn_inner = prod_spawn_inner - 1.1 * adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    end
                end
                --陆地食物+产出大于等于4
                if (adjacentPlot:GetYield(g_YIELD_FOOD) >= 4 and adjacentPlot:GetTerrainType() ~= 15) then
                    food_spawn_inner = food_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                end
                --陆地食物+产出小于等于3 不计入总分
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3
                        + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5) <= 3.5 and adjacentPlot:GetTerrainType() ~= 15) then
                    --food_spawn_start=food_spawn_start-0.1;
                    food_spawn_inner = food_spawn_inner - adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                end
                --海洋单元格
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) <= 3 and adjacentPlot:GetTerrainType() == 15) then
                    food_spawn_inner = food_spawn_inner - adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_inner = prod_spawn_inner - adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    --prod_spawn_start = prod_spawn_start - 0.5;--产出补算
                end

                --产出大于等于5
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3
                        + adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5) >= 5 and adjacentPlot:GetTerrainType() ~= 15) then
                    food_spawn_inner = food_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                end

                --海洋单元格
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) >= 4 and adjacentPlot:GetTerrainType() == 15) then
                    food_spawn_inner = food_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_FOOD);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_PRODUCTION);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_SCIENCE);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_CULTURE);
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_GOLD) / 3;--0.5
                    prod_spawn_inner = prod_spawn_inner + 0.1 * adjacentPlot:GetYield(g_YIELD_FAITH) / 1.5;--0,67
                    prod_spawn_inner = prod_spawn_inner + 0.5;--产出补算 锤
                end
                --
                --海洋单元格 产出补算
                if ((adjacentPlot:GetYield(g_YIELD_FOOD)
                        + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                        + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                        + adjacentPlot:GetYield(g_YIELD_CULTURE)
                        + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) > 3 and
                        (adjacentPlot:GetYield(g_YIELD_FOOD)
                                + adjacentPlot:GetYield(g_YIELD_PRODUCTION)
                                + adjacentPlot:GetYield(g_YIELD_SCIENCE)
                                + adjacentPlot:GetYield(g_YIELD_CULTURE)
                                + adjacentPlot:GetYield(g_YIELD_GOLD) / 3) < 4 and adjacentPlot:GetTerrainType() == 15) then
                    prod_spawn_start = prod_spawn_start + 0.5;--产出补算 锤
                end
                bCulture = false;
                bFaith = false;
                if (adjacentPlot:GetResourceType() ~= -1) then
                    -- Check for Coffee, Jade, Marble, Incense, Silk, dyes and clams
                    if (adjacentPlot:GetResourceType() == 12 or adjacentPlot:GetResourceType() == 20 or adjacentPlot:GetResourceType() == 21 or adjacentPlot:GetResourceType() == 25 or adjacentPlot:GetResourceType() == 49) then
                        bCulture = true;
                    elseif (adjacentPlot:GetResourceType() == 15 or adjacentPlot:GetResourceType() == 18 or adjacentPlot:GetResourceType() == 23) then
                        bFaith = true;
                    end
                end

                if (bCulture == true) then
                    culture_spawn_start = culture_spawn_start + 1;
                    if adjacentPlot:GetYield(g_YIELD_PRODUCTION) > 0 then
                        temp_tile = temp_tile + 2;
                    else
                        temp_tile = temp_tile + 1;
                    end
                end
                if (bFaith == true) then
                    faith_spawn_start = faith_spawn_start + 1;
                    if adjacentPlot:GetYield(g_YIELD_PRODUCTION) > 0 then
                        temp_tile = temp_tile + 1.5;
                    else
                        temp_tile = temp_tile + 0.5;
                    end
                end
                if (temp_tile > best_tile_inner or temp_tile == best_tile_inner) then
                    second_best_tile_inner = best_tile_inner
                    best_tile_inner = temp_tile
                else
                    if (temp_tile > second_best_tile_inner and temp_tile < best_tile_inner) then
                        second_best_tile_inner = temp_tile
                    end
                end
                temp_tile = 0

                -- Outer ring
                -- Tiles #18 to #35
            elseif (i > 17 and i < 35) then

                if (adjacentPlot:IsImpassable() == true) then
                    impassable_outer = impassable_outer + 1;
                end

                -- Checks to see if the plot is water
                if (adjacentPlot:IsWater() == true) then
                    water_outer = water_outer + 1;
                end

                -- Add to the Snow counter if snow shows up
                if (terrainType == 9 or terrainType == 10 or terrainType == 12 or terrainType == 13) then
                    snow_outer = snow_outer + 1;
                end

                -- Add to the Desert counter if desert shows up
                if (terrainType == 6 or terrainType == 7) then
                    desert_outer = desert_outer + 1;
                end

                -- Add to Floodplains if they are showing up
                if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) then
                    flood_outer = flood_outer + 1;
                end


            end
        end
    end

    impassable = impassable + impassable_start + impassable_inner + impassable_outer
    water = water + water_start + water_inner + water_outer
    snow = snow + snow_start + snow_inner + snow_outer
    flood = flood + flood_start + flood_inner --+ flood_outer
    desert = desert + desert_start + desert_inner + desert_outer
    hill = hill + hill_start + hill_inner
    __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Total mountain: ", impassable, "Total water: ", water, "Total snow: ", snow, "Total desert: ", desert, "Total hill", hill, "Immediate Food: ", food_spawn_start, "Immediate Prod: ", prod_spawn_start, "Immediate Culture: ", culture_spawn_start, "Immediate Faith: ", faith_spawn_start, "Floodplains", flood, "Best_tile", best_tile, "Best_tile_2", second_best_tile, "Plains Tiles", plains)
    EvalType = { impassable, water, snow, desert, food_spawn_start, prod_spawn_start, culture_spawn_start, faith_spawn_start, impassable_start, water_start, snow_start, desert_start, impassable_inner, water_inner, snow_inner, desert_inner, impassable_outer, water_outer, snow_outer, desert_outer, flood, hill_start, hill_inner, best_tile, second_best_tile, food_spawn_inner, prod_spawn_inner, best_tile_inner, second_best_tile_inner, plains }
    return EvalType
end

------------------------------------------------------------------------------------------------------------------------------------------------

function AddBonusFood(plot, intensity, flag, majListCiv)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    eResourceType = {};
    eResourceClassType = {};
    aBonus = {};
    local limit_1 = 0;
    local max_unFeature = 2;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local count = 0;
    local increment = 1;
    local start_range = 1;
    local end_range = 5;
    --方法变量
    local rngAdd = 0;--成功率附加
    local rngAddBlock = 14;--成功率附加每次失败递增
    local unSetrng = 0.5;--单元格基础失败率

    local rngSet = 0;--选择资源类型随机数，临时变量

    if (intensity == 0) then
        limit_1 = 0.9;
    else
        limit_1 = 0.5 / intensity;
    end

    for k = 0, 1 do

        if k == 0 then
            if (flag == 2 or flag == 1) then
                start_range = 1;
                end_range = 17;
                increment = 2;
            else
                start_range = 1;
                end_range = 17;--5
                increment = 1;
            end
        elseif k == 1 then
            if (flag == 2 or flag == 1) then
                start_range = 17;
                end_range = 1;
                increment = -1;
            else
                start_range = 1;
                end_range = 17;--5
                increment = 1;
            end
        end

        for i = start_range, end_range, increment do
            adjacentPlot = GetAdjacentTiles(plot, i)

            if (adjacentPlot ~= nil) then

                terrainType = adjacentPlot:GetTerrainType();

                if (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:IsNaturalWonder() == false) then

                    rng = (TerrainBuilder.GetRandomNumber(100, "test") + rngAdd) / 100;

                    --关联特殊处理
                    local civAddRng = 0;

                    --猎场
                    civAddRng = 0;
                    if (IsHuntCiv(majListCiv)) then
                        civAddRng = 1;

                        if (addHuntCount < 1 and (terrainType == 9 or terrainType == 10 or (adjacentPlot:GetFeatureType() == 3)) and adjacentPlot:GetResourceType() == -1) then
                            -- Deer
                            if (rng + civAddRng > unSetrng) then
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 4)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 4, 1);
                                    print("IsHuntCiv Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Deer");
                                    rngAdd = 0;
                                    addHuntCount = addHuntCount + 1;
                                    return true;
                                end
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end

                        end
                    end
                    --羊
                    civAddRng = 0;
                    if (IsPastureCiv(majListCiv)) then
                        civAddRng = 1;

                        if ((terrainType == 4 and adjacentPlot:GetFeatureType() == -1)
                                or (terrainType == 1 and adjacentPlot:GetFeatureType() == -1)
                                or (terrainType == 7 and adjacentPlot:GetFeatureType() == -1)
                                or (terrainType == 10 and adjacentPlot:GetFeatureType() == -1)) and addFoodSheepCount < 2 and adjacentPlot:IsNaturalWonder() == false then
                            -- sheep
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 7)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
                                    print("IsPastureCiv Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep");
                                    rngAdd = 0;
                                    addFoodSheepCount = addFoodSheepCount + 1;
                                    print("IsPastureCiv teamPVP addFoodSheepCount:", addFoodSheepCount);
                                    return true;
                                end
                            end
                        end
                    end
                    --雨林
                    civAddRng = 0;
                    if (IsJungleCiv(majListCiv)) then
                        civAddRng = 1;

                        if (addJungleCount < 5 and terrainType == 4 and adjacentPlot:GetFeatureType() == -1) and adjacentPlot:IsNaturalWonder() == false then
                            -- 黄地雨林
                            if (rng + 0.3 + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return true;
                            end
                        end

                        if (addJungleCount < 5 and terrainType == 1 and adjacentPlot:GetFeatureType() == -1) and adjacentPlot:IsNaturalWonder() == false then
                            -- 绿地丘陵-》黄地雨林
                            if (rng + 0.3 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert1 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return true;
                            end
                        end

                        if (addJungleCount < 5 and terrainType == 4 and adjacentPlot:GetFeatureType() == 3) and adjacentPlot:IsNaturalWonder() == false then
                            -- 黄地丘陵森林-》雨林
                            if (rng + 0.3 + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert2 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                --return true;继续执行补贴
                            end
                        end

                        if (addJungleCount < 5 and terrainType == 1 and adjacentPlot:GetFeatureType() == 3) and adjacentPlot:IsNaturalWonder() == false then
                            -- 黄地丘陵森林-》雨林
                            if (rng + 0.3 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                --return true;继续执行补贴
                            end
                        end
                    end
                    --森林
                    civAddRng = 0;
                    if (IsForestCiv(majListCiv)) then
                        civAddRng = 1;

                        if (addForestCount < 5 and adjacentPlot:GetResourceCount() < 1 and (terrainType == 1 or terrainType == 4) and (adjacentPlot:GetFeatureType() == -1) and (adjacentPlot:IsImpassable() == false) and (adjacentPlot:IsWater() == false) and (adjacentPlot:GetTerrainType() ~= 6) and (adjacentPlot:GetTerrainType() ~= 7) and (adjacentPlot:GetTerrainType() ~= 12) and (adjacentPlot:GetTerrainType() ~= 13)) then

                            if (rng + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                if not adjacentPlot:IsHills() then
                                    TerrainBuilder.SetTerrainType(adjacentPlot, adjacentPlot:GetTerrainType() + 1)
                                end
                                print("IsForestCiv Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Wood");
                                addForestCount = addForestCount + 1;
                                return true;
                            end
                        end
                    end
                    --森林+雨林
                    civAddRng = 0;
                    if (IsForestAndJungleCiv(majListCiv)) then
                        civAddRng = 1;

                        if (addForestCount < 2 and adjacentPlot:GetResourceCount() < 1 and (terrainType == 1 or terrainType == 4) and (adjacentPlot:GetFeatureType() == -1) and (adjacentPlot:IsImpassable() == false) and (adjacentPlot:IsWater() == false) and (adjacentPlot:GetTerrainType() ~= 6) and (adjacentPlot:GetTerrainType() ~= 7) and (adjacentPlot:GetTerrainType() ~= 12) and (adjacentPlot:GetTerrainType() ~= 13)) then

                            if (rng + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                if not adjacentPlot:IsHills() then
                                    TerrainBuilder.SetTerrainType(adjacentPlot, adjacentPlot:GetTerrainType() + 1)
                                end
                                print("IsForestCiv Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Wood");
                                addForestCount = addForestCount + 1;
                                return true;
                            end
                        end

                        if (addJungleCount < 3 and terrainType == 4 and adjacentPlot:GetFeatureType() == -1) and adjacentPlot:IsNaturalWonder() == false then
                            -- 黄地雨林
                            if (rng + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return true;
                            end
                        end
                    end
                    --香蕉
                    civAddRng = 0;
                    if (IsBananaCiv(majListCiv)) then
                        civAddRng = 1;

                        if (addBananaCount < 2 and terrainType == 3 and (adjacentPlot:GetFeatureType() == 3 or adjacentPlot:GetFeatureType() == 2 or adjacentPlot:GetFeatureType() == -1)) then
                            --平原\树-》平原雨林 然后加香蕉
                            --或者本身就可以加
                            if (rng + civAddRng + rngAdd > unSetrng) then
                                if (adjacentPlot:GetFeatureType() == 3 or adjacentPlot:GetFeatureType() == -1) then
                                    TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                end
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 0)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 0, 1);
                                    print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Banana");
                                    rngAdd = 0;
                                    addBananaCount = addBananaCount + 1;
                                    return true;
                                end
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end
                        end

                        if (addBananaCount < 2 and (terrainType == 0 and (adjacentPlot:GetFeatureType() == 3 or adjacentPlot:GetFeatureType() == -1))) then
                            --草原\树-》平原雨林 然后加香蕉
                            if (rng + civAddRng + rngAdd > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 0)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 0, 1);
                                    print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Banana");
                                    rngAdd = 0;
                                    addBananaCount = addBananaCount + 1;
                                    return true;
                                end
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end
                        end
                    end
                    --


                    if (terrainType == 3 and adjacentPlot:GetFeatureType() == g_FEATURE_JUNGLE) then
                        --banana
                        if (rng > unSetrng) then
                            if (ResourceBuilder.CanHaveResource(adjacentPlot, 0)) then
                                ResourceBuilder.SetResourceType(adjacentPlot, 0, 1);
                                print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Banana");
                                addBananaCount = addBananaCount + 1;
                                rngAdd = 0;
                                return true;
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif ((terrainType == 4 and adjacentPlot:GetFeatureType() == -1)
                            or (terrainType == 1 and adjacentPlot:GetFeatureType() == -1)
                            or (terrainType == 7 and adjacentPlot:GetFeatureType() == -1)
                            or (terrainType == 10 and adjacentPlot:GetFeatureType() == -1)) and addFoodSheepCount < 2 and adjacentPlot:IsNaturalWonder() == false then
                        -- sheep
                        if (rng + 0.15 > unSetrng) then
                            if (ResourceBuilder.CanHaveResource(adjacentPlot, 7)) then
                                ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
                                __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep");
                                rngAdd = 0;
                                addFoodSheepCount = addFoodSheepCount + 1;
                                print("teamPVP addFoodSheepCount:", addFoodSheepCount);
                                return true;
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock
                        end

                    elseif (terrainType == 6 and adjacentPlot:GetFeatureType() == -1) and adjacentPlot:IsNaturalWonder() == false then
                        -- Desert Sheep on Hill
                        TerrainBuilder.SetTerrainType(adjacentPlot, 7);
                        ResourceBuilder.SetResourceType(adjacentPlot, 7, 1); -- 不添加沙漠羊
                        __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep on Desert Hill");
                        return true;
                    elseif (terrainType == 4 and adjacentPlot:GetFeatureType() == -1) and adjacentPlot:IsNaturalWonder() == false then
                        -- 雨林
                        if (rng + 0.3 > unSetrng) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                            print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                            rngAdd = 0;
                            return true;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif (terrainType == 0 and addRiceCount < 1 and adjacentPlot:GetFeatureType() == -1) and adjacentPlot:IsNaturalWonder() == false then
                        -- Add Cattle / Rice
                        if (rng - 0.15 > unSetrng) then
                            if (ResourceBuilder.CanHaveResource(adjacentPlot, 1)) then
                                ResourceBuilder.SetResourceType(adjacentPlot, 1, 1);
                                __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Cattle");
                                rngAdd = 0;
                                addRiceCount = addRiceCount + 1;
                                print("teamPVP addRiceCount:", addRiceCount);
                                return true;
                            else
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 6)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 6, 1);
                                    __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Rice");
                                    rngAdd = 0;
                                    addRiceCount = addRiceCount + 1;
                                    print("teamPVP addRiceCount:", addRiceCount);
                                    return true;
                                end
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end


                    elseif (terrainType == 3 and addRiceCount < 1 and adjacentPlot:GetFeatureType() == -1) and adjacentPlot:IsNaturalWonder() == false then

                        if (rng > unSetrng) then
                            rngSet = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                            if (rngSet > 0.5) then
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 9)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 9, 1);
                                    __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Wheat");
                                    ngAdd = 0;
                                    addRiceCount = addRiceCount + 1;
                                    print("teamPVP addRiceCount:", addRiceCount);
                                    return true;
                                else
                                    if (ResourceBuilder.CanHaveResource(adjacentPlot, 52)) then
                                        ResourceBuilder.SetResourceType(adjacentPlot, 52, 1);
                                        __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Maize");
                                        rngAdd = 0;
                                        addRiceCount = addRiceCount + 1;
                                        print("teamPVP addRiceCount:", addRiceCount);
                                        return true;
                                    end
                                end
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif (terrainType == 6 and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() < 1) then
                        -- Oasis
                        local bOasis = true
                        for j = 0, 5 do
                            adjacentPlot2 = GetAdjacentTiles(adjacentPlot, j)
                            if (adjacentPlot2 ~= nil) then
                                if (adjacentPlot2:GetTerrainType() ~= 6 and adjacentPlot2:GetTerrainType() ~= 7 and adjacentPlot2:GetTerrainType() ~= 8 or adjacentPlot2:GetFeatureType() == g_FEATURE_OASIS) then
                                    bOasis = false
                                end
                            end

                        end
                        --rng = TerrainBuilder.GetRandomNumber(100,"test")/100;
                        if (rng > unSetrng) then
                            rngSet = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                            if (bOasis == true and rngSet > 0.75) then
                                ResourceBuilder.SetResourceType(adjacentPlot, -1);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 4);
                                __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Oasis");
                                return true;
                            else
                                --生成沙漠丘陵
                                TerrainBuilder.SetTerrainType(adjacentPlot, 7);
                                ResourceBuilder.SetResourceType(adjacentPlot, -1);
                                TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif (addFoodSheepCount < 2 and (terrainType == 3 and adjacentPlot:GetFeatureType() == 3 and adjacentPlot:IsNaturalWonder() == false)) then
                        -- sheep instead of forest
                        if (rng + 0.15 > unSetrng) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                            ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
                            addFoodSheepCount = addFoodSheepCount + 1;
                            print("teamPVP addFoodSheepCount:", addFoodSheepCount);
                            __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep on Plains Hills");
                            rngAdd = 0;
                            return true;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif (terrainType == 15 and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:IsFreshWater() == false and adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX) then

                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                        if (rng > unSetrng and adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX) then
                            -- Reef

                            __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Reef");
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_REEF);
                            rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;

                            return true;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif (terrainType == 15 and resourcesFishCount < 3) and adjacentPlot:IsNaturalWonder() == false then
                        -- fish
                        if (rng > unSetrng) then
                            if (ResourceBuilder.CanHaveResource(adjacentPlot, RESOURCE_FISH_INDEX)) then
                                ResourceBuilder.SetResourceType(adjacentPlot, RESOURCE_FISH_INDEX, 1);
                                __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Fish");
                                rngAdd = 0;
                                resourcesFishCount = resourcesFishCount + 1;
                                return true;
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end

                    end
                else
                    rngAdd = rngAdd + rngAddBlock;
                end
            end

            if (adjacentPlot ~= nil) then
                terrainType = adjacentPlot:GetTerrainType();
                if ((terrainType == 6 and flag == 2 and adjacentPlot:IsRiver() == true and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() < 1)) and adjacentPlot:IsNaturalWonder() == false then
                    -- Add Desert Floodplains
                    TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                    __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Turned the tile to a Desert Floodplains");
                    return true;
                end

                if (flag ~= 2 and flag ~= 1 and (terrainType == 2 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 5 and flag ~= 3 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 8 and flag ~= 3 and flag ~= 2 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 11 and flag ~= 3 and flag ~= 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) or (terrainType == 14 and flag ~= 3 and flag ~= 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) and adjacentPlot:GetResourceCount() < 1) and adjacentPlot:IsNaturalWonder() == false then
                    -- Convert to Flatland or Hills
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if rng > 0.80 and (terrainType == 2 or terrainType == 5) then
                        TerrainBuilder.SetTerrainType(adjacentPlot, terrainType - 1);
                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                        __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Turned the Grass Mountain to a Flat land with stones");
                        return true;
                    elseif rng > 0.70 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, terrainType - 1);
                        __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Turned the Mountain to a Hill");
                        return true
                    end
                end
            end
        end
    end
    __Debug("Food balancing: Couldn't add Food Bonus");
    return false;
end
------------------------------------------------------------------------------------------------------------------------------------------------

function AddBonusBind(plot, intensity, flag, majListCiv)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    eResourceType = {};
    eResourceClassType = {};
    aBonus = {};
    local limit_1 = 0;
    local max_unFeature = 2;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local count = 0;
    local increment = 1;
    local start_range = 1;
    local end_range = 5;
    --方法变量
    local rngAdd = 0;--成功率附加
    local rngAddBlock = 14;--成功率附加每次失败递增
    local unSetrng = 0.5;--单元格基础失败率

    local rngSet = 0;--选择资源类型随机数，临时变量

    if (intensity == 0) then
        limit_1 = 0.9;
    else
        limit_1 = 0.5 / intensity;
    end

    for k = 0, 1 do

        if k == 0 then
            if (flag == 2 or flag == 1) then
                start_range = 1;
                end_range = 17;
                increment = 2;
            else
                start_range = 1;
                end_range = 17;--5
                increment = 1;
            end
        elseif k == 1 then
            if (flag == 2 or flag == 1) then
                start_range = 17;
                end_range = 1;
                increment = -1;
            else
                start_range = 1;
                end_range = 17;--5
                increment = 1;
            end
        end

        for i = start_range, end_range, increment do
            adjacentPlot = GetAdjacentTiles(plot, i)

            if (adjacentPlot ~= nil) then

                terrainType = adjacentPlot:GetTerrainType();

                if (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:IsNaturalWonder() == false) then

                    local rng = (TerrainBuilder.GetRandomNumber(100, "test") + rngAdd) / 100;

                    --关联特殊处理
                    local civAddRng = 0;

                    --猎场
                    if (IsHuntCiv(majListCiv)) then
                        if (addHuntCount >= 1) then
                            return functionResultSuccess;
                        end
                        if (addHuntCount < 1 and (adjacentPlot:GetFeatureType() == 3)) then
                            -- Deer
                            if (rng + civAddRng > unSetrng) then
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 4)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 4, 1);
                                    print("IsHuntCiv Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Deer");
                                    rngAdd = 0;
                                    addHuntCount = addHuntCount + 1;
                                    return functionResultTrue;
                                end
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end
                    end
                    --羊
                    if (IsPastureCiv(majListCiv)) then
                        if (addFoodSheepCount >= 2) then
                            return functionResultSuccess;
                        end
                        if ((terrainType == 4 and adjacentPlot:GetFeatureType() == 3 or (adjacentPlot:GetFeatureType() == 2))
                                or (terrainType == 1 and adjacentPlot:GetFeatureType() == 3)
                                or (terrainType == 7 and adjacentPlot:GetFeatureType() == 3)) and addFoodSheepCount < 2 then
                            -- sheep
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                local tempGetFeatureType = adjacentPlot:GetFeatureType();
                                TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 7)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
                                    print("IsPastureCiv Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep");
                                    rngAdd = 0;
                                    addFoodSheepCount = addFoodSheepCount + 1;
                                    print("IsPastureCiv teamPVP addFoodSheepCount:", addFoodSheepCount);
                                    return functionResultTrue;
                                else
                                    --如果失败 则回退
                                    TerrainBuilder.SetFeatureType(adjacentPlot, tempGetFeatureType);
                                end
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end
                    end
                    --雨林
                    if (IsJungleCiv(majListCiv)) then
                        if (addJungleCount >= 5) then
                            return functionResultSuccess;
                        end
                        if (addJungleCount < 5 and terrainType == 4 and adjacentPlot:GetFeatureType() == 3) then
                            -- 黄地丘陵森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert2 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addJungleCount < 5 and terrainType == 3 and adjacentPlot:GetFeatureType() == 3) then
                            -- 黄地森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addJungleCount < 5 and terrainType == 1 and adjacentPlot:GetFeatureType() == 3) then
                            -- 绿地丘陵森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addJungleCount < 5 and terrainType == 0 and adjacentPlot:GetFeatureType() == 3) then
                            -- 绿地森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end
                    end
                    --森林
                    if (IsForestCiv(majListCiv)) then
                        if (addForestCount >= 5) then
                            return functionResultSuccess;
                        end
                        if (addForestCount < 5 and terrainType == 4 and adjacentPlot:GetFeatureType() == 2) then
                            -- 黄地丘陵雨林-》绿地森林
                            if (rng + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                print("IsForestCiv Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Wood");
                                addForestCount = addForestCount + 1;
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addForestCount < 5 and terrainType == 3 and adjacentPlot:GetFeatureType() == 2) then
                            -- 黄地雨林-》绿地森林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 0);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addForestCount = addForestCount + 1;
                                print("IsJungleCiv teamPVP addForestCount:", addForestCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end
                    end
                    --森林+雨林
                    if (IsForestAndJungleCiv(majListCiv)) then
                        if (addForestCount >= 2 and addJungleCount >= 3) then
                            return functionResultSuccess;
                        end
                        if (addJungleCount < 3 and terrainType == 4 and adjacentPlot:GetFeatureType() == 3) then
                            -- 黄地丘陵森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert2 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addJungleCount < 23 and terrainType == 3 and adjacentPlot:GetFeatureType() == 3) then
                            -- 黄地森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addJungleCount < 3 and terrainType == 1 and adjacentPlot:GetFeatureType() == 3) then
                            -- 绿地丘陵森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addJungleCount < 3 and terrainType == 0 and adjacentPlot:GetFeatureType() == 3) then
                            -- 绿地森林-》雨林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addJungleCount = addJungleCount + 1;
                                print("IsJungleCiv teamPVP addJungleCount:", addJungleCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end

                        if (addForestCount < 2 and terrainType == 4 and adjacentPlot:GetFeatureType() == 2) then
                            -- 黄地丘陵雨林-》绿地森林
                            if (rng + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                print("IsForestCiv Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Wood");
                                addForestCount = addForestCount + 1;
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        elseif (addForestCount < 2 and terrainType == 3 and adjacentPlot:GetFeatureType() == 2) then
                            -- 黄地雨林-》绿地森林
                            if (rng + 0.15 + civAddRng > unSetrng) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 0);
                                TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                print("IsJungleCiv convert3 Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                addForestCount = addForestCount + 1;
                                print("IsJungleCiv teamPVP addForestCount:", addForestCount);
                                return functionResultTrue;
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end
                    end
                    --香蕉
                    if (IsBananaCiv(majListCiv)) then
                        if (addBananaCount >= 2) then
                            return functionResultSuccess;
                        end
                        if (addBananaCount < 2 and terrainType == 4 and (adjacentPlot:GetFeatureType() == 3 or adjacentPlot:GetFeatureType() == 2)) then
                            --平原丘陵\树-》平原雨林 然后加香蕉
                            --或者本身就可以加
                            if (rng + civAddRng + rngAdd > unSetrng) then
                                local tempGetFeatureType = adjacentPlot:GetFeatureType();
                                if (adjacentPlot:GetFeatureType() == 3 or adjacentPlot:GetFeatureType() == -1) then
                                    TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                end
                                TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 0)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 0, 1);
                                    print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Banana");
                                    rngAdd = 0;
                                    addBananaCount = addBananaCount + 1;
                                    return functionResultTrue;
                                else
                                    --失败回退
                                    TerrainBuilder.SetFeatureType(adjacentPlot, tempGetFeatureType);
                                    TerrainBuilder.SetTerrainType(adjacentPlot, terrainType);
                                end
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end

                        if (addBananaCount < 2 and terrainType == 1 and (adjacentPlot:GetFeatureType() == 3)) then
                            --草原丘陵\树-》平原雨林 然后加香蕉
                            if (rng + civAddRng + rngAdd > unSetrng) then
                                local tempGetFeatureType = adjacentPlot:GetFeatureType();
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                                if (ResourceBuilder.CanHaveResource(adjacentPlot, 0)) then
                                    ResourceBuilder.SetResourceType(adjacentPlot, 0, 1);
                                    print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Banana");
                                    rngAdd = 0;
                                    addBananaCount = addBananaCount + 1;
                                    return functionResultTrue;
                                else
                                    --失败回退
                                    TerrainBuilder.SetFeatureType(adjacentPlot, tempGetFeatureType);
                                    TerrainBuilder.SetTerrainType(adjacentPlot, terrainType);
                                end
                            else
                                rngAdd = rngAdd + 3 * rngAddBlock;
                            end
                        end
                    end
                end
            end
        end
    end -- k end loop

    __Debug("Food balancing: Couldn't add Food Bonus");
    return functionResultFail;
end
------------------------------------------------------------------------------------------------------------------------------------------------

function AddBonusProd(plot, intensity, flag)
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local bWater = true;
    local count = 0;
    eResourceType = {};
    eResourceClassType = {};
    aBonus = {};
    local limit_1 = 0;
    local range = 17;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local start_range = 1;
    local end_range = 5;
    local increment = 1;

    --方法变量
    local rngAdd = 0;--成功率附加
    local rngAddBlock = 14;--成功率附加每次失败递增
    local unSetrng = 0.5;--单元格基础失败率

    local rngSet = 0;--选择资源类型随机数，临时变量

    local isAddStore = 0;

    if (intensity == 0) then
        limit_1 = 0.9;
    else
        limit_1 = 0.5 / intensity;
    end

    for k = 0, 1 do

        if k == 0 then
            if (flag == 2 or flag == 1) then
                start_range = 1;
                end_range = 17;
                increment = 2;
            else
                start_range = 1;
                end_range = 17;
                increment = 1;
            end
        elseif k == 1 then
            if (flag == 2 or flag == 1) then
                start_range = 17;
                end_range = 1;
                increment = -1;
            else
                start_range = 1;
                end_range = 17;
                increment = 1;
            end
        end

        for i = start_range, end_range, increment do
            adjacentPlot = GetAdjacentTiles(plot, i);

            if (adjacentPlot ~= nil) then

                if (adjacentPlot:GetResourceCount() < 1) and adjacentPlot:IsNaturalWonder() == false then

                    terrainType = adjacentPlot:GetTerrainType();
                    rng = (TerrainBuilder.GetRandomNumber(100, "test") + rngAdd) / 100;

                    if (((adjacentPlot:GetTerrainType() == 4) or (adjacentPlot:GetTerrainType() == 1) or (adjacentPlot:GetTerrainType() == 10))
                            and (adjacentPlot:GetFeatureType() == -1) and (adjacentPlot:IsImpassable() == false) and (adjacentPlot:IsWater() == false) and (adjacentPlot:GetTerrainType() ~= 6) and (adjacentPlot:GetTerrainType() ~= 7) and (adjacentPlot:GetTerrainType() ~= 12) and (adjacentPlot:GetTerrainType() ~= 13)) then
                        --Wood
                        if (rng > unSetrng) then
                            rngSet = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                            if (stonesCounts < 3 and terrainType == 1) then
                                local stonesPercent = isAddStore * 20 / 100;
                                if (rngSet > (0.5 + stonesPercent)) then
                                    stonesCounts = stonesCounts + 1;
                                    ResourceBuilder.SetResourceType(adjacentPlot, 8, 1);
                                    __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Flat land with stones");
                                    rngAdd = 0;
                                    isAddStore = 1;
                                    return true;
                                else
                                    TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                    __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Wood");
                                    rngAdd = 0;
                                    isAddStore = -1;
                                    return true
                                end
                            else
                                TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Wood");
                                rngAdd = 0;
                                return true
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif ((terrainType == 7 and adjacentPlot:GetResourceType() == -1) or (terrainType == 10 and adjacentPlot:GetResourceType() == -1)) then
                        if (rng > unSetrng) then
                            if (ResourceBuilder.CanHaveResource(adjacentPlot, 2)) then
                                ResourceBuilder.SetResourceType(adjacentPlot, 2, 1);
                                __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Copper");
                                rngAdd = 0;
                                return true;
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif ((terrainType == 9 or terrainType == 10) and adjacentPlot:GetResourceType() == -1) then
                        -- Deer
                        if (rng > unSetrng) then
                            if (ResourceBuilder.CanHaveResource(adjacentPlot, 4)) then
                                ResourceBuilder.SetResourceType(adjacentPlot, 4, 1);
                                __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: Deer");
                                rngAdd = 0;
                                return true;
                            end
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    end
                end
            end
            if (adjacentPlot ~= nil) then
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                terrainType = adjacentPlot:GetTerrainType();
                if (terrainType == 15 and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:IsFreshWater() == false and adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX) then
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if (rng > unSetrng and adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX) then
                        __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Reef");
                        TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_REEF);
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                        return true;
                    else
                        rngAdd = rngAdd + rngAddBlock;
                    end
                elseif (terrainType == 15 and adjacentPlot:GetFeatureType() == g_FEATURE_REEF and adjacentPlot:GetResourceType() == -1 and resourcesFishCount < 3) then
                    __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
                    ResourceBuilder.SetResourceType(adjacentPlot, RESOURCE_FISH_INDEX, 1);
                    resourcesFishCount = resourcesFishCount + 1;
                    return true;
                end
            end
        end
    end
    __Debug("Prod balancing: Couldn't add Prod Bonus");
    return false;
end

------------------------------------------------------------------------------------------------------------------------------------------------

function AddHills(plot, intensity, flag, civAddHillTeamPVP)
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    eResourceType = {};
    eResourceClassType = {};
    aBonus = {};
    local limit_1 = 0;
    local limit_2 = 0;
    local limit = 0;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local start_range = 0;
    local end_range = 17;
    local increment = 1;
    --方法变量
    local rngAdd = 0;--成功率附加
    local rngAddBlock = 50;--成功率附加每次失败递增
    intensity = intensity or 1
    if (intensity == 0) then
        limit_1 = 0.9;
        limit_2 = 0.75;
    else
        limit_1 = 1 / (intensity * 2 + 1);
        limit_2 = 1 / (intensity * 4 + 1);
    end

    for k = 0, 1 do

        if k == 0 then
            if (flag == 2 or flag == 1) then
                start_range = 0;
                end_range = 17;
                increment = 1;
            else
                start_range = 0;
                end_range = 17;
                increment = 1;
            end
        elseif k == 1 then
            if (flag == 2 or flag == 1) then
                start_range = 17;
                end_range = 0;
                increment = -1;
            else
                start_range = 17;
                end_range = 0;
                increment = -1;
            end
        end

        for i = start_range, end_range, increment do
            adjacentPlot = GetAdjacentTiles(plot, i);

            if (i < 6) then
                limit = limit_1
            else
                limit = limit_2
            end

            if (adjacentPlot ~= nil) then
                if adjacentPlot:IsNaturalWonder() == false then
                    terrainType = adjacentPlot:GetTerrainType();
                    rng = (TerrainBuilder.GetRandomNumber(100, "test") + rngAdd) / 100;
                    --强制补贴丘陵
                    if (civAddHillTeamPVP >= 12 and rng >= 1 and adjacentPlot:GetResourceCount() == 1 and (((adjacentPlot:GetYield(g_YIELD_PRODUCTION) + adjacentPlot:GetYield(g_YIELD_FOOD)) < 4) and adjacentPlot:GetYield(g_YIELD_SCIENCE) <= 0 and adjacentPlot:GetYield(g_YIELD_CULTURE) <= 0 and adjacentPlot:GetYield(g_YIELD_GOLD) <= 0 and adjacentPlot:GetYield(g_YIELD_FAITH) <= 0) and adjacentPlot:IsWater() == false
                            and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:IsNaturalWonder() == false and adjacentPlot:IsImpassable() == false) then
                        if (not ZYL_RVC_IsStrategicResource(adjacentPlot:GetResourceType()) and not ZYL_RVC_IsLeyLine(adjacentPlot:GetResourceType()) and (terrainType == 4 or terrainType == 3 or terrainType == 0 or terrainType == 1)) then
                            ResourceBuilder.SetResourceType(adjacentPlot, -1);
                            rngAdd = 0;
                            print("civAddHillTeamPVP IsDeleteResource true Get", adjacentPlot:GetX(), ":", adjacentPlot:GetY());
                        end
                    end
                    if (terrainType == 0 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                        if (rng > limit) then
                            TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                            __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Grassland Hill");
                            rngAdd = 0;
                            return true;
                        else
                            if (i < 6) then
                                rngAdd = rngAdd + rngAddBlock - 7;
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end

                        end
                    elseif (terrainType == 3 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                        if (rng > limit) then
                            TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                            __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Plain Hill");
                            rngAdd = 0;
                            return true;
                        else
                            if (i < 6) then
                                rngAdd = rngAdd + rngAddBlock - 7;
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end

                        end
                    elseif (terrainType == 6 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:GetFeatureType() ~= g_FEATURE_OASIS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                        if (rng > limit) then
                            TerrainBuilder.SetTerrainType(adjacentPlot, 7);
                            __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Desert Hill");
                            rngAdd = 0;
                            return true;
                        else
                            if (i < 6) then
                                rngAdd = rngAdd + rngAddBlock - 7;
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end

                        end
                    elseif (terrainType == 9 and adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                        if (rng > limit) then
                            TerrainBuilder.SetTerrainType(adjacentPlot, 10);
                            __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the tile to a Tundra Hill");
                            rngAdd = 0;
                            return true;
                        else
                            if (i < 6) then
                                rngAdd = rngAdd + rngAddBlock - 7;
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end

                        end
                    elseif (adjacentPlot:GetResourceType() == -1 and adjacentPlot:GetFeatureType() == g_FEATURE_MARSH and (terrainType == 0 or terrainType == 3)) then
                        if (rng > limit * 2) then
                            TerrainBuilder.SetTerrainType(adjacentPlot, terrainType + 1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            __Debug("Prod Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Turned the Marsh tile to a Hill");
                            rngAdd = 0;
                            return true;
                        else
                            if (i < 6) then
                                rngAdd = rngAdd + rngAddBlock - 7;
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end

                        end
                    else
                        if (i < 6) then
                            rngAdd = rngAdd + rngAddBlock - 7;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    end


                end
            end
        end

    end -- end k loop

    __Debug("Hill balancing: Couldn't add Prod Bonus");
    return false;
end
------------------------------------------------------------------------------

function Terraforming_Nuke_Mountain(plot)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    local adjacentPlot = nil;
    local limit = 0
    local limit_1 = 0.05
    local limit_2 = 0.2
    --------------------------------------------------------------------------------------------------------------
    -- Terraforming Nuke Mountain --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------
    for i = -1, 17 do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (i < 6) then
            limit = limit_1
        else
            limit = limit_2
        end
        if (adjacentPlot ~= nil) then
            if ((adjacentPlot:GetTerrainType() == 2 or adjacentPlot:GetTerrainType() == 5 or adjacentPlot:GetTerrainType() == 8 or adjacentPlot:GetTerrainType() == 11 or adjacentPlot:GetTerrainType() == 14) and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) and adjacentPlot:IsNaturalWonder() == false then
                local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if (rng > limit) then
                    __Debug("Nuked Mountain X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Replaced a Mountain by a Hill");
                    local tmp_terrain = adjacentPlot:GetTerrainType()
                    TerrainBuilder.SetTerrainType(adjacentPlot, tmp_terrain - 1);
                end
            end
        end
    end
end

------------------------------------------------------------------------------

function Terraforming_Mountain(plot, flag)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local distance = 0;
    local min_distance = 99;
    local minimal_effort_i = nil;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local rng = 0
    local count = 0
    local rngMountainAdd = 0
    local mountainTerrainTypeTemp = 0

    --------------------------------------------------------------------------------------------------------------
    -- Terraforming Mountain -------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------
    if flag == 3 then
        for i = 6, 36 do
            if (GetAdjacentTiles(plot, i) ~= nil) then
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                adjacentPlot = GetAdjacentTiles(plot, i)
                mountainTerrainTypeTemp = adjacentPlot:GetTerrainType();
                if (mountainTerrainTypeTemp == 1 and i < 18) then
                    rngMountainAdd = -100;
                end
                if (mountainTerrainTypeTemp == 4 and i < 18) then
                    rngMountainAdd = -100;
                end
                --
                if (mountainTerrainTypeTemp == 0 and i > 18) then
                    rngMountainAdd = 10;
                end
                if (mountainTerrainTypeTemp == 3 and i > 18) then
                    rngMountainAdd = 10;
                end
                --
                if (mountainTerrainTypeTemp == 1 and i > 18) then
                    rngMountainAdd = -10;
                end
                if (mountainTerrainTypeTemp == 4 and i > 18) then
                    rngMountainAdd = -10;
                end
                if (adjacentPlot:IsImpassable() == false
                        and adjacentPlot:IsWater() == false
                        and adjacentPlot:IsNaturalWonder() == false
                        and adjacentPlot:GetResourceCount() < 1
                        and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS
                        and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND
                        and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS
                        and rng <= (0.7 + 2 * (i - 6) / 100 + rngMountainAdd / 100)
                        and count <= 2) then
                    if adjacentPlot:GetTerrainType() == 0 or adjacentPlot:GetTerrainType() == 1 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 2);
                    elseif adjacentPlot:GetTerrainType() == 3 or adjacentPlot:GetTerrainType() == 4 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 5);
                    elseif adjacentPlot:GetTerrainType() == 9 or adjacentPlot:GetTerrainType() == 10 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 11);
                    elseif adjacentPlot:GetTerrainType() == 6 or adjacentPlot:GetTerrainType() == 7 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 8);
                    end
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1)
                    count = count + 1
                    __Debug("Terraforming_Mountain X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Place a Mountain");
                end
            end
        end
        count = 0;
        for i = 18, 60 do
            if (GetAdjacentTiles(plot, i) ~= nil) then
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                adjacentPlot = GetAdjacentTiles(plot, i)
                mountainTerrainTypeTemp = adjacentPlot:GetTerrainType();
                if (mountainTerrainTypeTemp == 1 and i < 18) then
                    rngMountainAdd = -100;
                end
                if (mountainTerrainTypeTemp == 4 and i < 18) then
                    rngMountainAdd = -100;
                end
                --
                if (mountainTerrainTypeTemp == 0 and i > 18) then
                    rngMountainAdd = 10;
                end
                if (mountainTerrainTypeTemp == 3 and i > 18) then
                    rngMountainAdd = 10;
                end
                --
                if (mountainTerrainTypeTemp == 1 and i > 18) then
                    rngMountainAdd = -10;
                end
                if (mountainTerrainTypeTemp == 4 and i > 18) then
                    rngMountainAdd = -10;
                end
                if (adjacentPlot:IsImpassable() == false
                        and adjacentPlot:IsWater() == false
                        and adjacentPlot:IsNaturalWonder() == false
                        and adjacentPlot:GetResourceCount() < 1
                        and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS
                        and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND
                        and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS
                        and rng <= (0.7 + 2 * (i - 18) / 100 + rngMountainAdd / 100)
                        and count <= 5) then
                    if adjacentPlot:GetTerrainType() == 0 or adjacentPlot:GetTerrainType() == 1 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 2);
                    elseif adjacentPlot:GetTerrainType() == 3 or adjacentPlot:GetTerrainType() == 4 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 5);
                    elseif adjacentPlot:GetTerrainType() == 9 or adjacentPlot:GetTerrainType() == 10 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 11);
                    elseif adjacentPlot:GetTerrainType() == 6 or adjacentPlot:GetTerrainType() == 7 then
                        TerrainBuilder.SetTerrainType(adjacentPlot, 8);
                    end
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1)
                    count = count + 1
                    __Debug("Terraforming_Mountain X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Place a Mountain");
                end
            end
        end
        return
    end

    count = 0
    for i = 0, 5 do
        if (GetAdjacentTiles(plot, i) ~= nil) then
            if (GetAdjacentTiles(plot, i):IsImpassable() == true) and GetAdjacentTiles(plot, i):IsNaturalWonder() == false then
                -- immediate wall
                __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Analysing the plot");
                if (i == 0) then
                    if (GetAdjacentTiles(plot, 5) ~= nil and GetAdjacentTiles(plot, i + 1) ~= nil) then
                        if (GetAdjacentTiles(plot, 5):IsImpassable() == true and GetAdjacentTiles(plot, i + 1):IsImpassable() == true) then
                            -- Walled-in is there actual terrain on the other side ?
                            if (GetAdjacentTiles(plot, 5 * i + 60) ~= nil) then
                                if (GetAdjacentTiles(plot, 5 * i + 60):IsImpassable() == false and GetAdjacentTiles(plot, 5 * i + 60):IsWater() == false) then
                                    -- Ok there is land let measure the distance to dig through
                                    if (GetAdjacentTiles(plot, 2 * i + 6) ~= nil and GetAdjacentTiles(plot, 3 * i + 18) ~= nil and GetAdjacentTiles(plot, 4 * i + 36) ~= nil) then
                                        if (GetAdjacentTiles(plot, 2 * i + 6):IsImpassable() == true) then
                                            distance = 2;
                                        else
                                            distance = 1;
                                        end
                                        if (GetAdjacentTiles(plot, 3 * i + 18):IsImpassable() == true) then
                                            distance = distance + 1;
                                        end
                                        if (GetAdjacentTiles(plot, 4 * i + 36):IsImpassable() == true) then
                                            distance = distance + 1;
                                        end
                                        __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance);
                                        if (distance < min_distance) then
                                            min_distance = distance;
                                            minimal_effort_i = i;
                                        end
                                    end
                                else
                                    __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");
                                end
                            else
                                __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
                            end
                        else
                            __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Can move around the Mountain");
                        end
                    end
                elseif (i > 0 and i < 5) then
                    if (GetAdjacentTiles(plot, i - 1) ~= nil and GetAdjacentTiles(plot, i + 1) ~= nil) then
                        if (GetAdjacentTiles(plot, i - 1):IsImpassable() == true and GetAdjacentTiles(plot, i + 1):IsImpassable() == true) then
                            -- Walled-in is there actual terrain on the other side ?
                            if (GetAdjacentTiles(plot, 5 * i + 60) ~= nil) then
                                if (GetAdjacentTiles(plot, 5 * i + 60):IsImpassable() == false and GetAdjacentTiles(plot, 5 * i + 60):IsWater() == false) then
                                    -- Ok there is land let measure the distance to dig through
                                    if (GetAdjacentTiles(plot, 2 * i + 6) ~= nil and GetAdjacentTiles(plot, 3 * i + 18) ~= nil and GetAdjacentTiles(plot, 4 * i + 36) ~= nil) then
                                        if (GetAdjacentTiles(plot, 2 * i + 6):IsImpassable() == true) then
                                            distance = 2;
                                        else
                                            distance = 1;
                                        end
                                        if (GetAdjacentTiles(plot, 3 * i + 18):IsImpassable() == true) then
                                            distance = distance + 1;
                                        end
                                        if (GetAdjacentTiles(plot, 4 * i + 36):IsImpassable() == true) then
                                            distance = distance + 1;
                                        end
                                        __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance);
                                        if (distance < min_distance) then
                                            min_distance = distance;
                                            minimal_effort_i = i;
                                        end
                                    end
                                else
                                    __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");
                                end
                            else
                                __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
                            end
                        else
                            __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Can move around the Mountain");
                        end
                    end
                elseif (i == 5) then
                    if (GetAdjacentTiles(plot, i - 1) ~= nil and GetAdjacentTiles(plot, 0) ~= nil) then
                        if (GetAdjacentTiles(plot, i - 1):IsImpassable() == true and GetAdjacentTiles(plot, 0):IsImpassable() == true) then
                            -- Walled-in is there actual terrain on the other side ?
                            if (GetAdjacentTiles(plot, 5 * i + 60) ~= nil) then
                                if (GetAdjacentTiles(plot, 5 * i + 60):IsImpassable() == false and GetAdjacentTiles(plot, 5 * i + 60):IsWater() == false) then
                                    -- Ok there is land let measure the distance to dig through
                                    if (GetAdjacentTiles(plot, 2 * i + 6) ~= nil and GetAdjacentTiles(plot, 3 * i + 18) ~= nil and GetAdjacentTiles(plot, 4 * i + 36) ~= nil) then
                                        if (GetAdjacentTiles(plot, 2 * i + 6):IsImpassable() == true) then
                                            distance = 2;
                                        else
                                            distance = 1;
                                        end
                                        if (GetAdjacentTiles(plot, 3 * i + 18):IsImpassable() == true) then
                                            distance = distance + 1;
                                        end
                                        if (GetAdjacentTiles(plot, 4 * i + 36):IsImpassable() == true) then
                                            distance = distance + 1;
                                        end
                                        __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance);
                                        if (distance < min_distance) then
                                            min_distance = distance;
                                            minimal_effort_i = i;
                                        end
                                    end
                                else
                                    __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");
                                end
                            else
                                __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
                            end
                        else
                            __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Can move around the Mountain");
                        end
                    end
                end
            else
                -- one tile away wall
                if (GetAdjacentTiles(plot, 2 * i + 6) ~= nil) then
                    __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, 2 * i + 6):GetX(), "Y: ", GetAdjacentTiles(plot, 2 * i + 6):GetY(), "Analysing the plot");
                    if (GetAdjacentTiles(plot, 2 * i + 6):IsImpassable() == true) then
                        if (i == 0) then
                            if (GetAdjacentTiles(plot, 17) ~= nil and GetAdjacentTiles(plot, 2 * i + 6 + 1) ~= nil) then
                                if (GetAdjacentTiles(plot, 17):IsImpassable() == true and GetAdjacentTiles(plot, 2 * i + 1 + 6):IsImpassable() == true) then
                                    -- Walled-in is there actual terrain on the other side ?
                                    if (GetAdjacentTiles(plot, 5 * i + 60) ~= nil) then
                                        if (GetAdjacentTiles(plot, 5 * i + 60):IsImpassable() == false and GetAdjacentTiles(plot, 5 * i + 60):IsWater() == false) then
                                            -- Ok there is land let measure the distance to dig through
                                            if (GetAdjacentTiles(plot, 3 * i + 18) ~= nil and GetAdjacentTiles(plot, 4 * i + 36) ~= nil) then
                                                if (GetAdjacentTiles(plot, 3 * i + 18):IsImpassable() == true) then
                                                    distance = 1;
                                                else
                                                    distance = 0;
                                                end
                                                if (GetAdjacentTiles(plot, 4 * i + 36):IsImpassable() == true) then
                                                    distance = distance + 1;
                                                end
                                                __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance)
                                                if (distance < min_distance) then
                                                    min_distance = distance;
                                                    minimal_effort_i = i;
                                                end
                                            end
                                        else
                                            __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");

                                        end
                                    else
                                        __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
                                    end
                                else
                                    __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, 2 * i + 6):GetX(), "Y: ", GetAdjacentTiles(plot, 2 * i + 6):GetY(), "Can move around the Mountain");
                                end
                            end
                        elseif (i > 0) then
                            if (GetAdjacentTiles(plot, 2 * i + 6 - 1) ~= nil and GetAdjacentTiles(plot, 2 * i + 1 + 6) ~= nil) then
                                if (GetAdjacentTiles(plot, 2 * i + 6 - 1):IsImpassable() == true and GetAdjacentTiles(plot, 2 * i + 1 + 6):IsImpassable() == true) then
                                    -- Walled-in is there actual terrain on the other side ?
                                    if (GetAdjacentTiles(plot, 5 * i + 60) ~= nil) then
                                        if (GetAdjacentTiles(plot, 5 * i + 60):IsImpassable() == false and GetAdjacentTiles(plot, 5 * i + 60):IsWater() == false) then
                                            -- Ok there is land let measure the distance to dig through
                                            if (GetAdjacentTiles(plot, 3 * i + 18) ~= nil and GetAdjacentTiles(plot, 4 * i + 36) ~= nil) then
                                                if (GetAdjacentTiles(plot, 3 * i + 18):IsImpassable() == true) then
                                                    distance = 1;
                                                else
                                                    distance = 0;
                                                end
                                                if (GetAdjacentTiles(plot, 4 * i + 36):IsImpassable() == true) then
                                                    distance = distance + 1;
                                                end
                                                __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "Distance to dig is", distance)
                                                if (distance < min_distance) then
                                                    min_distance = distance;
                                                    minimal_effort_i = i;
                                                end
                                            end
                                        else
                                            __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No good Terrain on the other side");

                                        end
                                    else
                                        __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, i):GetX(), "Y: ", GetAdjacentTiles(plot, i):GetY(), "No Terrain on the other side");
                                    end
                                else
                                    __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, 2 * i + 6):GetX(), "Y: ", GetAdjacentTiles(plot, 2 * i + 6):GetY(), "Can move around the Mountain");
                                end
                            end
                        end
                    end

                end
            end
        end
    end
    if (minimal_effort_i ~= nil) then
        __Debug("Terraforming_Mountain X: ", GetAdjacentTiles(plot, minimal_effort_i):GetX(), "Y: ", GetAdjacentTiles(plot, minimal_effort_i):GetY(), "Digging an openning");
        if (GetAdjacentTiles(plot, minimal_effort_i) ~= nil and GetAdjacentTiles(plot, 2 * minimal_effort_i + 6) ~= nil and GetAdjacentTiles(plot, 3 * minimal_effort_i + 18) ~= nil and GetAdjacentTiles(plot, 4 * minimal_effort_i + 36) ~= nil) then
            adjacentPlot = GetAdjacentTiles(plot, minimal_effort_i);
            adjacentPlot2 = GetAdjacentTiles(plot, 2 * minimal_effort_i + 6);
            adjacentPlot3 = GetAdjacentTiles(plot, 3 * minimal_effort_i + 18);
            adjacentPlot4 = GetAdjacentTiles(plot, 4 * minimal_effort_i + 36);
            if (adjacentPlot:IsImpassable() == true and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                TerrainBuilder.SetTerrainType(adjacentPlot, adjacentPlot:GetTerrainType() - 1)
                TerrainBuilder.SetFeatureType(adjacentPlot, -1)
                if adjacentPlot:GetTerrainType() == 10 or adjacentPlot:GetTerrainType() == 13 or adjacentPlot:GetTerrainType() == 7 then
                    TerrainBuilder.SetTerrainType(adjacentPlot, 4)
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                if rng > 0.75 then
                    TerrainBuilder.SetFeatureType(adjacentPlot, 3)
                end
                __Debug("Terraforming_Mountain X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "turn Mountain into a Hill");
            end
            if (adjacentPlot2:IsImpassable() == true and adjacentPlot2:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                TerrainBuilder.SetTerrainType(adjacentPlot2, adjacentPlot2:GetTerrainType() - 1)
                TerrainBuilder.SetFeatureType(adjacentPlot2, -1)
                if adjacentPlot2:GetTerrainType() == 10 or adjacentPlot2:GetTerrainType() == 13 or adjacentPlot2:GetTerrainType() == 7 then
                    TerrainBuilder.SetTerrainType(adjacentPlot2, 4)
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                if rng > 0.75 then
                    TerrainBuilder.SetFeatureType(adjacentPlot2, 3)
                end
                __Debug("Terraforming_Mountain X: ", adjacentPlot2:GetX(), "Y: ", adjacentPlot2:GetY(), "turn Mountain into a Hill");
            end
            if (adjacentPlot3:IsImpassable() == true and adjacentPlot3:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                TerrainBuilder.SetTerrainType(adjacentPlot3, adjacentPlot3:GetTerrainType() - 1)
                TerrainBuilder.SetFeatureType(adjacentPlot3, -1)
                if adjacentPlot3:GetTerrainType() == 10 or adjacentPlot3:GetTerrainType() == 13 or adjacentPlot3:GetTerrainType() == 7 then
                    TerrainBuilder.SetTerrainType(adjacentPlot3, 4)
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                if rng > 0.75 then
                    TerrainBuilder.SetFeatureType(adjacentPlot3, 3)
                end
                __Debug("Terraforming_Mountain X: ", adjacentPlot3:GetX(), "Y: ", adjacentPlot3:GetY(), "turn Mountain into a Hill");
            end
            if (adjacentPlot4:IsImpassable() == true and adjacentPlot4:GetFeatureType() ~= g_FEATURE_VOLCANO) then
                TerrainBuilder.SetTerrainType(adjacentPlot4, adjacentPlot4:GetTerrainType() - 1)
                TerrainBuilder.SetFeatureType(adjacentPlot4, -1)
                if adjacentPlot4:GetTerrainType() == 10 or adjacentPlot4:GetTerrainType() == 13 or adjacentPlot4:GetTerrainType() == 7 then
                    TerrainBuilder.SetTerrainType(adjacentPlot4, 4)
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                if rng > 0.75 then
                    TerrainBuilder.SetFeatureType(adjacentPlot4, 3)
                end
                __Debug("Terraforming_Mountain X: ", adjacentPlot4:GetX(), "Y: ", adjacentPlot4:GetY(), "turn Mountain into a Hill");
            end

        end
    end

end

------------------------------------------------------------------------------
function Terraforming_Polar_Start(plot)
    local ContinentNum = nil;
    local ContinentPlots = {};
    ContinentNum = plot:GetContinentType()
    ContinentPlots = Map.GetContinentPlots(ContinentNum);
    __Debug("Terraforming Polar Continent", ContinentNum);
    for i, iplot in ipairs(ContinentPlots) do
        if iplot ~= nil then
            local pPlot = Map.GetPlotByIndex(iplot)
            local iTerrain = pPlot:GetTerrainType();
            if (iTerrain == 12 or iTerrain == 13 or iTerrain == 14) then
                TerrainBuilder.SetTerrainType(pPlot, iTerrain - 3);
                print("Let Snow warm to Tundra success");
            end
        end
    end
    for i = 0, 90 do
        adjacentPlot = GetAdjacentTiles(plot, i)
        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetFeatureType() == 1 and rng > 0.1) then
                __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Removing Ice", i);
                TerrainBuilder.SetFeatureType(adjacentPlot, -1);
            end
        end
    end
end

------------------------------------------------------------------------------

function Terraforming_Best(plot, avg_best, avg_best_2, missing_amount, flag)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    -- flag = 4 floodplains civ
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    local bTerraform = true;
    local temp_tile = 0;
    local best_tile = 0;
    local valid_target_1 = nil;
    local valid_target_2 = nil;
    local second_best_tile = 0;
    local best_plot = nil;
    local best_plot_2 = nil;
    local adjacentPlot = nil;
    local bCulture = false;
    local bFaith = false;
    local adjust = 0;


    --------------------------------------------------------------------------------------------------------------
    -- Step: 0: Figuring out where are the best tiles ------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------

    for i = 0, 17 do
        adjacentPlot = GetAdjacentTiles(plot, i)
        if (adjacentPlot ~= nil and adjacentPlot:IsWater() == false and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO) and adjacentPlot:IsNaturalWonder() == false then
            temp_tile = 0;
            temp_tile = adjacentPlot:GetYield(g_YIELD_FOOD) + adjacentPlot:GetYield(g_YIELD_PRODUCTION) * 1.5 + adjacentPlot:GetYield(g_YIELD_GOLD) * 0.5;
            -- Best Plot: No Ressources, No Floodplains, Low Score, Inner Circle
            if (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and i < 6 and temp_tile < 3.6) then
                if (valid_target_1 == nil) then
                    valid_target_1 = i;
                end
                if (valid_target_2 == nil and valid_target_1 ~= i) then
                    valid_target_2 = i;
                end
                if (valid_target_2 ~= nil) and (valid_target_1 ~= nil) then
                    break
                end
                -- Second Best: With a poor Resource
            elseif (adjacentPlot:GetResourceType() < 10 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and i < 6 and temp_tile < 3.6) then
                if (valid_target_1 == nil) then
                    valid_target_1 = i;
                end
                if (valid_target_2 == nil and valid_target_1 ~= i) then
                    valid_target_2 = i;
                end
                if (valid_target_2 ~= nil) and (valid_target_1 ~= nil) then
                    break
                end
                -- Third Best: Only one floodplains tile destroyed
            elseif (adjacentPlot:GetResourceCount() < 1 and valid_target_2 == nil and i < 5 and temp_tile < 3.6) then
                if (valid_target_1 == nil) then
                    valid_target_1 = i;
                end
                -- Fourth Best: Slightly improve a good inner tile
            elseif (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and i < 6 and temp_tile < 4.75) then
                if (valid_target_1 == nil) then
                    valid_target_1 = i;
                end
                if (valid_target_2 == nil and valid_target_1 ~= i) then
                    valid_target_2 = i;
                end
                if (valid_target_2 ~= nil) and (valid_target_1 ~= nil) then
                    break
                end
                -- Fifth Best: Pick an bad tile on the second ring then player can decide to move
            elseif (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and i > 5 and temp_tile < 3.6) then
                if (valid_target_1 == nil) then
                    valid_target_1 = i;
                end
                if (valid_target_2 == nil and valid_target_1 ~= i) then
                    valid_target_2 = i;
                end
                if (valid_target_2 ~= nil) and (valid_target_1 ~= nil) then
                    break
                end
            end
        end
    end

    --------------------------------------------------------------------------------------------------------------
    -- Step: 1: Rebalancing Best Plot ----------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------

    missing_amount = missing_amount
    if missing_amount < 1.5 then
        avg_best = avg_best_2
    end
    __Debug("Terraforming Best valid_target_1: ", valid_target_1, "valid_target_2: ", valid_target_2);
    if (valid_target_1 ~= nil) then
        target_plot_1 = GetAdjacentTiles(plot, valid_target_1)
        if valid_target_2 == nil and missing_amount > 2 then
            missing_amount = missing_amount * 2
        end
        if (target_plot_1 == nil) then
            __Debug("Terraforming Best: No Valid Target 1 plot");
            return
        else
            if ZYL_RVC_IsStrategicResource(target_plot_1:GetResourceType()) then
                __Debug("Terraforming Best: No Valid Target 1 plot: Preserve Strategic Resource");
                return
            end
        end
        __Debug("Terraforming Best Place One: ", valid_target_1, "avg Best", avg_best, "missing_amount", missing_amount);
        if (avg_best >= 4.5 and avg_best < 5.75) then
            -- On average player have a 2/2 tile
            -- Player doesn't have a 2/2 tile

            target_plot_1 = GetAdjacentTiles(plot, valid_target_1)
            -- Grassland
            if (target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4)) then
                    -- +5 on Grassland
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if missing_amount > 1 then
                        rng = rng + 0.15
                    end
                    if (rng >= 0.75) then
                        -- Flat Deer Forest
                        TerrainBuilder.SetTerrainType(target_plot_1, 0);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        TerrainBuilder.SetFeatureType(target_plot_1, 3);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Grassland Forest with Deers");
                    elseif (rng >= 0.45 and rng < 0.75) then
                        -- Forested Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 1);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        TerrainBuilder.SetFeatureType(target_plot_1, 3);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Grassland Hill");
                    elseif (rng >= 0.15 and rng < 0.45) then
                        -- Stone Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 1);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 8, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Stone Grassland Hill");
                    elseif (rng >= 0.0 and rng < 0.15) then
                        -- Copper Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 1);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/1/2 Copper Grassland Hill");
                    end
                else
                    -- floodplains and floodplains Civs
                    if (target_plot_1:GetResourceCount() < 1) then
                        ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
                    end
                end
                -- Plains
            elseif (target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4)) then
                    -- +5 on Plains
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if missing_amount > 1 then
                        rng = rng + 0.15
                    end
                    if (rng >= 0.75) then
                        -- Hill with Sheep
                        TerrainBuilder.SetTerrainType(target_plot_1, 4);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
                    elseif (rng >= 0.25 and rng < 0.75) then
                        -- Copper Plain Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 4);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/2/2 Copper Plain Hill");
                    elseif (rng >= 0.0 and rng < 0.25) then
                        if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
                            -- Jungle Plain Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 2);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Jungle Plain Hill");
                        else
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
                        end
                    end
                else
                    -- floodplains and floodplains Civs
                    if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
                    end
                end
                -- Desert
            elseif (target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                    -- +5 on Desert -> impossible
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if (rng >= 0.5) then
                        -- Hill with Sheep
                        TerrainBuilder.SetTerrainType(target_plot_1, 7);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        --ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
                    elseif (rng >= 0.0 and rng < 0.5) then
                        -- Copper Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 7);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
                    end
                else
                    -- floodplains
                    if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
                    end
                end
                -- Tundra
            elseif (target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
                    -- +5 on Tundra -> impossible
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if (rng >= 0.75) then
                        -- Hill with Sheep
                        TerrainBuilder.SetTerrainType(target_plot_1, 10);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
                    elseif (rng >= 0.2 and rng < 0.75) then
                        -- Copper Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 10);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
                    elseif (rng >= 0.0 and rng < 0.2) then
                        -- Forested Deer
                        TerrainBuilder.SetTerrainType(target_plot_1, 10);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        TerrainBuilder.SetFeatureType(target_plot_1, 3);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
                    end
                end
            end

        elseif (avg_best >= 5.75) then

            target_plot_1 = GetAdjacentTiles(plot, valid_target_1)

            -- Grassland
            if (target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4)) then
                    -- +5.5 on Grassland
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if (rng >= 0) then
                        -- Forested Hill with deer
                        TerrainBuilder.SetTerrainType(target_plot_1, 1);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                        TerrainBuilder.SetFeatureType(target_plot_1, 3);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/3 Forested Deer Grassland Hill");

                    end
                else
                    -- floodplains and floodplains Civs
                    if (target_plot_1:GetResourceCount() < 1) then
                        ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
                    end
                end
                -- Plains
            elseif (target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4)) then
                    -- +5.5 on Plains
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if (rng >= 0.7) then
                        -- Forested Hill with Deer
                        TerrainBuilder.SetTerrainType(target_plot_1, 4);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        TerrainBuilder.SetFeatureType(target_plot_1, 3);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/4 Forested Plain Hill with Deer");
                    elseif (rng >= 0.5 and rng < 0.7) then
                        -- Forested Plain Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 4);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        TerrainBuilder.SetFeatureType(target_plot_1, 3);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/3 Forested Plain Hill");
                    elseif (rng >= 0 and rng < 0.5) then
                        -- Banana Jungle Hill
                        if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 0, 1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 2);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/2 Jungle Plain Hill with Banana");
                        elseif rng > 0.25 then
                            -- Forested Plain Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/4 Forested Plain Hill with Deer");
                        else
                            -- Sheep Plain Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Plain Hill with Sheep");
                        end

                    end
                else
                    -- floodplains and floodplains Civs
                    if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
                    end
                end
                -- Desert
            elseif (target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                    -- on Desert -> impossible
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if (rng >= 0.5) then
                        -- Hill with Sheep
                        TerrainBuilder.SetTerrainType(target_plot_1, 7);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        --ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
                    elseif (rng >= 0.0 and rng < 0.5) then
                        -- Copper Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 7);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
                    end
                else
                    -- floodplains
                    if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
                    end
                end
                -- Tundra
            elseif (target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                if (target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
                    -- +5 on Tundra -> impossible
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                    if (rng >= 0.75) then
                        -- Hill with Sheep
                        TerrainBuilder.SetTerrainType(target_plot_1, 10);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
                    elseif (rng >= 0.5 and rng < 0.75) then
                        -- Copper Hill
                        TerrainBuilder.SetTerrainType(target_plot_1, 10);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
                    elseif (rng >= 0.0 and rng < 0.5) then
                        -- Forested Deer
                        TerrainBuilder.SetTerrainType(target_plot_1, 10);
                        TerrainBuilder.SetFeatureType(target_plot_1, -1);
                        TerrainBuilder.SetFeatureType(target_plot_1, 3);
                        ResourceBuilder.SetResourceType(target_plot_1, -1);
                        ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                        __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
                    end
                end


            else
                -- 3/1

                target_plot_1 = GetAdjacentTiles(plot, valid_target_1)
                -- Grassland
                if (target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4)) then
                        -- +4.5 on Grassland
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 1);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Sheep Grassland Hill");

                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1) then
                            ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
                        end
                    end
                    -- Plains
                elseif (target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4)) then
                        -- +4.5 on Plains
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.0) then
                            -- Banana Jungle Hill
                            if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
                                TerrainBuilder.SetTerrainType(target_plot_1, 3);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 0, 1);
                                TerrainBuilder.SetFeatureType(target_plot_1, 2);
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Jungle Plain with Banana");
                            else
                                -- Forested Plain Hill
                                TerrainBuilder.SetTerrainType(target_plot_1, 3);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                TerrainBuilder.SetFeatureType(target_plot_1, 3);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 4, 1);
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Plain with Deer");
                            end

                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
                        end
                    end
                    -- Desert
                elseif (target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        -- on Desert -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.5) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            --ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
                        elseif (rng >= 0.0 and rng < 0.5) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
                        end
                    else
                        -- floodplains
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
                        end
                    end
                    -- Tundra
                elseif (target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
                        -- +5 on Tundra -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.66) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
                        elseif (rng >= 0.1 and rng < 0.66) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
                        elseif (rng >= 0.0 and rng < 0.1) then
                            -- Forested Deer
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
                        end
                    end


                end
            end
        end
    end

    --------------------------------------------------------------------------------------------------------------
    -- Step: 2: Rebalancing Second Best Plot ---------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------
    if missing_amount > 2 then
        __Debug("Terraforming Best do another plot valid_target_2: ", valid_target_2);
        if (valid_target_2 ~= nil) then
            target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
            if (target_plot_1 == nil) then
                __Debug("Terraforming Best: No Valid Target 2 plot");
                return
            else
                if ZYL_RVC_IsStrategicResource(target_plot_1:GetResourceType()) then
                    __Debug("Terraforming Best: No Valid Target 2 plot: Preserve Strategic Resource");
                    return
                end
            end
            __Debug("Terraforming Best Place Second: ", valid_target_2, "avg_best_2", avg_best_2);
            if ((avg_best_2) >= 4.25 + adjust and avg_best_2 < 5.75) then
                -- On average player have a 2/2 tile
                -- Player doesn't have a 2/2 tile

                target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
                -- Grassland
                if (target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4)) then
                        -- +5 on Grassland
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.75) then
                            -- Forested Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 1);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Grassland Hill");
                        elseif (rng >= 0.5 and rng < 0.75) then
                            -- Flat Deer Forest
                            TerrainBuilder.SetTerrainType(target_plot_1, 0);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Grassland Forest with Deers");
                        elseif (rng >= 0.2 and rng < 0.5) then
                            -- Stone Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 1);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 8, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Stone Grassland Hill");
                        elseif (rng >= 0.0 and rng < 0.2) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 1);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/1/2 Copper Grassland Hill");
                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1) then
                            ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
                        end
                    end
                    -- Plains
                elseif (target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4)) then
                        -- +5 on Plains
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.75) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
                        elseif (rng >= 0.25 and rng < 0.75) then
                            -- Copper Plain Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/2/2 Copper Plain Hill");
                        elseif (rng >= 0.0 and rng < 0.25) then
                            if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
                                -- Jungle Plain Hill
                                TerrainBuilder.SetTerrainType(target_plot_1, 4);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                TerrainBuilder.SetFeatureType(target_plot_1, 2);
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Jungle Plain Hill");
                            else
                                -- Hill with Sheep
                                TerrainBuilder.SetTerrainType(target_plot_1, 4);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Sheep Plain Hill");
                            end
                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
                        end
                    end
                    -- Desert
                elseif (target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        -- +5 on Desert -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.5) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            --ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
                        elseif (rng >= 0.0 and rng < 0.5) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
                        end
                    else
                        -- floodplains
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
                        end
                    end
                    -- Tundra
                elseif (target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
                        -- +5 on Tundra -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.75) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
                        elseif (rng >= 0.2 and rng < 0.75) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
                        elseif (rng >= 0.0 and rng < 0.2) then
                            -- Forested Deer
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
                        end
                    end
                end

            elseif (avg_best_2 >= 5.75) then

                target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
                -- Grassland
                if (target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4)) then
                        -- +5.5 on Grassland
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0) then
                            -- Forested Hill with deer
                            TerrainBuilder.SetTerrainType(target_plot_1, 1);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/3 Forested Deer Grassland Hill");

                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1) then
                            ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
                        end
                    end
                    -- Plains
                elseif (target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4)) then
                        -- +5.5 on Plains
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.7) then
                            -- Forested Hill with Deer
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/4 Forested Plain Hill with Deer");
                        elseif (rng >= 0.5 and rng < 0.7) then
                            -- Forested Plain Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 4);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/3 Forested Plain Hill");
                        elseif (rng >= 0 and rng < 0.5) then
                            -- Banana Jungle Hill
                            if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
                                TerrainBuilder.SetTerrainType(target_plot_1, 4);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 0, 1);
                                TerrainBuilder.SetFeatureType(target_plot_1, 2);
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/2 Jungle Plain Hill with Banana");
                            elseif rng > 0.25 then
                                -- Forested Plain Hill
                                TerrainBuilder.SetTerrainType(target_plot_1, 4);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                TerrainBuilder.SetFeatureType(target_plot_1, 3);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/4 Forested Plain Hill with Deer");
                            else
                                -- Sheep Plain Hill
                                TerrainBuilder.SetTerrainType(target_plot_1, 4);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 7, 1)
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Plain Hill with Sheep");
                            end

                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
                        end
                    end
                    -- Desert
                elseif (target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        -- on Desert -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.5) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            --ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
                        elseif (rng >= 0.0 and rng < 0.5) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
                        end
                    else
                        -- floodplains
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
                        end
                    end
                    -- Tundra
                elseif (target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
                        -- +5 on Tundra -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.75) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
                        elseif (rng >= 0.5 and rng < 0.75) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
                        elseif (rng >= 0.0 and rng < 0.5) then
                            -- Forested Deer
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
                        end
                    end
                end

            else
                -- 3/1

                target_plot_1 = GetAdjacentTiles(plot, valid_target_2)
                -- Grassland
                if (target_plot_1:GetTerrainType() == 0 or target_plot_1:GetTerrainType() == 1 or (target_plot_1:GetTerrainType() == 2 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND and flag ~= 4)) then
                        -- +4.5 on Grassland
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 1);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Sheep Grassland Hill");

                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1) then
                            ResourceBuilder.SetResourceType(target_plot_1, 6, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Rice Grassland Floodplains");
                        end
                    end
                    -- Plains
                elseif (target_plot_1:GetTerrainType() == 3 or target_plot_1:GetTerrainType() == 4 or (target_plot_1:GetTerrainType() == 5 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS or (target_plot_1:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS and flag ~= 4)) then
                        -- +4.5 on Plains
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.0) then
                            -- Banana Jungle plains
                            if (target_plot_1:GetY() > gridHeight * 0.25 and target_plot_1:GetY() < gridHeight * 0.75) then
                                TerrainBuilder.SetTerrainType(target_plot_1, 3);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 0, 1);
                                TerrainBuilder.SetFeatureType(target_plot_1, 2);
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/1 Jungle Plain with Banana");
                            else
                                -- Forested Plain Hill
                                TerrainBuilder.SetTerrainType(target_plot_1, 3);
                                TerrainBuilder.SetFeatureType(target_plot_1, -1);
                                TerrainBuilder.SetFeatureType(target_plot_1, 3);
                                ResourceBuilder.SetResourceType(target_plot_1, -1);
                                ResourceBuilder.SetResourceType(target_plot_1, 4, 1);
                                __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/2 Forested Plain with Deer");
                            end

                        end
                    else
                        -- floodplains and floodplains Civs
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 3/0 Wheat Plains Floodplains");
                        end
                    end
                    -- Desert
                elseif (target_plot_1:GetTerrainType() == 6 or target_plot_1:GetTerrainType() == 7 or (target_plot_1:GetTerrainType() == 8 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                        -- on Desert -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.5) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            --ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Desert Hill");
                        elseif (rng >= 0.0 and rng < 0.5) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 7);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Desert Hill");
                        end
                    else
                        -- floodplains
                        if (target_plot_1:GetResourceCount() < 1 and target_plot_1:GetFeatureType() ~= g_FEATURE_OASIS) then
                            ResourceBuilder.SetResourceType(target_plot_1, 9, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 2/0 Wheat Desert Floodplains");
                        end
                    end
                    -- Tundra
                elseif (target_plot_1:GetTerrainType() == 9 or target_plot_1:GetTerrainType() == 10 or (target_plot_1:GetTerrainType() == 11 and flag ~= 3 and target_plot_1:GetFeatureType() ~= g_FEATURE_VOLCANO)) then
                    if (target_plot_1:GetFeatureType() ~= g_FEATURE_MARSH) then
                        -- +5 on Tundra -> impossible
                        rng = TerrainBuilder.GetRandomNumber(100, "test") / 100
                        if (rng >= 0.66) then
                            -- Hill with Sheep
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 7, 1);
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/1 Sheep Tundra Hill");
                        elseif (rng >= 0.1 and rng < 0.66) then
                            -- Copper Hill
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 2, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Copper Tundra Hill");
                        elseif (rng >= 0.0 and rng < 0.1) then
                            -- Forested Deer
                            TerrainBuilder.SetTerrainType(target_plot_1, 10);
                            TerrainBuilder.SetFeatureType(target_plot_1, -1);
                            TerrainBuilder.SetFeatureType(target_plot_1, 3);
                            ResourceBuilder.SetResourceType(target_plot_1, -1);
                            ResourceBuilder.SetResourceType(target_plot_1, 4, 1)
                            __Debug("Terraforming Best X: ", target_plot_1:GetX(), "Y: ", target_plot_1:GetY(), "Added 1/0/2 Deer Tundra Hill");
                        end
                    end

                end

            end
        end
    end

end

------------------------------------------------------------------------------

function Terraforming_Water(plot)
    if plot == nil or plot:IsWater() then
        return;
    end

    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local adjacentPlot = nil;

    --------------------------------------------------------------------------------------------------------------
    -- Terraforming Water Start ----------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------

    for i = 0, 5 do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            local adjacentWater = false;
            for j = 0, 5 do
                local adjacentPlot_j = GetAdjacentTiles(adjacentPlot, j);
                if (adjacentPlot_j ~= nil and adjacentPlot_j:IsWater() == true) then
                    adjacentWater = true;
                end
            end
            if (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:IsUnit() == false and adjacentWater == false and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND) then
                __Debug("Terraforming Water X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Water Lake");
                TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                TerrainBuilder.SetTerrainType(adjacentPlot, 15);
                return
            end
        end

    end
    -- Second round if you have an unit -- todo later moving the unit to starting plot to allow the lake to be placed
    for i = 0, 5 do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            local adjacentWater = false;
            for j = 0, 5 do
                local adjacentPlot_j = GetAdjacentTiles(adjacentPlot, j);
                if (adjacentPlot_j ~= nil and adjacentPlot_j:IsWater() == true) then
                    adjacentWater = true;
                end
            end
            if (adjacentPlot:GetResourceCount() < 1 and adjacentWater == false and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND) then
                __Debug("Terraforming Water X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Water Lake but unit was on the way");
                TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                TerrainBuilder.SetTerrainType(adjacentPlot, 15);
                return
            end
        end

    end
    -- third round remove resources so water get priority
    for i = 0, 5 do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            local adjacentWater = false;
            for j = 0, 5 do
                local adjacentPlot_j = GetAdjacentTiles(adjacentPlot, j);
                if (adjacentPlot_j ~= nil and adjacentPlot_j:IsWater() == true) then
                    adjacentWater = true;
                end
            end
            if (adjacentWater == false and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND) then
                __Debug("Terraforming Water X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Water Lake but unit was on the way");
                ResourceBuilder.SetResourceType(adjacentPlot, -1);
                TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                TerrainBuilder.SetTerrainType(adjacentPlot, 15);
                return
            end
        end

    end

end

------------------------------------------------------------------------------

function Terraforming_Flood(plot, intensity)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    intensity = intensity or 1
    local max_water = 0;
    local harborplot_index = nil;
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    local bTerraform = true;
    local limit = 0;
    local limit_1 = 0.25 / intensity;
    local limit_2 = 0.5 / intensity;
    local limit_3 = 0.75 / intensity;
    local limit_4 = 1 / intensity;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;


    --------------------------------------------------------------------------------------------------------------
    -- Terraforming Floodplains Start ----------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------

    for i = -1, 17 do
        adjacentPlot = GetAdjacentTiles(plot, i);

        if (i < 6) then
            limit = limit_1
        else
            limit = limit_2
        end

        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS or adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_GRASSLAND) and adjacentPlot:IsNaturalWonder() == false then
                local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if (rng > limit / 2) then
                    __Debug("Terraforming Floodplains X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Removed: Floodplains");
                    if (i < 6) then
                        TerrainBuilder.SetFeatureType(plot, -1);
                    end
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                end
            end
        end

    end
end

------------------------------------------------------------------------------

function Terraforming_Coastal(plot, intensity, post_correction)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    intensity = intensity or 1
    local max_water = 0;
    local harborplot_index = nil;
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    local bTerraform = true;
    local count = 0;
    local limit = 0;
    local limit_1 = 0.75 / intensity;
    local limit_2 = 0.5 / intensity;
    local limit_3 = 0.33 / intensity;
    local limit_4 = 0.5 / intensity;
    local limit_5 = 0.5 / intensity;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;

    --------------------------------------------------------------------------------------------------------------
    -- Terraforming Coastal Start --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------




    -- Step 1  Getting a Valid Harbor
    max_water = 0;
    count = 0;
    harborplot_index = 0;
    for i = 0, 5 do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:IsWater() == true) then
                -- try to find the plot with a maximum number of adjacent water tile
                count = 0
                for j = 0, 5 do
                    adjacentPlot2 = GetAdjacentTiles(adjacentPlot, j);
                    if (adjacentPlot2 ~= nil) then
                        if (adjacentPlot2:IsWater() == true) then
                            count = count + 1;
                        end
                    end
                    if (count > max_water) then
                        max_water = count;
                        harborplot_index = i;
                    end
                end
            end
        end
    end


    -- Step 2 Cleaning the Location
    local harborPlot = nil
    if (harborplot_index ~= nil) then
        harborPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), harborplot_index);
        if (harborPlot ~= nil) then
            __Debug("Coastal Terraforming (Step 2) X: ", harborPlot:GetX(), "Y: ", harborPlot:GetY(), "Found a valid Harbor tile");
            ResourceBuilder.SetResourceType(harborPlot, -1);
            TerrainBuilder.SetFeatureType(harborPlot, -1);
        end
    end

    -- count
    local count_reefs = 0
    local count_resources = 0
    local count_water = 0
    for i = 0, 17 do
        --[[if (harborPlot ~= nil) then
			adjacentPlot = GetAdjacentTiles(harborPlot, i);
			else
			adjacentPlot = GetAdjacentTiles(plot, i);
		end--]]
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:IsWater() == true) then
                count_water = count_water + 1
            end
            if (adjacentPlot:GetFeatureType() == g_FEATURE_REEF) then
                count_reefs = count_reefs + 1;

            end
            if (adjacentPlot:IsWater() == true and adjacentPlot:GetResourceCount() > 0 and adjacentPlot:GetResourceType() ~= RESOURCE_OIL_INDEX) then
                count_resources = count_resources + 1;
            end
        end
    end
    __Debug("Count Waters: ", count_water);
    __Debug("Count Reefs: ", count_reefs);
    __Debug("Count Resources: ", count_resources);

    if count_water <= 1 then
        __Debug("Coastal Terraforming: Lake or Tiny Sea, stop there.")
        return
    end

    if (post_correction == false) then
        -- Step 3 Populating the harbor surrounding tiles

        for i = 0, 17 do
            --[[if (harborPlot ~= nil) then
				adjacentPlot = GetAdjacentTiles(harborPlot, i);
				else
				adjacentPlot = GetAdjacentTiles(plot, i);
		end--]]
            adjacentPlot = GetAdjacentTiles(plot, i);
            local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
            if (adjacentPlot ~= nil) then
                if (adjacentPlot:IsWater() == true and adjacentPlot:GetFeatureType() == -1 and (adjacentPlot:GetResourceCount() < 1 or adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX)) and adjacentPlot:IsNaturalWonder() == false then
                    if (count_resources < 3) and adjacentPlot:GetResourceCount() < 1 then
                        if (ResourceBuilder.CanHaveResource(adjacentPlot, RESOURCE_FISH_INDEX)) then
                            count_resources = count_resources + 1
                            ResourceBuilder.SetResourceType(adjacentPlot, RESOURCE_FISH_INDEX, 1);
                            TerrainBuilder.SetTerrainType(adjacentPlot, 15);
                            __Debug("Coastal Terraforming (Step 3) X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
                        end
                    end
                    if (rng > limit_1 and count_reefs < 1) and adjacentPlot:IsFreshWater() == false then
                        __Debug("Coastal Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Reef");
                        TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_REEF);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 15);
                        count_reefs = count_reefs + 1;
                        local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    elseif (((rng / count_resources > limit_2) or (count_resources < 3)) and adjacentPlot:GetResourceType() == -1) then
                        if (ResourceBuilder.CanHaveResource(adjacentPlot, RESOURCE_FISH_INDEX)) then
                            count_resources = count_resources + 1
                            ResourceBuilder.SetResourceType(adjacentPlot, RESOURCE_FISH_INDEX, 1);
                            __Debug("Coastal Terraforming (Step 3) X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
                        end

                    end
                end
            end
        end

        --6 12 18 24 30 36
        --补贴4～6环的鱼，靠近陆地
        local count_resources_4_6 = 0
        for i = 30 - 1, 126 - 1 do
            adjacentPlot = GetAdjacentTiles(plot, i);
            if (adjacentPlot ~= nil) then
                if (adjacentPlot:IsWater() == true and adjacentPlot:GetResourceCount() > 0 and adjacentPlot:GetResourceType() ~= RESOURCE_OIL_INDEX) then
                    count_resources_4_6 = count_resources_4_6 + 1;
                end
            end
        end

        --补贴鱼
        for i = 30 - 1, 126 - 1 do
            adjacentPlot = GetAdjacentTiles(plot, i);
            local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
            if (adjacentPlot ~= nil) then
                if rng > 0.33 and count_resources_4_6 < 5 and adjacentPlot:GetResourceCount() < 1 and adjacentPlot:IsWater() == true and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:IsNaturalWonder() == false then
                    if (TeamPVPIsAdjacentToLandAndNotAdjacent(adjacentPlot) == true) then
                        if (ResourceBuilder.CanHaveResource(adjacentPlot, RESOURCE_FISH_INDEX)) then
                            count_resources_4_6 = count_resources_4_6 + 1
                            ResourceBuilder.SetResourceType(adjacentPlot, RESOURCE_FISH_INDEX, 1);
                            TerrainBuilder.SetTerrainType(adjacentPlot, 15);
                            print("Coastal Terraforming (Step 4~6) X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
                        end
                    end
                end
            end
        end

        --移除密集鱼
        for i = 18 - 1, 126 - 1 do
            adjacentPlot = GetAdjacentTiles(plot, i);
            if (adjacentPlot ~= nil) then
                --判断为海资源格
                if adjacentPlot:GetResourceCount() > 0 and adjacentPlot:IsWater() == true and adjacentPlot:GetFeatureType() == -1 and adjacentPlot:IsNaturalWonder() == false then
                    --只移除鱼、螃蟹
                    if (adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX or adjacentPlot:GetResourceType() == 3) then
                        --过于密集
                        if (TeamPVPGetAdjacentWaterResourceCount(adjacentPlot) >= 3) then
                            --移除
                            --ResourceBuilder.SetResourceType(adjacentPlot, -1);
                            print("Coastal Terraforming (Step 3~6) X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "remove: Fish");
                        end
                    end

                end
            end
        end

        local count_reefs = 0
        local count_resources = 0
        for i = 0, 60 do
            --[[if (harborPlot ~= nil) then
			adjacentPlot = GetAdjacentTiles(harborPlot, i);
			else
			adjacentPlot = GetAdjacentTiles(plot, i);
		end--]]
            adjacentPlot = GetAdjacentTiles(plot, i);
            if (adjacentPlot ~= nil) then
                if (adjacentPlot:GetFeatureType() == g_FEATURE_REEF) then
                    count_reefs = count_reefs + 1;

                end
                if (adjacentPlot:IsWater() == true and adjacentPlot:GetResourceCount() > 0) then
                    count_resources = count_resources + 1;
                end
            end
        end
        __Debug("Count Reefs: ", count_reefs);
        __Debug("Count Resources: ", count_resources);

        -- Step 4 Ocean to Coast and Ice removal
        for i = 0, 60 do

            if (i < 6) then
                limit = limit_3;
            elseif (i > 5 and i < 18) then
                limit = limit_4;
            elseif (i > 18) then
                limit = limit_5;
            end

            adjacentPlot = GetAdjacentTiles(plot, i);
            if (adjacentPlot ~= nil) then
                terrainType = adjacentPlot:GetTerrainType();
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if (terrainType == 16) and rng > limit and (adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX or adjacentPlot:GetResourceCount() < 1) and adjacentPlot:IsNaturalWonder() == false then
                    __Debug("Terraforming Coastal X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Ocean to Coast tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 15);
                    local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if (adjacentPlot:GetFeatureType() == -1 and rng > limit and adjacentPlot:GetResourceType() == -1 and ((count_resources < 3 and i < 17) or (count_resources <= 6 and i > 36)) and (post_correction == false) and adjacentPlot:IsFreshWater() == false) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_REEF);
                        __Debug("Coastal Terraforming (Step 4) X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Reef", i);
                        count_resources = count_resources + 1;
                        local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                        if ((rng / count_resources / count_resources) > limit and adjacentPlot:GetResourceType() == -1) then
                            -- Reef with fish
                            __Debug("Coastal Terraforming (Step 4) X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Fish");
                            ResourceBuilder.SetResourceType(adjacentPlot, RESOURCE_FISH_INDEX, 1);
                        end
                    end

                    if (adjacentPlot:GetFeatureType() == 1 and rng > limit / 2) then
                        __Debug("Costal Terraforming (Step 4) X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Removing Ice", i);
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                    end
                end
            end


        end

    end
    print("Coastal Terraforming : Total Reefs Count:", count_reefs, "Total Sea Resources:", count_resources);

end

------------------------------------------------------------------------------

function Terraforming(plot, intensity, flag)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    local bTerraform = true;
    local limit = 0;
    local limit_1 = 0;
    local limit_2 = 0;
    local limit_3 = 0;
    local limit_4 = 0;
    local limit_tree = 0;
    local max_wood = 5;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local count_wood = 0;
    local d_factor = 0;

    --------------------------------------------------------------------------------------------------------------
    -- Terraforming the Tundra/Snow/Desert  ----------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------

    print("TeamPVP Terraforming Start X: ", plot:GetX(), "Terraforming Start Y: ", plot:GetY());


    -- #0 to #100 Tiles
    for i = -1, 80 do
        if (i < 6) then
            limit = limit_1
            d_factor = -1
        elseif (i > 5 and i < 18) then
            limit = limit_2
            d_factor = -1
        elseif (i > 17 and i < 36) then
            limit = limit_3
            d_factor = -1
        else
            limit = limit_4
            d_factor = 600
        end
        adjacentPlot = GetAdjacentTiles(plot, i);

        if (adjacentPlot ~= nil) then
            if adjacentPlot:IsNaturalWonder() == false then
                terrainType = adjacentPlot:GetTerrainType()
                if (adjacentPlot:GetFeatureType() == g_FEATURE_OASIS and flag ~= 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Oasis", i);
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                end
                if (adjacentPlot:GetFeatureType() == 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Ice", i);
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if ((terrainType == 9) and rng > limit and flag ~= 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Tundra to Plains tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS);
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if world_age == 1 and adjacentPlot:GetResourceCount() == 0 and adjacentPlot:GetFeatureType() < 4 and rng < 0.20 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Make it a Plains hill", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    end
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() == 0 and rng < 0.15 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Add woods", i);
                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    end
                end
                if ((terrainType == 10) and rng > limit and flag ~= 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Tundra Hills to Plains Hills tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    if adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() == 0 and rng < 0.15 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Add woods", i);
                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    end
                end
                if ((terrainType == 6) and rng > limit and flag ~= 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Desert to Plains tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS);
                    if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS_PLAINS);
                    end
                end
                if ((terrainType == 7) and rng > limit and flag ~= 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Desert Hills to Plains Hills tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                end
                if (terrainType == 12) then
                    if (i < 18 and flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS);
                    elseif (i < 36 and flag == 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 9);
                    elseif (flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 9);
                    end
                end

                if (terrainType == 13) then
                    if (i < 18 and flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    elseif (i < 36 and flag == 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 10);
                    elseif (flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 10);
                    end
                end
                if ((terrainType == 4) and rng > limit and adjacentPlot:GetFeatureType() ~= g_FEATURE_JUNGLE and flag ~= 1 and flag ~= 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Grassland Hills tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                end
                if ((terrainType == 3) and rng > limit and adjacentPlot:GetFeatureType() ~= g_FEATURE_JUNGLE and flag ~= 1 and flag ~= 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Grassland tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 0);
                end
                if ((terrainType == 0) and flag == 2) then
                    ResourceBuilder.SetResourceType(adjacentPlot, -1);
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland to Plains tile", i);
                    if (adjacentPlot:GetFeatureType() == g_FEATURE_MARSH) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                    end
                    TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                    terrainType = 3;
                    if (adjacentPlot:IsRiver() == true) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS_PLAINS);
                    end
                end
                if ((terrainType == 1) and flag == 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland Hills to Plains Hills tile", i);
                    ResourceBuilder.SetResourceType(adjacentPlot, -1);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                    terrainType = 4;
                end
                if ((terrainType == 2) and adjacentPlot:GetResourceCount() < 1 and flag == 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland Mountains to Plains Mountains tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 5);
                    terrainType = 5;
                end

                -- 沙漠文明绿地变沙地
                if (terrainType == 3 or terrainType == 4 or terrainType == 5) and flag == 2 then
                    local d_count = 0
                    local adjacentPlot2 = nil
                    for k = 0, 5 do
                        adjacentPlot2 = GetAdjacentTiles(adjacentPlot, k)
                        if adjacentPlot2 ~= nil then
                            if adjacentPlot2:GetTerrainType() == 6 or adjacentPlot2:GetTerrainType() == 7 or adjacentPlot2:GetTerrainType() == 8 then
                                d_count = d_count + 1
                            end
                        end
                    end
                    if d_count > d_factor then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Plains to Desert tile", i);
                        ResourceBuilder.SetResourceType(adjacentPlot, -1);
                        TerrainBuilder.SetTerrainType(adjacentPlot, terrainType + 3);
                        if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        elseif (adjacentPlot:IsRiver() == true and rng < 0.7) and terrainType == 3 then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        else
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        end
                    end
                end

                -- 冻土文明炸冻土
                if (terrainType >= 0 and terrainType <= 2) and flag == 1 then
                    if (i < 89) then
                        local originalResourceIndex = adjacentPlot:GetResourceType();
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 9);
                        if (adjacentPlot:GetFeatureType() ~= g_FEATURE_FOREST and adjacentPlot:GetFeatureType() ~= -1) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FOREST);
                        end
                        if originalResourceIndex ~= -1 then
                            ZYL_RVC_RestoreTundraResource(adjacentPlot, originalResourceIndex, TERRAIN_TUNDRA_RESOURCE);
                        end
                    end
                end
                if (terrainType >= 3 and terrainType <= 5) and flag == 1 then
                    if (i < 89) then
                        local originalResourceIndex = adjacentPlot:GetResourceType();
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 10);
                        if (adjacentPlot:GetFeatureType() ~= g_FEATURE_FOREST and adjacentPlot:GetFeatureType() ~= -1) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FOREST);
                        end
                        if originalResourceIndex ~= -1 then
                            ZYL_RVC_RestoreTundraResource(adjacentPlot, originalResourceIndex, TERRAIN_TUNDRA_HILLS_RESOURCE);
                        end
                    end
                end

                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if (adjacentPlot:IsWater() == false and adjacentPlot:IsImpassable() == false and adjacentPlot:GetTerrainType() ~= 12 and adjacentPlot:GetTerrainType() ~= 13 and adjacentPlot:GetTerrainType() ~= 6 and adjacentPlot:GetTerrainType() ~= 7 and adjacentPlot:GetFeatureType() == -1 and rng > limit_tree and adjacentPlot:GetResourceType() == -1 and count_wood < max_wood) then
                    TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    count_wood = count_wood + 1;
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Wood", i);
                end
            end
        end
    end
    count_wood = 0;
    __Debug("Terraforming East Side");

    if (MapConfiguration.GetValue("MapName") == nil) then
        return
    else
        if (MapConfiguration.GetValue("MapName") == "Tilted_Axis") then
            __Debug("Terraforming: Tilted Axis map");
            return
        end
    end

    local east_plot = plot;--GetAdjacentTiles(plot, 80);

    if (east_plot == nil) then
        return
    end

    -- #0 to #100 Tiles
    for i = -1, 80 do
        if (i < 6) then
            limit = limit_1
            d_factor = -1
        elseif (i > 5 and i < 18) then
            limit = limit_2
            d_factor = -1
        elseif (i > 17 and i < 36) then
            limit = limit_3
            d_factor = -1
        else
            limit = limit_4
            d_factor = 600
        end
        adjacentPlot = GetAdjacentTiles(east_plot, i);
        --__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Terrain Type: ", terrainType);
        --__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Feature Type: ", adjacentPlot:GetFeatureType());

        if (adjacentPlot ~= nil) then
            if adjacentPlot:IsNaturalWonder() == false then
                terrainType = adjacentPlot:GetTerrainType()
                if (adjacentPlot:GetFeatureType() == g_FEATURE_OASIS and flag ~= 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Oasis", i);
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                end
                if (adjacentPlot:GetFeatureType() == 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Ice", i);
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if ((terrainType == 9) and rng > limit and flag ~= 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Tundra to Plains tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS);
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if world_age == 1 and adjacentPlot:GetResourceCount() == 0 and adjacentPlot:GetFeatureType() < 4 and rng < 0.20 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Make it a Plains hill", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    end
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() == 0 and rng < 0.15 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Add woods", i);
                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    end
                end
                if ((terrainType == 10) and rng > limit and flag ~= 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Tundra Hills to Plains Hills tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    if adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() == 0 and rng < 0.15 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Add woods", i);
                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    end
                end
                if (terrainType == 12) then
                    if (i < 18 and flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS);
                    elseif (flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 9);
                    end
                end
                if (terrainType == 13) then
                    if (i < 18 and flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    elseif (flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 10);
                    end
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if ((terrainType == 0) and flag == 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland to Plains tile", i);
                    ResourceBuilder.SetResourceType(adjacentPlot, -1);
                    if (adjacentPlot:GetFeatureType() == g_FEATURE_MARSH) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                    end
                    TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                    if (adjacentPlot:IsRiver() == true) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS_PLAINS);
                    end
                end
                if ((terrainType == 1) and flag == 2) then
                    print("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland Hills to Plains Hills tile", i);
                    ResourceBuilder.SetResourceType(adjacentPlot, -1);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                end
                if ((terrainType == 2) and adjacentPlot:GetResourceCount() < 1 and flag == 2) then
                    print("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland Mountains to Plains Mountains tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 5);
                end
                if ((terrainType == 3 or terrainType == 4 or terrainType == 5) and flag == 2) then
                    local d_count = 0
                    local adjacentPlot2 = nil
                    for k = 0, 5 do
                        adjacentPlot2 = GetAdjacentTiles(adjacentPlot, k)
                        if adjacentPlot2 ~= nil then
                            if adjacentPlot2:GetTerrainType() == 6 or adjacentPlot2:GetTerrainType() == 7 or adjacentPlot2:GetTerrainType() == 8 then
                                d_count = d_count + 1
                            end
                        end
                    end
                    if d_count > d_factor then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Plains to Desert tile", i);
                        ResourceBuilder.SetResourceType(adjacentPlot, -1);
                        TerrainBuilder.SetTerrainType(adjacentPlot, terrainType + 3);
                        if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        elseif (adjacentPlot:IsRiver() == true and rng < 0.33) and terrainType == 3 then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        else
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        end
                    end
                end
                if (adjacentPlot:IsWater() == false and adjacentPlot:IsImpassable() == false and adjacentPlot:GetTerrainType() ~= 12 and adjacentPlot:GetTerrainType() ~= 13 and adjacentPlot:GetTerrainType() ~= 6 and adjacentPlot:GetTerrainType() ~= 7 and adjacentPlot:GetFeatureType() == -1 and rng > limit_tree and adjacentPlot:GetResourceType() == -1 and count_wood < max_wood) then
                    TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    count_wood = count_wood + 1;
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Wood", i);
                end
            end
        end


    end
    count_wood = 0;
    __Debug("Terraforming West Side");
    local west_plot = plot;--GetAdjacentTiles(plot, 80);

    if (west_plot == nil) then
        return
    end

    -- #0 to #100 Tiles
    for i = 80, -1, -1 do
        if (i < 6) then
            limit = limit_1
            d_factor = -1
        elseif (i > 5 and i < 18) then
            limit = limit_2
            d_factor = -1
        elseif (i > 17 and i < 36) then
            limit = limit_3
            d_factor = -1
        else
            limit = limit_4
            d_factor = -1
        end
        adjacentPlot = GetAdjacentTiles(west_plot, i);
        print("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "i: ", i);
        --__Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Feature Type: ", adjacentPlot:GetFeatureType());

        if (adjacentPlot ~= nil) then
            if adjacentPlot:IsNaturalWonder() == false then
                terrainType = adjacentPlot:GetTerrainType()
                if (adjacentPlot:GetFeatureType() == g_FEATURE_OASIS and flag ~= 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Oasis", i);
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                end
                if (adjacentPlot:GetFeatureType() == 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Remove Ice", i);
                    TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if ((terrainType == 9) and rng > limit and flag ~= 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Tundra to Plains tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS);
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if world_age == 1 and adjacentPlot:GetResourceCount() == 0 and adjacentPlot:GetFeatureType() < 4 and rng < 0.20 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Make it a Plains hill", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    end
                    rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                    if adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() == 0 and rng < 0.15 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Add woods", i);
                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    end
                end
                if ((terrainType == 10) and rng > limit and flag ~= 1) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Tundra Hills to Plains Hills tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    if adjacentPlot:GetFeatureType() == -1 and adjacentPlot:GetResourceCount() == 0 and rng < 0.15 then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Add woods", i);
                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    end
                end
                if (terrainType == 12) then
                    if (i < 18 and flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS);
                    elseif (flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 9);
                    end
                end
                if (terrainType == 13) then
                    if (i < 18 and flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Plain tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_PLAINS_HILLS);
                    elseif (flag ~= 1) then
                        __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing to Tundra tile", i);
                        TerrainBuilder.SetTerrainType(adjacentPlot, 10);
                    end
                end
                rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                if ((terrainType == 0) and flag == 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland to Plains tile", i);
                    ResourceBuilder.SetResourceType(adjacentPlot, -1);
                    if (adjacentPlot:GetFeatureType() == g_FEATURE_MARSH) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                    end
                    TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                    if (adjacentPlot:IsRiver() == true) then
                        TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS_PLAINS);
                    end
                end
                if ((terrainType == 1) and flag == 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland Hills to Plains Hills tile", i);
                    ResourceBuilder.SetResourceType(adjacentPlot, -1);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                end
                if ((terrainType == 2) and adjacentPlot:GetResourceCount() < 1 and flag == 2) then
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Grassland Mountains to Plains Mountains tile", i);
                    TerrainBuilder.SetTerrainType(adjacentPlot, 5);
                end
                print("TeamPVP adjacentPlot i=", i, ";terrainType=", terrainType);
                if ((terrainType == 3 or terrainType == 4 or terrainType == 5) and flag == 2) then
                    local d_count = 0
                    local adjacentPlot2 = nil
                    for k = 0, 5 do
                        adjacentPlot2 = GetAdjacentTiles(adjacentPlot, k)
                        if adjacentPlot2 ~= nil then
                            if adjacentPlot2:GetTerrainType() == 6 or adjacentPlot2:GetTerrainType() == 7 or adjacentPlot2:GetTerrainType() == 8 then
                                d_count = d_count + 1
                            end
                        end
                    end
                    if d_count > d_factor then
                        print("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Plains to Desert tile", i);
                        ResourceBuilder.SetResourceType(adjacentPlot, -1);
                        TerrainBuilder.SetTerrainType(adjacentPlot, terrainType + 3);
                        if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        elseif (adjacentPlot:IsRiver() == true and rng < 0.33 and terrainType == 3) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        else
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        end
                    end
                end
                if ((terrainType == 0 or terrainType == 1 or terrainType == 2) and flag == 2) then
                    local d_count = 0
                    local adjacentPlot2 = nil
                    for k = 0, 5 do
                        adjacentPlot2 = GetAdjacentTiles(adjacentPlot, k)
                        if adjacentPlot2 ~= nil then
                            if adjacentPlot2:GetTerrainType() == 6 or adjacentPlot2:GetTerrainType() == 7 or adjacentPlot2:GetTerrainType() == 8 then
                                d_count = d_count + 1
                            end
                        end
                    end
                    print("TeamPVP d_count:", d_count, "d_factor:", d_factor);
                    if d_count > d_factor then
                        print("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Changing Plains to Desert tile", i);
                        ResourceBuilder.SetResourceType(adjacentPlot, -1);
                        TerrainBuilder.SetTerrainType(adjacentPlot, terrainType + 6);
                        if (adjacentPlot:GetFeatureType() == g_FEATURE_FLOODPLAINS_PLAINS) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        elseif (adjacentPlot:IsRiver() == true and rng < 0.33 and terrainType == 3) then
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            TerrainBuilder.SetFeatureType(adjacentPlot, g_FEATURE_FLOODPLAINS);
                        else
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                        end
                    end
                end
                if (adjacentPlot:IsWater() == false and adjacentPlot:IsImpassable() == false and adjacentPlot:GetTerrainType() ~= 12 and adjacentPlot:GetTerrainType() ~= 13 and adjacentPlot:GetTerrainType() ~= 6 and adjacentPlot:GetTerrainType() ~= 7 and adjacentPlot:GetFeatureType() == -1 and rng > limit_tree and adjacentPlot:GetResourceType() == -1 and count_wood < max_wood) then
                    TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                    count_wood = count_wood + 1;
                    __Debug("Terraforming X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added: Wood", i);
                end
            end
        end


    end
    ----------------------------------------------------------------------
    --------------------- Terraforming Completed -------------------------
    ----------------------------------------------------------------------


end

------------------------------------------------------------------------------
function RemoveProd(plot)

    local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
    if rng > 0.5 then
        for j = 0, 17 do
            rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
            local otherPlot = GetAdjacentTiles(plot, j);
            --__Debug("Evaluate Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Terrain Type: ", terrainType);
            if otherPlot ~= nil then
                if (otherPlot:GetResourceType() == 4 or otherPlot:GetResourceType() == 8) then
                    __Debug("Prod balancing: Prod Removed", otherPlot:GetResourceType());
                    ResourceBuilder.SetResourceType(otherPlot, -1);
                    return true;
                end
                if (otherPlot:GetFeatureType() == 3 and otherPlot:GetResourceCount() < 1 and rng > 0.5) then
                    TerrainBuilder.SetFeatureType(otherPlot, -1);
                    __Debug("Prod balancing: Wood Removed");
                    return true;
                end
            end
        end
    else
        for j = 17, 0, -1 do
            rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
            local otherPlot = GetAdjacentTiles(plot, j);
            if otherPlot ~= nil then
                --__Debug("Evaluate Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Terrain Type: ", terrainType);
                if (otherPlot:GetResourceType() == 4) then
                    __Debug("Prod balancing: Prod Removed", otherPlot:GetResourceType());
                    ResourceBuilder.SetResourceType(otherPlot, -1);
                    return true;
                end
                if (otherPlot:GetFeatureType() == 3 and otherPlot:GetResourceCount() < 1 and rng > 0.5) then
                    TerrainBuilder.SetFeatureType(otherPlot, -1);
                    __Debug("Prod balancing: Wood Removed");
                    return true;
                end
                if (otherPlot:GetResourceType() == 8) then
                    __Debug("Prod balancing: Prod Removed", otherPlot:GetResourceType());
                    ResourceBuilder.SetResourceType(otherPlot, -1);
                    return true;
                end
            end
        end
    end
    __Debug("Prod balancing: Couldn't Remove Production through feature / resources, attempt Terrain");
    for j = 0, 17 do
        local otherPlot = GetAdjacentTiles(plot, j);
        --__Debug("Evaluate Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Terrain Type: ", terrainType);
        if otherPlot ~= nil then
            if (otherPlot:GetTerrainType() == 4 or otherPlot:GetTerrainType() == 1) and otherPlot:GetResourceType() == -1 then
                __Debug("Prod balancing: Prod Removed - Removed a Hill");
                TerrainBuilder.SetTerrainType(otherPlot, otherPlot:GetTerrainType() - 1)
                return true;
            end
        end
    end
    __Debug("Prod balancing: Failed to Remove Production ");
    return false;
end

------------------------------------------------------------------------------
function RemoveFood(plot)

    local rng = TerrainBuilder.GetRandomNumber(100, "test") / 100;
    if rng > 0.5 then
        for j = 0, 17 do
            local otherPlot = GetAdjacentTiles(plot, j);
            --__Debug("Evaluate Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Terrain Type: ", terrainType);
            if otherPlot ~= nil then
                if (otherPlot:GetResourceType() == 0 or otherPlot:GetResourceType() == 1 or otherPlot:GetResourceType() == 6 or otherPlot:GetResourceType() == 9) then
                    __Debug("Food balancing: Food Removed", otherPlot:GetResourceType());
                    ResourceBuilder.SetResourceType(otherPlot, -1);
                    return true;
                end
                if ((otherPlot:GetFeatureType() == 2 or otherPlot:GetFeatureType() == 5) and otherPlot:GetResourceCount() < 1) then
                    TerrainBuilder.SetFeatureType(otherPlot, -1);
                    __Debug("Food balancing: Jungle/Marsh Removed");
                    return true;
                end
            end
        end
    else
        for j = 17, 0, -1 do
            local otherPlot = GetAdjacentTiles(plot, j);
            --__Debug("Evaluate Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Terrain Type: ", terrainType);
            if otherPlot ~= nil then
                if ((otherPlot:GetFeatureType() == 2 or otherPlot:GetFeatureType() == 5) and otherPlot:GetResourceCount() < 1) then
                    TerrainBuilder.SetFeatureType(otherPlot, -1);
                    __Debug("Food balancing: Jungle/Marsh Removed");
                    return true;
                end
                if (otherPlot:GetResourceType() == 0 or otherPlot:GetResourceType() == 1 or otherPlot:GetResourceType() == 6 or otherPlot:GetResourceType() == 9) then
                    __Debug("Food balancing: Food Removed", otherPlot:GetResourceType());
                    ResourceBuilder.SetResourceType(otherPlot, -1);
                    return true;
                end
            end
        end
    end
    __Debug("Food balancing: Couldn't Remove Food");
    return false;
end

------------------------------------------------------------------------------
function Terraforming_BanLux(plot)
    for j = 0, 17 do
        local otherPlot = GetAdjacentTiles(plot, j);
        if otherPlot ~= nil then
            __Debug("Check Luxury Start X: ", otherPlot:GetX(), "Evaluate Start Y: ", otherPlot:GetY(), "Resource Type: ", otherPlot:GetResourceType());
            if (otherPlot:GetResourceType() == 11 or otherPlot:GetResourceType() == 27 or otherPlot:GetResourceType() == 28) then
                __Debug("Luxury balancing: Banned Luxury Removed", otherPlot:GetResourceType());
                ResourceBuilder.SetResourceType(otherPlot, -1);
                return true;
            end
        end
    end
end
------------------------------------------------------------------------------

function ZYL_RVC_LegacyBalanceStrategic(plot, leader)
    local iResourcesInDB = 0;
    local iStartEra = GameInfo.Eras[GameConfiguration.GetStartEra()];
    local iStartIndex = 1;
    local direction = 0;

    if iStartEra ~= nil then
        iStartIndex = iStartEra.ChronologyIndex;
    end
    print("iStartIndex", iStartIndex);
    --[[ Corrupted legacy log text retained only as a comment.
    print("BBSStratRes：", MapConfiguration.GetValue("BBSStratRes"));
    ]]
    print("BBSStratRes", MapConfiguration.GetValue("BBSStratRes"));
    -- 40 Aluminium
    -- 41 Coal
    -- 42 Horse
    -- 43 Iron
    -- 44 Niter
    -- 45 Oil
    -- 46 Uranium

    if MapConfiguration.GetValue("BBSStratRes") == 2 then
        local strategicResources = {
            RESOURCE_ALUMINUM_INDEX,
            RESOURCE_COAL_INDEX,
            RESOURCE_HORSES_INDEX,
            RESOURCE_IRON_INDEX,
            RESOURCE_NITER_INDEX,
            RESOURCE_OIL_INDEX,
            RESOURCE_URANIUM_INDEX
        };

        for _, resourceIndex in ipairs(strategicResources) do
            local bHasResource = false;
            if resourceIndex >= 0 then
                __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check for ", resourceIndex, " Guaranteed");
                bHasResource = FindResource(resourceIndex, plot);
                if (bHasResource == false) then
                    __Debug("Balance Resources: Need to add", resourceIndex);
                    PlaceResource(resourceIndex, plot, leader);
                end
            end
        end

    else

        if (iStartIndex == 1) then
            local bHasResource = false;
            if (FindResource(42, plot) == false) then
                bHasResource = PlaceResource(42, plot, leader);
            end

            if (FindResource(43, plot) == false) then
                bHasResource = PlaceResource(43, plot, leader);
            end
            --[[_Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Horse");
            bHasResource = FindResource(42, plot);
            if(bHasResource == false) then
                print("Balance Resources: Need to add Horses");
                PlaceResource(42, plot,leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Iron");
            bHasResource = FindResource(43, plot);
            if(bHasResource == false) then
                __Debug("Balance Resources: Need to add Iron");
                PlaceResource(43, plot,leader);
            end]]
            -- Broader Check Oil & Niter & Aluminium + Coal
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Oil");
            bHasResource = ContinentResource(45, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Iron");
                PlaceResource(45, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Niter");
            bHasResource = FindResource(44, plot, 100);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Niter");
                PlaceResource(44, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Aluminium");
            bHasResource = ContinentResource(40, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Aluminium");
                PlaceResource(40, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Coal");
            bHasResource = ContinentResource(41, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Coal");
                PlaceResource(41, plot, leader);
            end

            -- Classical or Medieval
        elseif (iStartIndex == 2 or iStartIndex == 3) then
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Horse");
            bHasResource = FindResource(42, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Horses");
                PlaceResource(42, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Iron");
            bHasResource = FindResource(43, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Iron");
                PlaceResource(43, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Niter");
            bHasResource = FindResource(44, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Niter");
                PlaceResource(44, plot, leader);
            end
            -- Broader Check Oil & Aluminium + Coal
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Oil");
            bHasResource = ContinentResource(45, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Iron");
                PlaceResource(45, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Aluminium");
            bHasResource = ContinentResource(40, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Aluminium");
                PlaceResource(40, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Coal");
            bHasResource = ContinentResource(41, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Coal");
                PlaceResource(41, plot, leader);
            end

            --
        elseif (iStartIndex == 4 or iStartIndex == 5) then
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Coal");
            bHasResource = FindResource(41, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Coal");
                PlaceResource(41, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Iron");
            bHasResource = FindResource(43, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Iron");
                PlaceResource(43, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Niter");
            bHasResource = FindResource(44, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Niter");
                PlaceResource(44, plot, leader);
            end
            -- Broader Check Oil & Aluminium
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Oil");
            bHasResource = ContinentResource(45, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Iron");
                PlaceResource(45, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Aluminium");
            bHasResource = ContinentResource(40, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Aluminium");
                PlaceResource(40, plot, leader);
            end

            --

        elseif (iStartIndex == 6) then
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Coal");
            bHasResource = FindResource(41, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Coal");
                PlaceResource(41, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Oil");
            bHasResource = FindResource(45, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Niter");
                PlaceResource(45, plot, leader);
            end
            -- Broader Aluminium
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Aluminium");
            bHasResource = ContinentResource(40, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Aluminium");
                PlaceResource(40, plot, leader);
            end

        elseif (iStartIndex > 6) then
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Aluminium");
            bHasResource = FindResource(40, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Aluminium");
                PlaceResource(40, plot, leader);
            end
            __Debug("Evaluate Start X: ", plot:GetX(), "Evaluate Start Y: ", plot:GetY(), "Check Oil");
            bHasResource = FindResource(45, plot);
            if (bHasResource == false) then
                __Debug("Balance Resources: Need to add Oil");
                PlaceResource(45, plot, leader);
            end
        end
    end
end

------------------------------------------------------------------------------
function BalanceStrategic(plot, leader)
    local startEra = GameInfo.Eras[GameConfiguration.GetStartEra()];
    local startIndex = startEra ~= nil and startEra.ChronologyIndex or 1;

    local function EnsureResource(resourceIndex, useContinentSearch, range)
        if resourceIndex < 0 then
            return;
        end

        local hasResource;
        if useContinentSearch then
            hasResource = ContinentResource(resourceIndex, plot);
        else
            hasResource = FindResource(resourceIndex, plot, range);
        end

        if hasResource == false then
            __Debug("Balance Resources: Need to add", resourceIndex);
            PlaceResource(resourceIndex, plot, leader);
        end
    end

    print("Start era index", startIndex);
    print("BBSStratRes", MapConfiguration.GetValue("BBSStratRes"));

    if MapConfiguration.GetValue("BBSStratRes") == 2 then
        local strategicResources = {
            RESOURCE_ALUMINUM_INDEX,
            RESOURCE_COAL_INDEX,
            RESOURCE_HORSES_INDEX,
            RESOURCE_IRON_INDEX,
            RESOURCE_NITER_INDEX,
            RESOURCE_OIL_INDEX,
            RESOURCE_URANIUM_INDEX
        };

        for _, resourceIndex in ipairs(strategicResources) do
            EnsureResource(resourceIndex, false);
        end
    elseif startIndex == 1 then
        EnsureResource(RESOURCE_HORSES_INDEX, false);
        EnsureResource(RESOURCE_IRON_INDEX, false);
        EnsureResource(RESOURCE_OIL_INDEX, true);
        EnsureResource(RESOURCE_NITER_INDEX, false, 100);
        EnsureResource(RESOURCE_ALUMINUM_INDEX, true);
        EnsureResource(RESOURCE_COAL_INDEX, true);
    elseif startIndex == 2 or startIndex == 3 then
        EnsureResource(RESOURCE_HORSES_INDEX, false);
        EnsureResource(RESOURCE_IRON_INDEX, false);
        EnsureResource(RESOURCE_NITER_INDEX, false);
        EnsureResource(RESOURCE_OIL_INDEX, true);
        EnsureResource(RESOURCE_ALUMINUM_INDEX, true);
        EnsureResource(RESOURCE_COAL_INDEX, true);
    elseif startIndex == 4 or startIndex == 5 then
        EnsureResource(RESOURCE_COAL_INDEX, false);
        EnsureResource(RESOURCE_IRON_INDEX, false);
        EnsureResource(RESOURCE_NITER_INDEX, false);
        EnsureResource(RESOURCE_OIL_INDEX, true);
        EnsureResource(RESOURCE_ALUMINUM_INDEX, true);
    elseif startIndex == 6 then
        EnsureResource(RESOURCE_COAL_INDEX, false);
        EnsureResource(RESOURCE_OIL_INDEX, false);
        EnsureResource(RESOURCE_ALUMINUM_INDEX, true);
    elseif startIndex > 6 then
        EnsureResource(RESOURCE_ALUMINUM_INDEX, false);
        EnsureResource(RESOURCE_OIL_INDEX, false);
    end
end

------------------------------------------------------------------------------
function PlaceResource(eResourceType, plot, leader)
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    local adjacentPlot = nil;
    -- Place a ressource, first inner ring, then anywhere in 4 tiles


    -- Inner ring
    -- Tiles #6 to #17
    for i = 6, 17 do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetResourceCount() == 0) and adjacentPlot:IsNaturalWonder() == false then
                if (ResourceBuilder.CanHaveResource(adjacentPlot, eResourceType) and adjacentPlot:IsImpassable() == false) then
                    ResourceBuilder.SetResourceType(adjacentPlot, eResourceType, 1);
                    __Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Added: ", eResourceType);
                    return true;
                end
            end

        end
    end

    if (eResourceType == RESOURCE_HORSES_INDEX or eResourceType == RESOURCE_IRON_INDEX) then
        local functionCount = 0;
        local successCount = 0;
        local isForce = false;

        print("PlaceResource leader:", leader);

        while (functionCount <= 20) do
            --大于10次失败 或是蒸汽英国补贴马
            if (functionCount >= 10 or (leader == "LEADER_VICTORIA_ALT" and eResourceType == RESOURCE_HORSES_INDEX)) then
                isForce = true;
            end
            local functionResult = civAddStrategyTeamPVP(eResourceType, plot, isForce);

            if (functionResult == functionResultFalse) then
                functionCount = functionCount + 1;
            elseif functionResult == functionResultTrue then
                functionCount = functionCount + 1;
                successCount = successCount + 1;
            elseif functionResult == functionResultSuccess or functionResult == functionResultFail then
                print("successCount:", successCount);
                break ;
            end
        end

        if (successCount >= 1) then
            return true;
        end
        print("functionCount:", functionCount);
    end

    -- Anywhere within in a 5 tiles radius
    for i = 0, 90 do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetResourceCount() == 0) and adjacentPlot:IsNaturalWonder() == false then
                if (ResourceBuilder.CanHaveResource(adjacentPlot, eResourceType) and adjacentPlot:IsImpassable() == false) then
                    ResourceBuilder.SetResourceType(adjacentPlot, eResourceType, 1);
                    __Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Added: ", eResourceType);
                    return true;
                end
            end

        end
    end

    __Debug("Balance Resources: Failed to Add:", eResourceType);
    return false;
end

------------------------------------------------------------------------------
function FindResource(eResourceType, plot, strength)
    local gridWidth, gridHeight = Map.GetGridSize();
    -- Checks to see if there is a specific strategic in a given distance
    local adjacentPlot = nil;
    if strength == nil then
        strength = 60
    end
    strength = 36;

    for i = 0, strength do
        adjacentPlot = GetAdjacentTiles(plot, i);
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetResourceCount() > 0) then
                if (eResourceType == adjacentPlot:GetResourceType()) then
                    __Debug("Evaluate Start X: ", adjacentPlot:GetX(), "Evaluate Start Y: ", adjacentPlot:GetY(), "Found Type: ", adjacentPlot:GetResourceType());
                    return true;
                end
            end

        end

    end

    return false;
end

------------------------------------------------------------------------------
function ContinentResource(eResourceType, plot)
    local gridWidth, gridHeight = Map.GetGridSize();
    -- Checks to see if there is a specific strategic on a specific continent
    local adjacentPlot = nil;
    local ContinentNum = plot:GetContinentType()
    local ContinentPlots = Map.GetContinentPlots(ContinentNum);
    __Debug("Check Continent:", ContinentNum, " For resource:", eResourceType);

    for i, plot in ipairs(ContinentPlots) do
        if plot ~= nil then
            local pPlot = Map.GetPlotByIndex(plot)
            if (pPlot ~= nil) then
                if (pPlot:GetResourceCount() > 0) then
                    if (eResourceType == pPlot:GetResourceType()) then
                        __Debug("ContinentResource X: ", pPlot:GetX(), " Y: ", pPlot:GetY(), "Found Type: ", pPlot:GetResourceType());
                        return true;
                    end
                end
            end

        end

    end

    return false;
end

------------------------------------------------------------------------------
function AddLuxuryStarting(plot, s_type, flag, majListCiv)
    -- Checks to see if it can place a nearby luxury
    local terrainType = plot:GetTerrainType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local iResourcesInDB = 0;
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    local currentContinent = plot:GetContinentType();
    local direction = 0;
    local bHasLuxury = false;
    local adjacentPlot = plot;
    eAddLux = {};
    eAddLux_Terrain = {};
    eAddLux_Feature = {};
    local count = 0;

    -- Find what luxury are on the current continent
    plots = Map.GetContinentPlots(currentContinent);
    for i, plot in ipairs(plots) do

        local pPlot = Map.GetPlotByIndex(plot);
        if (pPlot ~= nil) then
            if (pPlot:GetResourceCount() > 0) and pPlot:IsNaturalWonder() == false then
                -- 10 is citrus, 34 is jeans
                if ((pPlot:GetResourceType() >= 10 and pPlot:GetResourceType() < 34 and pPlot:GetResourceType() ~= 27 and pPlot:GetResourceType() ~= 28 and pPlot:GetResourceType() ~= 11 and s_type ~= "plains")
                        or (pPlot:GetResourceType() == 14 and pPlot:GetResourceType() == 16 and pPlot:GetResourceType() == 17 and pPlot:GetResourceType() == 26 and pPlot:GetResourceType() == 31 and s_type ~= "plains")
                        or pPlot:GetResourceType() == 53) then
                    bHasLuxury = true;
                    --__Debug("found luxury at X",  pPlot:GetX(), "Y: ", pPlot:GetY());
                    count = count + 1;
                    table.insert(eAddLux, pPlot:GetResourceType());
                    table.insert(eAddLux_Terrain, pPlot:GetTerrainType());
                    table.insert(eAddLux_Feature, pPlot:GetFeatureType());
                end
            end
        end

    end

    -- Try placing a Luxury in the 2 inner rings

    if (bHasLuxury == true) then
        for i = 17, 0, -1 do
            adjacentPlot = GetAdjacentTiles(plot, i);
            if (adjacentPlot ~= nil) then
                for j = 1, count do
                    if ((adjacentPlot:GetTerrainType() == eAddLux_Terrain[j]) and (adjacentPlot:GetResourceType() == -1)) and adjacentPlot:IsNaturalWonder() == false then
                        TerrainBuilder.SetFeatureType(adjacentPlot, eAddLux_Feature[j]);
                        __Debug("Balancing X: ", adjacentPlot:GetX(), "Y: ", adjacentPlot:GetY(), "Added a Luxury:", eAddLux[j]);
                        ResourceBuilder.SetResourceType(adjacentPlot, eAddLux[j], 1);
                        return true;
                    end
                end
            end

        end
    end

    __Debug("Balancing X: ", plotX, "Y: ", plotY, "Failed to add a Luxury");

    if (s_type == "food") then
        return AddBonusFood(plot,  math.floor(RichNum * 0.4), flag, majListCiv);
    end
    if (s_type == "prod") then
        return AddBonusProd(plot,  math.floor(RichNum * 0.4), flag);
    end
    return false;
end

-------------------------------------------------------------------------------------------------------
local FlagsData = { }
function GetCLFlag(Type)
    if FlagsData[Type] then
        return FlagsData[Type]
    end
    local Flag = 0
    if GameInfo.NW_StartBias[Type] then
        Flag = GameInfo.NW_StartBias[Type].Flag or 0
    end
    FlagsData[Type] = Flag
    return Flag
end
------------------------------------------------------------------------------
function IsTundraCiv(Type)
    return GetCLFlag(Type) == 1
end
------------------------------------------------------------------------------
function IsDesertCiv(Type)
    return GetCLFlag(Type) == 2
end
------------------------------------------------------------------------------
function IsMountainCiv(Type)
    return GetCLFlag(Type) == 3
end
------------------------------------------------------------------------------
function IsSeaStartCiv(Type)
    if GameInfo.Leaders_XP2[Type] and GameInfo.Leaders_XP2[Type].OceanStart == 1 then
        return true
    end
    return false
end
------------------------------------------------------------------------------
function IsFloodCiv(civilizationType)
    for row in GameInfo.StartBiasTerrains() do
        if (row.CivilizationType == civilizationType) then
            if row.FeatureType ~= nil then
                if row.FeatureType == "FEATURE_FLOODPLAINS" or row.FeatureType == "FEATURE_FLOODPLAINS_GRASSLAND" or row.FeatureType == "FEATURE_FLOODPLAINS_PLAINS" then
                    return true
                end
            end
        end
    end
    return false
end
------------------------------------------------------------------------------
function IsForestCiv(civilizationType)
    if (civilizationType == "CIVILIZATION_NORWAY") then
        --print("IsForestCiv civilizationType:",civilizationType);
        return true;
    end
    return false
end
------------------------------------------------------------------------------
function IsJungleCiv(civilizationType)
    if (civilizationType == "CIVILIZATION_BRAZIL" or civilizationType == "CIVILIZATION_KONGO") then
        --print("IsJungleCiv civilizationType:",civilizationType);
        return true;
    end
    return false
end
------------------------------------------------------------------------------
function IsLuxuryCiv(civilizationType)
    if (civilizationType == "CIVILIZATION_FRANCE") then
        --print("IsJungleCiv civilizationType:",civilizationType);
        return true;
    end
    return false
end
------------------------------------------------------------------------------
function IsForestAndJungleCiv(civilizationType)
    if (civilizationType == "CIVILIZATION_VIETNAM") then
        --print("IsForestCiv civilizationType:",civilizationType);
        return true;
    end
    return false
end
------------------------------------------------------------------------------
function IsBananaCiv(civilizationType)
    if (civilizationType == "CIVILIZATION_MAYA") then
        print("IsBananaCiv civilizationType:", civilizationType);
        return true;
    end
    return false
end
------------------------------------------------------------------------------
function IsPastureCiv(civilizationType)
    if (civilizationType == "CIVILIZATION_AUSTRALIA" or civilizationType == "CIVILIZATION_SCYTHIA" or civilizationType == "CIVILIZATION_MONGOLIA") then
        --print("IsPastureCiv civilizationType:",civilizationType);
        return true;
    end
    return false
end
------------------------------------------------------------------------------
function IsHuntCiv(civilizationType)
    if (civilizationType == "CIVILIZATION_CANADA" or civilizationType == "CIVILIZATION_SUK_TIBET") then
        print("IsHuntCiv civilizationType:", civilizationType);
        return true;
    end
    return false
end

function GetAdjacentTiles(plot, index)
    -- This is an extended version of Firaxis, moving like a clockwise snail on the hexagon grids
    local gridWidth, gridHeight = Map.GetGridSize();
    local count = 0;
    local k = 0;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local adjacentPlot5 = nil;


    -- Return Spawn if index < 0
    if (plot ~= nil and index ~= nil) then
        if (index < 0) then
            return plot;
        end

    else

        __Debug("GetAdjacentTiles: Invalid Arguments");
        return nil;
    end



    -- Return Starting City Circle if index between #0 to #5 (like Firaxis' GetAdjacentPlot)
    for i = 0, 5 do
        if (plot:GetX() >= 0 and plot:GetY() < gridHeight) then
            adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
            if (adjacentPlot ~= nil and index == i) then
                return adjacentPlot
            end
        end
    end

    -- Return Inner City Circle if index between #6 to #17

    count = 5;
    for i = 0, 5 do
        if (plot:GetX() >= 0 and plot:GetY() < gridHeight) then
            adjacentPlot2 = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
        end

        for j = i, i + 1 do
            --__Debug(i, j)
            k = j;
            count = count + 1;

            if (k == 6) then
                k = 0;
            end

            if (adjacentPlot2 ~= nil) then
                if (adjacentPlot2:GetX() >= 0 and adjacentPlot2:GetY() < gridHeight) then
                    adjacentPlot = Map.GetAdjacentPlot(adjacentPlot2:GetX(), adjacentPlot2:GetY(), k);

                else

                    adjacentPlot = nil;
                end
            end

            if (adjacentPlot ~= nil) then
                if (index == count) then
                    return adjacentPlot
                end
            end

        end
    end

    -- #18 to #35 Outer city circle
    count = 0;
    for i = 0, 5 do
        if (plot:GetX() >= 0 and plot:GetY() < gridHeight) then
            adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
            adjacentPlot2 = nil;
            adjacentPlot3 = nil;
        else
            adjacentPlot = nil;
            adjacentPlot2 = nil;
            adjacentPlot3 = nil;
        end
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
            end
            if (adjacentPlot3 ~= nil) then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 18 + i * 3;
            if (index == count) then
                return adjacentPlot2
            end
        end

        adjacentPlot2 = nil;

        if (adjacentPlot3 ~= nil) then
            if (i + 1) == 6 then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
                end
            else
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i + 1);
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 18 + i * 3 + 1;
            if (index == count) then
                return adjacentPlot2
            end
        end

        adjacentPlot2 = nil;

        if (adjacentPlot ~= nil) then
            if (i + 1 == 6) then
                if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
                end
                if (adjacentPlot3 ~= nil) then
                    if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                        adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
                    end
                end
            else
                if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i + 1);
                end
                if (adjacentPlot3 ~= nil) then
                    if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                        adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i + 1);
                    end
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 18 + i * 3 + 2;
            if (index == count) then
                return adjacentPlot2;
            end
        end

    end

    --  #35 #59 These tiles are outside the workable radius of the city
    local count = 0
    for i = 0, 5 do
        if (plot:GetX() >= 0 and plot:GetY() < gridHeight) then
            adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
            adjacentPlot2 = nil;
            adjacentPlot3 = nil;
            adjacentPlot4 = nil;
        else
            adjacentPlot = nil;
            adjacentPlot2 = nil;
            adjacentPlot3 = nil;
            adjacentPlot4 = nil;
        end
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
            end
            if (adjacentPlot3 ~= nil) then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
                    if (adjacentPlot4 ~= nil) then
                        if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                            adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
                        end
                    end
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            terrainType = adjacentPlot2:GetTerrainType();
            if (adjacentPlot2 ~= nil) then
                count = 36 + i * 4;
                if (index == count) then
                    return adjacentPlot2;
                end
            end

        end

        if (adjacentPlot3 ~= nil) then
            if (i + 1) == 6 then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
                end
            else
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i + 1);
                end
            end
        end

        if (adjacentPlot4 ~= nil) then
            if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
                if (adjacentPlot2 ~= nil) then
                    count = 36 + i * 4 + 1;
                    if (index == count) then
                        return adjacentPlot2;
                    end
                end
            end


        end

        adjacentPlot4 = nil;

        if (adjacentPlot ~= nil) then
            if (i + 1 == 6) then
                if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
                end
                if (adjacentPlot3 ~= nil) then
                    if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
                    end
                end
            else
                if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i + 1);
                end
                if (adjacentPlot3 ~= nil) then
                    if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i + 1);
                    end
                end
            end
        end

        if (adjacentPlot4 ~= nil) then
            if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
                if (adjacentPlot2 ~= nil) then
                    count = 36 + i * 4 + 2;
                    if (index == count) then
                        return adjacentPlot2;
                    end

                end
            end

        end

        adjacentPlot4 = nil;

        if (adjacentPlot ~= nil) then
            if (i + 1 == 6) then
                if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
                end
                if (adjacentPlot3 ~= nil) then
                    if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
                    end
                end
            else
                if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i + 1);
                end
                if (adjacentPlot3 ~= nil) then
                    if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i + 1);
                    end
                end
            end
        end

        if (adjacentPlot4 ~= nil) then
            if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                if (i + 1 == 6) then
                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
                else
                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i + 1);
                end
                if (adjacentPlot2 ~= nil) then
                    count = 36 + i * 4 + 3;
                    if (index == count) then
                        return adjacentPlot2;
                    end

                end
            end

        end

    end

    --  > #60 to #90

    local count = 0
    for i = 0, 5 do
        if (plot:GetX() >= 0 and plot:GetY() < gridHeight) then
            adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i); --first ring
            adjacentPlot2 = nil;
            adjacentPlot3 = nil;
            adjacentPlot4 = nil;
            adjacentPlot5 = nil;
        else
            adjacentPlot = nil;
            adjacentPlot2 = nil;
            adjacentPlot3 = nil;
            adjacentPlot4 = nil;
            adjacentPlot5 = nil;
        end
        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i); --2nd ring
            end
            if (adjacentPlot3 ~= nil) then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i); --3rd ring
                    if (adjacentPlot4 ~= nil) then
                        if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                            adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i); --4th ring
                            if (adjacentPlot5 ~= nil) then
                                if (adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
                                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i); --5th ring
                                end
                            end
                        end
                    end
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 60 + i * 5;
            if (index == count) then
                return adjacentPlot2; --5th ring
            end
        end

        adjacentPlot2 = nil;

        if (adjacentPlot5 ~= nil) then
            if (i + 1) == 6 then
                if (adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
                end
            else
                if (adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i + 1);
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 60 + i * 5 + 1;
            if (index == count) then
                return adjacentPlot2;
            end

        end

        adjacentPlot2 = nil;

        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
            end
            if (adjacentPlot3 ~= nil) then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
                    if (adjacentPlot4 ~= nil) then
                        if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                            if (i + 1 == 6) then
                                adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
                            else
                                adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i + 1);
                            end
                            if (adjacentPlot5 ~= nil) then
                                if (adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
                                    if (i + 1 == 6) then
                                        adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
                                    else
                                        adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i + 1);
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 60 + i * 5 + 2;
            if (index == count) then
                return adjacentPlot2;
            end

        end

        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                if (i + 1 == 6) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
                else
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i + 1); -- 2 ring
                end
            end
            if (adjacentPlot3 ~= nil) then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    if (i + 1 == 6) then
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
                    else
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i + 1); -- 3ring

                    end
                    if (adjacentPlot4 ~= nil) then
                        if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                            if (i + 1 == 6) then
                                adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
                            else
                                adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i + 1); --4th ring
                            end
                            if (adjacentPlot5 ~= nil) then
                                if (adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
                                    adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i); --5th ring
                                end
                            end
                        end
                    end
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 60 + i * 5 + 3;
            if (index == count) then
                return adjacentPlot2;
            end

        end

        adjacentPlot2 = nil

        if (adjacentPlot ~= nil) then
            if (adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
                if (i + 1 == 6) then
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
                else
                    adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i + 1); -- 2 ring
                end
            end
            if (adjacentPlot3 ~= nil) then
                if (adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
                    if (i + 1 == 6) then
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
                    else
                        adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i + 1); -- 3ring

                    end
                    if (adjacentPlot4 ~= nil) then
                        if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
                            if (i + 1 == 6) then
                                adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
                            else
                                adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i + 1); --4th ring
                            end
                            if (adjacentPlot5 ~= nil) then
                                if (adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
                                    if (i + 1 == 6) then
                                        adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0); --5th ring
                                    else
                                        adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i + 1); --5th ring
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        if (adjacentPlot2 ~= nil) then
            count = 60 + i * 5 + 4;
            if (index == count) then
                return adjacentPlot2;
            end

        end

    end

end

-----------------------------------------------------------------------------
function __Debug(...)
    print(...);
end

function __AddLeyLine(plot)
    local plotX = plot:GetX();
    local plotY = plot:GetY();
    for row in GameInfo.Resources() do
        if (row.ResourceClassType == "RESOURCECLASS_LEY_LINE") then
            for dx = -2, 2, 1 do
                for dy = -2, 2, 1 do
                    local otherPlot = Map.GetPlotXY(plotX, plotY, dx, dy, 2);
                    if (otherPlot) and otherPlot:GetIndex() ~= plot:GetIndex() then
                        if ResourceBuilder.CanHaveResource(otherPlot, row.Index) then
                            ResourceBuilder.SetResourceType(otherPlot, row.Index, 1);
                            return ;
                        end
                    end
                end
            end
        end
    end
end

-----------------------------------------------------------------------------
function __isHaveLuxury(plot)

    for i = 0, 17 do
        local pPlot = GetAdjacentTiles(plot, i);
        if (pPlot ~= nil) then
            if (pPlot:GetResourceCount() > 0) and pPlot:IsNaturalWonder() == false then
                -- 10 is citrus, 34 is jeans
                if ((pPlot:GetResourceType() >= 10 and pPlot:GetResourceType() < 34 and pPlot:GetResourceType() ~= 27 and pPlot:GetResourceType() ~= 28 and pPlot:GetResourceType() ~= 11 and s_type ~= "plains")
                        or (pPlot:GetResourceType() == 14 and pPlot:GetResourceType() == 16 and pPlot:GetResourceType() == 17 and pPlot:GetResourceType() == 26 and pPlot:GetResourceType() == 31 and s_type ~= "plains")
                        or pPlot:GetResourceType() == 53) then
                    return true;
                end
            end
        end
    end
    return false;

end
-----------------------------------------------------------------------------
function __countLuxuryTeamPVP(plot)
    local count = 0;
    for i = 0, 17 do
        local pPlot = GetAdjacentTiles(plot, i);
        if (pPlot ~= nil) then
            if (pPlot:GetResourceCount() > 0) and pPlot:IsNaturalWonder() == false then
                -- 10 is citrus, 34 is jeans
                if ((pPlot:GetResourceType() >= 10 and pPlot:GetResourceType() < 34 and pPlot:GetResourceType() ~= 27 and pPlot:GetResourceType() ~= 28 and pPlot:GetResourceType() ~= 11 and s_type ~= "plains")
                        or (pPlot:GetResourceType() == 14 and pPlot:GetResourceType() == 16 and pPlot:GetResourceType() == 17 and pPlot:GetResourceType() == 26 and pPlot:GetResourceType() == 31 and s_type ~= "plains")
                        or pPlot:GetResourceType() == 53) then
                    count = count + 1;
                end
            end
        end
    end
    return count;
end

function civAddFoodTeamPVP(startPlot, sPlayerLeaderName, sPlayerCivName, successCount, isLucky)
    print("civAddFoodTeamPVP start sPlayerLeaderName:", sPlayerLeaderName);
    local AddLuxuryStartFlag = "food";

    if (startPlot == nil) then
        return functionResultFail;
    end
    if (sPlayerLeaderName == nil) then
        return functionResultFail;
    end
    if (sPlayerCivName == nil) then
        return functionResultFail;
    end
    --获取玩家当前地块数据
    local tempEval = EvaluateStartingLocation(startPlot);
    local majList = { leader = sPlayerLeaderName, civ = sPlayerCivName, plotX = startPlot:GetX(), plotY = startPlot:GetY(), food_spawn_start = tempEval[5], prod_spawn_start = tempEval[6], culture_spawn_start = tempEval[7], faith_spawn_start = tempEval[8], impassable_start = tempEval[9], water_start = tempEval[10], snow_start = tempEval[11], desert_start = tempEval[12],
                      impassable_inner = tempEval[13], water_inner = tempEval[14], snow_inner = tempEval[15], desert_inner = tempEval[16], impassable_outer = tempEval[17], water_outer = tempEval[18], snow_outer = tempEval[19], desert_outer = tempEval[20], flood = tempEval[21], hill_start = tempEval[22], hill_inner = tempEval[23], prod_adjust = tempEval[6], food_adjust = tempEval[5],
                      best_tile = tempEval[24], best_tile_2 = tempEval[25], food_spawn_inner = tempEval[26], prod_spawn_inner = tempEval[27], best_tile_inner = tempEval[28], best_tile_inner_2 = tempEval[29], plains = tempEval[30] }
    local plotX = majList.plotX;
    local plotY = majList.plotY;
    --要求玩家出生地不是海水单元格（排除毛利等）
    if (Map.GetPlot(plotX, plotY):IsWater() == true) then
        --是在水上出生 结束补贴食物
        return functionResultFail;
    end
    --获取文明标签 0普通文明，1冻土文明，2沙漠文明，3山脉文明
    local civFlag = 0;
    if GetCLFlag(majList.civ) ~= 0 then
        civFlag = GetCLFlag(majList.civ)
    end
    if GetCLFlag(majList.leader) ~= 0 then
        civFlag = GetCLFlag(majList.civ)
    end
    if civFlag == 1 or civFlag == 2 then

    end

    --沙漠文明只补0次
    if civFlag == 2 and (successCount >= 0) and majList.desert_start > 0 then
        return functionResultSuccess;
    elseif civFlag == 1 and (successCount >= 2) and majList.snow_start > 0 then
        return functionResultSuccess;
    end
    --运气补正
    local luckyDeviationNumber = 0;
    if (isLucky == true) then
        luckyDeviationNumber = 1;
    end
    --计算最小食物数
    local minFood = 5 + iBalancingOneDeviationNumber + luckyDeviationNumber;

    --判断玩家食物
    local foodStart = majList.food_spawn_start / 2 + majList.food_spawn_inner / 2;
    print("civAddFoodTeamPVP food_spawn_start:", majList.food_spawn_start / 2);
    print("civAddFoodTeamPVP food_spawn_inner:", majList.food_spawn_inner / 2);
    print("civAddFoodTeamPVP minFood:", minFood);
    if (foodStart >= minFood) then
        --充足 结束补贴食物
        return functionResultSuccess;
    end
    --不足 准备补贴

    --为玩家增加食物
    local addFoodResult = false;
    --如果没有奢侈，预先提供奢侈
    --如果是奢侈文明，则判断他的奢侈数量
    if (IsLuxuryCiv(majList.civ)) then
        if (__countLuxuryTeamPVP(Map.GetPlot(plotX, plotY)) < 2) then
            addFoodResult = AddLuxuryStarting(Map.GetPlot(plotX, plotY), AddLuxuryStartFlag, civFlag, majList.civ);
        end
    elseif (majList.civ ~= MALI_CIVILIZATION_TYPE and __isHaveLuxury(Map.GetPlot(plotX, plotY)) == false) then
        addProdResult = AddLuxuryStarting(Map.GetPlot(plotX, plotY), AddLuxuryStartFlag, civFlag, majList.civ);
    end
    --奢侈没有成功补上，或者未补贴过，补贴一个食物
    if (addFoodResult == false) then
        addFoodResult = AddBonusFood(Map.GetPlot(plotX, plotY),  math.floor(RichNum * 0.4), civFlag, majList.civ);
    end
    --返回结果
    if (addFoodResult) then
        return functionResultTrue;
    else
        return functionResultFalse;
    end
end

function civRemoveFoodTeamPVP(startPlot, sPlayerLeaderName, sPlayerCivName)
    if (startPlot == nil) or sPlayerLeaderName == nil or sPlayerCivName == nil then
        return functionResultFail;
    end
    --获取玩家当前地块数据
    local tempEval = EvaluateStartingLocation(startPlot);
    local majList = { leader = sPlayerLeaderName, civ = sPlayerCivName, plotX = startPlot:GetX(), plotY = startPlot:GetY(), food_spawn_start = tempEval[5], prod_spawn_start = tempEval[6], culture_spawn_start = tempEval[7], faith_spawn_start = tempEval[8], impassable_start = tempEval[9], water_start = tempEval[10], snow_start = tempEval[11], desert_start = tempEval[12],
                      impassable_inner = tempEval[13], water_inner = tempEval[14], snow_inner = tempEval[15], desert_inner = tempEval[16], impassable_outer = tempEval[17], water_outer = tempEval[18], snow_outer = tempEval[19], desert_outer = tempEval[20], flood = tempEval[21], hill_start = tempEval[22], hill_inner = tempEval[23], prod_adjust = tempEval[6], food_adjust = tempEval[5],
                      best_tile = tempEval[24], best_tile_2 = tempEval[25], food_spawn_inner = tempEval[26], prod_spawn_inner = tempEval[27], best_tile_inner = tempEval[28], best_tile_inner_2 = tempEval[29], plains = tempEval[30] }
    local plotX = majList.plotX;
    local plotY = majList.plotY;
    --要求玩家出生地不是海水单元格（排除毛利等）
    if (Map.GetPlot(plotX, plotY):IsWater() == true) then
        --是在水上出生 结束补贴食物
        return functionResultFail;
    end
    --计算最大食物数
    local maxFood = 9 + iBalancingOneDeviationNumber;
    --判断玩家食物
    local foodStart = majList.food_spawn_start / 2 + majList.food_spawn_inner / 2;
    if (foodStart <= maxFood) then
        --充足 结束补贴食物
        return functionResultSuccess;
    end--过多 准备移除

    RemoveFood(Map.GetPlot(plotX, plotY));

    return functionResultTrue;
end

function civAddProdTeamPVP(startPlot, sPlayerLeaderName, sPlayerCivName, successCount, isLucky)
    print("civAddProdTeamPVP start sPlayerLeaderName:", sPlayerLeaderName);
    local AddLuxuryStartFlag = "prod";

    if (startPlot == nil) or sPlayerLeaderName == nil or sPlayerCivName == nil then
        return functionResultFail;
    end
    --获取玩家当前地块数据
    local tempEval = EvaluateStartingLocation(startPlot);
    local majList = { leader = sPlayerLeaderName, civ = sPlayerCivName, plotX = startPlot:GetX(), plotY = startPlot:GetY(), food_spawn_start = tempEval[5], prod_spawn_start = tempEval[6], culture_spawn_start = tempEval[7], faith_spawn_start = tempEval[8], impassable_start = tempEval[9], water_start = tempEval[10], snow_start = tempEval[11], desert_start = tempEval[12],
                      impassable_inner = tempEval[13], water_inner = tempEval[14], snow_inner = tempEval[15], desert_inner = tempEval[16], impassable_outer = tempEval[17], water_outer = tempEval[18], snow_outer = tempEval[19], desert_outer = tempEval[20], flood = tempEval[21], hill_start = tempEval[22], hill_inner = tempEval[23], prod_adjust = tempEval[6], food_adjust = tempEval[5],
                      best_tile = tempEval[24], best_tile_2 = tempEval[25], food_spawn_inner = tempEval[26], prod_spawn_inner = tempEval[27], best_tile_inner = tempEval[28], best_tile_inner_2 = tempEval[29], plains = tempEval[30] }
    local plotX = majList.plotX;
    local plotY = majList.plotY;
    --要求玩家出生地不是海水单元格（排除毛利等）
    if (Map.GetPlot(plotX, plotY):IsWater() == true) then
        --是在水上出生 结束补贴食物
        return functionResultFail;
    end
    --获取文明标签 0普通文明，1冻土文明，2沙漠文明，3山脉文明
    local civFlag = 0;
    if (IsDesertCiv(majList.civ) and majList.desert_start > 0) then
        civFlag = 2;
        --沙漠文明只补3次
        if (successCount >= 3) then
            return functionResultSuccess;
        end
    elseif (IsTundraCiv(majList.civ) and majList.snow_start > 0) then
        civFlag = 1;
        --冻土文明只补1次
        if (successCount >= 1) then
            return functionResultSuccess;
        end
    elseif (IsMountainCiv(majList.leader) or IsMountainCiv(majList.civ)) then
        civFlag = 3;
    end
    --运气补正
    local luckyDeviationNumber = 0;
    if (isLucky == true) then
        luckyDeviationNumber = 0;
    end
    --计算最小产出数
    local minProd = 7 + iBalancingOneDeviationNumber + luckyDeviationNumber;
    --判断玩家产出
    local prodStart = majList.prod_spawn_start / 2 + majList.prod_spawn_inner / 2;
    print("civAddProdTeamPVP prod_spawn_start:", majList.prod_spawn_start / 2);
    print("civAddProdTeamPVP prod_spawn_inner:", majList.prod_spawn_inner / 2);
    if (prodStart >= minProd) then
        --充足 结束补贴产出
        return functionResultSuccess;
    end--不足 准备补贴

    --为玩家增加食物
    local addProdResult = false;
    --如果没有奢侈，预先提供奢侈
    --如果是奢侈文明，则判断他的奢侈数量
    if (IsLuxuryCiv(majList.civ)) then
        if (__countLuxuryTeamPVP(Map.GetPlot(plotX, plotY)) < 2) then
            addFoodResult = AddLuxuryStarting(Map.GetPlot(plotX, plotY), AddLuxuryStartFlag, civFlag, majList.civ);
        end
    elseif (majList.civ ~= MALI_CIVILIZATION_TYPE and __isHaveLuxury(Map.GetPlot(plotX, plotY)) == false) then
        addProdResult = AddLuxuryStarting(Map.GetPlot(plotX, plotY), AddLuxuryStartFlag, civFlag, majList.civ);
    end
    --奢侈没有成功补上，或者未补贴过，补贴一个产出
    if (addProdResult == false) then
        addProdResult = AddBonusProd(Map.GetPlot(plotX, plotY),  math.floor(RichNum * 0.4), civFlag, majList.civ);
    end
    --返回结果
    if (addProdResult) then
        return functionResultTrue;
    else
        return functionResultFalse;
    end
end

function civRemoveProdTeamPVP(startPlot, sPlayerLeaderName, sPlayerCivName)
    if (startPlot == nil) or sPlayerLeaderName == nil or sPlayerCivName == nil then
        return functionResultFail;
    end
    --获取玩家当前地块数据
    local tempEval = EvaluateStartingLocation(startPlot);
    local majList = { leader = sPlayerLeaderName, civ = sPlayerCivName, plotX = startPlot:GetX(), plotY = startPlot:GetY(), food_spawn_start = tempEval[5], prod_spawn_start = tempEval[6], culture_spawn_start = tempEval[7], faith_spawn_start = tempEval[8], impassable_start = tempEval[9], water_start = tempEval[10], snow_start = tempEval[11], desert_start = tempEval[12],
                      impassable_inner = tempEval[13], water_inner = tempEval[14], snow_inner = tempEval[15], desert_inner = tempEval[16], impassable_outer = tempEval[17], water_outer = tempEval[18], snow_outer = tempEval[19], desert_outer = tempEval[20], flood = tempEval[21], hill_start = tempEval[22], hill_inner = tempEval[23], prod_adjust = tempEval[6], food_adjust = tempEval[5],
                      best_tile = tempEval[24], best_tile_2 = tempEval[25], food_spawn_inner = tempEval[26], prod_spawn_inner = tempEval[27], best_tile_inner = tempEval[28], best_tile_inner_2 = tempEval[29], plains = tempEval[30] }
    local plotX = majList.plotX;
    local plotY = majList.plotY;
    --要求玩家出生地不是海水单元格（排除毛利等）
    if (Map.GetPlot(plotX, plotY):IsWater() == true) then
        --是在水上出生 结束补贴食物
        return functionResultFail;
    end
    --计算最大产出数
    local maxProd = 11 + iBalancingOneDeviationNumber;
    --判断玩家产出
    local prodStart = majList.prod_spawn_start / 2 + majList.prod_spawn_inner / 2;
    if (prodStart <= maxProd) then
        --充足 结束补贴产出
        return functionResultSuccess;
    end--过多 准备移除

    RemoveProd(Map.GetPlot(plotX, plotY));

    return functionResultTrue;
end

function civAddHillTeamPVP(startPlot, sPlayerLeaderName, sPlayerCivName, isLucky, civAddHillTeamPVP)
    print("丘陵补贴 start sPlayerLeaderName:", sPlayerLeaderName);
    if (startPlot == nil) or sPlayerLeaderName == nil or sPlayerCivName == nil then
        return functionResultFail;
    end
    --获取玩家当前地块数据
    local tempEval = EvaluateStartingLocation(startPlot);
    local majList = { leader = sPlayerLeaderName, civ = sPlayerCivName, plotX = startPlot:GetX(), plotY = startPlot:GetY(), food_spawn_start = tempEval[5], prod_spawn_start = tempEval[6], culture_spawn_start = tempEval[7], faith_spawn_start = tempEval[8], impassable_start = tempEval[9], water_start = tempEval[10], snow_start = tempEval[11], desert_start = tempEval[12],
                      impassable_inner = tempEval[13], water_inner = tempEval[14], snow_inner = tempEval[15], desert_inner = tempEval[16], impassable_outer = tempEval[17], water_outer = tempEval[18], snow_outer = tempEval[19], desert_outer = tempEval[20], flood = tempEval[21], hill_start = tempEval[22], hill_inner = tempEval[23], prod_adjust = tempEval[6], food_adjust = tempEval[5],
                      best_tile = tempEval[24], best_tile_2 = tempEval[25], food_spawn_inner = tempEval[26], prod_spawn_inner = tempEval[27], best_tile_inner = tempEval[28], best_tile_inner_2 = tempEval[29], plains = tempEval[30] }
    local plotX = majList.plotX;
    local plotY = majList.plotY;
    --要求玩家出生地不是海水单元格（排除毛利等）
    if (Map.GetPlot(plotX, plotY):IsWater() == true) then
        --是在水上出生 结束补贴食物
        return functionResultFail;
    end
    --获取文明标签 0普通文明，1冻土文明，2沙漠文明，3山脉文明
    local civFlag = 0;
    local civDeviationNumber = 0;
    if (IsDesertCiv(majList.civ) and majList.desert_start > 0) then
        civFlag = 2;
        civDeviationNumber = 1;
    elseif (IsTundraCiv(majList.civ) and majList.snow_start > 0) then
        civFlag = 1;
    elseif (IsMountainCiv(majList.leader) or IsMountainCiv(majList.civ)) then
        civFlag = 3;
        civDeviationNumber = 1;
    end
    --运气补正
    local luckyDeviationNumber = 0;
    if (isLucky == true) then
        luckyDeviationNumber = 1;
    end
    --计算最小丘陵数
    local minHill = 7 + iBalancingOneDeviationNumber + civDeviationNumber + luckyDeviationNumber;

    --判断玩家丘陵
    print("civAddHillTeamPVP majList.hill:", (majList.hill_start + majList.hill_inner));
    if (((majList.hill_start + majList.hill_inner)) >= minHill) then
        --充足 结束补贴丘陵
        return functionResultSuccess;
    end
    --不足 准备补贴
    --为玩家增加丘陵
    local addHillResult = AddHills(Map.GetPlot(plotX, plotY),  math.floor(RichNum * 0.4), 0, civAddHillTeamPVP);
    --返回结果
    if (addHillResult) then
        return functionResultTrue;
    else
        return functionResultFalse;
    end
end
--------
function AddBonusOneRing(plot, intensity, flag, isMust)
    -- flag = 0 normal
    -- flag = 1 tundra civ
    -- flag = 2 desert civ
    -- flag = 3 mountain civ
    local iResourcesInDB = 0;
    local terrainType = plot:GetTerrainType();
    local featureType = plot:GetFeatureType();
    local gridWidth, gridHeight = Map.GetGridSize();
    local direction = 0;
    eResourceType = {};
    eResourceClassType = {};
    aBonus = {};
    local limit_1 = 0;
    local max_unFeature = 2;
    local adjacentPlot = nil;
    local adjacentPlot2 = nil;
    local adjacentPlot3 = nil;
    local adjacentPlot4 = nil;
    local count = 0;
    local increment = 1;
    local start_range = 1;
    local end_range = 5;
    --方法变量
    local rngAdd = 0;--成功率附加
    local rngAddBlock = 14;--成功率附加每次失败递增
    local unSetrng = 0.5;--单元格基础失败率

    local rngSet = 0;--选择资源类型随机数，临时变量

    if (intensity == 0) then
        limit_1 = 0.9;
    else
        limit_1 = 0.5 / intensity;
    end

    for k = 0, 1 do

        if k == 0 then
            if (flag == 2 or flag == 1) then
                start_range = 1;
                end_range = 5;
                increment = 2;
            else
                start_range = 1;
                end_range = 5;--17
                increment = 1;
            end
        elseif k == 1 then
            if (flag == 2 or flag == 1) then
                start_range = 5;
                end_range = 1;
                increment = -1;
            else
                start_range = 5;
                end_range = 1;--17
                increment = -1;
            end
        end

        --检查是否已有2-2
        for i = start_range, end_range, increment do
            adjacentPlot = GetAdjacentTiles(plot, i)

            if (adjacentPlot ~= nil) then

                terrainType = adjacentPlot:GetTerrainType();
                --如果已有2-2或更大，则返回success
                if (adjacentPlot:GetYield(g_YIELD_PRODUCTION) >= 2 and adjacentPlot:GetYield(g_YIELD_FOOD) >= 2 and not ZYL_RVC_IsStrategicResource(adjacentPlot:GetResourceType()) and not ZYL_RVC_IsLeyLine(adjacentPlot:GetResourceType())) then
                    print("teamPVP checkGetYield success");
                    return true;
                end
            end
        end
        print("teamPVP checkGetYield：isMust", isMust);
        for i = start_range, end_range, increment do
            adjacentPlot = GetAdjacentTiles(plot, i)

            if (adjacentPlot ~= nil) then

                terrainType = adjacentPlot:GetTerrainType();
                if (isMust == true and addBonusOneRingIsDeleteResource == false and adjacentPlot:GetResourceCount() == 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:IsNaturalWonder() == false and adjacentPlot:IsImpassable() == false) then
                    local rng = (TerrainBuilder.GetRandomNumber(100, "test") + rngAdd) / 100;
                    if (rng > 0.7 and not ZYL_RVC_IsStrategicResource(adjacentPlot:GetResourceType()) and not ZYL_RVC_IsLeyLine(adjacentPlot:GetResourceType()) and (terrainType == 4 or terrainType == 3 or terrainType == 0 or terrainType == 1)) then
                        ResourceBuilder.SetResourceType(adjacentPlot, -1);
                        addBonusOneRingIsDeleteResource = true;
                        print("addBonusOneRingIsDeleteResource true Get", adjacentPlot:GetX(), ":", adjacentPlot:GetY());
                    end
                end
                if (adjacentPlot:GetResourceCount() < 1 and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_VOLCANO and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_PLAINS and adjacentPlot:GetFeatureType() ~= g_FEATURE_FLOODPLAINS_GRASSLAND and adjacentPlot:GetFeatureType() ~= g_FEATURE_MARSH and adjacentPlot:IsNaturalWonder() == false and adjacentPlot:IsImpassable() == false) then

                    rng = (TerrainBuilder.GetRandomNumber(100, "test") + rngAdd) / 100;

                    if ((terrainType == 4 or terrainType == 3) and adjacentPlot:GetFeatureType() == -1) then
                        --黄地丘陵
                        if (isMust == false and terrainType == 3) then
                            --非必要 无视平原
                            --跳过
                        else
                            --执行
                            if (rng > unSetrng) then
                                if (addFoodSheepCount < 2) then
                                    rngSet = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                                    if (rngSet > (0.75)) then
                                        -- 雨林
                                        if (isMust == true and terrainType == 3) then
                                            --升为丘陵
                                            TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                        end
                                        TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                        print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                        rngAdd = 0;
                                        return true;
                                    else
                                        --羊
                                        if (isMust == true and terrainType == 3) then
                                            --升为丘陵
                                            TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                        end
                                        if (ResourceBuilder.CanHaveResource(adjacentPlot, 7)) then
                                            ResourceBuilder.SetResourceType(adjacentPlot, 7, 1);
                                            __Debug("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: Sheep");
                                            rngAdd = 0;
                                            addFoodSheepCount = addFoodSheepCount + 1;
                                            print("teamPVP addFoodSheepCount:", addFoodSheepCount);
                                            return true;
                                        end
                                    end
                                else
                                    -- 雨林
                                    if (isMust == true and terrainType == 3) then
                                        --升为丘陵
                                        TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                    end
                                    TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                    print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                    rngAdd = 0;
                                    return true;
                                end
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end
                        end
                    elseif ((terrainType == 4 or terrainType == 3) and adjacentPlot:GetFeatureType() == 3) then
                        if (isMust == false and terrainType == 3) then
                            --非必要 无视平原
                            --跳过
                        else
                            --绿地丘陵
                            if (rng > unSetrng) then
                                -- 森林-》雨林
                                if (isMust == true and terrainType == 3) then
                                    --升为丘陵
                                    TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                                end
                                TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                                print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                                rngAdd = 0;
                                return true;
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end
                        end
                    elseif ((terrainType == 3) and adjacentPlot:GetFeatureType() == 2 and isMust == true) then
                        --黄地
                        if (rng > unSetrng) then
                            -- 平原雨林-》丘陵雨林
                            TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                            print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added Hill");
                            return true;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif ((terrainType == 3) and adjacentPlot:GetFeatureType() == -1 and isMust == true) then
                        --黄地
                        if (rng > unSetrng) then
                            -- 平原雨林-》丘陵雨林
                            TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                            print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added Hill");
                            TerrainBuilder.SetFeatureType(adjacentPlot, 2);
                            rint("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added: 雨林 on Plains Hill");
                            return true;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif ((terrainType == 0) and adjacentPlot:GetFeatureType() == 3 and isMust == true) then
                        --绿地
                        if (rng > unSetrng) then
                            -- 草原森林-》丘陵树林
                            TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                            print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added Hill");
                            return true;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif ((terrainType == 0) and adjacentPlot:GetFeatureType() == -1 and isMust == true) then
                        --绿地
                        if (rng > unSetrng) then
                            -- 草原森林-》丘陵树林
                            TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                            print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Added Hill");
                            TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                            print("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: 森林");
                            return true;
                        else
                            rngAdd = rngAdd + rngAddBlock;
                        end
                    elseif ((terrainType == 1 or terrainType == 0)
                            and (adjacentPlot:GetFeatureType() == -1)) then
                        if (isMust == false and terrainType == 0) then
                            --非必要 无视平原
                            --跳过
                        else
                            --绿地丘陵
                            if (rng > unSetrng) then
                                rngSet = TerrainBuilder.GetRandomNumber(100, "test") / 100;
                                if (stonesCounts < 3) then
                                    if (rngSet > (0.25)) then
                                        --石头
                                        if (isMust == true and terrainType == 0) then
                                            --升为丘陵
                                            TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                                        end
                                        stonesCounts = stonesCounts + 1;
                                        ResourceBuilder.SetResourceType(adjacentPlot, 8, 1);
                                        print("Food Balancing X: ", adjacentPlot:GetX(), "Food Balancing Y: ", adjacentPlot:GetY(), "Flat land with stones");
                                        rngAdd = 0;
                                        isAddStore = 1;
                                        return true;
                                    else
                                        --森林
                                        if (isMust == true and terrainType == 0) then
                                            --升为丘陵
                                            TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                                        end
                                        TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                        print("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: 森林");
                                        rngAdd = 0;
                                        isAddStore = -1;
                                        return true;
                                    end
                                else
                                    --森林
                                    if (isMust == true and terrainType == 0) then
                                        --升为丘陵
                                        TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                                    end
                                    TerrainBuilder.SetFeatureType(adjacentPlot, 3);
                                    print("Prod Balancing X: ", adjacentPlot:GetX(), "Prod Balancing Y: ", adjacentPlot:GetY(), "Added: 森林");
                                    rngAdd = 0;
                                    return true;
                                end
                            else
                                rngAdd = rngAdd + rngAddBlock;
                            end
                        end
                    end
                else
                    rngAdd = rngAdd + rngAddBlock;
                end
            end
        end
    end -- k end loop

    print("AddBonusOneRing false");
    return false;
end

function civAddOneRingFloorsTeamPVP(startPlot, sPlayerLeaderName, sPlayerCivName, isMust)
    if (startPlot == nil) or sPlayerLeaderName == nil or sPlayerCivName == nil then
        return functionResultFail;
    end
    --获取玩家当前地块数据
    local tempEval = EvaluateStartingLocation(startPlot);
    local majList = { leader = sPlayerLeaderName, civ = sPlayerCivName, plotX = startPlot:GetX(), plotY = startPlot:GetY(), food_spawn_start = tempEval[5], prod_spawn_start = tempEval[6], culture_spawn_start = tempEval[7], faith_spawn_start = tempEval[8], impassable_start = tempEval[9], water_start = tempEval[10], snow_start = tempEval[11], desert_start = tempEval[12],
                      impassable_inner = tempEval[13], water_inner = tempEval[14], snow_inner = tempEval[15], desert_inner = tempEval[16], impassable_outer = tempEval[17], water_outer = tempEval[18], snow_outer = tempEval[19], desert_outer = tempEval[20], flood = tempEval[21], hill_start = tempEval[22], hill_inner = tempEval[23], prod_adjust = tempEval[6], food_adjust = tempEval[5],
                      best_tile = tempEval[24], best_tile_2 = tempEval[25], food_spawn_inner = tempEval[26], prod_spawn_inner = tempEval[27], best_tile_inner = tempEval[28], best_tile_inner_2 = tempEval[29], plains = tempEval[30] }
    local plotX = majList.plotX;
    local plotY = majList.plotY;
    --要求玩家出生地不是海水单元格（排除毛利等）
    if (Map.GetPlot(plotX, plotY):IsWater() == true) then
        --是在水上出生 结束补贴一环保底
        return functionResultFail;
    end
    --获取文明标签 0普通文明，1冻土文明，2沙漠文明，3山脉文明
    local civFlag = 0;
    if (IsDesertCiv(majList.civ) and majList.desert_start > 0) then
        civFlag = 2;
        --沙漠文明只补0次
        return functionResultSuccess;
    elseif (IsTundraCiv(majList.civ) and majList.snow_start > 0) then
        civFlag = 1;
        --冻土文明只补0次
        return functionResultSuccess;
    elseif (IsMountainCiv(majList.leader) or IsMountainCiv(majList.civ)) then
        civFlag = 3;
    end

    --为玩家增加一环保底
    local addOneRingResult = false;
    local iBalancingThree =  math.floor(RichNum * 0.4)
    addOneRingResult = AddBonusOneRing(Map.GetPlot(plotX, plotY), iBalancingThree, civFlag, isMust);
    --返回结果
    if (addOneRingResult) then
        return functionResultSuccess;
    else
        return functionResultFalse;
    end
end

function TeamPVPIsAdjacentToLandAndNotAdjacent(plot)
    for direction = 0, 5, 1 do
        local adjacentPlot = GetAdjacentTiles(plot, direction);
        if (adjacentPlot ~= nil) then
            --1环有水资源 pass
            if (((adjacentPlot:GetResourceCount() > 0 and (adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX or adjacentPlot:GetResourceType() == 3)) or adjacentPlot:GetFeatureType() == g_FEATURE_REEF) and adjacentPlot:IsWater() == true) then
                return false;
            end
        end

    end

    for direction = 0, 17, 1 do
        local adjacentPlot = GetAdjacentTiles(plot, direction);
        if (adjacentPlot ~= nil) then
            --2环有海岸 success
            if (adjacentPlot:IsCoastalLand()) then
                return true;
            end
        end
    end
    return false;
end

function TeamPVPGetAdjacentWaterResourceCount(plot)
    local count = 0;

    for direction = 0, 5, 1 do
        local adjacentPlot = GetAdjacentTiles(plot, direction);
        if (adjacentPlot ~= nil) then
            --1环有水资源 pass
            if (((adjacentPlot:GetResourceCount() > 0 and (adjacentPlot:GetResourceType() == RESOURCE_FISH_INDEX or adjacentPlot:GetResourceType() == 3)) or adjacentPlot:GetFeatureType() == g_FEATURE_REEF) and adjacentPlot:IsWater() == true) then
                count = count + 1;
            end
        end
    end

    print("TeamPVPGetAdjacentWaterResourceCount count:", count);
    return count;
end

function civAddStrategyTeamPVP(eResourceType, startPlot, isForce)
    print("civAddStrategyTeamPVP start startPlot X:", startPlot:GetX(), ";Y:", startPlot:GetY(), ";isForce:", isForce, ";eResourceType:", eResourceType);
    if (startPlot == nil or eResourceType == nil or isForce == nil) then
        return functionResultFail;
    end
    --判断战略是否存在
    local bHasResource = FindResource(eResourceType, startPlot);

    if (bHasResource) then
        --战略存在
        print("civAddStrategyTeamPVP end true");
        return functionResultSuccess;
    end

    local rngAdd = 0;
    -- 6 12 18 3环
    for i = 6, 36 do
        local adjacentPlot = GetAdjacentTiles(startPlot, i);
        if (adjacentPlot ~= nil) then
            --随机
            local rng = (TerrainBuilder.GetRandomNumber(100, "test") + rngAdd);
            if (rng > 50) then
                local terrainType = adjacentPlot:GetTerrainType();
                if (isForce == false) then
                    if (adjacentPlot:GetResourceCount() == 0) and adjacentPlot:IsNaturalWonder() == false then
                        if (ResourceBuilder.CanHaveResource(adjacentPlot, eResourceType) and adjacentPlot:IsImpassable() == false) then
                            ResourceBuilder.SetResourceType(adjacentPlot, eResourceType, 1);
                            return functionResultSuccess;
                        end
                    end
                else
                    --强制设置战略资源马
                    if (adjacentPlot:GetResourceCount() == 0) and adjacentPlot:IsNaturalWonder() == false and adjacentPlot:IsImpassable() == false and eResourceType == RESOURCE_HORSES_INDEX then
                        if (terrainType == 4 or terrainType == 1 or terrainType == 0 or terrainType == 3) then
                            --移除地貌
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            --如果是丘陵 设置为平原
                            if (terrainType == 4) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 3);
                            end
                            if (terrainType == 1) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 0);
                            end
                            ResourceBuilder.SetResourceType(adjacentPlot, eResourceType, 1);
                            return functionResultSuccess;
                        end
                    end
                    --强制设置战略资源铁
                    if (adjacentPlot:GetResourceCount() == 0) and adjacentPlot:IsNaturalWonder() == false and adjacentPlot:IsImpassable() == false and eResourceType == RESOURCE_IRON_INDEX then
                        if (terrainType == 10 or terrainType == 7 or terrainType == 4 or terrainType == 1
                                or terrainType == 0 or terrainType == 3 or terrainType == 6 or terrainType == 9) then
                            --移除地貌
                            TerrainBuilder.SetFeatureType(adjacentPlot, -1);
                            --如果是平原 设置为丘陵
                            if (terrainType == 3) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 4);
                            end
                            if (terrainType == 0) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 1);
                            end
                            if (terrainType == 9) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 10);
                            end
                            if (terrainType == 6) then
                                TerrainBuilder.SetTerrainType(adjacentPlot, 7);
                            end
                            ResourceBuilder.SetResourceType(adjacentPlot, eResourceType, 1);
                            return functionResultSuccess;
                        end
                    end
                end
            else
                rngAdd = rngAdd + 20;
            end
        end
    end
    --返回结果
    return functionResultFalse;
end

function MapHasResource(iResources)
    local iW, iH = Map.GetGridSize();
    for k = 0, iH * iW - 1 do
        local pPlot = Map.GetPlotByIndex(k);
        if pPlot:GetResourceType() == iResources then
            return true
        end
    end
    return false
end
