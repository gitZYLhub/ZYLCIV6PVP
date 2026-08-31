------------------------------------------------------------------------------
--	FILE:	 DW_RiversLakes.lua
--	AUTHOR:  EvilVictor (Seven05)
--	PURPOSE: Map Utility Script
------------------------------------------------------------------------------
--	Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------


--Used to determine the next direction when turning
if(FlowDirectionTypes ~= nil) then
	TurnRightFlowDirections = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH]
			= FlowDirectionTypes.FLOWDIRECTION_NORTHEAST,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST]
			= FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST]
			= FlowDirectionTypes.FLOWDIRECTION_SOUTH,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTH]
			= FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST]
			= FlowDirectionTypes.FLOWDIRECTION_NORTHWEST,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST]
			= FlowDirectionTypes.FLOWDIRECTION_NORTH,
	};

	TurnLeftFlowDirections = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH]
			= FlowDirectionTypes.FLOWDIRECTION_NORTHWEST,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST]
			= FlowDirectionTypes.FLOWDIRECTION_NORTH,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST]
			= FlowDirectionTypes.FLOWDIRECTION_NORTHEAST,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTH]
			= FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST]
			= FlowDirectionTypes.FLOWDIRECTION_SOUTH,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST]
			= FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST,
	};
end

function GetOppositeFlowDirection(dir)
	local numTypes = FlowDirectionTypes.NUM_FLOWDIRECTION_TYPES;
	return ((dir + 3) % numTypes);
end

function GetRiverValueAtPlot(plot)
	if(plot:IsNWOfCliff() or plot:IsWOfCliff() or plot:IsNEOfCliff()) then
		return -1;
	elseif(plot:IsNaturalWonder() or AdjacentToNaturalWonder(plot)) then
		return -1;
	end


	local sum = GetPlotElevation(plot) * 20;

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do

		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);

		if (adjacentPlot ~= nil) then
			sum = sum + GetPlotElevation(adjacentPlot);

			if(g_TERRAIN_TYPE_DESERT == adjacentPlot:GetTerrainType()) then
				sum = sum + 4;
			end
		else
			sum = sum + 40;
		end

	end

	sum = sum + TerrainBuilder.GetRandomNumber(10, "River Rand");

	return sum;
end

function GetPlotElevation(plot)
	if (plot:IsMountain()) then
		return 4;
	elseif (plot:IsHills()) then
		return 3;
	elseif (not plot:IsWater()) then
		return 2;
	else
		return 1;
	end
end

nextRiverID = 0;
_rivers = {};
RoutePlots = {}				-- 修路
LastRoutePlot = nil			-- 上一次修路的单元格

function DoRiver(startPlot, thisFlowDirection, originalFlowDirection, riverID)

	if nextRiverID == riverID then
		LastRoutePlot = nil
	end

	if CanRoute(startPlot) then
		if not LastRoutePlot then
			RoutePlots[startPlot] = true
			LastRoutePlot = startPlot
		else
			if #GetAdjacentRoute(startPlot) == 0 then
				RoutePlots[startPlot] = true
				local AdjacentPlots_1 = Map.GetAdjacentPlots(startPlot:GetX(), startPlot:GetY())
				for _, kPlot in ipairs(AdjacentPlots_1) do
					if CanRoute(kPlot) and kPlot:IsRiver() then
						local Distance = Map.GetPlotDistance(kPlot:GetX(), kPlot:GetY(), LastRoutePlot:GetX(), LastRoutePlot:GetY())
						if Distance == 1 then
							RoutePlots[kPlot] = true
							break
						end
					end
				end
				LastRoutePlot = startPlot
			end
		end
	end

	thisFlowDirection = thisFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;
	originalFlowDirection = originalFlowDirection or FlowDirectionTypes.NO_FLOWDIRECTION;

	-- pStartPlot = the plot at whose SE corner the river is starting
	if (riverID == nil) then
		riverID = nextRiverID;
		nextRiverID = nextRiverID + 1;
	end

	local otherRiverID = _rivers[startPlot]
	if (otherRiverID ~= nil and otherRiverID ~= riverID and originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
		return; -- Another river already exists here; can't branch off of an existing river!
	end

	local riverPlot;

	local bestFlowDirection = FlowDirectionTypes.NO_FLOWDIRECTION;
	if (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTH) then

		riverPlot = startPlot;
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetWOfRiver(riverPlot, true, thisFlowDirection, riverID);
--		print ("NORTH: " .. tostring(riverPlot:GetX()) .. ", " .. tostring(riverPlot:GetY()));
		riverPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_NORTHEAST);

		if (riverPlot == nil or riverPlot:IsWater() or riverPlot:IsNEOfRiver() or riverPlot:IsNWOfRiver()) then
			if riverID == _rivers[riverPlot] then
				TerrainBuilder.SetTerrainType(riverPlot, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(riverPlot, -1);
				ResourceBuilder.SetResourceType(riverPlot, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHEAST) then
		riverPlot = startPlot;
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNWOfRiver(riverPlot, true, thisFlowDirection, riverID);
--		print ("NE: " .. tostring(riverPlot:GetX()) .. ", " .. tostring(riverPlot:GetY()));
		-- riverPlot does not change

		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (adjacentPlot == nil or adjacentPlot:IsWater() or riverPlot:IsWOfRiver() or adjacentPlot:IsNEOfRiver()) then
			if riverID == _rivers[adjacentPlot] then
				TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(adjacentPlot, -1);
				ResourceBuilder.SetResourceType(adjacentPlot, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST) then

		riverPlot = Map.GetAdjacentPlot(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (riverPlot == nil) then
			return;
		end
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNEOfRiver(riverPlot, true, thisFlowDirection, riverID);
--		print ("SE: " .. tostring(riverPlot:GetX()) .. ", " .. tostring(riverPlot:GetY()));
		-- riverPlot does not change

		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if (adjacentPlot == nil or adjacentPlot:IsWater() or riverPlot:IsNWOfRiver()) then
			if riverID == _rivers[adjacentPlot] then
				TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(adjacentPlot, -1);
				ResourceBuilder.SetResourceType(adjacentPlot, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end
		local adjacentPlot2 = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (adjacentPlot2 == nil or adjacentPlot2:IsWOfRiver()) then
			if riverID == _rivers[adjacentPlot2] then
				TerrainBuilder.SetTerrainType(adjacentPlot2, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(adjacentPlot2, -1);
				ResourceBuilder.SetResourceType(adjacentPlot2, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTH) then

		riverPlot = Map.GetAdjacentPlot(startPlot:GetX(), startPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (riverPlot == nil) then
			return;
		end
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetWOfRiver(riverPlot, true, thisFlowDirection, riverID);
--		print ("SOUTH: " .. tostring(riverPlot:GetX()) .. ", " .. tostring(riverPlot:GetY()));
		-- riverPlot does not change

		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHEAST);
		if (adjacentPlot == nil or adjacentPlot:IsWater() or riverPlot:IsNWOfRiver()) then
			if riverID == _rivers[adjacentPlot] then
				TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(adjacentPlot, -1);
				ResourceBuilder.SetResourceType(adjacentPlot, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end
		local adjacentPlot2 = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_EAST);
		if (adjacentPlot2 == nil or adjacentPlot2:IsNEOfRiver()) then
			if riverID == _rivers[adjacentPlot2] then
				TerrainBuilder.SetTerrainType(adjacentPlot2, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(adjacentPlot2, -1);
				ResourceBuilder.SetResourceType(adjacentPlot2, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST) then

		riverPlot = startPlot;
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNWOfRiver(riverPlot, true, thisFlowDirection, riverID);
--		print ("SW: " .. tostring(riverPlot:GetX()) .. ", " .. tostring(riverPlot:GetY()));
		-- riverPlot does not change

		local adjacentPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_SOUTHWEST);
		if (adjacentPlot == nil or adjacentPlot:IsWater() or adjacentPlot:IsWOfRiver() or riverPlot:IsNEOfRiver()) then
			if riverID == _rivers[adjacentPlot] then
				TerrainBuilder.SetTerrainType(adjacentPlot, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(adjacentPlot, -1);
				ResourceBuilder.SetResourceType(adjacentPlot, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end

	elseif (thisFlowDirection == FlowDirectionTypes.FLOWDIRECTION_NORTHWEST) then

		riverPlot = startPlot;
		_rivers[riverPlot] = riverID;
		TerrainBuilder.SetNEOfRiver(riverPlot, true, thisFlowDirection, riverID);
--		print ("NW: " .. tostring(riverPlot:GetX()) .. ", " .. tostring(riverPlot:GetY()));
		riverPlot = Map.GetAdjacentPlot(riverPlot:GetX(), riverPlot:GetY(), DirectionTypes.DIRECTION_WEST);

		if (riverPlot == nil or riverPlot:IsWater() or riverPlot:IsNWOfRiver() or riverPlot:IsWOfRiver()) then
			if riverID == _rivers[riverPlot] then
				TerrainBuilder.SetTerrainType(riverPlot, g_TERRAIN_TYPE_COAST);
				TerrainBuilder.SetFeatureType(riverPlot, -1);
				ResourceBuilder.SetResourceType(riverPlot, -1);
				AreaBuilder.Recalculate();
			end
			return;
		end

	else

		--error("Illegal direction type");
		-- River is starting here, set the direction in the next step
		riverPlot = startPlot;
	end

	if (riverPlot == nil or riverPlot:IsWater()) then
		-- The river has flowed off the edge of the map or into the ocean. All is well.
		return;
	end

	-- Storing X,Y positions as locals to prevent redundant function calls.
	local riverPlotX = riverPlot:GetX();
	local riverPlotY = riverPlot:GetY();

	-- Table of methods used to determine the adjacent plot.
	local adjacentPlotFunctions = {
		[FlowDirectionTypes.FLOWDIRECTION_NORTH] = function()
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHEAST] = function()
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHEAST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST] = function()
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_EAST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTH] = function()
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_SOUTHWEST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST] = function()
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_WEST);
		end,

		[FlowDirectionTypes.FLOWDIRECTION_NORTHWEST] = function()
			return Map.GetAdjacentPlot(riverPlotX, riverPlotY, DirectionTypes.DIRECTION_NORTHWEST);
		end
	}
	local adjacentPlotOrder = {
		FlowDirectionTypes.FLOWDIRECTION_NORTH,
		FlowDirectionTypes.FLOWDIRECTION_NORTHEAST,
		FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST,
		FlowDirectionTypes.FLOWDIRECTION_SOUTH,
		FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST,
		FlowDirectionTypes.FLOWDIRECTION_NORTHWEST
	};

	if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

		-- Attempt to calculate the best flow direction.
		local bestValue = math.huge;
		for _, flowDirection in ipairs(adjacentPlotOrder) do
			local getAdjacentPlot = adjacentPlotFunctions[flowDirection];

			if (GetOppositeFlowDirection(flowDirection) ~= originalFlowDirection) then

				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then

					local adjacentPlot = getAdjacentPlot();

					if (adjacentPlot ~= nil) then

						local value = GetRiverValueAtPlot(adjacentPlot);
						if (flowDirection == originalFlowDirection) then
							value = (value * 11) / 12;
						end

						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end
					end
				end
			end
		end

		-- Try a second pass allowing the river to "flow backwards".
		if(bestFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then

			local bestValue = math.huge;
			for _, flowDirection in ipairs(adjacentPlotOrder) do
				local getAdjacentPlot = adjacentPlotFunctions[flowDirection];

				if (thisFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION or
					flowDirection == TurnRightFlowDirections[thisFlowDirection] or
					flowDirection == TurnLeftFlowDirections[thisFlowDirection]) then

					local adjacentPlot = getAdjacentPlot();

					if (adjacentPlot ~= nil) then

						local value = GetRiverValueAtPlot(adjacentPlot);
						if (value < bestValue) then
							bestValue = value;
							bestFlowDirection = flowDirection;
						end
					end
				end
			end
		end

	end

	--Recursively generate river.
	if (bestFlowDirection ~= FlowDirectionTypes.NO_FLOWDIRECTION) then
		if  (originalFlowDirection == FlowDirectionTypes.NO_FLOWDIRECTION) then
			originalFlowDirection = bestFlowDirection;
		end

		DoRiver(riverPlot, bestFlowDirection, originalFlowDirection, riverID);
	end

end

-- 添加河流源头
function AddRivers(args)
	-- 705: 自定义方法利用降雨设置地图
	args = args or {};
	local rainfall = args.rainfall or 2;

	-- 河流发源地：多少个单元格范围内无河流
	local riverSourceRangeDefault = 5 - rainfall;
	-- 河流发源地：多少个单元格范围内无水
	local seaWaterRangeDefault = 4 - rainfall;
	local plotsPerRiverEdge = 14 - rainfall;

	seaWaterRangeDefault = 2;
	plotsPerRiverEdge = 1;

	print("Team PVP 地图生成器 - 添加河流");

	local passConditions = {
		-- 河流发源地条件1：丘陵或山脉
		function(plot)
			return (plot:IsHills() or plot:IsMountain());
		end,
		-- 河流发源地条件2：非临海陆地则1/8概率发源河流
		function(plot)
			return (not plot:IsCoastalLand()) and (TerrainBuilder.GetRandomNumber(8, "MapGenerator AddRivers") == 0);
		end,
		-- 河流发源地条件3：丘陵或山脉且河流小于...本大陆的单元格数？
		function(plot)
			local area = plot:GetArea();
			return (plot:IsHills() or plot:IsMountain()) and (area:GetRiverEdgeCount() < ((area:GetPlotCount() / plotsPerRiverEdge) + 1));
		end,
		-- 河流发源地条件4：河流小于...本大陆的单元格数？
		function(plot)
			local area = plot:GetArea();
			return (area:GetRiverEdgeCount() < (area:GetPlotCount() / plotsPerRiverEdge) + 1);
		end
	}

	for iPass, passCondition in ipairs(passConditions) do
		if (iPass <= 2) then
			riverSourceRange = riverSourceRangeDefault;
			seaWaterRange = seaWaterRangeDefault;
		else
			riverSourceRange = riverSourceRange;
			seaWaterRange = seaWaterRange;
		end

		local iW, iH = Map.GetGridSize();
		for i = 0, (iW * iH) - 1, 1 do
			plot = Map.GetPlotByIndex(i);
			if(not plot:IsWater()) then
				if(passCondition(plot) and plot:IsNaturalWonder() == false and AdjacentToNaturalWonder(plot) == false) then
					if (not Map.FindWater(plot, riverSourceRange, true)) then
						if (not Map.FindWater(plot, seaWaterRange, false)) then
							local inlandCorner = TerrainBuilder.GetInlandCorner(plot);
							if(inlandCorner and plot:IsNaturalWonder() == false and AdjacentToNaturalWonder(plot) == false) then
								DoRiver(inlandCorner);
							end
						end
					end
				end
			end
		end
	end
end

function AddLakes(largeLakes)

	print("Map Generation - Adding Lakes");
	largeLakes = largeLakes or 0;

	local numLakesAdded = 0;
	local numLargeLakesAdded = 0;

	local lakePlotRand = GlobalParameters.LAKE_PLOT_RANDOM or 25;
	local iW, iH = Map.GetGridSize();
	local numLakesNeeded = math.ceil((iW + iH) / 10)

	for i = 0, (iW * iH) - 1, 1 do
		plot = Map.GetPlotByIndex(i);
		if(plot) then
		-- 705: Added oasis check to make sure this plot isn't a desert, I don't want lakes
		-- created on desert tiles.
			if (plot:IsWater() == false and TerrainBuilder.CanHaveFeature(plot, g_FEATURE_OASIS) == false) then
				if (plot:IsCoastalLand() == false) then
					if (plot:IsRiver() == false and plot:IsRiverAdjacent() == false) then
						if (AdjacentToNaturalWonder(plot) == false and AdjacentToCoast(plot) == false) then
							local r = TerrainBuilder.GetRandomNumber(lakePlotRand, "MapGenerator AddLakes");
							if r == 0 then
								numLakesAdded = numLakesAdded + 1;
								
								if(numLakesNeeded > numLakesAdded + numLargeLakesAdded) then
									local bLakes = AddMoreLake(plot);
									if(bLakes == true) then
										numLargeLakesAdded = numLargeLakesAdded + 1;
									end
								end
								
								TerrainBuilder.SetTerrainType(plot, g_TERRAIN_TYPE_COAST);
							end
						end
					end
				end
			end
		end
	end
	
	-- this is a minimalist update because lakes have been added
	if numLakesAdded > 0 then
		print(tostring(numLakesNeeded).." lakes needed")
		print(tostring(numLakesAdded).." lakes added")
		print(tostring(largeLakes).." large lakes needed")
		print(tostring(numLargeLakesAdded).." large lakes added")
		AreaBuilder.Recalculate();
	end
end

function AddMoreLake(plot)
	local largeLake = 0;
	lakePlots = {};

	-- 705: Added oasis check to make sure adjacent plot isn't a desert

	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot) then
			if (adjacentPlot:IsWater() == false and TerrainBuilder.CanHaveFeature(plot, g_FEATURE_OASIS) == false)  then
				if (adjacentPlot:IsCoastalLand() == false) then
					if (adjacentPlot:IsRiver() == false and adjacentPlot:IsRiverAdjacent() == false) then
						if (AdjacentToNaturalWonder(adjacentPlot) == false and AdjacentToCoast(plot) == false) then
							local r = TerrainBuilder.GetRandomNumber(4 + largeLake, "MapGenerator AddLakes");
							if r < 2 then
								table.insert(lakePlots, adjacentPlot);
								largeLake = largeLake + 1;
							end
						end
					end
				end
			end
		end
	end

	for iLake, lakePlot in ipairs(lakePlots) do
		TerrainBuilder.SetTerrainType(lakePlot, g_TERRAIN_TYPE_COAST);
	end

	if (largeLake > 0) then
		return true;
	else 
		return false;
	end
end

function AdjacentToNaturalWonder(plot)
	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			if(adjacentPlot:IsNaturalWonder() == true) then
				return true;
			end
		end
	end 
	return false;
end

function AdjacentToCoast(plot)
	-- 705: Custom method to keep new lakes two tiles from ocean coast
	for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
		local adjacentPlot = Map.GetAdjacentPlot(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			if(adjacentPlot:IsCoastalLand()) then
				return true;
			end
		end
	end 
	return false;
end

function GetAdjacentRoute(plot)
	local AdjacentRoute = {}
	if not plot then
		return AdjacentRoute
	end

	local AdjacentPlots = Map.GetAdjacentPlots(plot:GetX(), plot:GetY())
	for _, iPlot in ipairs(AdjacentPlots) do
		if RoutePlots[iPlot] then
			table.insert(AdjacentRoute, iPlot)
		end
	end
	return AdjacentRoute
end

function GetRealRouteNum(plot)
	if not plot then
		return
	end
	local Num = 0
	local AdjacentPlots = Map.GetAdjacentPlots(plot:GetX(), plot:GetY())
	for _, iPlot in ipairs(AdjacentPlots) do
		if plot:IsRoute() then
			Num = Num + 1
		end
	end
	return Num
end

function GetAdjacentWaterNum(plot)
	local Num = 0
	local AdjacentPlots = Map.GetAdjacentPlots(plot:GetX(), plot:GetY())
	for _, iPlot in ipairs(AdjacentPlots) do
		if iPlot:IsWater() then
			Num = Num + 1;
		end
	end
	return Num
end

function DoRoute()
	local iW, iH = Map.GetGridSize();
	local RouteLevel = tonumber(MapConfiguration.GetValue("RouteLevel")) or -1;
	if RouteLevel < 0 then
		Game:SetProperty("ZYLRM_ROUTE_TILES", 0);
		print("ZYLRM routes: 0 (disabled)");
		return;
	end
	AreaBuilder.Recalculate();
	local biggestArea = Areas.FindBiggestArea(false);
	local biggestAreaID = biggestArea and biggestArea:GetID() or -1;

	for i = 0, (iW * iH) - 1 do
		local pPlot = Map.GetPlotByIndex(i)
		if pPlot:IsCoastalLand() and CanRoute(pPlot) then				-- 沿海修路
			if pPlot:GetArea():GetID() == biggestAreaID and GetAdjacentWaterNum(pPlot) <= 3 and #GetAdjacentRoute(pPlot) < 3 then
				RoutePlots[pPlot] = true
			end
		end
	end

	for i = 0, (iW * iH) -1 do
		local pPlot = Map.GetPlotByIndex(i)
		if not RoutePlots[pPlot] and pPlot:IsRiver() and CanRoute(pPlot) then		-- 填补漏洞
			if #GetAdjacentRoute(pPlot) == 0 then
				RoutePlots[pPlot] = true
			end
		end
	end

	local Route_expand = false
	while Route_expand == false do
		Route_expand = true
		for y = 0, iH - 1 do
			for x = 0, iW -1 do
				local scanY = y;
				if x % 3 == 0 then		-- 反向折线
					scanY = iH - y - 1
				end
				local i = scanY * iW + x
				local pPlot = Map.GetPlotByIndex(i)
				if pPlot then
					if not RoutePlots[pPlot] and CanRoute(pPlot) and pPlot:IsRiver() then		-- 这一格没有路，并且可以铺路，并且沿河
						local Adjacent_Route_1 = GetAdjacentRoute(pPlot)					-- 判断这一格相邻的单元格属性
						for _, kPolot in ipairs(Adjacent_Route_1) do
							local Adjacent_Route_2 = GetAdjacentRoute(kPolot)
							if #Adjacent_Route_2 == 1 then
								local Distance = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), Adjacent_Route_2[1]:GetX(), Adjacent_Route_2[1]:GetY())		-- 判断是否相邻
								if Distance > 1 then
									RoutePlots[pPlot] = true
									Route_expand = false
--									print("道路延展")
									break
								end
							end
						end
					end
				end
			end
		end
	end

	for ik = 0, 1 do
		for k = 0, 1 do
			for i = 0, (iW * iH) -1 do
				local pPlot = Map.GetPlotByIndex(i)
				if pPlot then
					if #GetAdjacentRoute(pPlot) >= 4 then
						RoutePlots[pPlot] = nil
					end
				end
			end
		end

		local Route_expand = false
		while Route_expand == false do
			Route_expand = true
			for y = 0, iH - 1 do
				for x = 0, iW -1 do
					local scanY = y;
					if x % 3 == 0 then		-- 反向折线
						scanY = iH - y - 1
					end
					local i = scanY * iW + x
					local pPlot = Map.GetPlotByIndex(i)
					if pPlot then
						if not RoutePlots[pPlot] and CanRoute(pPlot) then		-- 这一格没有路，并且可以铺路
							local Adjacent_Route_1 = GetAdjacentRoute(pPlot)					-- 判断这一格相邻的单元格属性
							for _, kPolot in ipairs(Adjacent_Route_1) do
								local Adjacent_Route_2 = GetAdjacentRoute(kPolot)
								if #Adjacent_Route_2 == 1 then
									local Distance = Map.GetPlotDistance(pPlot:GetX(), pPlot:GetY(), Adjacent_Route_2[1]:GetX(), Adjacent_Route_2[1]:GetY())		-- 判断是否相邻
									if Distance > 1 then
										RoutePlots[pPlot] = true
										Route_expand = false
--										print("道路延展")
										break
									end
								end
							end
						end
					end
				end
			end
		end
	end

	for k = 0, 3 do			-- 小三角路抹除
		for i = 0, (iW * iH) -1 do
			local pPlot = Map.GetPlotByIndex(i)
			if pPlot then
				local Adjacent_1 = GetAdjacentRoute(pPlot)
				if Adjacent_1 and #Adjacent_1 == 2 then
					for _, iPlot in ipairs(GetAdjacentRoute(Adjacent_1[1])) do
						if iPlot == Adjacent_1[2] then
							RoutePlots[pPlot] = nil
							break
						end
					end
				end
			end
		end
	end

	for i = 0, (iW * iH) -1 do			-- 碎片路删除
		local pPlot = Map.GetPlotByIndex(i)
		if #GetAdjacentRoute(pPlot) == 0 then
			RoutePlots[pPlot] = nil
		end
	end

	local routePlotIndices = {};
	for pPlot in pairs(RoutePlots) do
		if pPlot ~= nil then
			table.insert(routePlotIndices, pPlot:GetIndex());
		end
	end
	table.sort(routePlotIndices);
	for _, plotIndex in ipairs(routePlotIndices) do		-- 修路
		local pPlot = Map.GetPlotByIndex(plotIndex);
		if CanRoute(pPlot) then
			RouteBuilder.SetRouteType(plotIndex, RouteLevel);
		end
	end
	local routeCount = 0;
	for i = 0, (iW * iH) - 1 do
		local pPlot = Map.GetPlotByIndex(i);
		if pPlot ~= nil and pPlot:IsRoute() then
			routeCount = routeCount + 1;
		end
	end
	Game:SetProperty("ZYLRM_ROUTE_TILES", routeCount);
	print(string.format("ZYLRM routes: %d (level %d)", routeCount, RouteLevel));
end

function CanRoute(pPlot)
	if not pPlot then
		return false
	end

	if not pPlot:IsImpassable() and not pPlot:IsWater() then
		return true
	else
		return false
	end
end
