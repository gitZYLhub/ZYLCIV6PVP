-- Military Training keeps its native Encampment trigger. This script adds
-- Harbor districts as the other half of the "Encampment or Harbor" condition.
-- Include formal Harbor replacements so civilization-unique districts work.

local militaryTraining = GameInfo.Civics["CIVIC_MILITARY_TRAINING"];
local harbor = GameInfo.Districts["DISTRICT_HARBOR"];
local MILITARY_TRAINING_INDEX = militaryTraining and militaryTraining.Index or -1;
local harborDistricts = {};

if harbor ~= nil then
	harborDistricts[harbor.Index] = true;
end

for replacement in GameInfo.DistrictReplaces() do
	if replacement.ReplacesDistrictType == "DISTRICT_HARBOR" then
		local district = GameInfo.Districts[replacement.CivUniqueDistrictType];
		if district ~= nil then
			harborDistricts[district.Index] = true;
		end
	end
end

local function OnDistrictConstructed(playerID, districtType, x, y)
	if MILITARY_TRAINING_INDEX < 0 or not harborDistricts[districtType] then
		return;
	end

	local player = Players[playerID];
	if player == nil or not player:IsAlive() or not player:IsMajor() then
		return;
	end

	local culture = player:GetCulture();
	if culture == nil or culture:HasCivic(MILITARY_TRAINING_INDEX) or
		culture:HasBoostBeenTriggered(MILITARY_TRAINING_INDEX) or
		not culture:CanTriggerBoost(MILITARY_TRAINING_INDEX) then
		return;
	end

	culture:TriggerBoost(MILITARY_TRAINING_INDEX);
end

GameEvents.OnDistrictConstructed.Add(OnDistrictConstructed);
