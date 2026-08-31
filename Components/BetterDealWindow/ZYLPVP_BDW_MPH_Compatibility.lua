-- MPH trade-category restrictions adapted as a post-load extension for
-- Better Deal Window.  This file intentionally does not include another deal
-- view: DiplomacyDealView_ZYLPVP_Expansion2.lua is the sole entry point.

local function IsLobbyOptionEnabled(optionName : string)
	local value = GameConfiguration.GetValue(optionName);
	return value == true or value == 1 or value == "1";
end

local isTradingAllowed = not IsLobbyOptionEnabled("DIPLOMATIC_DEAL");
local isGoldTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_GOLD");
local isFavorTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_FAVOR");
local isStrategicsTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_STRATEGICS");
local isLuxuriesTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_LUXURIES");
local isCitiesTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_CITIES");
local isCaptivesTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_CAPTIVES");
local isGreatWorksTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_GREATWORKS");
local isAgreementsTradingAllowed = not IsLobbyOptionEnabled("NO_TRADING_AGREEMENTS");

local MPH_BASE_PopulateAvailableGold = PopulateAvailableGold;
local MPH_BASE_PopulateAvailableFavor = PopulateAvailableFavor;
local MPH_BASE_PopulateAvailableResources = PopulateAvailableResources;
local MPH_BASE_PopulateAvailableLuxuryResources = PopulateAvailableLuxuryResources;
local MPH_BASE_PopulateAvailableStrategicResources = PopulateAvailableStrategicResources;
local MPH_BASE_PopulateAvailableAgreements = PopulateAvailableAgreements;
local MPH_BASE_PopulateAvailableCities = PopulateAvailableCities;
local MPH_BASE_PopulateAvailableGreatWorks = PopulateAvailableGreatWorks;
local MPH_BASE_PopulateAvailableCaptives = PopulateAvailableCaptives;

local function HideBlockedGroup(iconList : table)
	if iconList ~= nil and iconList.GetTopControl ~= nil then
		local topControl = iconList.GetTopControl();
		if topControl ~= nil then topControl:SetHide(true); end
	end
	return 0;
end

function PopulateAvailableGold(player : table, iconList : table)
	if not isTradingAllowed or not isGoldTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableGold(player, iconList);
end

function PopulateAvailableFavor(player : table, iconList : table)
	if not isTradingAllowed or not isFavorTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableFavor(player, iconList);
end

function PopulateAvailableResources(player : table, iconList : table, className : string)
	if not isTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableResources(player, iconList, className);
end

function PopulateAvailableLuxuryResources(player : table, iconList : table)
	if not isTradingAllowed or not isLuxuriesTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableLuxuryResources(player, iconList);
end

function PopulateAvailableStrategicResources(player : table, iconList : table)
	if not isTradingAllowed or not isStrategicsTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableStrategicResources(player, iconList);
end

function PopulateAvailableAgreements(player : table, iconList : table)
	if not isTradingAllowed or not isAgreementsTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableAgreements(player, iconList);
end

function PopulateAvailableCities(player : table, iconList : table)
	if not isTradingAllowed or not isCitiesTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableCities(player, iconList);
end

function PopulateAvailableGreatWorks(player : table, iconList : table)
	if not isTradingAllowed or not isGreatWorksTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableGreatWorks(player, iconList);
end

function PopulateAvailableCaptives(player : table, iconList : table)
	if not isTradingAllowed or not isCaptivesTradingAllowed then return HideBlockedGroup(iconList); end
	return MPH_BASE_PopulateAvailableCaptives(player, iconList);
end
