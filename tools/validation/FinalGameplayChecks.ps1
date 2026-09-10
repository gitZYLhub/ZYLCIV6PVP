function Get-ZylFinalGameplayContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowEmptyString()]
        [string]$GameplaySourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    $gameplayOverridePath = Join-Path $modRoot 'sql\ZYL_GameplayOverrides.sql'
    $governorOverridePath = Join-Path $modRoot 'sql\ZYL_GovernorOverrides.sql'

    $bbgMaoriPath = Join-Path $modRoot 'Components\BBG\sql\XP2\Maori.sql'
    if (-not (Test-Path -LiteralPath $bbgMaoriPath)) {
        $issues.Add('BBG Maori gameplay SQL is missing.')
    }
    else {
        $bbgMaoriSql = Get-Content -LiteralPath $bbgMaoriPath -Raw
        if ($bbgMaoriSql -notmatch "(?s)UPDATE\s+Leaders_XP2\s+SET\s+OceanStart\s*=\s*0\s+WHERE\s+LeaderType\s*=\s*'LEADER_KUPE'") {
            $issues.Add('Kupe is no longer locked to BBG land-based starting behavior.')
        }
        if ($bbgMaoriSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasTerrains.*?'CIVILIZATION_MAORI'\s*,\s*'TERRAIN_COAST'\s*,\s*'1'") {
            $issues.Add('Maori no longer have the T1 Coast bias required by Rich Mainland shore placement.')
        }
        foreach ($maoriFeature in @('FEATURE_FOREST', 'FEATURE_JUNGLE')) {
            if ($bbgMaoriSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasFeatures.*?'CIVILIZATION_MAORI'\s*,\s*'$maoriFeature'\s*,\s*4") {
                $issues.Add("Maori are missing their T4 $maoriFeature start bias.")
            }
        }
    }

    $bbgGermanyPath = Join-Path $modRoot 'Components\BBG\sql\Base\Germany.sql'
    if (-not (Test-Path -LiteralPath $bbgGermanyPath)) {
        $issues.Add('BBG Germany gameplay SQL is missing.')
    }
    else {
        $bbgGermanySql = Get-Content -LiteralPath $bbgGermanyPath -Raw
        if ($bbgGermanySql -notmatch "(?s)UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_EXTRA_DISTRICT_EACH_CITY'") {
            $issues.Add('Germany extra district capacity is not unlocked at Early Empire.')
        }
    }

    if (-not (Test-Path -LiteralPath $gameplayOverridePath)) {
        $issues.Add('ZYL gameplay override SQL is missing.')
    }
    else {
        $gameplayOverrideSql = if ($PSBoundParameters.ContainsKey('GameplaySourceOverride')) {
            $GameplaySourceOverride
        }
        else {
            Get-Content -LiteralPath $gameplayOverridePath -Raw
        }
        foreach ($requiredToken in @(
            'CITY_POPULATION_NO_WATER',
            'CITY_POPULATION_COAST',
            'BBG_MAYA_CAPITAL_HOUSING',
            'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING',
            'TECH_COST_PERCENT_CHANGE_BEFORE_GAME_ERA',
            "('TECH_CELESTIAL_NAVIGATION', 'TECH_SAILING')",
            'TRAIT_MAORI_EMBARKED_ABILITY',
            'BBG_PLOT_HAS_FOREST_EARLY_EMPIRE',
            'BBG_PLOT_HAS_JUNGLE_EARLY_EMPIRE',
            'TRAIT_MAORI_PREVENT_HARVEST',
            "WHERE TechnologyType = 'TECH_ARCHERY'",
            "WHERE TechnologyType = 'TECH_BRONZE_WORKING'",
            "WHERE TechnologyType = 'TECH_MILITARY_TACTICS'",
            "WHERE CivicType = 'CIVIC_GAMES_RECREATION'",
            "WHERE CivicType = 'CIVIC_RECORDED_HISTORY'",
            "WHERE CivicType = 'CIVIC_HUMANISM'",
            "WHERE CivicType = 'CIVIC_NAVAL_TRADITION'",
            "WHERE CivicType = 'CIVIC_FEUDALISM'",
            'BBG_MALI_FAITH_NEXT_DESERT',
            'BBG_MALI_FAITH_NEXT_DESERT_HILLS',
            'BBG_MALI_FAITH_NEXT_CAPITAL',
            'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION',
            'TRAIT_BBG_MANSA_FREE_TRADER_BANKS',
            'ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS',
            'ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS',
            'ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER',
            'ZYL_MALI_DESERT_CITY_CENTER_FAITH',
            'ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH',
            'TRAIT_MALI_MINES_PRODUCTION',
            'TRAIT_MALI_MINES_GOLD',
            'TRAIT_DESERT_CITY_CENTER_FAITH',
            'TRAIT_DESERT_HILLS_CITY_CENTER_FAITH',
            'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION',
            'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION_BUILDING',
            'BBG_COLUMBIA_MOVEMENT_BONUS',
            'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT',
            'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING',
            'BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET',
            'GAUL_MINE_CULTURE',
            'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING',
            'PLOT_HAS_MINE_REQUIREMENTS',
            'OPPIDUM_GRANT_TECH_APPRENTICESHIP',
            'SUGUBA_CHEAPER_BUILDING_PURCHASE',
            'SUGUBA_CHEAPER_DISTRICT_PURCHASE',
            'SUGUBA_CHEAPER_UNIT_PURCHASE',
            'FEATURE_OASIS',
            'Feature_YieldChanges',
            'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER',
            'MISSION_NEWCONTINENT_FAITH',
            'MISSION_NEWCONTINENT_FOOD',
            'MISSION_NEWCONTINENT_PRODUCTION',
            'ZYL_RUSSIA_FLAT_TUNDRA_CITY_HAS_LAVRA',
            'ZYL_RUSSIA_TUNDRA_HILLS_CITY_HAS_LAVRA',
            'BBG_CITY_HAS_DISTRICT_LAVRA_REQUIREMENT',
            'BBG_SULEIMAN_COMBAT_BUFF',
            'OPPONENT_IS_IN_GOLDEN_AGE_REQUIREMENTS',
            'BBG_APPEAL_WYWH',
            'BBG_AUTOMATON_GDR_PROD',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX',
            'TRAIT_INCREASED_TUNDRA_HILLS_FAITH',
            'TRAIT_ADJACENT_DISTRICTS_HARBOR_ADJACENCYGOLD',
            'TRAIT_ADJACENT_DISTRICTS_COMMERCIALHUB_ADJACENCYGOLD'
        )) {
            if (-not $gameplayOverrideSql.Contains($requiredToken)) {
                $issues.Add("Gameplay override SQL is missing invariant: $requiredToken")
            }
        }

        if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*'3'\s+WHERE\s+Name\s*=\s*'CITY_POPULATION_NO_WATER'") {
            $issues.Add('No-water city base Housing is not locked to 3.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*'4'\s+WHERE\s+Name\s*=\s*'CITY_POPULATION_COAST'") {
            $issues.Add('Coast-only city base Housing is not locked to 4.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TechnologyPrereqs\s+WHERE\s+Technology\s*=\s*'TECH_CELESTIAL_NAVIGATION'") {
            $issues.Add('Celestial Navigation prerequisite cleanup is missing.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)INSERT\s+OR\s+IGNORE\s+INTO\s+TechnologyPrereqs\s*\(\s*Technology\s*,\s*PrereqTech\s*\)\s*VALUES\s*\(\s*'TECH_CELESTIAL_NAVIGATION'\s*,\s*'TECH_SAILING'\s*\)") {
            $issues.Add('Celestial Navigation is not directly unlocked by Sailing.')
        }
        if ($gameplayOverrideSql -match "(?s)\(\s*'TECH_CELESTIAL_NAVIGATION'\s*,\s*'TECH_ASTROLOGY'\s*\)") {
            $issues.Add('Celestial Navigation still has an Astrology prerequisite.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+ModifierType\s*=\s*'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING'\s+WHERE\s+ModifierId\s*=\s*'BBG_MAYA_CAPITAL_HOUSING'") {
            $issues.Add('Maya Housing modifier is not scoped to all cities.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)INSERT\s+OR\s+IGNORE\s+INTO\s+DistrictModifiers\s*\(\s*DistrictType\s*,\s*ModifierId\s*\)\s*VALUES\s*\(\s*'DISTRICT_OPPIDUM'\s*,\s*'OPPIDUM_GRANT_TECH_APPRENTICESHIP'\s*\)") {
            $issues.Add('Oppidum no longer grants the Apprenticeship boost.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)INSERT\s+OR\s+IGNORE\s+INTO\s+TraitModifiers\s*\(\s*TraitType\s*,\s*ModifierId\s*\)\s*VALUES\s*\(\s*'TRAIT_CIVILIZATION_ADJACENT_DISTRICTS'\s*,\s*'TRAIT_ADJACENT_DISTRICTS_HARBOR_ADJACENCYGOLD'\s*\),\s*\(\s*'TRAIT_CIVILIZATION_ADJACENT_DISTRICTS'\s*,\s*'TRAIT_ADJACENT_DISTRICTS_COMMERCIALHUB_ADJACENCYGOLD'\s*\)") {
            $issues.Add('Meiji Harbour / Commercial Hub adjacency is not restored for every Japanese leader.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_DIVINE_WIND'\s+AND\s+ModifierId\s+IN\s*\(\s*'TRAIT_ADJACENT_DISTRICTS_HARBOR_ADJACENCYGOLD'\s*,\s*'TRAIT_ADJACENT_DISTRICTS_COMMERCIALHUB_ADJACENCYGOLD'\s*\)") {
            $issues.Add('Hojo still carries the personal Meiji Harbour / Commercial Hub copy (would double the bonus).')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ExcludedAdjacencies\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_ADJACENT_DISTRICTS'\s+AND\s+YieldChangeId\s*=\s*'River_Gold'") {
            $issues.Add('Japanese Commercial Hubs still exclude the River adjacency.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_SAILING'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_MAORI_EMBARKED_ABILITY'") {
            $issues.Add('Final Maori embarked-unit +2 Movement bonus is not unlocked at Sailing.')
        }
        $maoriProductionBindings = @(
            @('BBG_PLOT_HAS_FOREST_EARLY_EMPIRE', 'TRAIT_MAORI_PRODUCTION_WOODS'),
            @('BBG_PLOT_HAS_JUNGLE_EARLY_EMPIRE', 'TRAIT_MAORI_PRODUCTION_RAINFOREST')
        )
        foreach ($binding in $maoriProductionBindings) {
            $requirementSetId = [regex]::Escape($binding[0])
            $modifierId = [regex]::Escape($binding[1])
            if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'$requirementSetId'\s+WHERE\s+ModifierId\s*=\s*'$modifierId'") {
                $issues.Add("Maori +1 Production modifier is not unlocked at Early Empire: $($binding[1])")
            }
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_MAORI_MANA'\s+AND\s+ModifierId\s*=\s*'TRAIT_MAORI_PREVENT_HARVEST'") {
            $issues.Add('Final Maori override does not remove the resource-harvesting restriction.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_MALI_GOLD_DESERT'.*?'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION'.*?'BBG_MALI_FAITH_NEXT_DESERT'.*?'BBG_MALI_FAITH_NEXT_DESERT_HILLS'.*?'BBG_MALI_FAITH_NEXT_CAPITAL'") {
            $issues.Add('Final Mali override does not remove the Production penalty and Foreign Trade city Faith package.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SAHEL_MERCHANTS'.*?ModifierId\s*=\s*'TRAIT_BBG_MANSA_FREE_TRADER_BANKS'") {
            $issues.Add('Final Mansa Musa override does not remove the Banking Trade Route modifier.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_MALI_GOLD_DESERT'.*?'ZYL_MALI_FAITH_DESERT'.*?'ZYL_MALI_FAITH_DESERT_HILLS'.*?'BBG_MALI_GOLD_DESERT_MINES'.*?'BBG_MALI_GOLD_DESERT_HILLS_MINES'") {
            $issues.Add('Final Mali override does not detach the superseded Desert Faith and Desert-only Mine modifiers.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SAHEL_MERCHANTS'.*?'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION'.*?'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION_BUILDING'") {
            $issues.Add('Final Mansa Musa override does not remove both Holy Site Production modifiers.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s+AND\s+ModifierId\s*=\s*'BBG_COLUMBIA_MOVEMENT_BONUS'.*?INSERT\s+OR\s+IGNORE\s+INTO\s+TraitModifiers\s*\(\s*TraitType\s*,\s*ModifierId\s*\)\s+VALUES\s*\(\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s*,\s*'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT'\s*\)") {
            $issues.Add('Final Gran Colombia override does not restore the original all-unit movement trait attachment.')
        }
        if ($gameplayOverrideSql -notmatch "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING'\s*;") {
            $issues.Add('Final Trajan override does not unlock the free City Center building at Foreign Trade.')
        }
        if ($gameplayOverrideSql -match "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING'") {
            $issues.Add('Final Trajan override still unlocks the free City Center building at Early Empire.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SUK_GALLIC_WAR'\s+AND\s+ModifierId\s*=\s*'GAUL_MINE_CULTURE'") {
            $issues.Add('Final Gaul override does not detach GAUL_MINE_CULTURE from Vercingetorix.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)UPDATE\s+Modifiers\s+SET\s+ModifierType\s*=\s*'MODIFIER_PLAYER_ADJUST_PLOT_YIELD'\s*,\s*OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING'\s*,\s*SubjectRequirementSetId\s*=\s*'PLOT_HAS_MINE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'GAUL_MINE_CULTURE'") {
            $issues.Add('Final Gaul override does not lock GAUL_MINE_CULTURE to Bronze Working and Mine plots.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)\('GAUL_MINE_CULTURE'\s*,\s*'YieldType'\s*,\s*'YIELD_CULTURE'\).*?\('GAUL_MINE_CULTURE'\s*,\s*'Amount'\s*,\s*1\).*?\('TRAIT_CIVILIZATION_GAUL'\s*,\s*'GAUL_MINE_CULTURE'\)") {
            $issues.Add('Final Gaul override does not lock the +1 Culture argument and civilization-trait attachment.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_MONASTERIES_KING'.*?ModifierId\s*=\s*'TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY'.*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'Amount'\s*,\s*1\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_HOLY_SITE'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'YieldType'\s*,\s*'YIELD_FAITH'\).*?\('TRAIT_CIVILIZATION_KHMER_BARAYS'\s*,\s*'ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\)") {
            $issues.Add('Final Khmer override does not provide the standard +1 river Holy Site Faith bonus on the civilization trait.')
        }
        if ($gameplayOverrideSql -match "(?s)\('TRAIT_LEADER_MONASTERIES_KING'\s*,\s*'TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY'\)") {
            $issues.Add('Final Khmer override still attaches the old river Holy Site Faith modifier to Jayavarman.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)UPDATE\s+ModifierArguments\s+SET\s+Value\s*=\s*1\s+WHERE\s+ModifierId\s+IN\s*\(\s*'TRAIT_TRADE_FOOD_FROM_CAMPS'\s*,\s*'TRAIT_TRADE_FOOD_FROM_PASTURES'\s*\)\s+AND\s+Name\s*=\s*'Amount'") {
            $issues.Add('Final Cree override does not restore outgoing Camp/Pasture Trade Route Food to +1.')
        }
        if ($gameplayOverrideSql -match "(?s)UPDATE\s+Modifiers\s+SET(?:(?!;).)*SubjectStackLimit(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_CAMPS'(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_PASTURES'(?:(?!;).)*;") {
            $issues.Add('Final Cree override incorrectly uses a modifier stack limit as an improvement-count cap.')
        }
        foreach ($maliCityFaithBinding in @(
            @('ZYL_MALI_DESERT_CITY_CENTER_FAITH', 'ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS', 'REQUIRES_PLOT_HAS_DESERT'),
            @('ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH', 'ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS', 'REQUIRES_PLOT_HAS_DESERT_HILLS')
        )) {
            $modifierId = [regex]::Escape($maliCityFaithBinding[0])
            $requirementSetId = [regex]::Escape($maliCityFaithBinding[1])
            $terrainRequirementId = [regex]::Escape($maliCityFaithBinding[2])
            if ($gameplayOverrideSql -notmatch "(?s)\('ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER'\s*,\s*'REQUIREMENT_PLOT_DISTRICT_TYPE_MATCHES'\).*?\('ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_CITY_CENTER'\).*?\('$requirementSetId'\s*,\s*'$terrainRequirementId'\).*?\('$requirementSetId'\s*,\s*'ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER'\).*?\('$modifierId'\s*,\s*'MODIFIER_PLAYER_ADJUST_PLOT_YIELD'\s*,\s*'$requirementSetId'\).*?\('$modifierId'\s*,\s*'YieldType'\s*,\s*'YIELD_FAITH'\).*?\('$modifierId'\s*,\s*'Amount'\s*,\s*2\).*?\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'$modifierId'\)") {
                $issues.Add("Mali Desert City Center +2 Faith binding is incomplete: $($maliCityFaithBinding[0])")
            }
        }
        if ($gameplayOverrideSql -notmatch "(?s)\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'TRAIT_MALI_MINES_PRODUCTION'\).*?\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'TRAIT_MALI_MINES_GOLD'\).*?SET\s+SubjectRequirementSetId\s*=\s*'PLOT_HAS_MINE_REQUIREMENTS'.*?WHERE\s+ModifierId\s+IN\s*\(\s*'TRAIT_MALI_MINES_PRODUCTION'\s*,\s*'TRAIT_MALI_MINES_GOLD'\s*\)") {
            $issues.Add('Mali original Mine modifiers are not attached with an all-Mines scope.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)ModifierArguments\s*\(\s*ModifierId\s*,\s*Name\s*,\s*Value\s*\).*?'TRAIT_MALI_MINES_PRODUCTION'\s*,\s*'YieldType'\s*,\s*'YIELD_PRODUCTION'.*?'TRAIT_MALI_MINES_PRODUCTION'\s*,\s*'Amount'\s*,\s*-1.*?'TRAIT_MALI_MINES_GOLD'\s*,\s*'YieldType'\s*,\s*'YIELD_GOLD'.*?'TRAIT_MALI_MINES_GOLD'\s*,\s*'Amount'\s*,\s*4") {
            $issues.Add('Mali Mine yields are not locked to -1 Production / +4 Gold.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s+IN\s*\(.*?'SUGUBA_CHEAPER_BUILDING_PURCHASE'.*?'SUGUBA_CHEAPER_DISTRICT_PURCHASE'.*?'SUGUBA_CHEAPER_UNIT_PURCHASE'.*?\)\s+AND\s+Name\s*=\s*'Amount'") {
            $issues.Add('Final Suguba purchase discount override is not locked to 10%.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)Feature_YieldChanges\s*\(\s*FeatureType\s*,\s*YieldType\s*,\s*YieldChange\s*\).*?'FEATURE_OASIS'\s*,\s*'YIELD_FOOD'\s*,\s*4.*?'FEATURE_OASIS'\s*,\s*'YIELD_GOLD'\s*,\s*1") {
            $issues.Add('Global Oasis feature yields do not seed the required 4 Food / 1 Gold values.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+YieldChange\s*=\s*4\s+WHERE\s+FeatureType\s*=\s*'FEATURE_OASIS'\s+AND\s+YieldType\s*=\s*'YIELD_FOOD'.*?SET\s+YieldChange\s*=\s*1\s+WHERE\s+FeatureType\s*=\s*'FEATURE_OASIS'\s+AND\s+YieldType\s*=\s*'YIELD_GOLD'") {
            $issues.Add('Global Oasis feature yields are not forced to exactly 4 Food / 1 Gold.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)\('ZYL_RUSSIA_FLAT_TUNDRA_CITY_HAS_LAVRA'\s*,\s*'REQUIRES_PLOT_HAS_TUNDRA'\).*?\('ZYL_RUSSIA_FLAT_TUNDRA_CITY_HAS_LAVRA'\s*,\s*'BBG_CITY_HAS_DISTRICT_LAVRA_REQUIREMENT'\).*?\('ZYL_RUSSIA_TUNDRA_HILLS_CITY_HAS_LAVRA'\s*,\s*'REQUIRES_PLOT_HAS_TUNDRA_HILLS'\).*?\('ZYL_RUSSIA_TUNDRA_HILLS_CITY_HAS_LAVRA'\s*,\s*'BBG_CITY_HAS_DISTRICT_LAVRA_REQUIREMENT'\)") {
            $issues.Add('Russia Tundra Faith requirement sets must require the terrain and a Lavra in the owning city.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'ZYL_RUSSIA_FLAT_TUNDRA_CITY_HAS_LAVRA'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_INCREASED_TUNDRA_FAITH'.*?SET\s+SubjectRequirementSetId\s*=\s*'ZYL_RUSSIA_TUNDRA_HILLS_CITY_HAS_LAVRA'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_INCREASED_TUNDRA_HILLS_FAITH'") {
            $issues.Add('Russia Tundra Faith modifiers are not bound to the Lavra-city terrain sets.')
        }
        foreach ($russiaFaithSet in @('ZYL_RUSSIA_FLAT_TUNDRA_CITY_HAS_LAVRA', 'ZYL_RUSSIA_TUNDRA_HILLS_CITY_HAS_LAVRA')) {
            if ($gameplayOverrideSql.Contains("('$russiaFaithSet', 'BBG_REQUIRES_DISTRICT_IS_NOT_CITY_CENTER')")) {
                $issues.Add("Russia Lavra-city Tundra Faith incorrectly excludes the City Center: $russiaFaithSet")
            }
        }
        foreach ($obsoleteRussiaToken in @('ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE', 'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA', 'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_CITY_HAS_HOLY_SITE')) {
            if ($gameplayOverrideSql.Contains($obsoleteRussiaToken)) {
                $issues.Add("Russia Tundra Faith still contains obsolete adjacency logic: $obsoleteRussiaToken")
            }
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+StartBiasResources\s+WHERE\s+CivilizationType\s*=\s*'CIVILIZATION_FRANCE'.*?ResourceClassType\s*=\s*'RESOURCECLASS_LUXURY'") {
            $issues.Add('France does not clear its existing Luxury resource biases before rebuilding them.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasResources\s*\(\s*CivilizationType\s*,\s*ResourceType\s*,\s*Tier\s*\)\s*SELECT\s*'CIVILIZATION_FRANCE'\s*,\s*ResourceType\s*,\s*4\s+FROM\s+Resources\s+WHERE\s+ResourceClassType\s*=\s*'RESOURCECLASS_LUXURY'") {
            $issues.Add('France does not receive a civilization-wide T4 bias for every active Luxury resource.')
        }
        $magnificenceRequirements = @(
            @('ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP', 'BBG_REQUIRES_PLOT_HAS_IMPROVED_LUXURY'),
            @('ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP', 'BBG_UTILS_PLAYER_HAS_CIVIC_CRAFTSMANSHIP_REQUIREMENT'),
            @('ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM', 'BBG_REQUIRES_PLOT_HAS_IMPROVED_BONUS'),
            @('ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM', 'BBG_UTILS_PLAYER_HAS_CIVIC_FEUDALISM_REQUIREMENT'),
            @('ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES', 'REQUIRES_PLOT_HAS_IMPROVED_STRATEGIC'),
            @('ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES', 'BBG_UTILS_PLAYER_HAS_TECH_CASTLES_REQUIREMENT')
        )
        foreach ($binding in $magnificenceRequirements) {
            $requirementSetId = [regex]::Escape($binding[0])
            $requirementId = [regex]::Escape($binding[1])
            if ($gameplayOverrideSql -notmatch "\('$requirementSetId'\s*,\s*'$requirementId'\)") {
                $issues.Add("Magnificence resource Culture requirement is missing: $($binding[0]) -> $($binding[1])")
            }
        }
        $magnificenceModifiers = @(
            @('BBG_MAGNIFICENCE_CULTURE_ON_LUX', 'ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP'),
            @('BBG_MAGNIFICENCE_CULTURE_ON_BONUS', 'ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM'),
            @('BBG_MAGNIFICENCE_CULTURE_ON_STRAT', 'ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES')
        )
        foreach ($binding in $magnificenceModifiers) {
            $modifierId = [regex]::Escape($binding[0])
            $requirementSetId = [regex]::Escape($binding[1])
            if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'$requirementSetId'\s+WHERE\s+ModifierId\s*=\s*'$modifierId'") {
                $issues.Add("Magnificence resource Culture modifier has the wrong unlock: $($binding[0])")
            }
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s*=\s*'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER'.*?DELETE\s+FROM\s+Modifiers\s+WHERE\s+ModifierId\s*=\s*'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER'") {
            $issues.Add('Malformed Scythia medieval ability giver is not removed.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ImprovementModifiers\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_MISSION'.*?'MISSION_NEWCONTINENT_FAITH'.*?'MISSION_NEWCONTINENT_FOOD'.*?'MISSION_NEWCONTINENT_PRODUCTION'") {
            $issues.Add('Spain Mission orphan modifier links are not removed.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'OPPONENT_IS_IN_GOLDEN_AGE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'BBG_SULEIMAN_COMBAT_BUFF'") {
            $issues.Add('Suleiman BBG combat bonus is not limited to opponents in Golden/Heroic Ages.')
        }
        if ($gameplayOverrideSql -match "(?s)SET\s+SubjectRequirementSetId\s*=\s*'OPPONENT_IS_NOT_IN_GOLDEN_AGE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'BBG_SULEIMAN_COMBAT_BUFF'") {
            $issues.Add('Suleiman +2 and +4 combat modifiers would overlap against Normal/Dark-Age opponents.')
        }
        if ($gameplayOverrideSql -notmatch "(?s)SET\s+OwnerRequirementSetId\s*=\s*'PLAYER_HAS_GOLDEN_AGE'\s+WHERE\s+ModifierId\s+IN\s*\(\s*'BBG_APPEAL_WYWH'\s*,\s*'BBG_AUTOMATON_GDR_PROD'\s*\)") {
            $issues.Add('Wish You Were Here Appeal and Automaton GDR production are not limited to Golden/Heroic Ages.')
        }
        $johannesburgOuterModifiers = @(
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX_BALLISTICS',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS_BALLISTICS',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT_BALLISTICS',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX_INDUS',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS_INDUS',
            'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT_INDUS'
        )
        $johannesburgInnerModifiers = @(
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_BALLISTICS',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_BALLISTICS',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_BALLISTICS',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_INDUS',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_INDUS',
            'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_INDUS'
        )
        foreach ($modifierId in $johannesburgOuterModifiers) {
            $escapedModifierId = [regex]::Escape($modifierId)
            if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s+IN\s*\(.*?'$escapedModifierId'.*?\)\s+AND\s+Name\s+IN\s*\(\s*'Amount'\s*,\s*'YieldType'\s*\)") {
                $issues.Add("Johannesburg attach modifier still risks consuming city-yield arguments: $modifierId")
            }
        }
        foreach ($modifierId in $johannesburgInnerModifiers) {
            $escapedModifierId = [regex]::Escape($modifierId)
            if ($gameplayOverrideSql -notmatch "\('$escapedModifierId'\s*,\s*'Amount'\s*,\s*'1'\)" -or
                    $gameplayOverrideSql -notmatch "\('$escapedModifierId'\s*,\s*'YieldType'\s*,\s*'YIELD_PRODUCTION'\)") {
                $issues.Add("Johannesburg city-yield modifier is missing Amount=1 or YieldType=YIELD_PRODUCTION: $modifierId")
            }
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s*=\s*'UNIQUE_LEADER_SPIES_START_PROMOTED'\s+AND\s+Name\s*=\s*'Amount'") {
            $issues.Add("France's attach modifier still carries the child experience argument.")
        }
        if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s+IN\s*\(\s*'CHICHEN_ITZA_JUNGLE_CULTURE'\s*,\s*'CHICHEN_ITZA_JUNGLE_PRODUCTION'\s*\)\s+AND\s+Name\s*=\s*'ModifierId'") {
            $issues.Add('Chichen Itza direct plot-yield modifiers still carry obsolete child-modifier links.')
        }
    }

    $bbgGovernorPath = Join-Path $modRoot 'Components\BBG\sql\XP1\Governors_XP1_or_XP2.sql'
    if (-not (Test-Path -LiteralPath $bbgGovernorPath)) {
        $issues.Add('BBG governor gameplay SQL is missing.')
    }
    else {
        $bbgGovernorSql = Get-Content -LiteralPath $bbgGovernorPath -Raw
        if ($bbgGovernorSql.Contains('BBG_MOKSHA_GREATPROPHET_POINT_FOR_HS')) {
            $issues.Add('Moksha still contains the unbound duplicate Great Prophet point attach chain.')
        }
        if ($bbgGovernorSql -notmatch "\(\s*'BBG_MOKSHA_PROPHET_POINTS'\s*,\s*'Amount'\s*,\s*2\s*\)" -or
            $bbgGovernorSql -notmatch "\(\s*'GOVERNOR_PROMOTION_CARDINAL_CITADEL_OF_GOD'\s*,\s*'BBG_MOKSHA_PROPHET_POINTS'\s*\)") {
            $issues.Add('Moksha Citadel of God must keep its effective local +2 Great Prophet point modifier.')
        }
    }

    return @($issues)
}
