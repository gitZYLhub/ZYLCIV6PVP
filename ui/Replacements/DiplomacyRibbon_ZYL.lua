-- ZYL diplomacy ribbon: BSM-style expanded cards with Diplomatic Visibility
-- gates, while retaining the Expansion 2 ribbon behavior and leader tooltips.

include("DiplomacyRibbon_Expansion2.lua");

local ZYL_XP2_FinishAddingLeader = FinishAddingLeader;
local ZYL_XP2_UpdateStatValues = UpdateStatValues;
local ZYL_XP2_LateInitialize = LateInitialize;
local ZYL_XP2_OnShutdown = OnShutdown;
local m_abilityTooltipCache = {};
local TOOLTIP_SEPARATOR = "[NEWLINE]------------------[NEWLINE]";
local ZYL_DIPLOMACY_RIBBON_MODE = 0;
local ZYL_DIPLOMACY_RIBBON_EVENTS_BOUND = false;
-- Match BSM's ribbon paging: left click toggles the research page, while
-- right click switches between the normal statistics and total-yield pages.
local m_TechCivisProgress = true;
local m_Totalyield = true;

local function IsValidPlayer(playerID)
	return playerID ~= nil and playerID ~= PlayerTypes.NONE and playerID ~= PlayerTypes.OBSERVER and Players[playerID] ~= nil;
end

local function GetRibbonMode()
	local mode = tonumber(GameConfiguration.GetValue("ZYL_DIPLOMACY_RIBBON_MODE"));
	if mode == 1 then
		return 1;
	end
	return ZYL_DIPLOMACY_RIBBON_MODE;
end

local function GetAccessLevel(targetID)
	local localID = Game.GetLocalPlayer();
	if not IsValidPlayer(localID) or not IsValidPlayer(targetID) then
		return 4;
	end
	if localID == targetID then
		return 4;
	end

	local localPlayer = Players[localID];
	local localDiplomacy = localPlayer and localPlayer:GetDiplomacy();
	local level = 0;
	if localDiplomacy ~= nil then
		level = tonumber(localDiplomacy:GetVisibilityOn(targetID)) or 0;
	end
	if GetRibbonMode() == 0 then
		return math.max(0, math.min(level, 4));
	end

	-- Teammates share their complete ribbon intelligence.  Against enemies,
	-- use the best visibility held by any living member of the local team.
	local localTeam = localPlayer:GetTeam();
	local targetTeam = Players[targetID]:GetTeam();
	if localTeam == targetTeam then
		return 4;
	end
	for _, teammate in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if Players[teammate] ~= nil and Players[teammate]:GetTeam() == localTeam then
			local diplomacy = Players[teammate]:GetDiplomacy();
			if diplomacy ~= nil then
				local teammateLevel = tonumber(diplomacy:GetVisibilityOn(targetID)) or 0;
				level = math.max(level, teammateLevel);
			end
		end
	end
	return math.max(0, math.min(level, 4));
end

local function SetHide(control, hidden)
	if control ~= nil then
		control:SetHide(hidden);
	end
end

local function SetText(control, value)
	if control ~= nil then
		control:SetText(value);
	end
end

local function SetLocked(control, icon)
	SetText(control, icon .. "?");
end

local function GetFoodSurplus(city)
	if city == nil or city:GetGrowth() == nil then
		return 0;
	end
	local growth = city:GetGrowth();
	local food = Round(growth:GetFoodSurplus(), 1);
	if growth:GetTurnsUntilStarvation() ~= -1 then
		return food;
	end
	local happiness = growth:GetHappinessGrowthModifier();
	local other = growth:GetOtherGrowthModifier();
	local modified = Round(food * math.max(1 + happiness / 100 + other, 0), 2);
	local result = modified * growth:GetHousingGrowthModifier();
	if city:IsOccupied() then
		result = modified * growth:GetOccupationGrowthModifier();
	end
	return result;
end

local function GetFoodSurplusTotal(playerID)
	local total = 0;
	if not IsValidPlayer(playerID) then
		return total;
	end
	for _, city in Players[playerID]:GetCities():Members() do
		total = total + GetFoodSurplus(city);
	end
	return total;
end

local function GetProductionTotal(playerID)
	local total = 0;
	if not IsValidPlayer(playerID) then
		return total;
	end
	for _, city in Players[playerID]:GetCities():Members() do
		total = total + city:GetYield(YieldTypes.PRODUCTION);
	end
	return total;
end

local function GetPopulationTotal(playerID)
	local total = 0;
	if not IsValidPlayer(playerID) then
		return total;
	end
	for _, city in Players[playerID]:GetCities():Members() do
		total = total + city:GetPopulation();
	end
	return total;
end

function OnMouseClick_TPT_Control_1L()
	m_TechCivisProgress = not m_TechCivisProgress;
	UpdateLeaders();
end

function OnMouseClick_TPT_Control_1R()
	-- Right-click buttons do not receive the standard UI click sound.
	UI.PlaySound("Play_UI_Click");
	m_Totalyield = not m_Totalyield;
	UpdateLeaders();
end

local function SetResearchCard(uiLeader, playerID, unlocked, revealTarget)
	if not revealTarget then
		SetHide(uiLeader.ScienceButton, true);
		SetHide(uiLeader.ScienceText, true);
		SetHide(uiLeader.ScienceTurnsLeft, true);
		SetHide(uiLeader.CultureButton, true);
		SetHide(uiLeader.CultureText, true);
		SetHide(uiLeader.CultureTurnsLeft, true);
		return;
	end

	local show = unlocked and IsValidPlayer(playerID);
	SetHide(uiLeader.ScienceButton, not show);
	SetHide(uiLeader.ScienceText, false);
	SetHide(uiLeader.ScienceTurnsLeft, not show);
	SetHide(uiLeader.CultureButton, not show);
	SetHide(uiLeader.CultureText, false);
	SetHide(uiLeader.CultureTurnsLeft, not show);
	if not show then
		SetText(uiLeader.ScienceText, "[ICON_Science]?");
		SetText(uiLeader.CultureText, "[ICON_Culture]?");
		uiLeader.ScienceText:SetToolTipString(Locale.Lookup("LOC_ZYL_DIPLOMACY_RIBBON_RESEARCH_LOCKED_TT"));
		uiLeader.CultureText:SetToolTipString(Locale.Lookup("LOC_ZYL_DIPLOMACY_RIBBON_RESEARCH_LOCKED_TT"));
		return;
	end

	local player = Players[playerID];
	local techs = player:GetTechs();
	local techID = techs:GetResearchingTech();
	if techID ~= nil and techID >= 0 and GameInfo.Technologies[techID] ~= nil then
		local tech = GameInfo.Technologies[techID];
		local progress = techs:GetResearchProgress(techID);
		local cost = techs:GetResearchCost(techID);
		local percent = cost > 0 and math.min(progress / cost, 1) or 0;
		uiLeader.ScienceProgressMeter:SetPercent(percent);
		uiLeader.ScienceBoostMeter:SetPercent(percent);
		local x, y, sheet = IconManager:FindIconAtlas("ICON_" .. tech.TechnologyType, 38);
		if sheet ~= nil then uiLeader.ResearchIcon:SetTexture(x, y, sheet); end
		TruncateStringWithTooltip(uiLeader.ScienceText, 58, Locale.Lookup(tech.Name));
		SetText(uiLeader.ScienceTurnsLeft, "[ICON_Turn] " .. tostring(techs:GetTurnsLeft()));
	else
		SetText(uiLeader.ScienceText, "?");
		uiLeader.ScienceText:SetToolTipString("");
		SetText(uiLeader.ScienceTurnsLeft, "");
		uiLeader.ScienceProgressMeter:SetPercent(0);
		uiLeader.ScienceBoostMeter:SetPercent(0);
	end

	local culture = player:GetCulture();
	local civicID = culture:GetProgressingCivic();
	if civicID ~= nil and civicID >= 0 and GameInfo.Civics[civicID] ~= nil then
		local civic = GameInfo.Civics[civicID];
		local progress = culture:GetCulturalProgress(civicID);
		local cost = culture:GetCultureCost(civicID);
		local percent = cost > 0 and math.min(progress / cost, 1) or 0;
		uiLeader.CultureProgressMeter:SetPercent(percent);
		uiLeader.CultureBoostMeter:SetPercent(percent);
		local x, y, sheet = IconManager:FindIconAtlas("ICON_" .. civic.CivicType, 38);
		if sheet ~= nil then uiLeader.CultureIcon:SetTexture(x, y, sheet); end
		TruncateStringWithTooltip(uiLeader.CultureText, 58, Locale.Lookup(civic.Name));
		SetText(uiLeader.CultureTurnsLeft, "[ICON_Turn] " .. tostring(culture:GetTurnsLeft()));
	else
		SetText(uiLeader.CultureText, "?");
		uiLeader.CultureText:SetToolTipString("");
		SetText(uiLeader.CultureTurnsLeft, "");
		uiLeader.CultureProgressMeter:SetPercent(0);
		uiLeader.CultureBoostMeter:SetPercent(0);
	end
end

local function GetLocalizedText(textKey)
	if textKey == nil or textKey == "" then
		return nil;
	end

	local localizedText = Locale.Lookup(textKey);
	if localizedText == nil or localizedText == "" or localizedText == textKey then
		return nil;
	end
	return localizedText;
end

local function AppendLocalizedEntry(parts, seenEntries, row)
	if row == nil then
		return;
	end

	local name = GetLocalizedText(row.Name);
	local description = GetLocalizedText(row.Description);
	if name == nil or description == nil then
		return;
	end

	local entryKey = name .. "|" .. description;
	if seenEntries[entryKey] then
		return;
	end

	seenEntries[entryKey] = true;
	table.insert(parts, TOOLTIP_SEPARATOR);
	table.insert(parts, name);
	table.insert(parts, "[NEWLINE]");
	table.insert(parts, description);
end

local function CollectTraitTypes(associationTable, ownerColumn, ownerType)
	local traitTypes = {};
	if ownerType == nil then
		return traitTypes;
	end

	for row in associationTable() do
		if row[ownerColumn] == ownerType and row.TraitType ~= nil then
			table.insert(traitTypes, row.TraitType);
		end
	end
	return traitTypes;
end

local function AppendTraitDescriptions(parts, seenEntries, traitTypes)
	for _, traitType in ipairs(traitTypes) do
		AppendLocalizedEntry(parts, seenEntries, GameInfo.Traits[traitType]);
	end
end

local function AppendTraitObjects(parts, seenEntries, traitTypes, objectTable)
	for _, traitType in ipairs(traitTypes) do
		for row in objectTable() do
			if row.TraitType == traitType then
				AppendLocalizedEntry(parts, seenEntries, row);
			end
		end
	end
end

local function BuildPlayerAbilityTooltip(playerID)
	local playerConfig = PlayerConfigurations[playerID];
	if playerConfig == nil then
		return nil;
	end

	local leaderType = playerConfig:GetLeaderTypeName();
	local civilizationType = playerConfig:GetCivilizationTypeName();
	if leaderType == nil or civilizationType == nil then
		return nil;
	end

	local cacheKey = leaderType .. "|" .. civilizationType;
	if m_abilityTooltipCache[cacheKey] ~= nil then
		return m_abilityTooltipCache[cacheKey];
	end

	local leaderRow = GameInfo.Leaders[leaderType];
	local civilizationRow = GameInfo.Civilizations[civilizationType];
	local leaderName = leaderRow ~= nil and GetLocalizedText(leaderRow.Name) or nil;
	local civilizationName = civilizationRow ~= nil and GetLocalizedText(civilizationRow.Name) or nil;
	if leaderName == nil and civilizationName == nil then
		return nil;
	end

	local parts = {};
	if leaderName ~= nil then
		table.insert(parts, leaderName);
	end
	if civilizationName ~= nil then
		if #parts > 0 then
			table.insert(parts, "[NEWLINE]");
		end
		table.insert(parts, civilizationName);
	end

	local leaderTraits = CollectTraitTypes(GameInfo.LeaderTraits, "LeaderType", leaderType);
	local civilizationTraits = CollectTraitTypes(GameInfo.CivilizationTraits, "CivilizationType", civilizationType);
	local seenEntries = {};

	AppendTraitDescriptions(parts, seenEntries, leaderTraits);
	AppendTraitDescriptions(parts, seenEntries, civilizationTraits);

	for _, objectTable in ipairs({
		GameInfo.Districts,
		GameInfo.Buildings,
		GameInfo.Improvements,
		GameInfo.Units
	}) do
		AppendTraitObjects(parts, seenEntries, leaderTraits, objectTable);
		AppendTraitObjects(parts, seenEntries, civilizationTraits, objectTable);
	end

	local tooltip = table.concat(parts);
	m_abilityTooltipCache[cacheKey] = tooltip;
	return tooltip;
end

local function GetLeaderContainer(uiLeader)
	if uiLeader == nil then
		return nil;
	end
	if uiLeader.LeaderContainer ~= nil then
		return uiLeader.LeaderContainer;
	end
	if uiLeader.Controls ~= nil then
		return uiLeader.Controls.LeaderContainer;
	end
	return nil;
end

function FinishAddingLeader(playerID, uiLeader, kProps)
	ZYL_XP2_FinishAddingLeader(playerID, uiLeader, kProps);

	local leaderContainer = GetLeaderContainer(uiLeader);
	if leaderContainer == nil then
		return;
	end

	-- In multiplayer, uncontacted human players are present in the ribbon with
	-- a masked portrait. Do not resolve their configuration and leak identity.
	if kProps ~= nil and kProps.isMasked then
		leaderContainer:SetToolTipString("");
		SetHide(uiLeader.TPT_Control_1, true);
		for _, control in ipairs({
			uiLeader.Score, uiLeader.Military, uiLeader.Science, uiLeader.Culture,
			uiLeader.Gold, uiLeader.Faith, uiLeader.Favor, uiLeader.Cities,
			uiLeader.Food_Total, uiLeader.Production_Total, uiLeader.GoldPerTurn,
			uiLeader.FaithperTurn, uiLeader.FavorperTurn, uiLeader.ScienceButton,
			uiLeader.ScienceText, uiLeader.ScienceTurnsLeft, uiLeader.CultureButton,
			uiLeader.CultureText, uiLeader.CultureTurnsLeft
		}) do
			SetHide(control, true);
		end
		uiLeader.StatStack:CalculateSize();
		return;
	end

	local tooltip = BuildPlayerAbilityTooltip(playerID);
	leaderContainer:SetToolTipString(tooltip or "");
	if uiLeader.TPT_Control_1 ~= nil then
		uiLeader.TPT_Control_1:SetHide(false);
		uiLeader.TPT_Control_1:RegisterCallback(Mouse.eLClick, OnMouseClick_TPT_Control_1L);
		uiLeader.TPT_Control_1:RegisterCallback(Mouse.eRClick, OnMouseClick_TPT_Control_1R);
	end
	UpdateStatValues(playerID, uiLeader);
end

function UpdateStatValues(playerID, uiLeader)
	ZYL_XP2_UpdateStatValues(playerID, uiLeader);

	local localID = Game.GetLocalPlayer();
	local revealTarget = true;
	if IsValidPlayer(localID) and playerID ~= localID then
		local diplomacy = Players[localID]:GetDiplomacy();
		revealTarget = diplomacy ~= nil and diplomacy:HasMet(playerID);
	end

	local showResearch = not m_TechCivisProgress;
	local showDefault = m_TechCivisProgress and m_Totalyield;
	local showTotalYield = m_TechCivisProgress and not m_Totalyield;
	SetHide(uiLeader.TPT_Control_1, not revealTarget);

	-- Preserve the unused stock controls expected by the Firaxis script, but
	-- separate the active controls into BSM-style mutually exclusive pages.
	SetHide(uiLeader.Score, true);
	SetHide(uiLeader.Favor, true);
	SetHide(uiLeader.FavorperTurn, true);

	SetHide(uiLeader.Military, not (showDefault and revealTarget));
	SetHide(uiLeader.Science, not (showDefault and revealTarget));
	SetHide(uiLeader.Culture, not (showDefault and revealTarget));
	SetHide(uiLeader.Gold, not (showDefault and revealTarget));
	SetHide(uiLeader.Faith, not (showDefault and revealTarget));

	SetHide(uiLeader.Cities, not (showTotalYield and revealTarget));
	SetHide(uiLeader.Food_Total, not (showTotalYield and revealTarget));
	SetHide(uiLeader.Production_Total, not (showTotalYield and revealTarget));
	SetHide(uiLeader.GoldPerTurn, not (showTotalYield and revealTarget));
	SetHide(uiLeader.FaithperTurn, not (showTotalYield and revealTarget));

	if not revealTarget or not IsValidPlayer(playerID) then
		SetResearchCard(uiLeader, playerID, false, false);
		uiLeader.StatStack:CalculateSize();
		return;
	end

	local player = Players[playerID];
	local accessLevel = GetAccessLevel(playerID);
	SetText(uiLeader.Science, "[ICON_Science]" .. tostring(Round(player:GetTechs():GetScienceYield())));
	SetText(uiLeader.Culture, "[ICON_Culture]" .. tostring(Round(player:GetCulture():GetCultureYield())));
	SetText(uiLeader.Gold, "[ICON_Gold]" .. tostring(math.floor(player:GetTreasury():GetGoldBalance())));
	SetText(uiLeader.Faith, "[ICON_Faith]" .. tostring(Round(player:GetReligion():GetFaithBalance())));

	if accessLevel >= 1 then
		SetText(uiLeader.Military, "[ICON_Strength]" .. tostring(Round(player:GetStats():GetMilitaryStrengthWithoutTreasury())));
	else
		SetLocked(uiLeader.Military, "[ICON_Strength]");
	end
	if accessLevel >= 2 then
		SetText(uiLeader.Cities, "[ICON_Citizen]" .. tostring(GetPopulationTotal(playerID)));
		SetText(uiLeader.Food_Total, "[ICON_Food]" .. tostring(Round(GetFoodSurplusTotal(playerID))));
		SetText(uiLeader.Production_Total, "[ICON_Production]" .. tostring(Round(GetProductionTotal(playerID))));
	else
		SetLocked(uiLeader.Cities, "[ICON_Citizen]");
		SetLocked(uiLeader.Food_Total, "[ICON_Food]");
		SetLocked(uiLeader.Production_Total, "[ICON_Production]");
	end
	if accessLevel >= 3 then
		local treasury = player:GetTreasury();
		local goldPerTurn = math.floor(treasury:GetGoldYield() - treasury:GetTotalMaintenance());
		local faithPerTurn = Round(player:GetReligion():GetFaithYield());
		SetText(uiLeader.GoldPerTurn, "[ICON_Gold]" .. tostring(goldPerTurn));
		SetText(uiLeader.FaithperTurn, "[ICON_Faith]" .. tostring(faithPerTurn));
	else
		SetLocked(uiLeader.GoldPerTurn, "[ICON_Gold]");
		SetLocked(uiLeader.FaithperTurn, "[ICON_Faith]");
	end
	SetResearchCard(uiLeader, playerID, accessLevel >= 4, showResearch);

	uiLeader.StatStack:CalculateSize();
	local stackSize = uiLeader.StatStack:GetSize();
	local containerSize = uiLeader.LeaderContainer:GetSize();
	uiLeader.ActiveLeaderAndStats:SetSizeVal(containerSize.x - 4, stackSize.y + 55);
end

local function OnZylRibbonIntelChanged()
	if type(UpdateLeaders) == "function" then
		UpdateLeaders();
	end
end

local function BindZylRibbonEvents()
	if ZYL_DIPLOMACY_RIBBON_EVENTS_BOUND then
		return;
	end
	ZYL_DIPLOMACY_RIBBON_EVENTS_BOUND = true;
	if Events.ResearchChanged ~= nil then Events.ResearchChanged.Add(OnZylRibbonIntelChanged); end
	if Events.ResearchCompleted ~= nil then Events.ResearchCompleted.Add(OnZylRibbonIntelChanged); end
	if Events.CivicChanged ~= nil then Events.CivicChanged.Add(OnZylRibbonIntelChanged); end
	if Events.SpyMissionCompleted ~= nil then Events.SpyMissionCompleted.Add(OnZylRibbonIntelChanged); end
	if Events.DiplomacySessionClosed ~= nil then Events.DiplomacySessionClosed.Add(OnZylRibbonIntelChanged); end
	if Events.TradeRouteActivityChanged ~= nil then Events.TradeRouteActivityChanged.Add(OnZylRibbonIntelChanged); end
end

function LateInitialize()
	ZYL_XP2_LateInitialize();
	BindZylRibbonEvents();
end

function OnShutdown()
	if ZYL_DIPLOMACY_RIBBON_EVENTS_BOUND then
		if Events.ResearchChanged ~= nil then Events.ResearchChanged.Remove(OnZylRibbonIntelChanged); end
		if Events.ResearchCompleted ~= nil then Events.ResearchCompleted.Remove(OnZylRibbonIntelChanged); end
		if Events.CivicChanged ~= nil then Events.CivicChanged.Remove(OnZylRibbonIntelChanged); end
		if Events.SpyMissionCompleted ~= nil then Events.SpyMissionCompleted.Remove(OnZylRibbonIntelChanged); end
		if Events.DiplomacySessionClosed ~= nil then Events.DiplomacySessionClosed.Remove(OnZylRibbonIntelChanged); end
		if Events.TradeRouteActivityChanged ~= nil then Events.TradeRouteActivityChanged.Remove(OnZylRibbonIntelChanged); end
		ZYL_DIPLOMACY_RIBBON_EVENTS_BOUND = false;
	end
	ZYL_XP2_OnShutdown();
end

ContextPtr:SetShutdown(OnShutdown);

-- Expansion 2 executes its own LateInitialize while this replacement is being
-- included. Bind the additional, low-frequency refresh events explicitly so
-- they are also active on the first load (and after a save reload).
BindZylRibbonEvents();
