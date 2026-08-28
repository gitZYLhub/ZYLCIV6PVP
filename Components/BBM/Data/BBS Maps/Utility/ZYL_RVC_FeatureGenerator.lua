------------------------------------------------------------------------------
--	FILE:	 DW_FeatureGenerator.lua
--	AUTHOR:  EvilVictor (Seven05)
--	PURPOSE: Map Utility Script
------------------------------------------------------------------------------
--	Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
DW_FeatureGenerator = {};
------------------------------------------------------------------------------
function DW_FeatureGenerator.Create(args)
	args = args or {};
	local rainfall = (args.rainfall - 2) * 2 or 0;
	local iEquatorAdjustment = args.iEquatorAdjustment or 0;
	
	-- Sea Level and World Age map options affect only plot generation.
	-- World Age option affects plot generation and geothermal/volcanic features
	-- Temperature map options affect only terrain generation.
	-- Rainfall map options affect only feature generation.

	-- Set feature traits.
	local iJunglePercent = args.iJunglePercent or 20;
	local iForestPercent = args.iForestPercent or 18;
	local iMarshPercent = args.iMarshPercent or 3;
	local iOasisPercent = args.iOasisPercent or 1;
	local iReefPercent = args.iReefPercent or 8;

	iJunglePercent = iJunglePercent + (rainfall * 2);
	iForestPercent = iForestPercent + rainfall;
	iMarshPercent = iMarshPercent + rainfall / 2;
	iOasisPercent = iOasisPercent + rainfall / 4;

	local gridWidth, gridHeight = Map.GetGridSize();
	local iEquator = math.ceil(gridHeight / 2) + iEquatorAdjustment;
	-- create instance data
	local instance = {
	
		-- methods
		__initFractals			= DW_FeatureGenerator.__initFractals,
		__initFeatureTypes		= DW_FeatureGenerator.__initFeatureTypes,
		AddFeatures				= DW_FeatureGenerator.AddFeatures,
		AddFeaturesFromContinents = DW_FeatureGenerator.AddFeaturesFromContinents,
		GetLatitudeAtPlot		= DW_FeatureGenerator.GetLatitudeAtPlot,
		AddFeaturesAtPlot		= DW_FeatureGenerator.AddFeaturesAtPlot,
		AddOasisAtPlot			= DW_FeatureGenerator.AddOasisAtPlot,
		AddIceToMap				= DW_FeatureGenerator.AddIceToMap,
		AddMarshAtPlot			= DW_FeatureGenerator.AddMarshAtPlot,
		AddJunglesAtPlot		= DW_FeatureGenerator.AddJunglesAtPlot,
		AddForestsAtPlot		= DW_FeatureGenerator.AddForestsAtPlot,
		AddReefAtPlot			= DW_FeatureGenerator.AddReefAtPlot,
		
		-- members
		iGridW = gridWidth,
		iGridH = gridHeight,
		
		iJungleMaxPercent = iJunglePercent,
		iForestMaxPercent = iForestPercent,
		iMarshMaxPercent = iMarshPercent,
		iOasisMaxPercent = iOasisPercent,
		iReefMaxPercent = iReefPercent,

		iForestCount = 0,
		iJungleCount = 0,
		iMarshCount = 0,
		iOasisCount = 0,
		iReefCount = 0,
		iFissureCount = 0,
		iNumLandPlots = 0,
		iNumJunglablePlots = 0,
		iNumReefablePlots = 0,
		iceLat = 0.78;

		RichNum = args.RichNum or 6,

		-- Rainforest on Earth mostly in Tropics, so keep in narrow band around Equator
		iJungleBottom = iEquator - (35 * gridHeight / 180);
		iJungleTop = iEquator + (35 * gridHeight / 180);
		iNumEquator = iEquator,
	};

	return instance;
end
------------------------------------------------------------------------------
function DW_FeatureGenerator:AddFeatures(allow_mountains_on_coast, bRiversStartInland, args)
	args = args or {}
	local iMinFloodplainSize = 3;
	local iMaxFloodplainSize = 3;
	TerrainBuilder.GenerateFloodplains(bRiversStartInland, iMinFloodplainSize, iMaxFloodplainSize);

	if allow_mountains_on_coast == false then -- remove any mountains from coastal plots
		for x = 0, self.iGridW - 1 do
			for y = 0, self.iGridH - 1 do
				local plot = Map.GetPlot(x, y)
				if plot:GetPlotType() == g_PLOT_TYPE_MOUNTAIN then
					if plot:IsCoastalLand() then
						plot:SetPlotType(g_PLOT_TYPE_HILLS, false, true); -- 这些标志用于区域的恢复和图形的重建。不要一次又一次地回收，而是在循环结束时回收。
					end
				end
			end
		end
	end

	-- This map has no polar climate, so do not generate latitude-based ice caps.
	
	-- 主循环，根据该类型的数量和百分比为所有单元格添加地貌，但不包括那些不能与其他地貌相邻的地貌
	for y = 0, self.iGridH - 1, 1 do
		for x = 0, self.iGridW - 1, 1 do
			local i = y * self.iGridW + x;
			local plot = Map.GetPlotByIndex(i);
			if(plot ~= nil) then
				local featureType = plot:GetFeatureType();
				local IsIsHill = plot:IsHills()

				-- 不可通行或已有地貌
				if(plot:IsImpassable() or featureType ~= g_FEATURE_NONE) then

				-- 水源：检查礁石
				elseif(plot:IsWater() == true) then					
					if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_REEF) == true ) then
						self:AddReefAtPlot(plot, x, y);
					end
				else
					self.iNumLandPlots = self.iNumLandPlots + 1;
					
					-- 泛滥
					if((TerrainBuilder.CanHaveFeature(plot, g_FEATURE_FLOODPLAINS) == true) and featureType == g_FEATURE_NONE) then
						-- All desert plots along river are set to flood plains.
						TerrainBuilder.SetFeatureType(plot, g_FEATURE_FLOODPLAINS)
					end

					local bMarsh = false;
					local bJungle = false;
					if(featureType == g_FEATURE_NONE) then
						-- 检查沼泽
						bMarsh = self:AddMarshAtPlot(plot, x, y);
						-- 检查雨林
						if(featureType == g_FEATURE_NONE and  bMarsh == false) then
							bJungle = self:AddJunglesAtPlot(plot, x, y);
						end
						-- 检查森林
						if IsIsHill then
							if(featureType == g_FEATURE_NONE and bMarsh== false and bJungle == false) then
								self:AddForestsAtPlot(plot, x, y);
							end
						end
					end
				end
			end
		end
	end
	
	print("Number of Tiles:      ", self.iNumLandPlots);
	print("Number of Forests:    ", self.iForestCount);
	print("Percent Forests:      ", (100 * self.iForestCount) / self.iNumLandPlots);
	print("Number of Jungles:    ", self.iJungleCount);
	print("Percent Jungles:      ", (100 * self.iJungleCount) / self.iNumLandPlots);
	print("Percent of Junglable: ", (100 * self.iJungleCount) / self.iNumJunglablePlots);
	print("Number of Marshes:    ", self.iMarshCount);
end
------------------------------------------------------------------------------
function DW_FeatureGenerator:AddFeaturesFromContinents(arg)

	local aPossibleFissureIndices = {};

	-- 绿洲尽管没有靠近大陆边界，但仍在这个循环中。
	-- 由于无法与其他功能相邻，因此需要进入二次循环
	for y = 0, self.iGridH - 1, 1 do
		for x = 0, self.iGridW - 1, 1 do
			local i = y * self.iGridW + x;
			local plot = Map.GetPlotByIndex(i);
			if(plot ~= nil) then
				local featureType = plot:GetFeatureType();

				if(plot:IsImpassable() or featureType ~= g_FEATURE_NONE) then
					--No Feature
				else
					if (TerrainBuilder.CanHaveFeature(plot, g_FEATURE_OASIS) == true and math.ceil(self.iOasisCount * 100 / self.iNumLandPlots) <= self.iOasisMaxPercent ) then
						if(TerrainBuilder.GetRandomNumber(4, "Oasis Random") == 1) then
							TerrainBuilder.SetFeatureType(plot, g_FEATURE_OASIS);
							self.iOasisCount = self.iOasisCount + 1;
						end
					end
					if (TerrainBuilder.CanHaveFeature(plot, g_FEATURE_GEOTHERMAL_FISSURE) == true) then
						if (Map.FindSecondContinent(plot, 3)) then
							table.insert(aPossibleFissureIndices, i);
						end
					end
				end
			end
		end
	end

	-- 在大陆边界放置地热
	arg = arg or {}
	local FissuresMultyDesired = arg.FissuresMultyDesired or 1
	local iDesiredFissures = self.iNumLandPlots / 100 * FissuresMultyDesired;
	if (iDesiredFissures > 0 and #aPossibleFissureIndices > 0) then
		aShuffledIndices =  GetShuffledCopyOfTable(aPossibleFissureIndices);
		for i, index in ipairs(aShuffledIndices) do
			local pPlot = Map.GetPlotByIndex(index);
			if not pPlot:IsHills() then
				TerrainBuilder.SetTerrainType(pPlot, pPlot:GetTerrainType() + 1);
			end
			TerrainBuilder.SetFeatureType(pPlot, g_FEATURE_GEOTHERMAL_FISSURE);
			self.iFissureCount = self.iFissureCount + 1;
			print ("在下述坐标放置了一个地热！(x, y): " .. pPlot:GetX() .. ", " .. pPlot:GetY());
			if (self.iFissureCount >= iDesiredFissures) then
				break
			end
		end
	end

	-- 还有裂缝要埋吗？  将它们添加到任何地方
	if (iDesiredFissures > self.iFissureCount) then
		local aFullMapFissureIndices = {};
		for y = 0, self.iGridH - 1, 1 do
			for x = 0, self.iGridW - 1, 1 do
				local i = y * self.iGridW + x;
				local plot = Map.GetPlotByIndex(i);
				if(plot ~= nil) then
					local featureType = plot:GetFeatureType();

					if(plot:IsImpassable() or featureType ~= g_FEATURE_NONE) then
						--No Feature
					else
						if (TerrainBuilder.CanHaveFeature(plot, g_FEATURE_GEOTHERMAL_FISSURE) == true) then
							if (not Map.FindSecondContinent(plot, 3)) then
								table.insert(aFullMapFissureIndices, i);
							end
						end
					end
				end
			end
		end
		if (#aFullMapFissureIndices > 0) then
			aShuffledIndices =  GetShuffledCopyOfTable(aFullMapFissureIndices);
			for i, index in ipairs(aShuffledIndices) do
				local pPlot = Map.GetPlotByIndex(index);
				if not pPlot:IsHills() then
					TerrainBuilder.SetTerrainType(pPlot, pPlot:GetTerrainType() + 1);
				end
				TerrainBuilder.SetFeatureType(pPlot, g_FEATURE_GEOTHERMAL_FISSURE);
				self.iFissureCount = self.iFissureCount + 1;
				print ("Full-Map Fissure Placed at (x, y): " .. pPlot:GetX() .. ", " .. pPlot:GetY());
				if (self.iFissureCount >= iDesiredFissures) then
					break
				end
			end
		end
	end

	print("绿洲数量: ", self.iOasisCount);
	print("地热数量: ", self.iFissureCount)
end
------------------------------------------------------------------------------
function DW_FeatureGenerator:AddIceToMap()

	local iTargetIceTiles = (self.iGridH * self.iGridW * GlobalParameters.ICE_TILES_PERCENT) / 100;

	local aPhases = {};
	local iPhases = 0;
	for row in GameInfo.RandomEvents() do
		if (row.EffectOperatorType == "SEA_LEVEL") then
			local kPhaseDetails = {};
			kPhaseDetails.RandomEventEnum = row.Index;
			kPhaseDetails.IceLoss = row.IceLoss;
			table.insert(aPhases, kPhaseDetails);
			iPhases = iPhases + 1;
		end
	end
	
	if (iPhases <= 0) then 
		return;
	end
	
	-- 705: I don't like the way they changed ice placement.
	-- First, we need permanent ice that isn't just along the map edges, but all ice directly on
	-- the map edge should be permanent even if it is adjacent to land.
	-- Then, the phases for melting ice need to be placed a little less uniform so we get some
	-- interesting places in the ice, especially where it's adjacent to land.

	------------------------------
	-- PHASE ONE: PERMANENT ICE --
	------------------------------
	local iIceLossThisLevel = aPhases[iPhases].IceLoss;
	local iPermanentIcePercent = 100 - iIceLossThisLevel;
	local iPermanentIceTiles = math.floor(self.iGridW * 2.2); --(iTargetIceTiles * iPermanentIcePercent) / 100;

	print ("Permanent Ice Tiles: " .. tostring(iPermanentIceTiles));
	
	-- 705: We don't need to count tiles, just brute force the map edges first and reduce the
	-- number of permanent ice needed as we go
	-- 边缘放置冰块
	for x = 0, self.iGridW - 1, 1 do
		y = 0;
		local i = y * self.iGridW + x;
		local plot = Map.GetPlotByIndex(i);
		if (plot ~= nil) then
			if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true) then
				TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
				TerrainBuilder.AddIce(plot:GetIndex(), -1);
				iPermanentIceTiles = iPermanentIceTiles -1;
				iTargetIceTiles = iTargetIceTiles - 1;
			end
		end
	end
	for x = 0, self.iGridW - 1, 1 do
		local y = self.iGridH - 1;
		local i = y * self.iGridW + x;
		local plot = Map.GetPlotByIndex(i);
		if (plot ~= nil) then
			if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true) then
				TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
				TerrainBuilder.AddIce(plot:GetIndex(), -1);
				iPermanentIceTiles = iPermanentIceTiles -1;
				iTargetIceTiles = iTargetIceTiles - 1;
			end
		end
	end
	
	local i__iFlags = TerrainBuilder.GetFractalFlags();
	local variationFrac11 = Fractal.Create(self.iGridW, self.iGridH, 3, i__iFlags, -1, -1);
	local variationFrac22 = Fractal.Create(self.iGridW, self.iGridH, 3, i__iFlags, -1, -1);
	local variationFrac33 = Fractal.Create(self.iGridW, self.iGridH, 3, i__iFlags, -1, -1);
	
	local Ice_boundary = 1
	local Ice_latitude = (1 - (Ice_boundary / (self.iGridW * 0.5))) ^ 2 / 2;
	local Ice_latitude2 = 0.66
	
	for y = 1, self.iGridH - 2, 1 do -- Skip edges, they're already done
		for x = 0, self.iGridW - 1, 1 do
			local terrainType = plot:GetTerrainType();
			local i = y * self.iGridW + x;
			local plot = Map.GetPlotByIndex(i);
			local nPlot = plot:GetNearestLandPlot()
			local Distance = nPlot and Map.GetPlotDistance(plot:GetX(), plot:GetY(), nPlot:GetX(), nPlot:GetY()) or 0;
			if Distance >= 2 then
				local lat = (GetLatitudeAtPlot(variationFrac11, x, y) ^ 2 + GetLatitudeAtPlot(variationFrac22, y, x) ^ 2) / 2;
				local lat2 = GetLatitudeAtPlot(variationFrac33, x, y);
				if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true and IsAdjacentToRiver(x, y) == false) then
					if lat >= Ice_latitude and lat2 > Ice_latitude2 then
						TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
						TerrainBuilder.AddIce(plot:GetIndex(), 0);				
					end
				end
			end
		end
	end
--	AreaBuilder.Recalculate();

--	if (iPermanentIceTiles > 0) then		
--		for y = 1, self.iGridH - 2, 1 do -- Skip edges, they're already done
--			for x = 0, self.iGridW - 1, 1 do
--				local terrainType = plot:GetTerrainType();
--				local rand = TerrainBuilder.GetRandomNumber(100, "Add Ice Lua")/100.0;
--				local i = y * self.iGridW + x;
--				local plot = Map.GetPlotByIndex(i);
--				local lat = math.abs((self.iGridH/2) - y)/(self.iGridH/2)

--				if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true and IsAdjacentToRiver(x, y) == false) then
--					if(terrainType == g_TERRAIN_TYPE_COAST) then		
--						if(rand < 4 * (lat - 0.9)) then -- 0.875
--							TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
--							TerrainBuilder.AddIce(plot:GetIndex(), -1);
--							iTargetIceTiles = iTargetIceTiles - 1;
--						elseif(rand < 1 * (lat - 0.75)) then -- 4 *
--							TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
--							TerrainBuilder.AddIce(plot:GetIndex(), -1);
--							iTargetIceTiles = iTargetIceTiles - 1;
--						end
--					else
--						if(rand < 6 * (lat - 0.9)) then -- 0.875
--							TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
--							TerrainBuilder.AddIce(plot:GetIndex(), -1); 
--							iTargetIceTiles = iTargetIceTiles - 1;
--						elseif(rand < 2 * (lat - 0.75)) then -- 4 *
--							TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
--							TerrainBuilder.AddIce(plot:GetIndex(), -1);
--							iTargetIceTiles = iTargetIceTiles - 1;
--						end
--					end
--				end
--			end
--		end
--	end

	---------------------------------------
	-- PHASE TWO: ICE THAT CAN DISAPPEAR --
	---------------------------------------
	
	-- 705: Change static 10x adjactent ice count to use the current phase, this really helps
	-- change the ice from just a blob at the poles to a more interesting layout.
--	if (iPhases > 1) then
--		for iPhaseIndex = iPhases, 1, -1 do
--			kPhaseDetails = aPhases[iPhaseIndex];
--			local iIcePercentToAdd = 0;
--			if (iPhaseIndex == 1) then 
--				iIcePercentToAdd = kPhaseDetails.IceLoss;			
--			else
--				iIcePercentToAdd = kPhaseDetails.IceLoss - aPhases[iPhaseIndex - 1].IceLoss;
--			end
--			local iIceTilesToAdd = math.floor((iTargetIceTiles * iIcePercentToAdd) / 100);

--			print ("iPhaseIndex: " .. tostring(iPhaseIndex) .. ", iIceTilesToAdd: " .. tostring(iIceTilesToAdd) .. ", RandomEventEnum: " .. tostring(kPhaseDetails.RandomEventEnum));

--			 Find all plots on map adjacent to already-placed ice
--			local aTargetPlots = {};
--			for y = 0, self.iGridH - 1, 1 do
--				for x = 0, self.iGridW - 1, 1 do
--					local i = y * self.iGridW + x;
--					local plot = Map.GetPlotByIndex(i);
--					if (plot ~= nil) then
--						local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_ICE);
--						if (TerrainBuilder.CanHaveFeature(plot, g_FEATURE_ICE) == true and iAdjacent > 0) then
--							local kPlotDetails = {};
--							kPlotDetails.PlotIndex = i;
--							kPlotDetails.AdjacentIce = iAdjacent;
--							kPlotDetails.AdjacentToLand = IsAdjacentToLandPlot(x, y);
--							table.insert(aTargetPlots, kPlotDetails);
--						end
--					end
--				end
--			end

--			 Roll die to see which of these get ice
--			if (#aTargetPlots > 0) then
--				local iPercentNeeded = 100 * iIceTilesToAdd / #aTargetPlots;
--				for i, targetPlot in ipairs(aTargetPlots) do
--					local iFinalPercentNeeded = iPercentNeeded + iPhaseIndex * targetPlot.AdjacentIce;
--					if (targetPlot.AdjacentToLand == true) then
--						iFinalPercentNeeded = iFinalPercentNeeded / (iPhases - iPhaseIndex + 1);
--					end
--					if (TerrainBuilder.GetRandomNumber(100, "Permanent Ice") <= iFinalPercentNeeded) then
--					    local plot = Map.GetPlotByIndex(targetPlot.PlotIndex);
--						TerrainBuilder.SetFeatureType(plot, g_FEATURE_ICE);
--						TerrainBuilder.AddIce(plot:GetIndex(), kPhaseDetails.RandomEventEnum); 
--					end
--				end
--			end
--		end
--	end
end
------------------------------------------------------------------------------
function DW_FeatureGenerator:AddMarshAtPlot(plot, iX, iY)
	--Marsh Check. First see if it can place the feature.
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_MARSH)) then
		if(math.ceil(self.iMarshCount * 100 / self.iNumLandPlots) <= self.iMarshMaxPercent) then
			--Weight based on adjacent plots if it has more than 3 start subtracting
			local iScore = 0;
			
			-- 705: Modified base score from 300 and added check for rivers and coast.
			
			if plot:IsCoastalLand() then
				iScore = iScore + 100;
			end
			if IsAdjacentToRiver(iX, iY) then
				iScore = iScore + 100;
			end

			local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_MARSH);
				

			if(iAdjacent == 0 ) then
				iScore = iScore;
			elseif(iAdjacent == 1) then
				iScore = iScore - 200;
			elseif (iAdjacent == 2 or iAdjacent == 3) then
				iScore = iScore - 200;
			elseif (iAdjacent == 4) then
				iScore = iScore - 200;
			else
				iScore = iScore - 200;
			end
			
			-- 705: Modified base score from 300 and added check for jungles and forest.
			
			iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_JUNGLE);

			if(iAdjacent == 1) then
				iScore = iScore + 50;
			elseif (iAdjacent == 2 or iAdjacent == 3) then
				iScore = iScore + 100;
			end
			
			iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_FOREST);

			if(iAdjacent == 1) then
				iScore = iScore + 25;
			elseif (iAdjacent == 2 or iAdjacent == 3) then
				iScore = iScore + 50;
			end
				
			if(TerrainBuilder.GetRandomNumber(400, "Resource Placement Score Adjust") <= iScore) then
				TerrainBuilder.SetFeatureType(plot, g_FEATURE_MARSH);
				self.iMarshCount = self.iMarshCount + 1;

				return true;
			end
		end
	end

	return false;
end
------------------------------------------------------------------------------
function DW_FeatureGenerator:AddJunglesAtPlot(plot, iX, iY)
	--Jungle Check. First see if it can place the feature.
	
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_JUNGLE)) then
		if(iY >= self.iJungleBottom  and iY <= self.iJungleTop) then 
			self.iNumJunglablePlots = self.iNumJunglablePlots + 1;
			if(math.ceil(self.iJungleCount * 100 / self.iNumJunglablePlots) <= self.iJungleMaxPercent) then
				-- 705: Heavily modified to scale by distance from top/bottom limits and clump together
				-- by using the existing terrain and water proximity.  This will break up the heavy band
				-- of jungles at the equator that the original code created.
				local iCenter = math.ceil((self.iJungleBottom + self.iJungleTop) / 2);
				local iScore = 200;
				iScore = iScore - (math.abs(iY - iCenter) * 10);

				if plot:IsCoastalLand() then
					iScore = iScore + 100;
				end
				if(IsAdjacentToRiver(iX, iY) == true) then
					iScore = iScore + 200;
				end
				if(terrainType == g_TERRAIN_TYPE_PLAINS) then
					iScore = iScore + 100;
				end

				local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_JUNGLE);

				if(iAdjacent == 0 ) then
					iScore = iScore;
				elseif(iAdjacent == 1) then
					iScore = iScore + 50;
				elseif (iAdjacent == 2 or iAdjacent == 3) then
					iScore = iScore + 150;
				elseif (iAdjacent == 4) then
					iScore = iScore - 50;
				else
					iScore = iScore - 150;
				end
				
				if(terrainType == g_TERRAIN_TYPE_PLAINS_HILLS or terrainType == g_TERRAIN_TYPE_GRASS_HILLS) then
					iScore = iScore - 50;
				end

				if(TerrainBuilder.GetRandomNumber(400, "Resource Placement Score Adjust") <= iScore) then
					TerrainBuilder.SetFeatureType(plot, g_FEATURE_JUNGLE);
					local terrainType = plot:GetTerrainType();

					if(terrainType == g_TERRAIN_TYPE_PLAINS_HILLS or terrainType == g_TERRAIN_TYPE_GRASS_HILLS) then
						TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS_HILLS);
					else
						if(TerrainBuilder.GetRandomNumber(18, "Hills Adjust") <= self.RichNum)then
							TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS_HILLS);
						else
							TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_PLAINS);
						end
					end
					self.iJungleCount = self.iJungleCount + 1;
					return true;
				end
			end
		end
	end

	return false
end
------------------------------------------------------------------------------
function DW_FeatureGenerator:AddForestsAtPlot(plot, iX, iY)
	--Forest Check. First see if it can place the feature.
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_FOREST)) then
		if(math.ceil(self.iForestCount * 100 / self.iNumLandPlots) <= self.iForestMaxPercent) then
			--Weight based on adjacent plots if it has more than 3 start subtracting
			local iScore = 200;
			
			-- 705: Added boost for rivers and grassland.

			if IsAdjacentToRiver(iX, iY) then
				iScore = iScore + 100;
			end
			if(terrainType == g_TERRAIN_TYPE_GRASS) then
				iScore = iScore + 100;
			end

			local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_FOREST);

			if(iAdjacent == 0 ) then
				iScore = iScore;
			elseif(iAdjacent == 1) then
				iScore = iScore + 50;
			elseif (iAdjacent == 2 or iAdjacent == 3) then
				iScore = iScore + 150;
			elseif (iAdjacent == 4) then
				iScore = iScore - 50;
			else
				iScore = iScore - 200;
			end
				
			if(TerrainBuilder.GetRandomNumber(300, "Resource Placement Score Adjust") <= iScore) then
				TerrainBuilder.SetFeatureType(plot, g_FEATURE_FOREST);
				self.iForestCount = self.iForestCount + 1;
				if not plot:IsHills() then
					TerrainBuilder.SetTerrainType(plot, plot:GetTerrainType() + 1)
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function DW_FeatureGenerator:AddReefAtPlot(plot, iX, iY)
	--礁石检查
	local lat = math.abs((self.iGridH/2) - iY)/(self.iGridH/2)
	if(TerrainBuilder.CanHaveFeature(plot, g_FEATURE_REEF) and lat < self.iceLat) then
		self.iNumReefablePlots = self.iNumReefablePlots + 1;
		if(math.ceil(self.iReefCount * 100 / self.iNumReefablePlots) <= self.iReefMaxPercent) then
				--Weight based on adjacent plots
				local iScore  = 3 * math.abs(iY - self.iNumEquator);
				local iAdjacent = TerrainBuilder.GetAdjacentFeatureCount(plot, g_FEATURE_REEF);
				if(iAdjacent == 0 ) then
					iScore = iScore + 100;
				elseif(iAdjacent == 1) then
					iScore = iScore + 125;
				elseif (iAdjacent == 2) then
					iScore = iScore  + 150;
				elseif (iAdjacent == 3 or iAdjacent == 4) then
					iScore = iScore + 175;
				else
					iScore = iScore + 10000;
				end
				if(TerrainBuilder.GetRandomNumber(200, "Resource Placement Score Adjust") >= iScore) then
					TerrainBuilder.SetFeatureType(plot, g_FEATURE_REEF);
					self.iReefCount = self.iReefCount + 1;
				end
		end
	end
end
