-- Vampire Castles may replace ordinary resources and removable features.
-- Clear them after the improvement is placed so no harvest yield is granted.

local vampireCastleInfo = GameInfo.Improvements['IMPROVEMENT_VAMPIRE_CASTLE'];
local vampireCastleIndex = vampireCastleInfo and vampireCastleInfo.Index or -1;
local removableResourceClasses = {
	RESOURCECLASS_BONUS = true,
	RESOURCECLASS_LUXURY = true,
	RESOURCECLASS_STRATEGIC = true,
};
local removableResources = {};

for resource in GameInfo.Resources() do
	if removableResourceClasses[resource.ResourceClassType] then
		removableResources[resource.Index] = true;
	end
end

local removableFeatures = {};
for feature in GameInfo.Features() do
	if feature.Removable == true or feature.Removable == 1 then
		removableFeatures[feature.Index] = true;
	end
end

local function OnVampireCastleAdded(x, y, improvementIndex, playerID)
	if improvementIndex ~= vampireCastleIndex then
		return;
	end

	local plot = Map.GetPlot(x, y);
	if plot == nil then
		return;
	end

	local resourceIndex = plot:GetResourceType();
	if removableResources[resourceIndex] then
		ResourceBuilder.SetResourceType(plot, -1);
	end

	local featureIndex = plot:GetFeatureType();
	if removableFeatures[featureIndex] then
		TerrainBuilder.SetFeatureType(plot, -1);
	end
end

Events.ImprovementAddedToMap.Add(OnVampireCastleAdded);
