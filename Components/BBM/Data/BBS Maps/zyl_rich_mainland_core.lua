------------------------------------------------------------------------------
--	FILE:	 zyl_rich_mainland_core.lua
--	DERIVED: ZYL Lightweight Balance 的富饶竖向大陆
--	PURPOSE: 组队 PVP / FFA 富饶大陆的共享生成核心。
--	SOURCE AUTHORS: 千川白浪、号码菌、红魔族首席魔法师
--	INTEGRATION: Namespaced and repaired for ZYL Lightweight Balance Mod.
------------------------------------------------------------------------------
include "MapEnums"
include "ZYL_RVC_MapUtilities"
include "ZYL_RVC_MountainsCliffs"
include "ZYL_RVC_RiversLakes"
include "ZYL_RVC_FeatureGenerator"
include "ZYL_RVC_DW_TerrainGenerator"
include "NaturalWonderGenerator"
include "ZYL_RVC_ResourceGenerator"
include "ZYL_RVC_CoastalLowlands"
include "AssignStartingPlots"
include "ZYL_RVC_AssignStartingPlots";
include "ZYL_RVC_Balance";

if type(ZYL_RICH_MAINLAND_VARIANT) ~= "table" then
	error("ZYL Rich Mainland core must be loaded through a variant entry script");
end

local IS_TEAM = ZYL_RICH_MAINLAND_VARIANT.team == true;
local IS_FFA = ZYL_RICH_MAINLAND_VARIANT.ffa == true;
local VARIANT_ID = tostring(ZYL_RICH_MAINLAND_VARIANT.id or "UNKNOWN");
local LOG_PREFIX = "ZYLRM[" .. VARIANT_ID .. "]";

local g_iW, g_iH;
local g_iBaseW, g_iLegacyW, g_iContentOffsetX, g_iAddedOceanWidth;
local g_fHorizontalScale = 1;
local g_iFlags = {};
local g_continentsFrac = nil;
local featureGen = nil;
local world_age_new = 5;
local world_age_normal = 3;
local world_age_old = 2;
-- Grain 4 produces larger, more coherent islands than the former grain-5
-- layer.  The old layer used water percentile 67 (about 33% candidate land).
-- Its target is now +20% final island land on the shared legacy content canvas.
local ZYL_RICH_MAINLAND_ISLAND_BASE_WATER_PERCENT = 67;
local ZYL_RICH_MAINLAND_ISLAND_LAND_MULTIPLIER = 1.20;
local ZYL_RICH_MAINLAND_ISLAND_GRAIN = 4;
local RichNum;
local CompetitionMode = false;
local Remove_South_Sea_Resource_Plots = {}		-- 需要移除资源的远洋单元格（来自竖向大陆海陆生成）

-------------------------------------------------------------------------------
-- Both Rich Mainland variants use their legacy content canvas and turn the
-- added width into a continuous deep ocean at the horizontal wrap seam.
function GetMapInitData(MapSize)
	local width = 0;
	local height = 0;
	for row in GameInfo.Maps() do
		if MapSize == row.Hash then
			width = row.GridWidth;
			height = row.GridHeight;
			break;
		end
	end
	return {Width = width, Height = height, WrapX = true,};
end

local function ZYL_InitializeExpandedOceanCanvas()
	local baseWidths = ZYL_RICH_MAINLAND_VARIANT.baseWidthsByHeight or {};
	g_iLegacyW = math.min(g_iW, tonumber(baseWidths[g_iH]) or g_iW);
	g_iBaseW = g_iLegacyW;
	g_iAddedOceanWidth = math.max(0, g_iW - g_iBaseW);
	g_iContentOffsetX = math.floor(g_iAddedOceanWidth / 2);
	g_fHorizontalScale = 1;
	print(string.format("%s: horizontal canvas actual=%dx%d legacy=%dx%d generation=%dx%d offset=%d addedOcean=%d scale=%.4f wrapX=%s",
		LOG_PREFIX, g_iW, g_iH, g_iLegacyW, g_iH, g_iBaseW, g_iH,
		g_iContentOffsetX, g_iAddedOceanWidth, g_fHorizontalScale,
		tostring(Map:IsWrapX())));
end

local function ZYL_IsAddedCentralOceanColumn(x)
	return x < g_iContentOffsetX or x >= g_iContentOffsetX + g_iBaseW;
end

-- Both variants keep a continuous deep-water barrier along the wrap seam.
-- Do not manufacture a shallow-water strip at either pole: the forced boundary
-- rows are kept deep by ZYL_RemovePolarShallowSea after all terrain passes.
function ZYL_EnforceCentralOceanBarrier(terrainTypes)
	if not g_iBaseW or g_iAddedOceanWidth <= 0 then return end
	local deepCount = 0;
	for y = 0, g_iH - 1 do
		for x = 0, g_iW - 1 do
			local isCentralOcean = ZYL_IsAddedCentralOceanColumn(x);
			local index = y * g_iW + x;
			if isCentralOcean then
				plotTypes[index] = g_PLOT_TYPE_OCEAN;
				if terrainTypes ~= nil then
					terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;
				else
					local plot = Map.GetPlot(x, y);
					if plot ~= nil and plot:GetTerrainType() ~= g_TERRAIN_TYPE_OCEAN then
						TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_OCEAN);
					end
				end
				deepCount = deepCount + 1;
			end
		end
	end
	if terrainTypes == nil then
		Game:SetProperty("ZYLRM_CENTRAL_DEEP_OCEAN_TILES", deepCount);
		Game:SetProperty("ZYLRM_POLAR_SHALLOW_ROUTE_TILES", 0);
		print(string.format("%s: central ocean enforced (%d pole-to-pole deep-water tiles; no forced polar shallows)",
			LOG_PREFIX, deepCount));
	end
end

-- The legacy generator forces y=0/y=1 at the south edge and y=height-1 at the
-- north edge to water.  The terrain/shelf passes could then turn those entire
-- rows into Coast, creating conspicuous horizontal shallow-sea stripes.  Keep
-- every forced boundary row as deep ocean for both variants; interior Coast
-- produced by the normal adjacency/shelf rules remains untouched.
local function ZYL_RemovePolarShallowSea(terrainTypes)
	if g_iH == nil or g_iH < 2 then return end
	local deepCount = 0;
	for _, y in ipairs({ 0, 1, g_iH - 1 }) do
		for x = 0, g_iW - 1 do
			local index = y * g_iW + x;
			if plotTypes[index] == g_PLOT_TYPE_OCEAN then
				if terrainTypes ~= nil then
					terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;
				else
					local plot = Map.GetPlot(x, y);
					if plot ~= nil and plot:GetTerrainType() ~= g_TERRAIN_TYPE_OCEAN then
						TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_OCEAN);
					end
				end
				deepCount = deepCount + 1;
			end
		end
	end
	if terrainTypes == nil then
		Game:SetProperty("ZYLRM_POLAR_SHALLOW_ROUTE_TILES", 0);
		print(string.format("%s: polar forced-water rows kept deep (%d tiles; no horizontal shallow-sea stripe)",
			LOG_PREFIX, deepCount));
	end
end

-------------------------------------------------------------------------------
function BBS_Assign(args)
	--[[ Corrupted legacy log text retained only as a comment.
	print("地图：富饶竖向大陆出生点分配中")
	]]
	print(LOG_PREFIX .. ": assigning starting plots")
	local start_plot_database = {};
	start_plot_database = ZYL_RVC_AssignStartingPlots.Create(args)
	return start_plot_database
end
-------------------------------------------------------------------------------
function GenerateMap()
	--[[ Corrupted legacy log text retained only as a comment.
	print("地图：富饶竖向大陆开始生成");
	]]
	print(LOG_PREFIX .. ": Rich Mainland generation started")
	local pPlot;

	-- 全局设置
	--【温度】
	-- 温度将影响地图中草原和平原的比例
	g_iW, g_iH = Map.GetGridSize();
	ZYL_InitializeExpandedOceanCanvas();
	g_iFlags = TerrainBuilder.GetFractalFlags();
	local temperature = MapConfiguration.GetValue("temperature");
	if temperature == 4 then
		temperature  =  1 + TerrainBuilder.GetRandomNumber(3, "Random Temperature- Lua");
	end
	
	--【纪元】
	-- 纪元将影响地图中丘陵和山脉的比例
	local world_age = MapConfiguration.GetValue("world_age");
	if (world_age == 1) then
		world_age = world_age_new;
	elseif (world_age == 2) then
		world_age = world_age_normal;
	elseif (world_age == 3) then
		world_age = world_age_old;
	else
		world_age = 2 + TerrainBuilder.GetRandomNumber(4, "Random World Age - Lua");
	end

	--【富饶系数】
	-- 富饶系数将综合影响地图中地貌/资源/大陆/自然奇观/开局补正
	RichNum = tonumber(MapConfiguration.GetValue("RichNum")) or 4;
	RichNum = math.max(1, math.min(10, RichNum));

	local PVPGames = MapConfiguration.GetValue("MapTrait") or 0;
	CompetitionMode = PVPGames == 1 or PVPGames == true;
	if CompetitionMode then
		RichNum = 3
	end
	print("富饶系数", RichNum);

	--【海陆、地形】
	print("划分海陆");
	plotTypes = TeamPVPGeneratePlotTypes(world_age);
	terrainTypes = TeamPVPGenerateTerrainTypes(plotTypes, g_iW, g_iH, g_iFlags, true, temperature);
	ZYL_RemovePolarShallowSea(terrainTypes);
	ZYL_EnforceCentralOceanBarrier(terrainTypes);
	ApplyBaseTerrain(plotTypes, terrainTypes, g_iW, g_iH);

	-- 分配大陆
	print(LOG_PREFIX .. ": generating continent layout");
	TeamPVPGenerateContinents(plotTypes);

	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();

	--【丰富大陆边界地形】
	print("在板块交界处增加火山");
	local iContinentBoundaryPlots = GetContinentBoundaryPlotCount(g_iW, g_iH);
	TeamPVPAddTerrainFromContinents(plotTypes, terrainTypes, world_age, g_iW, g_iH, iContinentBoundaryPlots);
	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	--[[ Corrupted legacy log text retained only as a comment.

	print("分析降雨量，增加地貌与河流");
	]]
	print("Adding features and rivers")
	AddFeatures();
	
	print("增加悬崖");
	AddCliffs(plotTypes, terrainTypes);

	print("增加自然奇观");
	local mapRow = ZYL_RVC_GetMapRow();
	local wonderScale = IS_FFA and g_fHorizontalScale or 1;
	local baseWonderTarget = math.floor((mapRow and mapRow.NumNaturalWonders or 4) + RichNum / 3);
	local wonderTarget = baseWonderTarget * wonderScale;
	local nwGen = NaturalWonderGenerator.Create({
		numberToPlace = math.max(0, math.floor(wonderTarget + 0.5)),
	});

	print("增加大陆边界地貌");
	AddFeaturesFromContinents();
	DW_MarkCoastalLowlands();

	-- This map intentionally omits the standalone offshore ice islands.


	resourcesConfig = MapConfiguration.GetValue("resources");
	local startConfig = MapConfiguration.GetValue("start");-- Get the start config
	local resGen = ZYL_RVC_ResourceGenerator.Create({
		resources = resourcesConfig,
		START_CONFIG = startConfig,
		plotTypes = plotTypes,
		RichNum = RichNum
	});
	if CompetitionMode then
		Add_LEY_LINE()
	end
	--[[ Corrupted legacy log text retained only as a comment.
	-- Remove_SouthSeaResource()  -- 竖向大陆远洋资源清除(距陆地>5格的远洋格子清空资源)，富饶南北无此机制；
	                               -- 注释以保留远洋水域资源，对齐富饶南北水域资源量（玩家反馈水域资源偏少）

	print("分配出生点");
	]]
	print("Assigning starting plots")
	local start_plot_database = BBS_Assign({
		MIN_MAJOR_CIV_FERTILITY = 150,
		MIN_MINOR_CIV_FERTILITY = 5,
		MIN_BARBARIAN_FERTILITY = 1,
		START_MIN_Y = 15,
		START_MAX_Y = 15,
		START_CONFIG = startConfig,
		WATER = false,
		LAND = false,
	})

	print("增加部落村庄");
	local GoodyGen = TPT_AddGoodies(g_iW, g_iH, {
		TilesPerGoody = 60 - RichNum * 3,
		GoodyRange = 5 - math.floor(RichNum/5)
	});

	print("地图平衡");
	local Balance = ZYL_RVC_Balance({
		RichNum= RichNum
	});
	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	RichNSBalance();
	if IS_FFA then
		ZYL_EnforceFFAMountainRatio();
	end
	ZYL_EnsureSeaCivReefFish();
	ZYL_EnsureRussiaFoodTiles();
	ZYL_RVC_EnforceSeaResourceRules();
	ZYL_EnsureCoastalStartReefResource();
	ZYL_RemovePolarShallowSea();
	ZYL_EnforceCentralOceanBarrier();
	--[[ Corrupted legacy log text retained only as a comment.

	print("开始生成道路");
	]]
	print("Generating routes")
	DoRoute()
	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
	ZYLRM_LogFinalStatistics();
	--[[ Corrupted legacy log text retained only as a comment.
	print("地图：富饶竖向大陆生成完毕");
	]]
	print(LOG_PREFIX .. ": Rich Mainland generation complete")
end

-------------------------------------------------------------------------------
-- Deterministic diagnostics for multiplayer map verification.  Count the
-- final plot state because continent-edge terrain and spawn balancing can
-- still alter mountains after the initial tectonics pass.
function ZYLRM_LogFinalStatistics()
	local landCount = 0;
	local mountainCount = 0;
	local islandLandCount = 0;
	local mapHash = 104729;
	local biggestArea = Areas.FindBiggestArea(false);
	local biggestAreaID = biggestArea and biggestArea:GetID() or -1;
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		if plot ~= nil and not plot:IsWater() then
			landCount = landCount + 1;
			if plot:IsMountain() then mountainCount = mountainCount + 1; end
			if plot:GetArea():GetID() ~= biggestAreaID then
				islandLandCount = islandLandCount + 1;
			end
		end
		if plot ~= nil then
			local riverFlags = 0;
			if plot:IsWOfRiver() then riverFlags = riverFlags + 1; end
			if plot:IsNWOfRiver() then riverFlags = riverFlags + 2; end
			if plot:IsNEOfRiver() then riverFlags = riverFlags + 4; end
			local cliffFlags = 0;
			if plot:IsWOfCliff() then cliffFlags = cliffFlags + 1; end
			if plot:IsNWOfCliff() then cliffFlags = cliffFlags + 2; end
			if plot:IsNEOfCliff() then cliffFlags = cliffFlags + 4; end
			local value = (plot:GetTerrainType() + 2)
				+ (plot:GetFeatureType() + 2) * 31
				+ (plot:GetResourceType() + 2) * 131
				+ plot:GetResourceCount() * 521
				+ riverFlags * 2089
				+ cliffFlags * 8191
				+ (plot:GetImprovementType() + 2) * 32771
				+ (plot:GetRouteType() + 2) * 131101;
			mapHash = (mapHash * 65599 + value + plotIndex) % 2147483647;
		end
	end
	local majorIDs = {};
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs() or {}) do
		table.insert(majorIDs, playerID);
	end
	table.sort(majorIDs);
	for _, playerID in ipairs(majorIDs) do
		local player = Players[playerID];
		local startPlot = player ~= nil and player:GetStartingPlot() or nil;
		local startIndex = startPlot ~= nil and startPlot:GetIndex() or -1;
		mapHash = (mapHash * 65599 + playerID * 257 + startIndex + 2) % 2147483647;
	end
	local mapFingerprint = tostring(math.floor(mapHash));
	local mountainPercent = landCount > 0 and (mountainCount * 100 / landCount) or 0;
	Game:SetProperty("ZYLRM_VARIANT", VARIANT_ID);
	Game:SetProperty("ZYLRM_LAND_TILES", landCount);
	Game:SetProperty("ZYLRM_MOUNTAIN_TILES", mountainCount);
	Game:SetProperty("ZYLRM_ISLAND_LAND_TILES", islandLandCount);
	Game:SetProperty("ZYLRM_CONTINENT_MODE", IS_TEAM and "HORIZONTAL_STRIPES" or "STAMPED");
	Game:SetProperty("ZYLRM_HORIZONTAL_SCALE", g_fHorizontalScale);
	Game:SetProperty("ZYLRM_GENERATION_WIDTH", g_iBaseW);
	Game:SetProperty("ZYLRM_MAP_FINGERPRINT", mapFingerprint);
	print(string.format("%s mountains: %d / %d land tiles (%.2f%%)", LOG_PREFIX, mountainCount, landCount, mountainPercent));
	print(LOG_PREFIX .. " offshore island land:", islandLandCount, "tiles");
	print(LOG_PREFIX .. " map fingerprint:", mapFingerprint);
end

-------------------------------------------------------------------------------
-- FFA keeps the original terrain generator, then tops the final map up to a
-- stable 3.5% mountain share after spawn balancing has finished removing or
-- reshaping highlands.  Start rings, resources, wonders and coast access are
-- never consumed by this pass.
function ZYL_EnforceFFAMountainRatio()
	local targetRatio = 0.035;
	local protected = {};
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local startPlot = Players[playerID] and Players[playerID]:GetStartingPlot() or nil;
		if startPlot ~= nil then
			for plotIndex = 0, Map.GetPlotCount() - 1 do
				local plot = Map.GetPlotByIndex(plotIndex);
				if Map.GetPlotDistance(startPlot:GetX(), startPlot:GetY(), plot:GetX(), plot:GetY()) <= 2 then
					protected[plotIndex] = true;
				end
			end
		end
	end

	local landCount = 0;
	local mountainCount = 0;
	local candidates = {};
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		if plot ~= nil and not plot:IsWater() then
			landCount = landCount + 1;
			if plot:IsMountain() then
				mountainCount = mountainCount + 1;
			elseif not protected[plotIndex]
				and not plot:IsNaturalWonder()
				and plot:GetFeatureType() == -1
				and plot:GetResourceType() == -1
				and not plot:IsCoastalLand() then
				local adjacentMountains = 0;
				local adjacentHills = 0;
				for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
					local adjacent = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
					if adjacent ~= nil then
						if adjacent:IsMountain() then adjacentMountains = adjacentMountains + 1 end
						if adjacent:IsHills() then adjacentHills = adjacentHills + 1 end
					end
				end
				local score = adjacentMountains * 1000 + adjacentHills * 100;
				if plot:IsRiver() or plot:IsRiverAdjacent() then score = score - 10000 end
				score = score + TerrainBuilder.GetRandomNumber(100, "ZYLRM FFA mountain candidate");
				table.insert(candidates, { Plot = plot, Score = score });
			end
		end
	end
	local targetCount = math.ceil(landCount * targetRatio);
	local needed = math.max(0, targetCount - mountainCount);
	table.sort(candidates, function(a, b)
		if a.Score == b.Score then return a.Plot:GetIndex() < b.Plot:GetIndex() end
		return a.Score > b.Score;
	end);
	local added = 0;
	for i = 1, math.min(needed, #candidates) do
		local plot = candidates[i].Plot;
		local mountainTerrain = ConvertToMountain(plot:GetTerrainType());
		if mountainTerrain ~= plot:GetTerrainType() then
			TerrainBuilder.SetTerrainType(plot, mountainTerrain);
			added = added + 1;
		end
	end
	mountainCount = mountainCount + added;
	Game:SetProperty("ZYLRM_FFA_MOUNTAINS_ADDED", added);
	print(string.format("%s FFA mountain guarantee: added %d, final %d/%d (%.2f%%), target %.2f%%",
		LOG_PREFIX, added, mountainCount, landCount,
		landCount > 0 and mountainCount * 100 / landCount or 0, targetRatio * 100));
end

-------------------------------------------------------------------------------
-- Ocean-start leaders (normally Kupe) receive at least one reef+fish tile in
-- the two rings around their final start.  Existing fish/reef tiles are reused
-- first; only an otherwise empty ocean tile is converted to coast as fallback.
function ZYL_EnsureSeaCivReefFish()
	local reefRow = GameInfo.Features["FEATURE_REEF"];
	local fishRow = GameInfo.Resources["RESOURCE_FISH"];
	if reefRow == nil or fishRow == nil then return end
	local reefIndex = reefRow.Index;
	local fishIndex = fishRow.Index;
	local guaranteed = 0;

	local function nearbyWater(startPlot)
		local plots = {};
		for plotIndex = 0, Map.GetPlotCount() - 1 do
			local plot = Map.GetPlotByIndex(plotIndex);
			local distance = plot and Map.GetPlotDistance(startPlot:GetX(), startPlot:GetY(), plot:GetX(), plot:GetY()) or 99;
			if plot ~= nil and plot:IsWater() and not plot:IsLake() and not plot:IsNaturalWonder()
				and distance >= 1 and distance <= 2 then
				table.insert(plots, plot);
			end
		end
		return plots;
	end

	local function isExact(plot)
		return plot:GetFeatureType() == reefIndex and plot:GetResourceType() == fishIndex;
	end

	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local leader = PlayerConfigurations[playerID]:GetLeaderTypeName();
		local startPlot = Players[playerID] and Players[playerID]:GetStartingPlot() or nil;
		if startPlot ~= nil and startPlot:IsWater() and IsSeaStartCiv(leader) then
			local plots = nearbyWater(startPlot);
			local target = nil;
			for _, plot in ipairs(plots) do
				if isExact(plot) then target = plot; break end
			end
			if target == nil then
				for _, plot in ipairs(plots) do
					if plot:GetResourceType() == fishIndex and plot:GetFeatureType() == -1 then
						if plot:GetTerrainType() ~= g_TERRAIN_TYPE_COAST then
							TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_COAST);
						end
						TerrainBuilder.SetFeatureType(plot, reefIndex);
						if isExact(plot) then target = plot; break end
					end
				end
			end
			if target == nil then
				for _, plot in ipairs(plots) do
					if plot:GetFeatureType() == reefIndex and plot:GetResourceType() == -1 then
						ResourceBuilder.SetResourceType(plot, fishIndex, 1);
						if isExact(plot) then target = plot; break end
					end
				end
			end
			if target == nil then
				for _, plot in ipairs(plots) do
					if plot:GetTerrainType() == g_TERRAIN_TYPE_COAST and plot:GetFeatureType() == -1
						and plot:GetResourceType() == -1 and TerrainBuilder.CanHaveFeature(plot, reefIndex) then
						TerrainBuilder.SetFeatureType(plot, reefIndex);
						if ResourceBuilder.CanHaveResource(plot, fishIndex) then
							ResourceBuilder.SetResourceType(plot, fishIndex, 1);
							target = plot;
						end
						if target ~= nil then break end
					end
				end
			end
			if target == nil then
				for _, plot in ipairs(plots) do
					if plot:GetFeatureType() == -1 and plot:GetResourceType() == -1 then
						TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_COAST);
						TerrainBuilder.SetFeatureType(plot, reefIndex);
						ResourceBuilder.SetResourceType(plot, fishIndex, 1);
						if isExact(plot) then target = plot end
						if target ~= nil then break end
					end
				end
			end
			if target ~= nil and isExact(target) then
				guaranteed = guaranteed + 1;
				print(LOG_PREFIX, "reef-fish guarantee player", playerID, "start", startPlot:GetX(), startPlot:GetY(), "plot", target:GetX(), target:GetY());
			else
				print(LOG_PREFIX, "WARNING: unable to place reef-fish for ocean-start player", playerID);
			end
		end
	end
	Game:SetProperty("ZYLRM_SEA_CIV_REEF_FISH", guaranteed);
end

-------------------------------------------------------------------------------
-- Match BBM's minimum coastal-start rule on both Rich Mainland variants. Every
-- major civilization whose final starting plot is coastal land receives at
-- least one reef with Fish or Turtles exactly two tiles from the start.
function ZYL_EnsureCoastalStartReefResource()
	local reefRow = GameInfo.Features["FEATURE_REEF"];
	local fishRow = GameInfo.Resources["RESOURCE_FISH"];
	local turtlesRow = GameInfo.Resources["RESOURCE_TURTLES"];
	local coastRow = GameInfo.Terrains["TERRAIN_COAST"];
	if reefRow == nil or fishRow == nil or coastRow == nil then return end

	local reefIndex = reefRow.Index;
	local fishIndex = fishRow.Index;
	local turtlesIndex = turtlesRow and turtlesRow.Index or -1;
	local coastIndex = coastRow.Index;
	local plotCount = Map.GetPlotCount();
	local turtlesOnMap = false;
	if turtlesIndex >= 0 then
		for plotIndex = 0, plotCount - 1 do
			local plot = Map.GetPlotByIndex(plotIndex);
			if plot ~= nil and plot:GetResourceType() == turtlesIndex then
				turtlesOnMap = true;
				break;
			end
		end
	end

	local function ShufflePlots(plots, label)
		for i = #plots, 2, -1 do
			local j = TerrainBuilder.GetRandomNumber(i, label) + 1;
			plots[i], plots[j] = plots[j], plots[i];
		end
	end

	local function GetRingWater(startPlot, distance)
		local plots = {};
		for plotIndex = 0, plotCount - 1 do
			local plot = Map.GetPlotByIndex(plotIndex);
			if plot ~= nil and plot:IsWater() and not plot:IsLake() and not plot:IsNaturalWonder()
				and Map.GetPlotDistance(startPlot:GetX(), startPlot:GetY(), plot:GetX(), plot:GetY()) == distance then
				table.insert(plots, plot);
			end
		end
		return plots;
	end

	local function IsGuaranteed(plot)
		local resourceIndex = plot:GetResourceType();
		return plot:GetFeatureType() == reefIndex
			and resourceIndex >= 0
			and (resourceIndex == fishIndex or (turtlesIndex >= 0 and resourceIndex == turtlesIndex));
	end

	local function CountInnerLuxuries(startPlot)
		local count = 0;
		for plotIndex = 0, plotCount - 1 do
			local plot = Map.GetPlotByIndex(plotIndex);
			local distance = plot and Map.GetPlotDistance(startPlot:GetX(), startPlot:GetY(), plot:GetX(), plot:GetY()) or 99;
			if plot ~= nil and distance >= 1 and distance <= 3 then
				local resource = GameInfo.Resources[plot:GetResourceType()];
				if resource ~= nil and resource.ResourceClassType == "RESOURCECLASS_LUXURY" then
					count = count + 1;
				end
			end
		end
		return count;
	end

	local function AddReefToFish(plot)
		local originalTerrain = plot:GetTerrainType();
		if originalTerrain ~= coastIndex then
			TerrainBuilder.SetTerrainType(plot, coastIndex);
		end
		if plot:GetFeatureType() == -1 and TerrainBuilder.CanHaveFeature(plot, reefIndex) then
			TerrainBuilder.SetFeatureType(plot, reefIndex);
			if IsGuaranteed(plot) then return true end
			TerrainBuilder.SetFeatureType(plot, -1);
		end
		if originalTerrain ~= coastIndex then
			TerrainBuilder.SetTerrainType(plot, originalTerrain);
		end
		return false;
	end

	local function PlaceGuarantee(plot, preferredResource)
		local originalTerrain = plot:GetTerrainType();
		local originalFeature = plot:GetFeatureType();
		local originalResource = plot:GetResourceType();
		if originalTerrain ~= coastIndex then
			TerrainBuilder.SetTerrainType(plot, coastIndex);
		end
		ResourceBuilder.SetResourceType(plot, -1);
		TerrainBuilder.SetFeatureType(plot, -1);
		if TerrainBuilder.CanHaveFeature(plot, reefIndex) then
			TerrainBuilder.SetFeatureType(plot, reefIndex);
			local resourcesToTry = { preferredResource };
			if preferredResource ~= fishIndex then table.insert(resourcesToTry, fishIndex) end
			for _, resourceIndex in ipairs(resourcesToTry) do
				if resourceIndex ~= nil and resourceIndex >= 0 and ResourceBuilder.CanHaveResource(plot, resourceIndex) then
					ResourceBuilder.SetResourceType(plot, resourceIndex, 1);
					if IsGuaranteed(plot) then return true end
					ResourceBuilder.SetResourceType(plot, -1);
				end
			end
		end

		-- A failed candidate must remain byte-for-byte equivalent in map state.
		ResourceBuilder.SetResourceType(plot, -1);
		TerrainBuilder.SetFeatureType(plot, -1);
		TerrainBuilder.SetTerrainType(plot, originalTerrain);
		if originalFeature ~= -1 then TerrainBuilder.SetFeatureType(plot, originalFeature) end
		if originalResource ~= -1 then ResourceBuilder.SetResourceType(plot, originalResource, 1) end
		return false;
	end

	local function RelocateRingTwoResource(source, ringThree)
		local sourceTerrain = source:GetTerrainType();
		local sourceFeature = source:GetFeatureType();
		local sourceResource = source:GetResourceType();
		if sourceResource < 0 then return false end

		local destinations = {};
		for _, destination in ipairs(ringThree) do
			if destination:GetFeatureType() == -1 and destination:GetResourceType() == -1 then
				table.insert(destinations, destination);
			end
		end
		ShufflePlots(destinations, "ZYL RVC coastal-start resource relocation");

		for _, destination in ipairs(destinations) do
			local destinationTerrain = destination:GetTerrainType();
			if destinationTerrain ~= sourceTerrain then
				TerrainBuilder.SetTerrainType(destination, sourceTerrain);
			end
			local canFeature = sourceFeature == -1 or TerrainBuilder.CanHaveFeature(destination, sourceFeature);
			if canFeature then
				if sourceFeature ~= -1 then TerrainBuilder.SetFeatureType(destination, sourceFeature) end
				local canResource = ResourceBuilder.CanHaveResource(destination, sourceResource);
				if canResource then
					ResourceBuilder.SetResourceType(destination, sourceResource, 1);
					if destination:GetResourceType() == sourceResource
						and destination:GetFeatureType() == sourceFeature then
						ResourceBuilder.SetResourceType(source, -1);
						TerrainBuilder.SetFeatureType(source, -1);
						return true;
					end
				end
			end

			-- Restore a failed destination before trying the next one.
			ResourceBuilder.SetResourceType(destination, -1);
			TerrainBuilder.SetFeatureType(destination, -1);
			TerrainBuilder.SetTerrainType(destination, destinationTerrain);
		end
		return false;
	end

	local playerIDs = PlayerManager.GetAliveMajorIDs();
	table.sort(playerIDs);
	local guaranteed = 0;
	for _, playerID in ipairs(playerIDs) do
		local startPlot = Players[playerID] and Players[playerID]:GetStartingPlot() or nil;
		if startPlot ~= nil and startPlot:IsCoastalLand() then
			local ringTwo = GetRingWater(startPlot, 2);
			local ringThree = GetRingWater(startPlot, 3);
			local target = nil;
			for _, plot in ipairs(ringTwo) do
				if IsGuaranteed(plot) then target = plot; break end
			end

			-- Preserve an existing Fish and add only the missing Reef when possible.
			if target == nil then
				local fishCandidates = {};
				for _, plot in ipairs(ringTwo) do
					if plot:GetResourceType() == fishIndex and plot:GetFeatureType() == -1 then
						table.insert(fishCandidates, plot);
					end
				end
				ShufflePlots(fishCandidates, "ZYL RVC coastal-start Fish Reef");
				for _, plot in ipairs(fishCandidates) do
					if AddReefToFish(plot) then target = plot; break end
				end
			end

			if target == nil then
				local preferredResource = fishIndex;
				if turtlesOnMap and CountInnerLuxuries(startPlot) < 3
					and TerrainBuilder.GetRandomNumber(100, "ZYL RVC ring-two Turtles or Fish") <= 50 then
					preferredResource = turtlesIndex;
				end

				local emptyReefs = {};
				local emptyCoast = {};
				local emptyOcean = {};
				local replaceNoResource = {};
				local replaceBonus = {};
				local replaceLuxury = {};
				local replaceStrategic = {};
				for _, plot in ipairs(ringTwo) do
					local featureIndex = plot:GetFeatureType();
					local resourceIndex = plot:GetResourceType();
					if featureIndex == reefIndex and resourceIndex == -1 then
						table.insert(emptyReefs, plot);
					elseif featureIndex == -1 and resourceIndex == -1 then
						if plot:GetTerrainType() == coastIndex then
							table.insert(emptyCoast, plot);
						else
							table.insert(emptyOcean, plot);
						end
					elseif resourceIndex == -1 then
						table.insert(replaceNoResource, plot);
					else
						local resource = GameInfo.Resources[resourceIndex];
						local resourceClass = resource and resource.ResourceClassType or "";
						if resourceClass == "RESOURCECLASS_BONUS" then
							table.insert(replaceBonus, plot);
						elseif resourceClass == "RESOURCECLASS_LUXURY" then
							table.insert(replaceLuxury, plot);
						else
							table.insert(replaceStrategic, plot);
						end
					end
				end

				local candidateGroups = {
					emptyReefs, emptyCoast, emptyOcean, replaceNoResource
				};
				for groupIndex, candidates in ipairs(candidateGroups) do
					ShufflePlots(candidates, "ZYL RVC coastal-start Reef resource " .. tostring(groupIndex));
					for _, plot in ipairs(candidates) do
						if PlaceGuarantee(plot, preferredResource) then target = plot; break end
					end
					if target ~= nil then break end
				end

				-- If ring two has no empty tile, mirror BBM's behavior by moving
				-- one existing water resource to ring three before using its tile.
				if target == nil then
					local resourceGroups = { replaceBonus, replaceLuxury, replaceStrategic };
					for groupIndex, candidates in ipairs(resourceGroups) do
						ShufflePlots(candidates, "ZYL RVC coastal-start resource candidates " .. tostring(groupIndex));
						for _, plot in ipairs(candidates) do
							if RelocateRingTwoResource(plot, ringThree)
								and PlaceGuarantee(plot, preferredResource) then
								target = plot;
								break;
							end
						end
						if target ~= nil then break end
					end
				end

				-- Preserve BBM's final forced fallback if no ring-three relocation
				-- is possible on an unusually cramped coastline.
				if target == nil then
					local resourceGroups = { replaceBonus, replaceLuxury, replaceStrategic };
					for _, candidates in ipairs(resourceGroups) do
						for _, plot in ipairs(candidates) do
							if PlaceGuarantee(plot, preferredResource) then target = plot; break end
						end
						if target ~= nil then break end
					end
				end
			end

			if target ~= nil and IsGuaranteed(target) then
				guaranteed = guaranteed + 1;
				print(LOG_PREFIX, "coastal-start reef resource player", playerID,
					"start", startPlot:GetX(), startPlot:GetY(),
					"plot", target:GetX(), target:GetY(),
					"resource", target:GetResourceType());
			else
				print(LOG_PREFIX, "WARNING: unable to place ring-two reef resource for coastal-start player", playerID);
			end
		end
	end
	Game:SetProperty("ZYLRM_COASTAL_START_REEF_RESOURCE", guaranteed);
end

-------------------------------------------------------------------------------
-- Russia's tundra conversion can otherwise leave too little workable food.
-- Count rings one and two after all balancing; add sheep on tundra hills until
-- at least two non-mountain land tiles have two food.
function ZYL_EnsureRussiaFoodTiles()
	local sheepRow = GameInfo.Resources["RESOURCE_SHEEP"];
	if sheepRow == nil then return end
	local sheepIndex = sheepRow.Index;
	for _, playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if PlayerConfigurations[playerID]:GetCivilizationTypeName() == "CIVILIZATION_RUSSIA" then
			local startPlot = Players[playerID] and Players[playerID]:GetStartingPlot() or nil;
			if startPlot ~= nil then
				local ringPlots = {};
				for plotIndex = 0, Map.GetPlotCount() - 1 do
					local plot = Map.GetPlotByIndex(plotIndex);
					local distance = Map.GetPlotDistance(startPlot:GetX(), startPlot:GetY(), plot:GetX(), plot:GetY());
					if distance >= 1 and distance <= 2 and not plot:IsWater() and not plot:IsMountain() then
						table.insert(ringPlots, plot);
					end
				end
				local function countFoodTiles()
					local count = 0;
					for _, plot in ipairs(ringPlots) do
						if plot:GetYield(g_YIELD_FOOD) >= 2 then count = count + 1 end
					end
					return count;
				end
				local before = countFoodTiles();
				local added = 0;
				if before < 2 then
					local candidates = {};
					for _, plot in ipairs(ringPlots) do
						if plot:GetYield(g_YIELD_FOOD) < 2 and plot:GetResourceType() == -1
							and plot:GetFeatureType() ~= g_FEATURE_GEOTHERMAL_FISSURE
							and not plot:IsNaturalWonder() then
							local terrain = plot:GetTerrainType();
							local priority = 4;
							if terrain == g_TERRAIN_TYPE_TUNDRA_HILLS and plot:GetFeatureType() == -1 then priority = 1
							elseif terrain == g_TERRAIN_TYPE_TUNDRA and plot:GetFeatureType() == -1 then priority = 2
							elseif terrain == g_TERRAIN_TYPE_TUNDRA or terrain == g_TERRAIN_TYPE_TUNDRA_HILLS then priority = 3 end
							table.insert(candidates, { Plot = plot, Priority = priority });
						end
					end
					table.sort(candidates, function(a, b)
						if a.Priority == b.Priority then return a.Plot:GetIndex() < b.Plot:GetIndex() end
						return a.Priority < b.Priority;
					end);
					for _, candidate in ipairs(candidates) do
						if countFoodTiles() >= 2 then break end
						local plot = candidate.Plot;
						if plot:GetFeatureType() ~= -1 then TerrainBuilder.SetFeatureType(plot, -1) end
						TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_TUNDRA_HILLS);
						if ResourceBuilder.CanHaveResource(plot, sheepIndex) then
							ResourceBuilder.SetResourceType(plot, sheepIndex, 1);
							-- In the base rules tundra hills (0 food) plus sheep (+1)
							-- still miss the requested two-food floor.  Keep the sheep,
							-- but promote only this guarantee tile to plains hills if the
							-- active ruleset reports less than two actual food.
							if plot:GetYield(g_YIELD_FOOD) < 2 then
								TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS_HILLS);
							end
							if plot:GetYield(g_YIELD_FOOD) >= 2 then added = added + 1 end
						end
					end
				end
				local after = countFoodTiles();
				Game:SetProperty("ZYLRM_RUSSIA_FOOD_TILES_" .. tostring(playerID), after);
				print(LOG_PREFIX, "Russia food guarantee player", playerID, "before", before, "sheep added", added, "after", after);
				if after < 2 then print(LOG_PREFIX, "WARNING: Russia food guarantee could not reach two tiles") end
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Final sea-resource pass. Starting-plot balancing can alter features after the
-- resource generator runs, so enforce reef-only resources after all balancing.
-- The private Lightweight Balance Shark resource is not
-- imported into ZYLPVPMOD, so this pass intentionally handles base/DLC sea
-- resources only.
function ZYL_RVC_EnforceSeaResourceRules()
	local reefRow = GameInfo.Features["FEATURE_REEF"];
	local turtleRow = GameInfo.Resources["RESOURCE_TURTLES"];
	local amberRow = GameInfo.Resources["RESOURCE_AMBER"];
	if reefRow == nil then
		return;
	end

	local reefIndex = reefRow.Index;
	local reefOnlyResources = {};
	if turtleRow ~= nil then
		reefOnlyResources[turtleRow.Index] = "RESOURCE_TURTLES";
	end
	if amberRow ~= nil then
		reefOnlyResources[amberRow.Index] = "RESOURCE_AMBER";
	end

	local removedByType = {};
	local plotCount = Map.GetPlotCount();
	for plotIndex = 0, plotCount - 1 do
		local plot = Map.GetPlotByIndex(plotIndex);
		if plot ~= nil then
			local resourceIndex = plot:GetResourceType();
			if reefOnlyResources[resourceIndex] ~= nil and plot:GetFeatureType() ~= reefIndex then
				removedByType[resourceIndex] = (removedByType[resourceIndex] or 0) + 1;
				ResourceBuilder.SetResourceType(plot, -1);
			end
		end
	end

	local function ShufflePlots(plots, label)
		for i = #plots, 2, -1 do
			local j = TerrainBuilder.GetRandomNumber(i, label) + 1;
			plots[i], plots[j] = plots[j], plots[i];
		end
	end

	local function GetCandidates(resourceIndex, requiredFeatureIndex)
		local candidates = {};
		for plotIndex = 0, plotCount - 1 do
			local plot = Map.GetPlotByIndex(plotIndex);
			if plot ~= nil
				and plot:GetResourceType() == -1
				and (requiredFeatureIndex == nil or plot:GetFeatureType() == requiredFeatureIndex)
				and ResourceBuilder.CanHaveResource(plot, resourceIndex) then
				table.insert(candidates, plotIndex);
			end
		end
		return candidates;
	end

	-- Iterate resource types in a stable order.  This loop consumes the
	-- synchronized map RNG while shuffling candidates, so pairs() could make
	-- different clients consume the RNG stream in different orders.
	local removedResourceIndices = {};
	for resourceIndex in pairs(removedByType) do
		table.insert(removedResourceIndices, resourceIndex);
	end
	table.sort(removedResourceIndices);
	for _, resourceIndex in ipairs(removedResourceIndices) do
		local removedCount = removedByType[resourceIndex]
		local candidates = GetCandidates(resourceIndex, reefIndex);
		ShufflePlots(candidates, "ZYL RVC reef-only resource replacement");
		local placed = math.min(removedCount, #candidates);
		for i = 1, placed do
			ResourceBuilder.SetResourceType(Map.GetPlotByIndex(candidates[i]), resourceIndex, 1);
		end
		print("ZYL RVC reef-only resource correction", reefOnlyResources[resourceIndex], removedCount, placed);
	end
end

-------------------------------------------------------------------------------
function Remove_SouthSeaResource()
	for _, index in ipairs(Remove_South_Sea_Resource_Plots) do
		local pPlot = Map.GetPlotByIndex(index);
		ResourceBuilder.SetResourceType(pPlot, -1);
	end
end
-------------------------------------------------------------------------------
function Add_LEY_LINE()
	if GameInfo.Resources['RESOURCE_LEY_LINE'] == nil then return end
	local LEY_LINE_index = GameInfo.Resources['RESOURCE_LEY_LINE'].Index

 	if GameInfo.Resources['RESOURCE_LEY_LINE'] ~= nil then
		local iW, iH = Map.GetGridSize();
		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				local pPlot = Map.GetPlotByIndex(index)
				if pPlot:GetResourceType() == -1 and ResourceBuilder.CanHaveResource(pPlot, LEY_LINE_index) then
					local AddOk = true

					local plots = Map.GetNeighborPlots(iX, iY, 6)
					for i, adjPlot in ipairs(plots) do
						if adjPlot:GetResourceType() == LEY_LINE_index then
							--[[ Corrupted legacy log text retained only as a comment.
							print("这里有地脉")
							]]
							print("Nearby ley line found")
							AddOk = false
							break
						end
					end

					--for i = 0, getadjNun(5) do
					--	local iPlot = GetAdjacentTiles(pPlot, i)
					--	if iPlot ~= nil then
					--		if iPlot:GetResourceType() == LEY_LINE_index then
					--			print("这里有地脉")
					--			AddOk = false
					--			break
					--		end
					--	end
					--end
					if AddOk then
						ResourceBuilder.SetResourceType(pPlot, LEY_LINE_index, 1);
						print("放置地脉")
					end
				end
			end
		end
 	end
end

function getadjNun(n)
	if not n or n <= 0 then
		return -1
	end

	local i = 0
	for j = 1, n do
		i = i + 6 * j
	end
	return i
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
	if(plot ~= nil and index ~= nil) then
		if (index < 0) then
			return plot;
		end

		else

		__Debug("GetAdjacentTiles: Invalid Arguments");
		return nil;
	end



	-- Return Starting City Circle if index between #0 to #5 (like Firaxis' GetAdjacentPlot)
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			if (adjacentPlot ~= nil and index == i) then
				return adjacentPlot
			end
		end
	end

	-- Return Inner City Circle if index between #6 to #17

	count = 5;
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot2 = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
		end

		for j = i, i+1 do
			--__Debug(i, j)
			k = j;
			count = count + 1;

			if (k == 6) then
				k = 0;
			end

			if (adjacentPlot2 ~= nil) then
				if(adjacentPlot2:GetX() >= 0 and adjacentPlot2:GetY() < gridHeight) then
					adjacentPlot = Map.GetAdjacentPlot(adjacentPlot2:GetX(), adjacentPlot2:GetY(), k);

					else

					adjacentPlot = nil;
				end
			end


			if (adjacentPlot ~=nil) then
				if(index == count) then
					return adjacentPlot
				end
			end

		end
	end

	-- #18 to #35 Outer city circle
	count = 0;
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
			adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), i);
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
			else
			adjacentPlot = nil;
			adjacentPlot2 = nil;
			adjacentPlot3 = nil;
		end
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3;
			if(index == count) then
				return adjacentPlot2
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot3 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
				end
				else
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i +1);
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3 + 1;
			if(index == count) then
				return adjacentPlot2
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			count = 18 + i * 3 + 2;
			if(index == count) then
				return adjacentPlot2;
			end
		end

	end

	--  #35 #59 These tiles are outside the workable radius of the city
	local count = 0
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
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
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
						end
					end
				end
			end
		end

		if (adjacentPlot2 ~= nil) then
			terrainType = adjacentPlot2:GetTerrainType();
			if (adjacentPlot2 ~=nil) then
				count = 36 + i * 4;
				if(index == count) then
					return adjacentPlot2;
				end
			end

		end

		if (adjacentPlot3 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
				end
				else
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i +1);
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 1;
					if(index == count) then
						return adjacentPlot2;
					end
				end
			end


		end

		adjacentPlot4 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i);
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 2;
					if(index == count) then
						return adjacentPlot2;
					end

				end
			end

		end

		adjacentPlot4 = nil;

		if (adjacentPlot ~= nil) then
			if (i+1 == 6) then
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0);
					end
				end
				else
				if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1);
				end
				if (adjacentPlot3 ~= nil) then
					if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1);
					end
				end
			end
		end

		if (adjacentPlot4 ~= nil) then
			if (adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
					else
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1);
				end
				if (adjacentPlot2 ~= nil) then
					count = 36 + i * 4 + 3;
					if(index == count) then
						return adjacentPlot2;
					end

				end
			end

		end

	end

	--  > #60 to #90

	local count = 0
	for i = 0, 5 do
		if(plot:GetX() >= 0 and plot:GetY() < gridHeight) then
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
		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i); --2nd ring
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i); --3rd ring
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i); --4th ring
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
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
			if(index == count) then
				return adjacentPlot2; --5th ring
			end
		end

		adjacentPlot2 = nil;

		if (adjacentPlot5 ~= nil) then
			if (i + 1) == 6 then
				if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
				end
				else
				if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
					adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i +1);
				end
			end
		end


		if (adjacentPlot2 ~= nil) then
			count = 60 + i * 5 + 1;
			if(index == count) then
				return adjacentPlot2;
			end

		end

		adjacentPlot2 = nil;

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i);
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i);
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0);
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1);
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									if (i+1 == 6) then
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0);
										else
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i+1);
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
			if(index == count) then
				return adjacentPlot2;
			end

		end

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
					else
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1); -- 2 ring
				end
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					if (i+1 == 6) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
						else
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1); -- 3ring

					end
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1); --4th ring
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
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
			if(index == count) then
				return adjacentPlot2;
			end

		end

		adjacentPlot2 = nil

		if (adjacentPlot ~=nil) then
			if(adjacentPlot:GetX() >= 0 and adjacentPlot:GetY() < gridHeight) then
				if (i+1 == 6) then
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), 0); -- 2 ring
					else
					adjacentPlot3 = Map.GetAdjacentPlot(adjacentPlot:GetX(), adjacentPlot:GetY(), i+1); -- 2 ring
				end
			end
			if (adjacentPlot3 ~= nil) then
				if(adjacentPlot3:GetX() >= 0 and adjacentPlot3:GetY() < gridHeight) then
					if (i+1 == 6) then
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), 0); -- 3ring
						else
						adjacentPlot4 = Map.GetAdjacentPlot(adjacentPlot3:GetX(), adjacentPlot3:GetY(), i+1); -- 3ring

					end
					if (adjacentPlot4 ~= nil) then
						if(adjacentPlot4:GetX() >= 0 and adjacentPlot4:GetY() < gridHeight) then
							if (i+1 == 6) then
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), 0); --4th ring
								else
								adjacentPlot5 = Map.GetAdjacentPlot(adjacentPlot4:GetX(), adjacentPlot4:GetY(), i+1); --4th ring
							end
							if (adjacentPlot5 ~= nil) then
								if(adjacentPlot5:GetX() >= 0 and adjacentPlot5:GetY() < gridHeight) then
									if (i+1 == 6) then
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), 0); --5th ring
										else
										adjacentPlot2 = Map.GetAdjacentPlot(adjacentPlot5:GetX(), adjacentPlot5:GetY(), i+1); --5th ring
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
			if(index == count) then
				return adjacentPlot2;
			end

		end

	end

end
-------------------------------------------------------------------------------
function RichNSBalance()
	local function GetResourceIndex(resourceType)
		local row = GameInfo.Resources[resourceType];
		return row and row.Index or -1;
	end
	local function GetFeatureIndex(featureType)
		local row = GameInfo.Features[featureType];
		return row and row.Index or -1;
	end
	local function GetTerrainIndex(terrainType)
		local row = GameInfo.Terrains[terrainType];
		return row and row.Index or -1;
	end

	local terrainGrass = GetTerrainIndex("TERRAIN_GRASS");
	local terrainGrassHills = GetTerrainIndex("TERRAIN_GRASS_HILLS");
	local terrainPlains = GetTerrainIndex("TERRAIN_PLAINS");
	local terrainPlainsHills = GetTerrainIndex("TERRAIN_PLAINS_HILLS");
	local terrainDesert = GetTerrainIndex("TERRAIN_DESERT");
	local terrainDesertHills = GetTerrainIndex("TERRAIN_DESERT_HILLS");
	local flatTerrainForHill = {
		[terrainGrassHills] = terrainGrass,
		[terrainPlainsHills] = terrainPlains,
	};
	local hillTerrainForFlat = {
		[terrainGrass] = terrainGrassHills,
		[terrainPlains] = terrainPlainsHills,
	};

	local resourceStone = GetResourceIndex("RESOURCE_STONE");
	local resourceCopper = GetResourceIndex("RESOURCE_COPPER");
	local resourceBananas = GetResourceIndex("RESOURCE_BANANAS");
	local resourceRice = GetResourceIndex("RESOURCE_RICE");
	local resourceCattle = GetResourceIndex("RESOURCE_CATTLE");
	local resourceFish = GetResourceIndex("RESOURCE_FISH");
	local resourceDeer = GetResourceIndex("RESOURCE_DEER");
	local featureReef = GetFeatureIndex("FEATURE_REEF");

	-- 将无地貌、资源的丘陵变为平地
	for i = 0, g_iH - 1 do
		for j = 0, g_iW - 1 do
			local pPlot = Map.GetPlotByIndex(i * g_iW + j);
			local flatTerrain = flatTerrainForHill[pPlot:GetTerrainType()];
			if flatTerrain and pPlot:GetFeatureType() == -1 and pPlot:GetResourceType() == -1 then
				TerrainBuilder.SetTerrainType(pPlot, flatTerrain)
			end
		end
	end

	-- 如果富饶系数大于等于4，所有人都会有加成资源屁股
	-- 如果富饶系数大于等于7，所有人都会有奢侈品屁股
	if RichNum >= 4 then
		local ChooseResourceClass = 'RESOURCECLASS_BONUS'
		if RichNum >= 7 then
			ChooseResourceClass = 'RESOURCECLASS_LUXURY'
		end
		local Resource_ValidTerrainsTable = {}
		for row in GameInfo.Resource_ValidTerrains() do
			if GameInfo.Resources[row.ResourceType].ResourceClassType == ChooseResourceClass then
				if not Resource_ValidTerrainsTable[row.TerrainType] then
					Resource_ValidTerrainsTable[row.TerrainType] = {}
				end
				table.insert(Resource_ValidTerrainsTable[row.TerrainType],GameInfo.Resources[row.ResourceType].Index)
				--[[ Corrupted legacy log text retained only as a comment.
				print(row.ResourceType,GameInfo.Resources[row.ResourceType].Index,'已记录')
			end
		end
				]]
				print("Registered resource", row.ResourceType, GameInfo.Resources[row.ResourceType].Index)
			end
		end
		local tempMajorList = PlayerManager.GetAliveMajorIDs();
		for i = 1, PlayerManager.GetAliveMajorsCount() do
			local civilizationType = PlayerConfigurations[tempMajorList[i]]:GetCivilizationTypeName();
			local skipMaliLuxuryCopy = RichNum >= 7 and civilizationType == "CIVILIZATION_MALI";
			if (PlayerConfigurations[tempMajorList[i]]:GetLeaderTypeName() ~= "LEADER_SPECTATOR"
				and PlayerConfigurations[tempMajorList[i]]:GetHandicapTypeID() ~= 2021024770
				and not skipMaliLuxuryCopy) then
				local pStartPlot_i = Players[tempMajorList[i]]:GetStartingPlot()
				if (pStartPlot_i ~= nil and pStartPlot_i:IsWater() == false) then
					local TerrainType = GameInfo.Terrains[pStartPlot_i:GetTerrainType()].TerrainType
					-- 先看一下玩家大陆的奢侈
					local flag = false;
					local Plots = Map.GetContinentPlots(pStartPlot_i:GetContinentType());
					if (Resource_ValidTerrainsTable[TerrainType] and #Resource_ValidTerrainsTable[TerrainType]>0) then
						for _,eResource in ipairs(Resource_ValidTerrainsTable[TerrainType]) do
							local iPlot = PlotsHasResource(eResource,Plots)
							if iPlot > 0 and ResourceBuilder.CanHaveResource(pStartPlot_i,eResource) then
								-- 这就好办了
								ResourceBuilder.SetResourceType(pStartPlot_i,eResource,1);
								flag = true;
								break;
							end
						end
						if not flag then
							for _,eResource in ipairs(Resource_ValidTerrainsTable[TerrainType]) do
								local iPlot = RichNSMapHasResource(eResource)
								if iPlot > 0 and ResourceBuilder.CanHaveResource(pStartPlot_i,eResource) then
									ResourceBuilder.SetResourceType(pStartPlot_i,eResource,1);
									flag = true;
									break;
								end
							end
						end
					end
					-- 到这里还不能保底那我也没招了
				end
			end
		end
	end

	-- 修正：RichNum * RichNum/200的沙漠变为沙漠丘陵
	-- 修正：RichNum * RichNum/200的沙漠丘陵变为铜
	-- 修正：RichNum * RichNum/100的石头将变为丘陵
	-- 修正：RichNum * RichNum/150的空雨林将变为香蕉
	-- 修正：RichNum * RichNum/150的空沼泽将变为大米
	-- 修正：RichNum * RichNum/200的空树林将变为鹿
	-- 修正：RichNum^3/1500 的空地将变为地脉
	-- 修正：RichNum * RichNum/300的绿地将变为牛
	-- 修正：RichNum * RichNum/300的鱼将变为礁石
	-- 修正：RichNum * RichNum/300的沙漠将变为绿洲
	local CanHaveLeyLine = false
	local CanHaveLeyLineIndex;
	if GameInfo.Resources['RESOURCE_LEY_LINE'] and GameInfo.Resources['RESOURCE_LEY_LINE'].Index ~= nil then
		CanHaveLeyLine = true
		CanHaveLeyLineIndex = GameInfo.Resources['RESOURCE_LEY_LINE'].Index
	end
	if RichNum > 0 then
		for i = 0, g_iH - 1 do
			for j = 0, g_iW - 1 do
				local pPlot = Map.GetPlotByIndex(i * g_iW + j);
				local hillTerrain = hillTerrainForFlat[pPlot:GetTerrainType()];
				if hillTerrain and pPlot:GetResourceType() == resourceStone and TerrainBuilder.GetRandomNumber(100, "Resource Placement Score Adjust") < RichNum * RichNum then
					TerrainBuilder.SetTerrainType(pPlot, hillTerrain)
				end
				if pPlot:GetTerrainType() == terrainDesert and pPlot:GetResourceType() == -1 and pPlot:GetFeatureType() == -1 and TerrainBuilder.GetRandomNumber(200, "Resource Placement Score Adjust") < RichNum * RichNum then
					TerrainBuilder.SetTerrainType(pPlot, terrainDesertHills)
				end
				if resourceCopper ~= -1 and pPlot:GetTerrainType() == terrainDesertHills and pPlot:GetResourceType() == -1 and TerrainBuilder.GetRandomNumber(200, "Resource Placement Score Adjust") < RichNum * RichNum then
					ResourceBuilder.SetResourceType(pPlot, resourceCopper, 1);
				end
				if resourceBananas ~= -1 and pPlot:GetFeatureType() == g_FEATURE_JUNGLE and pPlot:GetResourceType() == -1 and TerrainBuilder.GetRandomNumber(150, "Resource Placement Score Adjust") < RichNum * RichNum then
					ResourceBuilder.SetResourceType(pPlot, resourceBananas, 1);
				end
				if resourceRice ~= -1 and pPlot:GetFeatureType() == g_FEATURE_MARSH and pPlot:GetResourceType() == -1 and TerrainBuilder.GetRandomNumber(150, "Resource Placement Score Adjust") < RichNum * RichNum then
					ResourceBuilder.SetResourceType(pPlot, resourceRice, 1);
				end
				if resourceCattle ~= -1 and pPlot:GetFeatureType() == -1 and pPlot:GetTerrainType() == terrainGrass and pPlot:GetResourceType() == -1 and TerrainBuilder.GetRandomNumber(300, "Resource Placement Score Adjust") < RichNum * RichNum then
					ResourceBuilder.SetResourceType(pPlot, resourceCattle, 1);
				end
				if featureReef ~= -1 and pPlot:GetFeatureType() == -1 and pPlot:GetResourceType() == resourceFish and TerrainBuilder.GetRandomNumber(300, "Resource Placement Score Adjust") < RichNum * RichNum then
					TerrainBuilder.SetFeatureType(pPlot, featureReef)
				end
				if resourceDeer ~= -1 and pPlot:GetFeatureType() == g_FEATURE_FOREST and pPlot:GetResourceType() == -1 and TerrainBuilder.GetRandomNumber(200, "Resource Placement Score Adjust") < RichNum * RichNum then
					ResourceBuilder.SetResourceType(pPlot, resourceDeer, 1);
				end
				if not CompetitionMode and CanHaveLeyLine
					and pPlot:GetResourceType() == -1 and pPlot:GetFeatureType() == -1
					and ResourceBuilder.CanHaveResource(pPlot, CanHaveLeyLineIndex)
					and TerrainBuilder.GetRandomNumber(1500, "Resource Placement Score Adjust") < RichNum * RichNum * RichNum then
					ResourceBuilder.SetResourceType(pPlot,CanHaveLeyLineIndex,1);
				end
			end
		end
	end
end
-------------------------------------------------------------------------------
function PlotsHasResource(iResources,Plots)
    for  i, plot in ipairs(Plots) do
		local pPlot = Map.GetPlotByIndex(plot);
        if pPlot:GetResourceType() == iResources then
            return i
        end
    end
    return -1
end

-------------------------------------------------------------------------------

function RichNSMapHasResource(iResources)
    local iW, iH = Map.GetGridSize();
    for k = 0, iH * iW - 1 do
        local pPlot = Map.GetPlotByIndex(k);
        if pPlot:GetResourceType() == iResources then
            return k
        end
    end
    return -1
end
-------------------------------------------------------------------------------
function TeamPVPGenerateContinents(plotTypes)
	-- Team mode deliberately restores the Rich Vertical Continent strip logic:
	-- contiguous rows are assigned in bands so opposite teams get opposite
	-- mainland strips.  FFA uses the ordinary geographic plate assignment.
	if not IS_TEAM then
		TerrainBuilder.StampContinents();
		AreaBuilder.Recalculate();
		TerrainBuilder.AnalyzeChokepoints();
		return;
	end

	local iNumContinents = math.max(1, #GameInfo.Continents);
	local iContinent = TerrainBuilder.GetRandomNumber(iNumContinents, "ZYLRM continent seed");
	local mapRow = ZYL_RVC_GetMapRow();
	local mapContinents = math.max(1, (mapRow and mapRow.Continents or 1) + math.floor((RichNum or 4) / 3) - 1);
	local landCount = 0;
	for i = 0, g_iW * g_iH - 1 do
		if plotTypes[i] == g_PLOT_TYPE_LAND then landCount = landCount + 1 end
	end
	if landCount == 0 then
		TerrainBuilder.StampContinents();
		return;
	end
	local bandSize = math.max(1, math.ceil(landCount / mapContinents));
	local assigned = math.floor(bandSize / 2);
	local function assignPlot(plot)
		local continent = (iContinent + math.floor((assigned % landCount) / bandSize)) % iNumContinents;
		TerrainBuilder.SetContinentType(plot, continent);
		if plotTypes[plot:GetIndex()] == g_PLOT_TYPE_LAND then assigned = assigned + 1 end
	end
	for y = 0, g_iH - 1 do
		for x = 0, g_iW - 1 do assignPlot(Map.GetPlot(x, y)) end
	end
	AreaBuilder.Recalculate();
	TerrainBuilder.AnalyzeChokepoints();
end

-------------------------------------------------------------------------------
function TeamPVPGeneratePlotTypes(world_age)
	plotTypes = table.fill(g_PLOT_TYPE_LAND, g_iW * g_iH);

	-- 竖向大陆海陆生成：不对称水域裁剪。组队图保持原来的15格东西海；
	-- FFA 保持原来的12格东西海，额外宽度留给环绕接缝深海。
	local variationFrac1 = Fractal.Create(g_iH, g_iBaseW, 3, g_iFlags, -1, -1);
	local variationFrac2 = Fractal.Create(g_iH, g_iBaseW, 3, g_iFlags, -1, -1);
	local variationFrac3 = Fractal.Create(g_iBaseW, g_iH, 3, g_iFlags, -1, -1);
	local variationFrac4 = Fractal.Create(g_iBaseW, g_iH, 3, g_iFlags, -1, -1);

	local base_water_W = IS_FFA and 12 or 15
	local d_water_W = base_water_W * g_fHorizontalScale
	local d_water_H = 6
	local waterlatitude_W = 1 - (d_water_W * 2 / g_iH)
	local waterlatitude_H = 1 - (d_water_H * 2 / g_iH)
	print(string.format("%s: east/west sea width %.2f (base %d, horizontal scale %.4f)",
		LOG_PREFIX, d_water_W, base_water_W, g_fHorizontalScale));

	for y = 0, g_iH -1 do
		for x = 0, g_iW - 1 do
			local i = y * g_iW + x
			local pPlot = Map.GetPlotByIndex(i);
			local baseX = x - g_iContentOffsetX;
			if baseX < 0 or baseX >= g_iBaseW then
				plotTypes[i] = g_PLOT_TYPE_OCEAN;
				TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
			elseif baseX > g_iBaseW - g_iH / 2 then
				local lat = GetLatitudeAtPlot(variationFrac1, y, g_iBaseW - baseX);
				if lat >= waterlatitude_W then
					plotTypes[i] = g_PLOT_TYPE_OCEAN
					TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
				end
			elseif baseX < g_iH / 2 then
				local lat = GetLatitudeAtPlot(variationFrac2, y, baseX);
				if lat >= waterlatitude_W then
					plotTypes[i] = g_PLOT_TYPE_OCEAN
					TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
				end
			end
			if baseX >= 0 and baseX < g_iBaseW then
				if y > g_iH / 2 then
					local lat = GetLatitudeAtPlot(variationFrac3, baseX, g_iH - y);
					if lat >= waterlatitude_H then
						plotTypes[i] = g_PLOT_TYPE_OCEAN
						TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
					end
				else
					local lat = GetLatitudeAtPlot(variationFrac3, baseX, y);
					if lat >= waterlatitude_H then
						plotTypes[i] = g_PLOT_TYPE_OCEAN
						TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
					end
				end
			end
			if y <= 1 or y >= g_iH - 1 then
				plotTypes[i] = g_PLOT_TYPE_OCEAN
				TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
			end
		end
	end
	AreaBuilder.Recalculate();

	local biggest_area = Areas.FindBiggestArea(false);		-- 删除岛屿
	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i);
			local baseX = x - g_iContentOffsetX;
			if(plotTypes[i] == g_PLOT_TYPE_LAND and pPlot:GetArea() ~= biggest_area)
				or baseX <= 1 or baseX >= g_iBaseW - 2 then
				plotTypes[i] = g_PLOT_TYPE_OCEAN;
				TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_OCEAN);
			end
		end
	end

	-- 记录远洋格子（距最近陆地>5格），后续移除其资源
	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			local pPlot = Map.GetPlotByIndex(i)
			local nPlot = pPlot:GetNearestLandPlot()
			local Distance = nPlot and Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), nPlot:GetX(), nPlot:GetY()) or 0;
			if Distance > 5 and plotTypes[i] ~= g_PLOT_TYPE_LAND then
				table.insert(Remove_South_Sea_Resource_Plots, i)
			end
		end
	end

	-- 添加岛屿。岛带位于旧内容画布的东西海域内。
	local d_island = (base_water_W - 4) * g_fHorizontalScale
	local Islandlatitude_W = 1 - (d_island * 2 / g_iH)

	local d_island_2 = (base_water_W - 9) * g_fHorizontalScale
	local Islandlatitude_W_2 = 1 - (d_island_2 * 2 / g_iH)

	local args = args or {};
	local oldIslandLandPercent = 100 - ZYL_RICH_MAINLAND_ISLAND_BASE_WATER_PERCENT;
	local islandAreaScale = IS_FFA and g_fHorizontalScale or 1;
	local targetIslandLandPercent = oldIslandLandPercent
		* ZYL_RICH_MAINLAND_ISLAND_LAND_MULTIPLIER / islandAreaScale;
	-- Fractal:GetHeight consumes an integer percentile.  Nearest-integer
	-- rounding keeps the total target within roughly 1-2% of the requested
	-- +20% and avoids relying on implicit C/Lua coercion.
	args.iWaterPercent = math.clamp(math.floor(100 - targetIslandLandPercent + 0.5), 0, 100);
	args.iRegionWidth = math.ceil(g_iBaseW);
	args.iRegionHeight = math.ceil(g_iH);
	args.iRegionWestX = math.floor(0);
	args.iRegionSouthY = math.floor(0);
	args.iRegionGrain = ZYL_RICH_MAINLAND_ISLAND_GRAIN;
	args.iRegionHillsGrain = 6;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 6;
	args.iRegionFracYExp = 7;

	local iWaterPercent = args.iWaterPercent or 55;
	local iRegionWidth = args.iRegionWidth; -- Mandatory Parameter, no default
	local iRegionHeight = args.iRegionHeight; -- Mandatory Parameter, no default
	local iRegionWestX = args.iRegionWestX; -- Mandatory Parameter, no default
	local iRegionSouthY = args.iRegionSouthY; -- Mandatory Parameter, no default
	local iRegionGrain = args.iRegionGrain or 1;
	local iRegionPlotFlags = args.iRegionPlotFlags or g_iFlags;
	local iRegionTerrainFlags = g_iFlags; -- Removed from args list.
	local iRegionFracXExp = args.iRegionFracXExp or 6;
	local iRegionFracYExp = args.iRegionFracYExp or 5;
	local iRiftGrain = args.iRiftGrain or -1;
	print(string.format("%s: island layer waterPercent=%d grain=%d areaScale=%.4f (target +20%% island land, larger clusters)",
		LOG_PREFIX, iWaterPercent, iRegionGrain, islandAreaScale));

	local regionContinentsFrac;
	if(iRiftGrain > 0 and iRiftGrain < 4) then
		local riftsFrac = Fractal.Create(g_iBaseW, g_iH, rift_grain, {}, iRegionFracXExp, iRegionFracYExp);
		regionContinentsFrac = Fractal.CreateRifts(g_iBaseW, g_iH, iRegionGrain, iRegionPlotFlags, riftsFrac, iRegionFracXExp, iRegionFracYExp);
	else
		regionContinentsFrac = Fractal.Create(g_iBaseW, g_iH, iRegionGrain, iRegionPlotFlags, iRegionFracXExp, iRegionFracYExp);
	end
	local iWaterThreshold = regionContinentsFrac:GetHeight(iWaterPercent);

	for y = 0, g_iH -1 do
		for x = 0, g_iW - 1 do
			local baseX = x - g_iContentOffsetX;
			if y > d_water_H and y < g_iH - d_water_H then
				local i = y * g_iW + x
				local pPlot = Map.GetPlotByIndex(i);
				if baseX >= 0 and baseX < g_iBaseW then
					local val = regionContinentsFrac:GetHeight(baseX,y);
					if val >= iWaterThreshold then
						if baseX > g_iBaseW - g_iH / 2 then
							local lat = GetLatitudeAtPlot(variationFrac1, y, g_iBaseW - baseX);
							if lat >= Islandlatitude_W and lat <= Islandlatitude_W_2 then
								plotTypes[i] = g_PLOT_TYPE_LAND
								TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_DESERT);
							end
						elseif baseX < g_iH / 2 then
							local lat = GetLatitudeAtPlot(variationFrac2, y, baseX);
							if lat >= Islandlatitude_W and lat <= Islandlatitude_W_2 then
								plotTypes[i] = g_PLOT_TYPE_LAND
								TerrainBuilder.SetTerrainType(pPlot, g_TERRAIN_TYPE_DESERT);
							end
						end
					end
				end
			end
		end
	end
	AreaBuilder.Recalculate();

	local args = {};
	args.world_age = world_age;
	args.iW = g_iW;
	args.iH = g_iH;
	args.iFlags = g_iFlags;
	args.blendRidge = 10;
	args.blendFract = 1;
	-- Roughly +20% over Rich Vertical Continent: lower the tectonic threshold
	-- by two percentile points, retain passes, and add one extra highland point
	-- in the later mountain-detail fractal.
	args.extra_mountains = math.max(0, (2 + (3 - world_age)) * 2 + 2);
	args.tectonic_islands = tectonic_islands;
	mountainRatio = math.max(1, math.floor((24 + (3 - world_age)) * 1.70 + 0.5));
	plotTypes = ApplyTectonics(args, plotTypes);
	plotTypes = AddLonelyMountains(plotTypes, mountainRatio);

	-- 705: Found a good map, now we can loop through every tile and add additional details
	print("-");
	local plotDataIsCoastal = GenerateCoastalLandDataTable();
	local hillsAdded = 0;
	local mountainsAdded = 0;
	local mountainsFilled = 0;

	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			-- 705: First, clean up the rare case of a non mountain plot surrounded by mountains
			if(plotTypes[i] == g_PLOT_TYPE_LAND or plotTypes[i] == g_PLOT_TYPE_HILLS) then
				local mountainCount = 0;
				for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
					local adjacentPlot = Map.GetAdjacentPlot(x, y, direction);
					if adjacentPlot ~= nil then
						local newIndex = adjacentPlot:GetIndex();
						if(plotTypes[newIndex] == g_PLOT_TYPE_MOUNTAIN) then
							mountainCount = mountainCount + 1;
						end
					end
				end

				if(mountainCount > 1) then -- surrounded by mountains 相邻山大于
					for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
						local rChance = 1 + TerrainBuilder.GetRandomNumber(6, "Add pass - LUA Pangaea");
						local adjacentPlot = Map.GetAdjacentPlot(x, y, direction);
						if adjacentPlot ~= nil then
							local newIndex = adjacentPlot:GetIndex();
							if(plotTypes[newIndex] == g_PLOT_TYPE_MOUNTAIN and rChance > 3 ) then
								plotTypes[newIndex] = g_PLOT_TYPE_HILLS;
								mountainsFilled = mountainsFilled + 1;
							end
						end
					end
				end
			end

			-- 705: Detailed hills and mountains pass, Pangaea version creates fewer hills
			local rChance = TerrainBuilder.GetRandomNumber(6, "Add hills - LUA Mixed Continents");
			local mountainsAllowed = g_iH / (6 - world_age);

			if(plotDataIsCoastal[i] == false) then
				local hillCount = 0;
				for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
					local adjacentPlot = Map.GetAdjacentPlot(x, y, direction);
					if adjacentPlot ~= nil then
						local newIndex = adjacentPlot:GetIndex();
						if(plotTypes[newIndex] == g_PLOT_TYPE_HILLS) then
							hillCount = hillCount + 1;
						end
					end
				end
				-- Add hill to flatland areas
				if(hillCount < rChance - 2 and plotTypes[i] == g_PLOT_TYPE_LAND) then
					plotTypes[i] = g_PLOT_TYPE_HILLS;
					hillsAdded = hillsAdded + 2;

				-- Add mountain or remove hill in hilly areas
				elseif(hillCount > rChance + 1 and mountainsAdded < mountainsAllowed) then
					plotTypes[i] = g_PLOT_TYPE_MOUNTAIN;
					mountainsAdded = mountainsAdded + 4;
				elseif(hillCount > rChance) then
					plotTypes[i] = g_PLOT_TYPE_LAND;
				end

			end
		end
	end

	-- 丘陵补贴
	for x = 0, g_iW - 1 do
		for y = 0, g_iH - 1 do
			local i = y * g_iW + x;
			if not(plotTypes[i] == g_PLOT_TYPE_OCEAN or plotTypes[i] == g_PLOT_TYPE_MOUNTAIN) then
				local landnum = 0
				local hillnum = 0
				for j = 0, 5 do
					local pPlot = Map.GetAdjacentPlot(x, y, j)
					if pPlot and plotTypes[pPlot:GetIndex()] ~= g_PLOT_TYPE_OCEAN then
						landnum = landnum + 1
						if plotTypes[pPlot:GetIndex()] == g_PLOT_TYPE_HILLS then
							hillnum = hillnum + 1
						end
					else
						break
					end
				end

				if landnum == 6 then
					if hillnum == 0 then
						plotTypes[i] = g_PLOT_TYPE_HILLS
					end
				end
			end
		end
	end

	AddMountain(plotTypes)

	print("-");
	print("--- Details pass");
	print("-  Mountain Passes Cleared:", mountainsFilled);
	print("-              Hills added:", hillsAdded);
	print("-          Mountains added:", mountainsAdded);

	-- 705: Flip the map?
	local flipMap = DetermineFlip(plotTypes); -- Todo: check polar land to determine if we need to flip

	if(flipMap) then
		local i, j = 1, #plotTypes;
		while i < j do
			plotTypes[i], plotTypes[j] = plotTypes[j], plotTypes[i];
			i = i + 1;
			j = j - 1;
		end
		print("-");
		print("- Map Flipped!");
	end

	print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -");

	return plotTypes;
end

function InitFractal(args)

	if(args == nil) then args = {}; end

	local continent_grain = args.continent_grain or 2;
	local rift_grain = args.rift_grain or -1;
	-- Default no rifts. Set grain to between 1 and 3 to add rifts. - Bob
	local invert_heights = args.invert_heights or false;
	local polar = args.polar or true;
	local ridge_flags = args.ridge_flags or g_iFlags;

	local fracFlags = {};
	
	if(invert_heights) then
		fracFlags.FRAC_INVERT_HEIGHTS = true;
	end
	
	if(polar) then
		fracFlags.FRAC_POLAR = true;
	end

	-- 705: Reduce max vertical size and hope that the plot shift function will clean up this mess.
	local g_maxH = math.floor(g_iH * 0.9);

	if(rift_grain > 0 and rift_grain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_maxH, rift_grain, {}, 6, 5);
		g_continentsFrac = Fractal.CreateRifts(g_iW, g_maxH, continent_grain, fracFlags, riftsFrac, 6, 5);
	else
		g_continentsFrac = Fractal.Create(g_iW, g_maxH, continent_grain, fracFlags, 6, 5);	
	end

	-- Use Brian's tectonics method to weave ridgelines in to the continental fractal.
	-- Without fractal variation, the tectonics come out too regular.
	--
	--[[ "The principle of the RidgeBuilder code is a modified Voronoi diagram. I 
	added some minor randomness and the slope might be a little tricky. It was 
	intended as a 'whole world' modifier to the fractal class. You can modify 
	the number of plates, but that is about it." ]]-- Brian Wade - May 23, 2009
	--
	local mapRow = ZYL_RVC_GetMapRow();
	local numPlates = mapRow and mapRow.PlateValue or 4;
	
	-- 705: Increase plates for better detail on all map sizes
	numPlates = numPlates * 2;

	-- Blend a bit of ridge into the fractal.
	-- This will do things like roughen the coastlines and build inland seas. - Brian

	g_continentsFrac:BuildRidges(numPlates, {}, 1, 2);
end

function AddFeatures()
	print("增加地貌");
	-- 获取降雨量设置
	local rainfall = MapConfiguration.GetValue("rainfall");
	if rainfall == 4 then
		rainfall = 1 + TerrainBuilder.GetRandomNumber(3, "Random Rainfall - Lua");
	end
	
	-- 河流的形成受地块类型的影响，发源于高地，更倾向于流经低地。
	-- 705：将降雨考虑在内的自定义河流方法
	AddRivers({
		rainfall = rainfall + 1;
	});

	local args = {};
	args.rainfall = rainfall;
	
	-- 湖泊会干扰河流，导致河流停止，如果再早一点建起来，就无法流入海洋。
	local mapRow = ZYL_RVC_GetMapRow();
	local lakeScale = IS_FFA and g_fHorizontalScale or 1;
	local numLargeLakes = (mapRow and mapRow.Continents or 1) * lakeScale;
	-- 705：通过降雨调整大湖。
	numLargeLakes = math.floor(numLargeLakes + rainfall - 4 + 0.5);

	AddLakes(math.max(0, numLargeLakes));

	-- 雨林比例
	args.iJunglePercent = 18 + RichNum;
	-- 森林比例
	args.iForestPercent = 16 + RichNum * 1.6;
	-- 沼泽比例
	args.iMarshPercent = 4 - RichNum / 3;
	-- 绿洲比例
	args.iOasisPercent = 1;
	-- 礁石比例
	args.iReefPercent = 8 + RichNum / 1.5;
	
	featureGen = DW_FeatureGenerator.Create(args);
	featureGen:AddFeatures(true, true, {
		RichNum = RichNum
	});
end

function AddFeaturesFromContinents()
	--[[ Corrupted legacy log text retained only as a comment.
	print("为大陆边界增加地貌");
	]]
	print("Adding continent-boundary features")
	featureGen:AddFeaturesFromContinents({
		FissuresMultyDesired = 1 + RichNum/10
	});
end

-------------------------------------------------------------------------------
function GenerateWaterLayer (args, plotTypes)
	-- 这个功能的目的是允许将海洋添加到大型大陆的特定区域。
	local args = args or {};
	
	-- 处理参数或分配默认值。
	local iWaterPercent = args.iWaterPercent or 55;
	local iRegionWidth = args.iRegionWidth; -- Mandatory Parameter, no default
	local iRegionHeight = args.iRegionHeight; -- Mandatory Parameter, no default
	local iRegionWestX = args.iRegionWestX; -- Mandatory Parameter, no default
	local iRegionSouthY = args.iRegionSouthY; -- Mandatory Parameter, no default
	local iRegionGrain = args.iRegionGrain or 1;
	local iRegionPlotFlags = args.iRegionPlotFlags or g_iFlags;
	local iRegionFracXExp = args.iRegionFracXExp or 6;
	local iRegionFracYExp = args.iRegionFracYExp or 5;
	local iRiftGrain = args.iRiftGrain or -1;
	local bShift = args.bShift or true;

	-- Init the plot types array for this region's plot data. Redone for each new layer.
	-- Compare to self.wholeworldPlotTypes, which contains the sum of all layers.
	plotTypes2 = {};
	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			plotTypes2[i] = g_PLOT_TYPE_OCEAN;
		end
	end

	-- Init the land/water fractal
	local regionContinentsFrac;
	if (iRiftGrain > 0) and (iRiftGrain < 4) then
		local riftsFrac = Fractal.Create(iRegionWidth, iRegionHeight, iRiftGrain, {}, iRegionFracXExp, iRegionFracYExp);
		regionContinentsFrac = Fractal.CreateRifts(iRegionWidth, iRegionHeight, iRegionGrain, iRegionPlotFlags, riftsFrac, iRegionFracXExp, iRegionFracYExp);
	else
		regionContinentsFrac = Fractal.Create(iRegionWidth, iRegionHeight, iRegionGrain, iRegionPlotFlags, iRegionFracXExp, iRegionFracYExp);	
	end
	
	-- Using the fractal matrices we just created, determine fractal-height values for sea level.
	local iWaterThreshold = regionContinentsFrac:GetHeight(iWaterPercent);

	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			local val = regionContinentsFrac:GetHeight(x,y);
			if val <= iWaterThreshold then
				--do nothing
			else
				plotTypes2[i] = g_PLOT_TYPE_LAND;
			end
		end
	end

	if bShift then -- Shift plots to obtain a more natural shape.
		ShiftPlotTypes(plotTypes);
	end

	-- Apply the region's plots to the global plot array.
	for x = 0, iRegionWidth - 1, 1 do
		local wholeworldX = x + iRegionWestX;
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1;
			if plotTypes2[i] ~= g_PLOT_TYPE_OCEAN then
				local wholeworldY = y + iRegionSouthY;
				local index = wholeworldY * g_iW + wholeworldX + 1
				plotTypes[index] = g_PLOT_TYPE_OCEAN;
			end
		end
	end

	-- This region is done.
	return plotTypes;
end

-------------------------------------------------------------------------------------------
function DetermineFlip(plotTypes)
	-- 705: 看看我们是否需要翻转地图，把大部分的土地放在地图的北部边缘，使它看起来更像地球，这将使地图感觉更自然

	local g_iW, g_iH = Map.GetGridSize();

	-- 首先循环通过地图行并在每一行中记录地块
	local land_totals = {};
	for y = 0, g_iH - 1 do
		local current_row = 0;
		for x = 0, g_iW - 1 do
			local i = y * g_iW + x + 1;
			if (plotTypes[i] ~= g_PLOT_TYPE_OCEAN) then
				current_row = current_row + 1;
			end
		end
		table.insert(land_totals, current_row);
	end
	
	-- Now evaluate row groups, each record applying to the center row of the group.
	local row_groups = {};
	-- Determine the group size in relation to map height.
	local group_radius = math.floor(g_iH / 15);
	-- Measure the groups.
	for row_index = 1, g_iH do
		local current_group_total = 0;
		for current_row = row_index - group_radius, row_index + group_radius do
			local current_index = current_row % g_iH;
			if current_index == 0 then -- Modulo of the last row will be zero; this repairs the issue.
				current_index = g_iH;
			end
			current_group_total = current_group_total + land_totals[current_index];
		end
		table.insert(row_groups, current_group_total);
	end
	
	-- Identify the group with the least amount of land in it.
	local best_value = g_iW * (2 * group_radius + 1); -- Set initial value to max possible.
	local best_group = 1; -- Set initial best group as current map edge.
	for row_index, group_land_plots in ipairs(row_groups) do
		if group_land_plots < best_value then
			best_value = group_land_plots;
			best_group = row_index;
		end
	end
	
	if best_group < math.floor(g_iH * 0.25) then
		return false;
	end
	
	return true;
end

-------------------------------------------------------------------------------
function GenerateFractalLayerWithoutHills (args, plotTypes)
	--[[ 这个函数打算与ApplyTectonics配对。如果所有的山和
	--山脉地块将被大地构造所覆盖，那么为什么要浪费呢
	--产生它们的计算？ ]]--
	args = args or {};
	local plotTypes2 = {};

	-- Handle args or assign defaults.
	local iWaterPercent = args.iWaterPercent or 55;
	local iRegionWidth = args.iRegionWidth; -- Mandatory Parameter, no default
	local iRegionHeight = args.iRegionHeight; -- Mandatory Parameter, no default
	local iRegionWestX = args.iRegionWestX; -- Mandatory Parameter, no default
	local iRegionSouthY = args.iRegionSouthY; -- Mandatory Parameter, no default
	local iRegionGrain = args.iRegionGrain or 1;
	local iRegionPlotFlags = args.iRegionPlotFlags or g_iFlags;
	local iRegionTerrainFlags = g_iFlags; -- Removed from args list.
	local iRegionFracXExp = args.iRegionFracXExp or 6;
	local iRegionFracYExp = args.iRegionFracYExp or 5;
	local iRiftGrain = args.iRiftGrain or -1;
	
	--print("Received Region Data");
	--print(iRegionWidth, iRegionHeight, iRegionWestX, iRegionSouthY, iRegionGrain);
	--print("- - -");
	
	--print("Filled regional table.");
	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			plotTypes2[i] =g_PLOT_TYPE_OCEAN;
		end
	end

	-- Init the land/water fractal
	local regionContinentsFrac;
	if(iRiftGrain > 0 and iRiftGrain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, iRegionFracXExp, iRegionFracYExp);
		regionContinentsFrac = Fractal.CreateRifts(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, riftsFrac, iRegionFracXExp, iRegionFracYExp);
	else
		regionContinentsFrac = Fractal.Create(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, iRegionFracXExp, iRegionFracYExp);	
	end
	--print("Initialized main fractal");
	local iWaterThreshold = regionContinentsFrac:GetHeight(iWaterPercent);

	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			local val = regionContinentsFrac:GetHeight(x,y);
			if val <= iWaterThreshold or Adjacent(i) == true then
				--do nothing
			else
				plotTypes2[i] = g_PLOT_TYPE_LAND;
			end
		end
	end

	-- print("Shifted Plots - Width: ", iRegionWidth, "Height: ", iRegionHeight);

	-- Apply the region's plots to the global plot array.
	for x = 0, iRegionWidth - 1, 1 do
		local wholeworldX = x + iRegionWestX;
		for y = 0, iRegionHeight - 1, 1 do
			local index = y * iRegionWidth + x + 1
			if plotTypes2[index] ~= g_PLOT_TYPE_OCEAN then
				local wholeworldY = y + iRegionSouthY;
				local i = wholeworldY * g_iW + wholeworldX + 1
				plotTypes[i] = plotTypes2[index];
			end
		end
	end
	--print("Generated Plot Types");

	return plotTypes;
end

-------------------------------------------------------------------------------------------
function Adjacent(index)
	aIslands = islands;
	index = index -1;

	if(aIslands == nil) then
		return false;
	end
	
	if(index < 0) then
		return false
	end

	local plot = Map.GetPlotByIndex(index);
	if(aIslands[index] ~= nil and aIslands[index] == g_PLOT_TYPE_LAND) then
		return true;
	end

	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
		if(adjacentPlot ~= nil) then
			local newIndex = adjacentPlot:GetIndex();
			if(aIslands  ~= nil and aIslands[newIndex] == g_PLOT_TYPE_LAND) then
				return true;
			end
		end
	end

	return false;
end

function TeamPVPGenerateTerrainTypes(plotTypes, iW, iH, iFlags, bNoCoastalMountains, temperature, bonus_cold_shift)
	print("TeamPVP Generating Terrain Types");
	local terrainTypes = {};

	if(temperature == nil) then
		temperature = 2;
	end

	local coldShift = bonus_cold_shift or 0;
	local temperature_shift = 0.1;
	local desert_shift = 1;
	local plains_shift = 8;
	-- =====================================================================
	local Land_boundary = 8		-- 大陆距离地图边缘的距离

	local iTundra_rate = 0.40
	local iTundra_width = 10
	local iTundra_Balanced = 0.4
	
	local t_Tundra_rate_base = (((g_iH / 2) - Land_boundary) * iTundra_rate + Land_boundary) * 2 / g_iH
	local t_Tundra_width = (Land_boundary + iTundra_width) * 2 / g_iH
	
	local iDesertPercent = 5;
	local iPlainsPercent = 50; 
	local fSnowLatitude  = 1 + coldShift;
	local fTundraLatitude = fSnowLatitude
	local fGrassLatitude = 0.1; 
	local fDesertBottomLatitude = 0.1;
	local fDesertTopLatitude = 0.35;

	if temperature > 2.5 then
		iDesertPercent = iDesertPercent - desert_shift;
		fTundraLatitude = fTundraLatitude - (temperature_shift * 1.5);
		iPlainsPercent = iPlainsPercent + plains_shift;
		fDesertTopLatitude = fDesertTopLatitude - temperature_shift;
		fGrassLatitude = fGrassLatitude - (temperature_shift * 0.5);
	elseif temperature < 1.5 then
		iDesertPercent = iDesertPercent + desert_shift;
		fSnowLatitude  = fSnowLatitude + (temperature_shift * 0.5);
		fTundraLatitude = fTundraLatitude + temperature_shift;
		fDesertTopLatitude = fDesertTopLatitude + temperature_shift;
		fGrassLatitude = fGrassLatitude - (temperature_shift * 0.5);
		iPlainsPercent = iPlainsPercent + plains_shift;
	else
	end
	print("TeamPVP fTundraLatitude:",fTundraLatitude);

    iDesertPercent = iDesertPercent * 0.6;
	local iDesertTopPercent		= 100;
	local iDesertBottomPercent	= math.max(0, math.floor(100-iDesertPercent));
	local iPlainsTopPercent		= 100;
	local iPlainsBottomPercent	= math.max(0, math.floor(100-iPlainsPercent));

	print("-"); print("DW- Desert Percentage:", iDesertPercent);
	print("--- Latitude Readout ---");
	print("- All Grass End Latitude:", fGrassLatitude);
	print("- Desert Start Latitude:", fDesertBottomLatitude);
	print("- Desert End Latitude:", fDesertTopLatitude);
	print("- Tundra Start Latitude:", fTundraLatitude);
	print("- Snow Start Latitude:", fSnowLatitude);
	print("- - - - - - - - - - - - - -");

	local fracXExp = -1;
	local fracYExp = -1;
	local iDesertTop;
	local iDesertBottom;																
	local iPlainsTop;
	local iPlainsBottom;

	local grain_amount = 3;
	if temperature < 1.5 then -- World Temperature is Hot.
		grain_amount = 2;
	end

	deserts = Fractal.Create(iW, iH, grain_amount, iFlags, fracXExp, fracYExp);
	
	grain_amount = 4;
	plains = Fractal.Create(iW, iH, grain_amount, iFlags, fracXExp, fracYExp);
	local variationFrac = Fractal.Create(iW, iH, grain_amount, iFlags, fracXExp, fracYExp);

	iDesertTop = deserts:GetHeight(iDesertTopPercent);
	iDesertBottom = deserts:GetHeight(iDesertBottomPercent);


	iPlainsTop = plains:GetHeight(iPlainsTopPercent);
	iPlainsBottom = plains:GetHeight(iPlainsBottomPercent);
	
	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;
			if (plotTypes[index] == g_PLOT_TYPE_OCEAN) then
				if (TeamPVPIsAdjacentToLand(plotTypes, iX, iY)) then
					terrainTypes[index] = g_TERRAIN_TYPE_COAST;
				else
					terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;
				end
			end
		end
	end
	
	if (bNoCoastalMountains == true) then
		plotTypes = RemoveCoastalMountains(plotTypes, terrainTypes);
	end

	local landCheck = false;
	local landiY=nil;
	for iY = iH - 1,0,-1  do
		local landCount = 0;
		for iX = 0,iW - 1 do
			local index = (iY * iW) + iX;
			if(plotTypes[index] ~= g_PLOT_TYPE_OCEAN)then
				landCount=landCount+1;
			end
			if(landCount>5)then
				landCheck = true;
				landiY = iY;
				break;
			end
		end
		if(landCheck==true)then
			break;
		end
	end

	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;
			local lat = GetLatitudeAtPlot(variationFrac, iX, iY);

			if (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
			    terrainTypes[index] = g_TERRAIN_TYPE_GRASS_MOUNTAIN;

			    -- 地图整体偏下，北极应有更多冻土
				-- 冻毛线 删了删了全删了
			    local teampfTundraLatitude=fTundraLatitude;

				if(lat >= fSnowLatitude) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA_MOUNTAIN;
				elseif(lat >= teampfTundraLatitude) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA_MOUNTAIN;
				elseif (lat < fGrassLatitude) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS_MOUNTAIN;
				else
					local desertVal = deserts:GetHeight(iX, iY);
					local plainsVal = plains:GetHeight(iX, iY);
					if ((desertVal >= iDesertBottom) and (desertVal <= iDesertTop) and (lat >= fDesertBottomLatitude) and (lat < fDesertTopLatitude)) then
						terrainTypes[index] = g_TERRAIN_TYPE_DESERT_MOUNTAIN;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS_MOUNTAIN;
					end
				end

			elseif (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
				terrainTypes[index] = g_TERRAIN_TYPE_GRASS;

				local teampfTundraLatitude=fTundraLatitude;
				if(lat >= fSnowLatitude) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA;
				elseif(lat >= teampfTundraLatitude) then
					terrainTypes[index] = g_TERRAIN_TYPE_TUNDRA;
				elseif (lat < fGrassLatitude) then
					terrainTypes[index] = g_TERRAIN_TYPE_GRASS;
				else
					local desertVal = deserts:GetHeight(iX, iY);
					local plainsVal = plains:GetHeight(iX, iY);
					if ((desertVal >= iDesertBottom) and (desertVal <= iDesertTop) and (lat >= fDesertBottomLatitude) and (lat < fDesertTopLatitude)) then
						terrainTypes[index] = g_TERRAIN_TYPE_DESERT;
					elseif ((plainsVal >= iPlainsBottom) and (plainsVal <= iPlainsTop)) then
						terrainTypes[index] = g_TERRAIN_TYPE_PLAINS;
					end
				end
			end
		end
	end

	print("添加草原、沙漠过渡区");
	for iI = 0, 2 do
		local nearDesertPlots = {};
		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				if (terrainTypes[index] == g_TERRAIN_TYPE_GRASS) then
					-- Chance for each eligible plot to become an expansion is 1 / iExpansionDiceroll.
					-- Default is two passes at 1/4 chance per eligible plot on each pass.
					if (IsAdjacentToDesert(terrainTypes, iX, iY) ) then
						table.insert(nearDesertPlots, index);
					end
				end
			end
		end
		for i, index in ipairs(nearDesertPlots) do
			terrainTypes[index] = g_TERRAIN_TYPE_PLAINS;
		end
	end
	--[[ Corrupted legacy log text retained only as a comment.
   
	print("添加大陆架");
	for iI = 0, 2 do
	]]
	print("Adding continental shelf")
	for iI = 0, 2 do
		local shallowWaterPlots = {};
		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				if (terrainTypes[index] == g_TERRAIN_TYPE_OCEAN) then
					if (IsAdjacentToShallowWater(terrainTypes, iX, iY) and TerrainBuilder.GetRandomNumber(5, "add shallows") == 0) then
						table.insert(shallowWaterPlots, index);
					end
				end
			end
		end
		for i, index in ipairs(shallowWaterPlots) do
			terrainTypes[index] = g_TERRAIN_TYPE_COAST;
		end
	end
	
	return terrainTypes; 
end


function TeamPVPAddTerrainFromContinents(plotTypes, terrainTypes, world_age, iW, iH, iContinentBoundaryPlots)
	-- 在大陆边界处增加火山
	local iMountainPercentByDistance = {42, 24, 6}; 
	local iHillPercentByDistance = {50, 40, 30}; 
	local aLonelyMountainIndices = {};
	local iVolcanoesPlaced = 0;

	-- 计算火山数量
	local iTotalLandPlots = 0;
	for iX = 0, iW - 1 do
		for iY = 0, iH - 1 do
			local index = (iY * iW) + iX;
			if (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
				iTotalLandPlots = iTotalLandPlots + 1;
			end
		end
	end

	-- 平均每(iDivisor * 150)个陆地单元格分配一个火山
	local iDivisor = 8;
	if (world_age < 8) then
		iDivisor = 8 - world_age;
	end
	local iDesiredVolcanoes = iTotalLandPlots / (iDivisor * 150);
	print ("预计火山数量: " .. iDesiredVolcanoes);

	-- 2/3rds of Earth's volcanoes are near continent boundaries
	print ("大陆边界单元格数量: " .. iContinentBoundaryPlots);
	local iDesiredNearBoundaries = iDesiredVolcanoes * 2 / 3;

	if (iDesiredNearBoundaries > 0) then
		local iBoundaryPlotsPerVolcano = iContinentBoundaryPlots / iDesiredNearBoundaries;

		-- 密度不能少于每50个单元格一个
		if (iBoundaryPlotsPerVolcano < 50) then
			iBoundaryPlotsPerVolcano = 50;
		end
		print ("Boundary Plots Per Volcano: " .. iBoundaryPlotsPerVolcano);

		for iX = 0, iW - 1 do
			for iY = 0, iH - 1 do
				local index = (iY * iW) + iX;
				if (plotTypes[index] ~= g_PLOT_TYPE_OCEAN) then
					local pPlot = Map.GetPlotByIndex(index);
					local iPlotsFromBoundary = -1;
					local bVolcanoHere = false;
					-- 705: 现在，块状火山正在沙漠上形成
					if (GetNumberAdjacentVolcanoes(iX, iY) == 0 and GetNumberAdjacentMountains() < 4) then
						if (terrainTypes[index] ~= g_TERRAIN_TYPE_DESERT and terrainTypes[index] ~= g_TERRAIN_TYPE_DESERT_HILLS and terrainTypes[index] ~= g_TERRAIN_TYPE_DESERT_MOUNTAINS) then
							if (Map.FindSecondContinent(pPlot, 1)) then
								if (TerrainBuilder.GetRandomNumber(iBoundaryPlotsPerVolcano *.7, "Volcano on boundary") == 1) then
									bVolcanoHere = true;
								end
								iPlotsFromBoundary = 1;
							elseif(Map.FindSecondContinent(pPlot, 2)) then
								if (TerrainBuilder.GetRandomNumber(iBoundaryPlotsPerVolcano, "Volcano 1 from boundary") == 1) then
									bVolcanoHere = true;
								end
								iPlotsFromBoundary = 2;
							elseif(Map.FindSecondContinent(pPlot, 3)) then
								if (TerrainBuilder.GetRandomNumber(iBoundaryPlotsPerVolcano * 1.5, "Volcano 2 from boundary") == 1) then
									bVolcanoHere = true;
								end
								iPlotsFromBoundary = 3;

							elseif (plotTypes[index] == g_PLOT_TYPE_MOUNTAIN) then
								if (GetNumberAdjacentMountains() == 0) then
									table.insert(aLonelyMountainIndices, index);
								end
							end
						end
					end

					if (bVolcanoHere) then
						TerrainBuilder.SetTerrainType(pPlot, ConvertToMountain(terrainTypes[index]));
						TerrainBuilder.SetFeatureType(pPlot, g_FEATURE_VOLCANO);
						print ("Volcano Placed at (x, y): " .. iX .. ", " .. iY);
						iVolcanoesPlaced = iVolcanoesPlaced + 1;
					end
				end
			end
		end
		print ("Continent Edge Volcanoes Placed: " .. iVolcanoesPlaced);
	end

	if ((iDesiredVolcanoes - iVolcanoesPlaced) > 0 and #aLonelyMountainIndices > 0) then
		local iChance = #aLonelyMountainIndices / iDesiredVolcanoes;
		aShuffledIndices =  GetShuffledCopyOfTable(aLonelyMountainIndices);
		for i, index in ipairs(aShuffledIndices) do
			local pPlot = Map.GetPlotByIndex(index);
			local iX = pPlot:GetX();
			local iY = pPlot:GetY();
			
			if (GetNumberAdjacentVolcanoes(iX, iY) == 0) then
				TerrainBuilder.SetFeatureType(pPlot, g_FEATURE_VOLCANO);
				print ("Lonely Volcano Placed at (x, y): " .. iX .. ", " .. iY);
				iVolcanoesPlaced = iVolcanoesPlaced + 1;
				if (iVolcanoesPlaced >= iDesiredVolcanoes) then
					break
				end
			end
		end
	end

	print ("Total Volcanoes Placed: " .. iVolcanoesPlaced);
end

function TeamPVPIsAdjacentToLand(plotTypes, iX, iY)
	local adjacentPlot;	
	local iW, iH = Map.GetGridSize();

	for direction = 0, 5, 1 do
		adjacentPlot = Map.GetAdjacentPlot(iX, iY, direction);
		if (adjacentPlot ~= nil) then
			if(IsAdjacentToLand(plotTypes, adjacentPlot:GetX(), adjacentPlot:GetY()))then
				return true;
		    end
	   		local i = adjacentPlot:GetY() * iW + adjacentPlot:GetX();
			if (plotTypes[i] ~= g_PLOT_TYPE_OCEAN) then
				return true;
		    end
		end
	end
	return false;
end

function AddIceIsland(args, plotTypes)

	local args = args or {};
	args.iWaterPercent = 75;
	args.iRegionWidth = math.ceil(g_iW);
	args.iRegionHeight = math.ceil(g_iH);
	args.iRegionWestX = math.floor(0);
	args.iRegionSouthY = math.floor(0);
	args.iRegionGrain = 5;
	args.iRegionHillsGrain = 4;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 7;
	args.iRegionFracYExp = 6;


	-- Handle args or assign defaults.
	local iWaterPercent = args.iWaterPercent or 55;
	local iRegionWidth = args.iRegionWidth; -- Mandatory Parameter, no default
	local iRegionHeight = args.iRegionHeight; -- Mandatory Parameter, no default
	local iRegionWestX = args.iRegionWestX; -- Mandatory Parameter, no default
	local iRegionSouthY = args.iRegionSouthY; -- Mandatory Parameter, no default
	local iRegionGrain = args.iRegionGrain or 1;
	local iRegionPlotFlags = args.iRegionPlotFlags or g_iFlags;
	local iRegionTerrainFlags = g_iFlags; -- Removed from args list.
	local iRegionFracXExp = args.iRegionFracXExp or 6;
	local iRegionFracYExp = args.iRegionFracYExp or 5;
	local iRiftGrain = args.iRiftGrain or -1;

	-- Init the land/water fractal
	local regionContinentsFrac;
	if(iRiftGrain > 0 and iRiftGrain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, iRegionFracXExp, iRegionFracYExp);
		regionContinentsFrac = Fractal.CreateRifts(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, riftsFrac, iRegionFracXExp, iRegionFracYExp);
	else
		regionContinentsFrac = Fractal.Create(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, iRegionFracXExp, iRegionFracYExp);	
	end
	--print("Initialized main fractal");
	local iWaterThreshold = regionContinentsFrac:GetHeight(iWaterPercent);

	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			
			local plot = Map.GetPlotByIndex(i - 1);
			local nPlot = plot:GetNearestLandPlot()
			local Distance = nPlot and Map.GetPlotDistance(plot:GetX(), plot:GetY(), nPlot:GetX(), nPlot:GetY()) or 0;
			
			local val = regionContinentsFrac:GetHeight(x,y);
			if val <= iWaterThreshold or Adjacent(i) == true then
				--do nothing
			elseif Distance >= 5 then
				TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
				TerrainBuilder.AddIce(plot:GetIndex(), 0); 
			end
		end
	end
	AreaBuilder.Recalculate();
end

function AddMountain(plotTypes)
	local args = args or {};
	args.iWaterPercent = 93;
	args.iRegionWidth = math.ceil(g_iW);
	args.iRegionHeight = math.ceil(g_iH);
	args.iRegionWestX = math.floor(0);
	args.iRegionSouthY = math.floor(0);
	args.iRegionGrain = 5;
	args.iRegionHillsGrain = 6;
	args.iRegionPlotFlags = g_iFlags;
	args.iRegionFracXExp = 7;
	args.iRegionFracYExp = 6;


	-- Handle args or assign defaults.
	local iWaterPercent = args.iWaterPercent or 55;
	local iRegionWidth = args.iRegionWidth; -- Mandatory Parameter, no default
	local iRegionHeight = args.iRegionHeight; -- Mandatory Parameter, no default
	local iRegionWestX = args.iRegionWestX; -- Mandatory Parameter, no default
	local iRegionSouthY = args.iRegionSouthY; -- Mandatory Parameter, no default
	local iRegionGrain = args.iRegionGrain or 1;
	local iRegionPlotFlags = args.iRegionPlotFlags or g_iFlags;
	local iRegionTerrainFlags = g_iFlags; -- Removed from args list.
	local iRegionFracXExp = args.iRegionFracXExp or 6;
	local iRegionFracYExp = args.iRegionFracYExp or 5;
	local iRiftGrain = args.iRiftGrain or -1;

	-- Init the land/water fractal
	local regionContinentsFrac;
	if(iRiftGrain > 0 and iRiftGrain < 4) then
		local riftsFrac = Fractal.Create(g_iW, g_iH, rift_grain, {}, iRegionFracXExp, iRegionFracYExp);
		regionContinentsFrac = Fractal.CreateRifts(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, riftsFrac, iRegionFracXExp, iRegionFracYExp);
	else
		regionContinentsFrac = Fractal.Create(g_iW, g_iH, iRegionGrain, iRegionPlotFlags, iRegionFracXExp, iRegionFracYExp);	
	end
	--print("Initialized main fractal");
	local iWaterThreshold = regionContinentsFrac:GetHeight(iWaterPercent);

	-- Loop through the region's plots
	for x = 0, iRegionWidth - 1, 1 do
		for y = 0, iRegionHeight - 1, 1 do
			local i = y * iRegionWidth + x + 1; -- Lua arrays start at 1.
			
			local plot = Map.GetPlotByIndex(i - 1);
			
			local val = regionContinentsFrac:GetHeight(x,y);
			if val >= iWaterThreshold and plotTypes[i] == g_PLOT_TYPE_LAND then
				plotTypes[i] = g_PLOT_TYPE_MOUNTAIN;
			end
		end
	end
	AreaBuilder.Recalculate();
end









