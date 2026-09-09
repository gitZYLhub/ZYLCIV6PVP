function Get-ZylTeamPvpSecretSocietyContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [Parameter(Mandatory = $true)]
        [object]$CriteriaMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [AllowEmptyString()]
        [string]$GameplaySourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # Team PVP Secret Societies 3.93 and LightweightBalance resource harvesting
    # are local, mode-gated integration layers and must survive every ModInfo
    # regeneration.  Validate the high-risk balance values and all published
    # assets instead of relying on the upstream mod being installed.
    $teamPvpSocietyRoot = Join-Path $modRoot 'Components\TeamPVPSecretSocieties'
    $teamPvpSocietyPaths = @{
        Gameplay = Join-Path $teamPvpSocietyRoot 'Gameplay.sql'
        Building = Join-Path $teamPvpSocietyRoot 'Build_GildedShipyard.xml'
        Text = Join-Path $teamPvpSocietyRoot 'Text.xml'
        Icons = Join-Path $teamPvpSocietyRoot 'Icons.xml'
        Dependency = Join-Path $teamPvpSocietyRoot 'TeamPVPSecretSocieties.dep'
        Art = Join-Path $teamPvpSocietyRoot 'Buildings.artdef'
        TaoistUi = Join-Path $teamPvpSocietyRoot 'Taoist\UI\Taoist_UI.lua'
        TaoistGameplay = Join-Path $teamPvpSocietyRoot 'Taoist\Scripts\Taoist_Gameplay.lua'
        VampireCastleGameplay = Join-Path $teamPvpSocietyRoot 'Scripts\VampireCastle_Gameplay.lua'
    }
    foreach ($entry in $teamPvpSocietyPaths.GetEnumerator()) {
        if (-not (Test-Path -LiteralPath $entry.Value)) {
            $issues.Add("Team PVP Secret Societies $($entry.Key) resource is missing: $($entry.Value)")
        }
    }

    if ((Test-Path -LiteralPath $teamPvpSocietyPaths.TaoistUi -PathType Leaf) -and
            (Test-Path -LiteralPath $teamPvpSocietyPaths.TaoistGameplay -PathType Leaf)) {
        $taoistUiSource = Get-Content -LiteralPath $teamPvpSocietyPaths.TaoistUi -Raw
        $taoistGameplaySource = Get-Content `
            -LiteralPath $teamPvpSocietyPaths.TaoistGameplay -Raw
        foreach ($taoistRuntimeIssue in @(
                Get-ZylTaoistRuntimeContractIssues `
                    -UiSource $taoistUiSource `
                    -GameplaySource $taoistGameplaySource
            )) {
            $issues.Add($taoistRuntimeIssue)
        }
    }

    if (Test-Path -LiteralPath $teamPvpSocietyPaths.Dependency) {
        $teamPvpSocietyDep = Load-XmlDocument $teamPvpSocietyPaths.Dependency
        $teamPvpSocietyDepId = $teamPvpSocietyDep.SelectSingleNode('/*/ID/id')
        if ($null -eq $teamPvpSocietyDepId -or $teamPvpSocietyDepId.GetAttribute('text') -ne '8441e5c6-dae5-4fbc-b8d7-da3b9889df36') {
            $issues.Add('Team PVP Secret Societies art dependency has an unexpected or missing ID.')
        }
        if ($null -eq $teamPvpSocietyDep.SelectSingleNode('/*/RequiredGameArtIDs/Element[name/@text="Ethiopia" and id/@text="50320198-92ec-444f-805c-1b6f81dfb918"]')) {
            $issues.Add('Team PVP Secret Societies art dependency does not require the Ethiopia game-art package.')
        }
        if ($null -eq $teamPvpSocietyDep.SelectSingleNode('/*/ArtDefDependencies/Element[ArtDefPath/@text="Buildings.artdef"]')) {
            $issues.Add('Team PVP Secret Societies .dep does not publish Buildings.artdef.')
        }
        foreach ($consumerName in @('Landmarks', 'StrategicView_Sprite')) {
            if ($null -eq $teamPvpSocietyDep.SelectSingleNode("/*/SystemDependencies/Element[ConsumerName/@text='$consumerName' and ArtDefDependencyPaths/Element/@text='Buildings.artdef']")) {
                $issues.Add("Team PVP Secret Societies .dep does not route Buildings.artdef to $consumerName.")
            }
        }
    }

    if (Test-Path -LiteralPath $teamPvpSocietyPaths.Gameplay) {
        $teamPvpSocietySql = if ($PSBoundParameters.ContainsKey('GameplaySourceOverride')) {
            $GameplaySourceOverride
        } else {
            Get-Content -LiteralPath $teamPvpSocietyPaths.Gameplay -Raw
        }
        $requiredSocietySqlTokens = @(
            'DiscoverAtCityStateBaseChance = 100000',
            'DiscoverAtGoodyHutBaseChance = 100000',
            "WHERE GovernorPromotionType = 'GOVERNOR_PROMOTION_SANGUINE_PACT_2'",
            "SET BaseMoves = 2",
            "DELETE FROM GovernorPromotionModifiers",
            "WHERE ModifierId = 'SECRET_SOCIETY_VAMPIRE_ADDMOVE_TEAMPVP'",
            "('ROUTE_ANCIENT_ROAD', 'UNIT_VAMPIRE')",
            "('ROUTE_MEDIEVAL_ROAD', 'UNIT_VAMPIRE')",
            "('ROUTE_INDUSTRIAL_ROAD', 'UNIT_VAMPIRE')",
            "('ROUTE_MODERN_ROAD', 'UNIT_VAMPIRE')",
            "'SECRET_SOCIETIES_DISABLE_VAMPIRE_NORMAL_HEALING', 'Amount', -5",
            "'SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING', 'Amount', 50",
            "'SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING', 'Key', 'HEAL_ON_PILLAGE'",
            "'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT'",
            "'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT', 'Amount', 10",
            "'ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION', 'Amount', 15",
            "'ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION', 'Amount', 15",
            "'ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION', 'Amount', 1",
            "'ZYL_TPVP_SANGUINE_STABLE_PRODUCTION', 'Amount', 1",
            "'ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION', 'Amount', 2",
            "'ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION', 'Amount', 4",
            "'ZYL_TPVP_SANGUINE_MILITARY_POLICY_SLOT', 'GovernmentSlotType', 'SLOT_MILITARY'",
            "'ZYL_TPVP_SANGUINE_VAMPIRE_MOVEMENT', 'Amount', 1",
            "('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING')",
            "('GOVERNOR_PROMOTION_SANGUINE_PACT_2', 'SECRET_SOCIETY_GRANT_TWO_VAMPIRE_BUILDS')",
            "('GOVERNOR_PROMOTION_SANGUINE_PACT_3', 'SECRET_SOCIETY_GRANT_ONE_VAMPIRE_BUILD')",
            "('GOVERNOR_PROMOTION_SANGUINE_PACT_4', 'SECRET_SOCIETY_GRANT_ONE_VAMPIRE_BUILD')",
            "SET EarliestGameEra = 'ERA_RENAISSANCE'",
            "SET EarliestGameEra = 'ERA_INDUSTRIAL'",
            "WHERE BuildingType = 'BUILDING_GILDED_VAULT'",
            "PurchaseYield = 'YIELD_GOLD'",
            "'ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY_REQUIREMENT'",
            "'CivicType', 'CIVIC_POLITICAL_PHILOSOPHY'",
            "'ZYL_TPVP_OWLS_2_TRADE_ROUTE_CAPACITY'",
            "'ZYL_TPVP_PLAYER_HAS_GILDED_VAULT_REQUIREMENT'",
            "'ZYL_TPVP_OWLS_FIRST_GILDED_VAULT_TRADE_ROUTE_CAPACITY'",
            "'BUILDING_GILDED_VAULT_TRADE_ROUTE_CAPACITY'",
            "WHERE BuildingType = 'BUILDING_ALCHEMICAL_SOCIETY'",
            "WHEN 'YIELD_SCIENCE' THEN 4",
            "WHEN 'YIELD_PRODUCTION' THEN 2",
            "'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3_SPY_CAPACITY'",
            "'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_GOLD_INTEREST'",
            "'GOVERNOR_PROMOTION_VOIDSINGERS_2_GOLD_FROM_FAITH' THEN '10'",
            "'GOVERNOR_PROMOTION_VOIDSINGERS_2_SCIENCE_FROM_FAITH' THEN '10'",
            "'GOVERNOR_PROMOTION_VOIDSINGERS_2_CULTURE_FROM_FAITH' THEN '10'",
            "'ZYL_TPVP_VOIDSINGER_RELIC_PRODUCTION', 'YieldChange', 1",
            "'SANGUINE_PACT_VAMPIRE_COMBAT_STRENGTH_FROM_PROPERTY', 'Max', 3",
            "'SANGUINE_PACT_VAMPIRE_BARB_COMBAT_STRENGTH_FROM_PROPERTY'",
            "SET CanBuildOutsideTerritory = 0",
            'INSERT OR IGNORE INTO Improvement_ValidFeatures',
            'WHERE Removable = 1',
            'INSERT OR IGNORE INTO Improvement_ValidResources',
            "'RESOURCECLASS_BONUS'",
            "'RESOURCECLASS_LUXURY'",
            "'RESOURCECLASS_STRATEGIC'",
            "'UNIT_RETREAT_VAMPIRE_TO_CASTLE'",
            "'SECRET_SOCIETIES_ATTACH_PLAYER_CASTLES_GAIN_ADJACENT_YIELDS'",
            "'IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_FOOD', 9",
            "'IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_PRODUCTION', 5",
            "'RESOURCE_LEY_LINE', 'YIELD_GOLD', 40, NULL",
            "'IMPROVEMENT_FARM', 'RESOURCE_LEY_LINE', 0",
            "'BBG_BANK_TRADEROUTE_FROM_DOMESTIC'",
            "'BBG_BANK_TRADEROUTE_TO_DOMESTIC'",
            "'BBG_BANK_TRADEROUTE_FROM_INTERNATIONAL'",
            "'BBG_BANK_TRADEROUTE_TO_INTERNATIONAL'",
            "'BUILDING_IS_BANK', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT'",
            "'BUILDING_IS_SHIPYARD', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT'",
            "'BUILDING_IS_BANK_OR_SHIPYARD', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT'",
            "'BUILDING_IS_BANK_OR_SHIPYARD', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT'",
            "'BUILDING_BIG_BEN', 'BUILDING_GILDED_VAULT'",
            "'BUILDING_GILDED_Shipyard', 'BBG_SHIPYARD_FISHERY_PRODUCTION'",
            "ModifierId <> 'COAL_FROM_SHIPYARD_BBG'",
            "ModifierId LIKE 'ZYL_TPVP_GILDED_SHIPYARD_ADJ_%'",
            "'COAL_FROM_SHIPYARD_BBG'",
            "'ZYL_TPVP_MILITARYRESEARCH_GILDED_SHIPYARD_SCIENCE'",
            "'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION_ATTACH'",
            "'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD_ATTACH'",
            "'ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD', 'Amount', 4",
            "'ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD', 'Amount', 4"
        )
        foreach ($token in $requiredSocietySqlTokens) {
            if (-not $teamPvpSocietySql.Contains($token)) {
                $issues.Add("Team PVP Secret Societies SQL is missing required behavior: $token")
            }
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_1',\s*'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING'\)") {
            $issues.Add('Sanguine Pact advanced pillaging is not attached to tier 1.')
        }
        if ($teamPvpSocietySql -match "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_3',\s*'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING'\)") {
            $issues.Add('Sanguine Pact advanced pillaging must not remain attached to tier 3.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_1',\s*'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT_ATTACH'\)") {
            $issues.Add('Sanguine Pact combat-heal modifier is not attached to tier 1.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT_ATTACH',\s*'MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER',\s*'THIS_UNIT_IS_A_VAMPIRE'\)") {
            $issues.Add('Sanguine Pact combat healing is not restricted to Vampire units.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT',\s*'MODIFIER_PLAYER_UNIT_ADJUST_HEAL_FROM_COMBAT',\s*NULL\)") {
            $issues.Add('Sanguine Pact combat healing is not restricted to Vampire units.')
        }
        foreach ($sanguinePromotion in @(
            @{ Promotion = '1'; Modifier = 'ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION' },
            @{ Promotion = '1'; Modifier = 'ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION' },
            @{ Promotion = '1'; Modifier = 'ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION' },
            @{ Promotion = '1'; Modifier = 'ZYL_TPVP_SANGUINE_STABLE_PRODUCTION' },
            @{ Promotion = '2'; Modifier = 'ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION' },
            @{ Promotion = '2'; Modifier = 'ZYL_TPVP_SANGUINE_MILITARY_POLICY_SLOT' },
            @{ Promotion = '2'; Modifier = 'ZYL_TPVP_SANGUINE_VAMPIRE_MOVEMENT' },
            @{ Promotion = '3'; Modifier = 'ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION' }
        )) {
            $sanguineBindingPattern = "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_$($sanguinePromotion.Promotion)',\s*'$([regex]::Escape($sanguinePromotion.Modifier))'\)"
            if ($teamPvpSocietySql -notmatch $sanguineBindingPattern) {
                $issues.Add("Sanguine Pact tier $($sanguinePromotion.Promotion) is missing $($sanguinePromotion.Modifier).")
            }
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION',\s*'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION'\)") {
            $issues.Add('Sanguine Pact tier 1 does not use the building-production modifier for Encampment buildings.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION',\s*'DistrictType',\s*'DISTRICT_ENCAMPMENT'\).*?\('ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION',\s*'Amount',\s*15\)") {
            $issues.Add('Sanguine Pact Encampment-building Production bonus is not scoped to Encampments at +15%.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_SANGUINE_VAMPIRE_MOVEMENT',\s*'MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT',\s*'THIS_UNIT_IS_A_VAMPIRE'\)") {
            $issues.Add('Sanguine Pact vampire movement is not restricted to Vampire units.')
        }
        foreach ($otherSanguineTier in @('1', '3', '4')) {
            if ($teamPvpSocietySql -match "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_$otherSanguineTier',\s*'ZYL_TPVP_SANGUINE_VAMPIRE_MOVEMENT'\)") {
                $issues.Add("Sanguine Pact vampire movement must not be attached to tier $otherSanguineTier.")
            }
        }
        if ($teamPvpSocietySql -match "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_[1234]',\s*'SECRET_SOCIETY_VAMPIRE_ADDMOVE_TEAMPVP'\)") {
            $issues.Add('The upstream zero-value Vampire movement placeholder must not remain attached.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)UPDATE\s+Modifiers\s+SET\s+OwnerRequirementSetId\s*=\s*'ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY'\s+WHERE\s+ModifierId\s*=\s*'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_ECONOMIC_POLICY_SLOT'") {
            $issues.Add('Owls tier 1 economic policy slot is not delayed until Political Philosophy.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2',\s*'ZYL_TPVP_OWLS_2_TRADE_ROUTE_CAPACITY'\)") {
            $issues.Add('Owls tier 2 does not directly grant one Trade Route capacity.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_OWLS_2_TRADE_ROUTE_CAPACITY',\s*'Amount',\s*1\)") {
            $issues.Add('Owls tier 2 direct Trade Route capacity is not +1.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\(ModifierId,\s*ModifierType,\s*RunOnce,\s*Permanent,\s*OwnerRequirementSetId\)\s*VALUES\s*\(\s*'ZYL_TPVP_OWLS_FIRST_GILDED_VAULT_TRADE_ROUTE_CAPACITY',\s*'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_CAPACITY',\s*1,\s*1,\s*'ZYL_TPVP_PLAYER_HAS_GILDED_VAULT'\s*\)") {
            $issues.Add('The first-Gilded-Vault Trade Route modifier must be a permanent one-time player effect.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)\('GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2',\s*'ZYL_TPVP_OWLS_FIRST_GILDED_VAULT_TRADE_ROUTE_CAPACITY'\)") {
            $issues.Add('The first-Gilded-Vault Trade Route effect is not attached to Owls tier 2.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)DELETE\s+FROM\s+BuildingModifiers\s+WHERE\s+BuildingType\s*=\s*'BUILDING_GILDED_VAULT'\s+AND\s+ModifierId\s*=\s*'BUILDING_GILDED_VAULT_TRADE_ROUTE_CAPACITY'") {
            $issues.Add('The upstream per-Gilded-Vault Trade Route modifier is not removed.')
        }
        $bankTradeRouteModifiers = @(
            'BBG_BANK_TRADEROUTE_FROM_DOMESTIC',
            'BBG_BANK_TRADEROUTE_TO_DOMESTIC',
            'BBG_BANK_TRADEROUTE_FROM_INTERNATIONAL',
            'BBG_BANK_TRADEROUTE_TO_INTERNATIONAL'
        )
        foreach ($bankTradeRouteModifier in $bankTradeRouteModifiers) {
            $bankTradeRoutePattern = "(?is)SELECT\s+'BUILDING_GILDED_VAULT',\s*ModifierId\s+FROM\s+Modifiers\s+WHERE\s+ModifierId\s+IN\s*\((?:(?!\);).)*'$([regex]::Escape($bankTradeRouteModifier))'(?:(?!\);).)*\)"
            if ($teamPvpSocietySql -notmatch $bankTradeRoutePattern) {
                $issues.Add("The Gilded Vault is missing BBG Bank Trade Route parity: $bankTradeRouteModifier")
            }
        }
        if ($teamPvpSocietySql -notmatch "(?is)UPDATE\s+RequirementSets\s+SET\s+RequirementSetType\s*=\s*'REQUIREMENTSET_TEST_ANY'\s+WHERE\s+RequirementSetId\s+IN\s*\(\s*'BUILDING_IS_BANK'\s*,\s*'BUILDING_IS_SHIPYARD'\s*\)") {
            $issues.Add('Bank/Shipyard compatibility requirement sets are not converted to alternative-building checks.')
        }
        foreach ($compatibilitySpec in @(
            [pscustomobject]@{ Set = 'BUILDING_IS_BANK'; Requirement = 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT'; Building = 'BUILDING_GILDED_VAULT' },
            [pscustomobject]@{ Set = 'BUILDING_IS_SHIPYARD'; Requirement = 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT'; Building = 'BUILDING_GILDED_Shipyard' }
        )) {
            if ($teamPvpSocietySql -notmatch "(?is)\('$([regex]::Escape($compatibilitySpec.Requirement))',\s*'BuildingType',\s*'$([regex]::Escape($compatibilitySpec.Building))'\)") {
                $issues.Add("$($compatibilitySpec.Requirement) does not target $($compatibilitySpec.Building).")
            }
            if ($teamPvpSocietySql -notmatch "(?is)SELECT\s+'$([regex]::Escape($compatibilitySpec.Set))',\s*'$([regex]::Escape($compatibilitySpec.Requirement))'") {
                $issues.Add("$($compatibilitySpec.Set) does not include $($compatibilitySpec.Building).")
            }
        }
        foreach ($dramaticRequirement in @(
            'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT',
            'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT'
        )) {
            if ($teamPvpSocietySql -notmatch "(?is)SELECT\s+'BUILDING_IS_BANK_OR_SHIPYARD',\s*'$([regex]::Escape($dramaticRequirement))'") {
                $issues.Add("Dramatic Ages Bank/Shipyard compatibility is missing: $dramaticRequirement")
            }
        }
        if ($teamPvpSocietySql -notmatch "(?is)SELECT\s+'BUILDING_GILDED_Shipyard',\s*ModifierId\s+FROM\s+BuildingModifiers\s+WHERE\s+BuildingType\s*=\s*'BUILDING_SHIPYARD'\s+AND\s+ModifierId\s*<>\s*'COAL_FROM_SHIPYARD_BBG'") {
            $issues.Add('Direct regular-Shipyard building modifiers are not copied to the Gilded Shipyard with the duplicate Coal effect excluded.')
        }
        if ($teamPvpSocietySql -notmatch "(?is)SELECT\s+'BUILDING_BIG_BEN',\s*'BUILDING_GILDED_VAULT'") {
            $issues.Add('Big Ben does not accept the Gilded Vault as its Bank replacement prerequisite.')
        }
        foreach ($tradeCityStateSpec in @(
            [pscustomobject]@{ Modifier = 'ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD'; Building = 'BUILDING_GILDED_VAULT' },
            [pscustomobject]@{ Modifier = 'ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD'; Building = 'BUILDING_GILDED_Shipyard' }
        )) {
            if ($teamPvpSocietySql -notmatch "(?is)\('$([regex]::Escape($tradeCityStateSpec.Modifier))',\s*'BuildingType',\s*'$([regex]::Escape($tradeCityStateSpec.Building))'\).*?\('$([regex]::Escape($tradeCityStateSpec.Modifier))',\s*'Amount',\s*4\).*?\('$([regex]::Escape($tradeCityStateSpec.Modifier))',\s*'CityStatesOnly',\s*1\)") {
                $issues.Add("Trade City-State +4 Gold parity is malformed for $($tradeCityStateSpec.Building).")
            }
        }
        if ($teamPvpSocietySql -match 'ZYL_TPVP_GILDED_SHIPYARD_ADJ_[0-9]') {
            $issues.Add('The obsolete threshold-based Gilded Shipyard adjacency implementation is still present.')
        }
        foreach ($buildingType in @('BUILDING_GILDED_VAULT', 'BUILDING_GILDED_Shipyard')) {
            $goldPurchasePattern = "(?is)UPDATE\s+Buildings\s+SET(?:(?!;).)*PurchaseYield\s*=\s*'YIELD_GOLD'(?:(?!;).)*WHERE\s+BuildingType\s*=\s*'$([regex]::Escape($buildingType))'\s*;"
            if ($teamPvpSocietySql -notmatch $goldPurchasePattern) {
                $issues.Add("$buildingType is not pinned to Gold purchasing in the final Team PVP gameplay layer.")
            }
        }
        foreach ($outOfScopeToken in @(
            'TRAIT_LITHUANIANUNION_COMPLETE_RELIGION_RELIC_CPLMOD',
            'MESSENGER_GRANT_FREE_ENVOYS',
            'SIMULTANEUM_BUILDING_YIELDS_HIGH_ADJACENCY'
        )) {
            if ($teamPvpSocietySql.Contains($outOfScopeToken)) {
                $issues.Add("Unrelated upstream balance leaked into Secret Societies SQL: $outOfScopeToken")
            }
        }
        if ($teamPvpSocietySql.Contains('CIVIC_GRANT_PLAYER_GOVERNOR_POINTS')) {
            $issues.Add('Secret Society title refunds are duplicated outside the BBG-owned integration file.')
        }
    }

    if (Test-Path -LiteralPath $teamPvpSocietyPaths.VampireCastleGameplay) {
        $vampireCastleGameplay = Get-Content -LiteralPath $teamPvpSocietyPaths.VampireCastleGameplay -Raw
        foreach ($token in @(
            'IMPROVEMENT_VAMPIRE_CASTLE',
            'RESOURCECLASS_BONUS',
            'RESOURCECLASS_LUXURY',
            'RESOURCECLASS_STRATEGIC',
            'ResourceBuilder.SetResourceType(plot, -1)',
            'TerrainBuilder.SetFeatureType(plot, -1)',
            'Events.ImprovementAddedToMap.Add(OnVampireCastleAdded)'
        )) {
            if (-not $vampireCastleGameplay.Contains($token)) {
                $issues.Add("Vampire Castle tile-clearing script is missing required behavior: $token")
            }
        }

    }

    if (Test-Path -LiteralPath $teamPvpSocietyPaths.Building) {
        $gildedShipyard = Load-XmlDocument $teamPvpSocietyPaths.Building
        $gildedShipyardRow = $gildedShipyard.SelectSingleNode("/GameInfo/Buildings/Row[@BuildingType='BUILDING_GILDED_Shipyard']")
        if ($null -eq $gildedShipyardRow -or $gildedShipyardRow.GetAttribute('Cost') -ne '250') {
            $issues.Add('The Team PVP Gilded Shipyard must exist at its effective 250 Production cost.')
        }
        if ($null -eq $gildedShipyardRow -or $gildedShipyardRow.GetAttribute('PurchaseYield') -ne 'YIELD_GOLD') {
            $issues.Add('The Team PVP Gilded Shipyard must be purchasable with Gold.')
        }
        foreach ($yield in @{
            YIELD_FOOD = '1'
            YIELD_PRODUCTION = '1'
        }.GetEnumerator()) {
            $yieldRow = $gildedShipyard.SelectSingleNode("/GameInfo/Building_YieldChanges/Row[@BuildingType='BUILDING_GILDED_Shipyard' and @YieldType='$($yield.Key)']")
            if ($null -eq $yieldRow -or $yieldRow.GetAttribute('YieldChange') -ne $yield.Value) {
                $issues.Add("Gilded Shipyard base $($yield.Key) must be $($yield.Value).")
            }
        }
        $yieldDistrictCopyRows = @($gildedShipyard.SelectNodes("/GameInfo/Building_YieldDistrictCopies/Row[@BuildingType='BUILDING_GILDED_Shipyard']"))
        if ($yieldDistrictCopyRows.Count -ne 1 -or
                $yieldDistrictCopyRows[0].GetAttribute('OldYieldType') -ne 'YIELD_GOLD' -or
                $yieldDistrictCopyRows[0].GetAttribute('NewYieldType') -ne 'YIELD_PRODUCTION') {
            $issues.Add('The Gilded Shipyard must use one native Harbor Gold-adjacency to Production copy row.')
        }
        if ($null -eq $gildedShipyard.SelectSingleNode("/GameInfo/BuildingReplaces/Row[@CivUniqueBuildingType='BUILDING_GILDED_Shipyard' and @ReplacesBuildingType='BUILDING_SHIPYARD']")) {
            $issues.Add('The Gilded Shipyard is not registered as a native Shipyard replacement for Great-Person and boost compatibility.')
        }
        if ($null -eq $gildedShipyard.SelectSingleNode("/GameInfo/ModifierArguments/Row[@ModifierId='ZYL_TPVP_UNLOCK_GILDED_SHIPYARD' and @Name='BuildingTypeToReplace' and @Value='BUILDING_SHIPYARD']")) {
            $issues.Add('The Owls unlock modifier does not identify the regular Shipyard as the building being replaced.')
        }
    }

    if (Test-Path -LiteralPath $teamPvpSocietyPaths.Text) {
        $teamPvpSocietyText = Load-XmlDocument $teamPvpSocietyPaths.Text
        foreach ($language in @('en_US', 'zh_Hans_CN', 'zh_Hant_HK')) {
            foreach ($tag in @(
                'LOC_BUILDING_GILDED_Shipyard_DESCRIPTION',
                'LOC_BUILDING_GILDED_VAULT_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_HERMETIC_ORDER_1_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_HERMETIC_ORDER_4_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_VOIDSINGERS_3_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_VOIDSINGERS_4_DESCRIPTION',
                'LOC_UNIT_VAMPIRE_DESCRIPTION',
                'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_4_DESCRIPTION',
                'LOC_IMPROVEMENT_VAMPIRE_CASTLE_DESCRIPTION'
            )) {
                if ($null -eq $teamPvpSocietyText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='$tag' and @Language='$language']/Text")) {
                    $issues.Add("Team PVP Secret Societies localization is missing $tag for $language.")
                }
            }
        }
        $owlsTextChecks = @(
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_DESCRIPTION'; Tokens = @('Political Philosophy', 'Economic policy slot') },
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_DESCRIPTION'; Tokens = @('+1 [ICON_TradeRoute] Trade Route capacity') },
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_BUILDING_GILDED_VAULT_DESCRIPTION'; Tokens = @('originating in this city gain +2 [ICON_Gold]', 'ending in this city gain +1 [ICON_Gold]', 'first Gilded Vault', 'permanently grants +1 [ICON_TradeRoute]') },
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_BUILDING_GILDED_Shipyard_DESCRIPTION'; Tokens = @("Harbor's current [ICON_Gold] Gold adjacency bonus", 'including adjacency policy effects') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_DESCRIPTION'; Tokens = @('政治哲学', '经济政策槽位') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_DESCRIPTION'; Tokens = @('+1 [ICON_TradeRoute] 贸易路线容量') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_BUILDING_GILDED_VAULT_DESCRIPTION'; Tokens = @('从该城出发的贸易路线+2 [ICON_Gold]', '到达该城的贸易路线+1 [ICON_Gold]', '首次建成镀金宝库', '永久+1 [ICON_TradeRoute]') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_BUILDING_GILDED_Shipyard_DESCRIPTION'; Tokens = @('港口当前 [ICON_Gold] 金币相邻加成', '包括相邻加成政策的效果') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_DESCRIPTION'; Tokens = @('政治哲學', '經濟政策槽位') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_DESCRIPTION'; Tokens = @('+1 [ICON_TradeRoute] 貿易路線容量') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_BUILDING_GILDED_VAULT_DESCRIPTION'; Tokens = @('從該城出發的貿易路線+2 [ICON_Gold]', '到達該城的貿易路線+1 [ICON_Gold]', '首次建成鍍金寶庫', '永久+1 [ICON_TradeRoute]') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_BUILDING_GILDED_Shipyard_DESCRIPTION'; Tokens = @('港口當前 [ICON_Gold] 金幣相鄰加成', '包括相鄰加成政策的效果') }
        )
        foreach ($owlsTextCheck in $owlsTextChecks) {
            $owlsTextNode = $teamPvpSocietyText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='$($owlsTextCheck.Tag)' and @Language='$($owlsTextCheck.Language)']/Text")
            if ($null -eq $owlsTextNode) {
                $issues.Add("Owls localization is missing $($owlsTextCheck.Tag) for $($owlsTextCheck.Language).")
            }
            else {
                foreach ($owlsTextToken in $owlsTextCheck.Tokens) {
                    if (-not $owlsTextNode.InnerText.Contains($owlsTextToken)) {
                        $issues.Add("Owls localization $($owlsTextCheck.Tag) for $($owlsTextCheck.Language) is missing: $owlsTextToken")
                    }
                }
            }
        }
        $sanguineTextChecks = @(
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_UNIT_VAMPIRE_DESCRIPTION'; Tokens = @('2 [ICON_Movement]') },
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'; Tokens = @('2 [ICON_Movement]', '10 HP', '50 HP', '1 [ICON_Movement]', '+15% [ICON_Production]', 'buildings in Encampments') },
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'; Tokens = @('maximum of 2', '+1 [ICON_Movement]', '+2 [ICON_Production]', 'Military policy') },
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_3_DESCRIPTION'; Tokens = @('maximum to 3', '+4 [ICON_Production]') },
            [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_4_DESCRIPTION'; Tokens = @('Industrial Era', 'maximum to 4') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_UNIT_VAMPIRE_DESCRIPTION'; Tokens = @('2 [ICON_Movement]') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'; Tokens = @('2 [ICON_Movement]', '10点生命值', '50点生命值', '1 [ICON_Movement]', '军营及其中建筑时+15%') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'; Tokens = @('最多2座', '+1 [ICON_Movement]', '兵工厂+2', '军事政策槽位') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_3_DESCRIPTION'; Tokens = @('上限提高至3座', '军事学院+4') },
            [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_4_DESCRIPTION'; Tokens = @('工业时代', '上限提高至4座') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_UNIT_VAMPIRE_DESCRIPTION'; Tokens = @('2 [ICON_Movement]') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'; Tokens = @('2 [ICON_Movement]', '10生命', '50生命', '1 [ICON_Movement]', '軍營及其中建築時+15%') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'; Tokens = @('最多2座', '+1 [ICON_Movement]', '兵工廠+2', '軍事政策槽位') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_3_DESCRIPTION'; Tokens = @('上限提高至3座', '軍事學院+4') },
            [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_4_DESCRIPTION'; Tokens = @('工業時代', '上限提高至4座') }
        )
        foreach ($sanguineTextCheck in $sanguineTextChecks) {
            $sanguineTextNode = $teamPvpSocietyText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='$($sanguineTextCheck.Tag)' and @Language='$($sanguineTextCheck.Language)']/Text")
            if ($null -eq $sanguineTextNode) {
                $issues.Add("Sanguine Pact localization is missing $($sanguineTextCheck.Tag) for $($sanguineTextCheck.Language).")
            }
            else {
                foreach ($sanguineTextToken in $sanguineTextCheck.Tokens) {
                    if (-not $sanguineTextNode.InnerText.Contains($sanguineTextToken)) {
                        $issues.Add("Sanguine Pact localization $($sanguineTextCheck.Tag) for $($sanguineTextCheck.Language) is missing: $sanguineTextToken")
                    }
                }
            }
        }
        foreach ($legacyMovementTextSpec in @(
            @('en_US', 'LOC_UNIT_VAMPIRE_DESCRIPTION'),
            @('en_US', 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'),
            @('en_US', 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'),
            @('zh_Hans_CN', 'LOC_UNIT_VAMPIRE_DESCRIPTION'),
            @('zh_Hans_CN', 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'),
            @('zh_Hans_CN', 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'),
            @('zh_Hant_HK', 'LOC_UNIT_VAMPIRE_DESCRIPTION'),
            @('zh_Hant_HK', 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'),
            @('zh_Hant_HK', 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION')
        )) {
            $legacyMovementTextNode = $teamPvpSocietyText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='$($legacyMovementTextSpec[1])' and @Language='$($legacyMovementTextSpec[0])']/Text")
            if ($null -ne $legacyMovementTextNode -and $legacyMovementTextNode.InnerText.Contains('3 [ICON_Movement]')) {
                $issues.Add("Sanguine Pact localization still claims 3 base movement: $($legacyMovementTextSpec[1]) for $($legacyMovementTextSpec[0]).")
            }
        }
        foreach ($entry in @{
            en_US = 'Fisheries'
            zh_Hans_CN = '渔场'
            zh_Hant_HK = '漁場'
        }.GetEnumerator()) {
            $gildedShipyardText = $teamPvpSocietyText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='LOC_BUILDING_GILDED_Shipyard_DESCRIPTION' and @Language='$($entry.Key)']/Text")
            if ($null -eq $gildedShipyardText -or -not $gildedShipyardText.InnerText.Contains($entry.Value)) {
                $issues.Add("Gilded Shipyard localization for $($entry.Key) does not mention its Fishery Production bonus.")
            }
        }
    }

    $resourceHarvestPath = Join-Path $modRoot 'sql\ZYL_ResourceHarvests.sql'
    if (-not (Test-Path -LiteralPath $resourceHarvestPath)) {
        $issues.Add('LightweightBalance luxury/strategic resource harvest SQL is missing.')
    }
    else {
        $resourceHarvestSql = Get-Content -LiteralPath $resourceHarvestPath -Raw
        foreach ($token in @(
            'INSERT OR REPLACE INTO Resource_Harvests',
            "'RESOURCECLASS_STRATEGIC' THEN 'YIELD_PRODUCTION'",
            "'RESOURCECLASS_LUXURY' THEN 'YIELD_GOLD'",
            "'RESOURCE_CINNAMON'",
            "'RESOURCE_TOYS'"
        )) {
            if (-not $resourceHarvestSql.Contains($token)) {
                $issues.Add("Resource harvest SQL is missing required behavior: $token")
            }
        }
    }

    # The ModInfo mode gate and action graph live next to the payload checks so
    # this vertical contract cannot drift into a partially loaded integration.
    $secretSocietyCriterion = $criteriaMap['zyl_secretsocietiesxp2']
    if ($null -eq $secretSocietyCriterion -or
            $secretSocietyCriterion.SelectSingleNode("./RuleSetInUse[.='RULESET_EXPANSION_2']") -eq $null -or
            $secretSocietyCriterion.SelectSingleNode("./ModInUse[.='1B394FE9-23DC-4868-8F0A-5220CB8FB427']") -eq $null -or
            $secretSocietyCriterion.SelectSingleNode("./ConfigurationValueMatches[ConfigurationId='GAMEMODE_SECRETSOCIETIES' and Value='1']") -eq $null) {
        $issues.Add('Team PVP society integration is not gated by Gathering Storm, Ethiopia and the Secret Societies game mode.')
    }

    $expectedTeamPvpActions = @{
        'zyl_resourceharvests' = 'sql/ZYL_ResourceHarvests.sql'
        'zyl_tpvp_secretsocietiesart' = 'Components/TeamPVPSecretSocieties/TeamPVPSecretSocieties.dep'
        'zyl_tpvp_gildedshipyard' = 'Components/TeamPVPSecretSocieties/Build_GildedShipyard.xml'
        'zyl_tpvp_secretsocietiesgameplay' = 'Components/TeamPVPSecretSocieties/Gameplay.sql'
        'zyl_tpvp_taoistui' = 'Components/TeamPVPSecretSocieties/Taoist/UI/Taoist_UI.xml'
        'zyl_tpvp_taoistgameplay' = 'Components/TeamPVPSecretSocieties/Taoist/Scripts/Taoist_Gameplay.lua'
        'zyl_tpvp_vampirecastlegameplay' = 'Components/TeamPVPSecretSocieties/Scripts/VampireCastle_Gameplay.lua'
        'zyl_tpvp_secretsocietiestext' = 'Components/TeamPVPSecretSocieties/Text.xml'
        'zyl_tpvp_secretsocietiesicons' = 'Components/TeamPVPSecretSocieties/Icons.xml'
    }
    foreach ($entry in $expectedTeamPvpActions.GetEnumerator()) {
        $action = $actionIdMap[$entry.Key]
        if ($null -eq $action -or $action.SelectSingleNode("./File[.='$($entry.Value)']") -eq $null) {
            $issues.Add("Required Team PVP/LightweightBalance action is missing: $($entry.Key)")
        }
        if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $entry.Value))) {
            $issues.Add("Required Team PVP/LightweightBalance file is absent from the manifest: $($entry.Value)")
        }
    }

    $teamPvpArtAction = $actionIdMap['zyl_tpvp_secretsocietiesart']
    if ($null -eq $teamPvpArtAction -or
            $teamPvpArtAction.LocalName -ne 'UpdateArt' -or
            $teamPvpArtAction.ParentNode.LocalName -ne 'InGameActions' -or
            $null -eq $teamPvpArtAction.SelectSingleNode("./Criteria[.='ZYL_SecretSocietiesXP2']")) {
        $issues.Add('Team PVP Secret Societies art is not loaded in-game through its mode-gated .dep manifest.')
    }
    $vampireCastleGameplayAction = $actionIdMap['zyl_tpvp_vampirecastlegameplay']
    if ($null -eq $vampireCastleGameplayAction -or
            $vampireCastleGameplayAction.LocalName -ne 'AddGameplayScripts' -or
            $vampireCastleGameplayAction.ParentNode.LocalName -ne 'InGameActions' -or
            $null -eq $vampireCastleGameplayAction.SelectSingleNode("./Criteria[.='ZYL_SecretSocietiesXP2']")) {
        $issues.Add('Vampire Castle tile clearing is not loaded as a mode-gated in-game gameplay script.')
    }
    $taoistUiAction = $actionIdMap['zyl_tpvp_taoistui']
    if ($null -eq $taoistUiAction -or
            $taoistUiAction.LocalName -ne 'AddUserInterfaces' -or
            $taoistUiAction.ParentNode.LocalName -ne 'InGameActions' -or
            $null -eq $taoistUiAction.SelectSingleNode("./Criteria[.='ZYL_SecretSocietiesXP2']")) {
        $issues.Add('Taoist UI is not loaded as a mode-gated in-game interface.')
    }
    $taoistGameplayAction = $actionIdMap['zyl_tpvp_taoistgameplay']
    if ($null -eq $taoistGameplayAction -or
            $taoistGameplayAction.LocalName -ne 'AddGameplayScripts' -or
            $taoistGameplayAction.ParentNode.LocalName -ne 'InGameActions' -or
            $null -eq $taoistGameplayAction.SelectSingleNode("./Criteria[.='ZYL_SecretSocietiesXP2']")) {
        $issues.Add('Taoist gameplay is not loaded as a mode-gated in-game script.')
    }
    $teamPvpArtDefRelativePath = Normalize-RelativePath 'Components/TeamPVPSecretSocieties/Buildings.artdef'
    if (-not $listedFileMap.ContainsKey($teamPvpArtDefRelativePath)) {
        $issues.Add('Team PVP Secret Societies Buildings.artdef is absent from the manifest.')
    }

    return @($issues)
}

function Get-ZylTaoistRuntimeContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$UiSource,

        [Parameter(Mandatory = $true)]
        [string]$GameplaySource
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $helperTokens = @(
        'local function GetTaoistConfigurationValue(optionId, defaultValue)',
        'local value = GameConfiguration.GetValue(optionId)',
        'if value == nil then',
        'return defaultValue',
        'return value'
    )
    foreach ($sourceSpec in @(
        [pscustomobject]@{ Label = 'Taoist UI'; Source = $UiSource },
        [pscustomobject]@{ Label = 'Taoist gameplay'; Source = $GameplaySource }
    )) {
        foreach ($token in $helperTokens) {
            if (-not $sourceSpec.Source.Contains($token)) {
                $issues.Add("$($sourceSpec.Label) is missing the single-read configuration helper: $token")
            }
        }
    }

    foreach ($optionSpec in @(
        [pscustomobject]@{ Source = $UiSource; Id = 'Taoist_RigidTerrain'; Default = 'true' },
        [pscustomobject]@{ Source = $UiSource; Id = 'Taoist_SeaLeyline'; Default = 'true' },
        [pscustomobject]@{ Source = $UiSource; Id = 'Taoist_NoDistrict'; Default = 'true' },
        [pscustomobject]@{ Source = $UiSource; Id = 'Taoist_NoImprovement'; Default = 'true' },
        [pscustomobject]@{ Source = $UiSource; Id = 'Taoist_Disposable'; Default = 'true' },
        [pscustomobject]@{ Source = $UiSource; Id = 'Taoist_OutBorder'; Default = 'false' },
        [pscustomobject]@{ Source = $GameplaySource; Id = 'Taoist_PromotionSupplement'; Default = 'false' },
        [pscustomobject]@{ Source = $GameplaySource; Id = 'Taoist_Disposable'; Default = 'true' }
    )) {
        $helperCall = "GetTaoistConfigurationValue(`"$($optionSpec.Id)`", $($optionSpec.Default))"
        if (-not $optionSpec.Source.Contains($helperCall)) {
            $issues.Add("Taoist runtime is missing the configured default for $($optionSpec.Id).")
        }
        $directReadPattern = 'GameConfiguration\.GetValue\("' +
            [regex]::Escape($optionSpec.Id) + '"\)'
        if ([regex]::Matches($optionSpec.Source, $directReadPattern).Count -ne 0) {
            $issues.Add("Taoist runtime reads $($optionSpec.Id) directly instead of using the helper.")
        }
    }

    foreach ($token in @(
        'local featureType = pPlot:GetFeatureType()',
        'if featureType > -1 then',
        'local featureInfo = GameInfo.Features[featureType]',
        'if featureInfo == nil then',
        'local terrainInfo = GameInfo.Terrains[terrainType]'
    )) {
        if (-not $UiSource.Contains($token)) {
            $issues.Add("Taoist UI is missing safe terrain lookup: $token")
        }
    }
    if ($UiSource.Contains('GameInfo.Features[pPlot:GetFeatureType()]')) {
        $issues.Add('Taoist UI indexes feature metadata before checking the no-feature sentinel.')
    }

    foreach ($eventSpec in @(
        [pscustomobject]@{ Event = 'LoadGameViewStateDone'; Handler = 'Initialize' },
        [pscustomobject]@{ Event = 'UnitChargesChanged'; Handler = 'OnUnitChargesChanged' },
        [pscustomobject]@{ Event = 'UnitMoveComplete'; Handler = 'OnUnitMoveComplete' },
        [pscustomobject]@{ Event = 'UnitSelectionChanged'; Handler = 'OnUnitSelectionChanged' }
    )) {
        $eventName = [regex]::Escape($eventSpec.Event)
        $handlerName = [regex]::Escape($eventSpec.Handler)
        $addCount = [regex]::Matches(
            $UiSource,
            "(?m)^\s*Events\.$eventName\.Add\(\s*$handlerName\s*\)"
        ).Count
        $removeCount = [regex]::Matches(
            $UiSource,
            "(?m)^\s*Events\.$eventName\.Remove\(\s*$handlerName\s*\)"
        ).Count
        if ($addCount -ne 1 -or $removeCount -ne 1) {
            $issues.Add(
                "Taoist UI event lifecycle is not exactly paired: " +
                "$($eventSpec.Event)|$($eventSpec.Handler) (Add $addCount, Remove $removeCount)."
            )
        }
    }
    foreach ($token in @(
        'local isInitialized = false',
        'if isInitialized then',
        'ContextPtr:SetShutdown(OnShutdown)'
    )) {
        if (-not $UiSource.Contains($token)) {
            $issues.Add("Taoist UI is missing its hot-reload guard: $token")
        }
    }

    $combinedSource = $UiSource + "`n" + $GameplaySource
    if ([regex]::Matches($combinedSource, '(?m)^\s*print\(').Count -ne 0) {
        $issues.Add('Taoist runtime contains an unguarded print.')
    }
    foreach ($deadIdentifier in @(
        'MaxRecordActions',
        'AiTaoistAddLeyLineToMax',
        'pTaoistBaseCharge',
        'ifFixCharge'
    )) {
        if ($combinedSource.Contains($deadIdentifier)) {
            $issues.Add("Taoist runtime retains dead code: $deadIdentifier")
        }
    }
    if (-not $GameplaySource.Contains('local TaoistCharge = 0') -or
            [regex]::Matches($GameplaySource, '(?m)^\s*TaoistCharge\s*=\s*0\s*$').Count -ne 0) {
        $issues.Add('Taoist gameplay leaks TaoistCharge into the global environment.')
    }
    return @($issues)
}
