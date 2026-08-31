-- ZYLPVPMOD's single DiplomacyDealView entry point.
-- Better Deal Window owns the UI, while the compatibility layer below keeps
-- the MPH lobby restrictions authoritative.
include("DiplomacyDealView_Expansion2");

-- Better Deal Window's separate Monopolies replacement only changes product
-- icons.  Keep that behavior here so the UI context still has one owner.
local BASE_ZYLPVP_GetGreatWorkIcon = GetGreatWorkIcon;

local monopoliesValue = GameConfiguration.GetValue("GAMEMODE_MONOPOLIES");
if monopoliesValue == true or monopoliesValue == 1 or monopoliesValue == "1" then
	function GetGreatWorkIcon(kGreatWorkDesc : table)
		if kGreatWorkDesc ~= nil and
				kGreatWorkDesc.GreatWorkObjectType == "GREATWORKOBJECT_PRODUCT" and
				kGreatWorkDesc.GreatWorkType ~= nil then
			local greatWorkType : string = kGreatWorkDesc.GreatWorkType:gsub("GREATWORK_PRODUCT_", "");
			local greatWorkTrunc : string = greatWorkType:sub(1, #greatWorkType - 2);
			return "ICON_MONOPOLIES_AND_CORPS_RESOURCE_" .. greatWorkTrunc;
		end
		return BASE_ZYLPVP_GetGreatWorkIcon(kGreatWorkDesc);
	end
end

include("ZYLPVP_BDW_MPH_Compatibility");

print("Loaded ZYLPVPMOD Better Deal Window / MPH compatibility");
