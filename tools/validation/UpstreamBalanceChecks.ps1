function Get-ZylUpstreamBalanceContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [AllowEmptyString()]
        [string]$MaliSourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # ZYLPVPMOD's final gameplay override layer must remain later than every
    # embedded BBG/BBM action; otherwise an upstream update can silently restore
    # the values this integration intentionally replaces.
    $requiredOverrideActions = @{
        'zyl_gameplayoverrides' = '260000000'
        'zyl_governoroverrides' = '260000010'
        'zyl_gameplayoverridestext' = '260000020'
        'zyl_gameplayoverridesfrontendtext' = '260000020'
    }
    foreach ($entry in $requiredOverrideActions.GetEnumerator()) {
        if (-not $actionIdMap.ContainsKey($entry.Key)) {
            $issues.Add("Required gameplay override action is missing: $($entry.Key)")
            continue
        }
        $loadOrderNode = $actionIdMap[$entry.Key].SelectSingleNode('./Properties/LoadOrder')
        if ($null -eq $loadOrderNode -or $loadOrderNode.InnerText.Trim() -ne $entry.Value) {
            $issues.Add("Gameplay override action $($entry.Key) must load at $($entry.Value).")
        }
    }

    $requiredBbgChineseActions = @{
        'zyl_bbg74_chinesetextfrontend' = @('FrontEndActions', 'lang/ZYL_BBG74_Chinese_Text.xml')
        'zyl_bbg74_chinesetext' = @('InGameActions', 'lang/ZYL_BBG74_Chinese_Text.xml')
    }
    foreach ($entry in $requiredBbgChineseActions.GetEnumerator()) {
        $action = $actionIdMap[$entry.Key]
        $bbgChineseLoadOrderNode = if ($null -ne $action) {
            $action.SelectSingleNode('./Properties/LoadOrder')
        }
        else {
            $null
        }
        if ($null -eq $action -or
                $action.ParentNode.LocalName -ne $entry.Value[0] -or
                $action.LocalName -ne 'UpdateText' -or
                $null -eq $action.SelectSingleNode("./File[.='$($entry.Value[1])']") -or
                $null -eq $bbgChineseLoadOrderNode -or
                $bbgChineseLoadOrderNode.InnerText.Trim() -ne '259999990') {
            $issues.Add("BBG 7.4.6 Simplified Chinese overlay action is missing or malformed: $($entry.Key)")
        }
    }
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'lang/ZYL_BBG74_Chinese_Text.xml'))) {
        $issues.Add('BBG 7.4.6 Simplified Chinese overlay is absent from the ModInfo <Files> manifest.')
    }

    $disasterRangeAction = $actionIdMap['zyl_disablenaturaldisastersoption']
    if ($null -eq $disasterRangeAction -or
            $disasterRangeAction.LocalName -ne 'UpdateDatabase' -or
            $null -eq $disasterRangeAction.SelectSingleNode("./File[.='configuration/ZYL_DisasterRange.sql']")) {
        $issues.Add('The TPT no-natural-disasters lobby option is not loaded.')
    }
    $disasterRangePath = Join-Path $modRoot 'configuration\ZYL_DisasterRange.sql'
    if (Test-Path -LiteralPath $disasterRangePath) {
        $disasterRangeSql = Get-Content -LiteralPath $disasterRangePath -Raw
        if (-not $disasterRangeSql.Contains("WHERE Domain = 'RealismRange'") -or
                -not $disasterRangeSql.Contains('MinimumValue = -1')) {
            $issues.Add('The disaster-intensity range no longer exposes the -1/disabled value.')
        }
    }

    $bbgBasePath = Join-Path $modRoot 'Components\BBG\sql\Base\base.sql'
    if (Test-Path -LiteralPath $bbgBasePath) {
        $activeBbgTechMultiplier = @(Get-Content -LiteralPath $bbgBasePath | Where-Object {
            $_ -notmatch '^\s*--' -and $_ -match 'Cost\s*=\s*Cost\s*\*\s*1\.05'
        })
        if ($activeBbgTechMultiplier.Count -gt 0) {
            $issues.Add('BBG Medieval-and-later technology +5% base-cost multiplier is active.')
        }
    }

    # Improvement Housing is displayed as Housing / TilesRequired.  BBG's source
    # comment calls the Colossal Head value +1, but the shipped SQL deliberately
    # leaves the final database at 1 / 2, so the effective tooltip value is +0.5.
    $bbgCityStatesPath = Join-Path $modRoot 'Components\BBG\sql\Base\CityStates.sql'
    if (-not (Test-Path -LiteralPath $bbgCityStatesPath)) {
        $issues.Add('BBG city-state gameplay SQL is missing.')
    }
    else {
        $bbgCityStatesSql = Get-Content -LiteralPath $bbgCityStatesPath -Raw
        if ($bbgCityStatesSql -notmatch "(?s)UPDATE\s+Improvements\s+SET\s+Housing\s*=\s*1\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_COLOSSAL_HEAD'.*?UPDATE\s+Improvements\s+SET\s+TilesRequired\s*=\s*2\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_COLOSSAL_HEAD'") {
            $issues.Add('Colossal Head Housing must remain 1 / 2 (+0.5 per improvement) to match the final Chinese text.')
        }
    }

    $bbgMaliPath = Join-Path $modRoot 'Components\BBG\sql\XP2\Mali.sql'
    if (-not (Test-Path -LiteralPath $bbgMaliPath)) {
        $issues.Add('BBG Mali gameplay SQL is missing.')
    }
    else {
        $bbgMaliSql = if ($PSBoundParameters.ContainsKey('MaliSourceOverride')) {
            $MaliSourceOverride
        }
        else {
            Get-Content -LiteralPath $bbgMaliPath -Raw
        }
        foreach ($removedMaliToken in @(
            'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION',
            'BBG_MALI_FAITH_NEXT_DESERT',
            'BBG_MALI_FAITH_NEXT_DESERT_HILLS',
            'BBG_MALI_FAITH_NEXT_CAPITAL',
            'TRAIT_BBG_MANSA_FREE_TRADER_BANKS',
            'ZYL_MALI_FAITH_DESERT',
            'ZYL_MALI_FAITH_DESERT_HILLS',
            'BBG_MALI_GOLD_DESERT_MINES',
            'BBG_MALI_GOLD_DESERT_HILLS_MINES',
            'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION',
            'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION_BUILDING'
        )) {
            if ($bbgMaliSql.Contains($removedMaliToken)) {
                $issues.Add("Mali source still defines a removed modifier: $removedMaliToken")
            }
        }
        if ($bbgMaliSql -match "(?is)DELETE\s+FROM\s+(?:TraitModifiers|Modifiers|ModifierArguments)\b[^;]*GOLDEN_AGE_TRADE_ROUTE[^;]*;") {
            $issues.Add('Mansa Musa source still deletes the original Golden Age Trade Route modifier.')
        }
        if (-not $bbgMaliSql.Contains('GOLDEN_AGE_TRADE_ROUTE')) {
            $issues.Add('Mansa Musa source does not document preservation of the original Golden Age Trade Route modifier.')
        }
        foreach ($maliYieldBinding in @(
            @('ZYL_MALI_PRODUCTION_DESERT', 'YIELD_PRODUCTION', 'BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET'),
            @('ZYL_MALI_PRODUCTION_DESERT_HILLS', 'YIELD_PRODUCTION', 'BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET')
        )) {
            $modifierId = [regex]::Escape($maliYieldBinding[0])
            $yieldType = [regex]::Escape($maliYieldBinding[1])
            $requirementSetId = [regex]::Escape($maliYieldBinding[2])
            if ($bbgMaliSql -notmatch "(?s)\('$modifierId'\s*,\s*'MODIFIER_PLAYER_ADJUST_PLOT_YIELD'\s*,\s*'$requirementSetId'\).*?\('$modifierId'\s*,\s*'YieldType'\s*,\s*'$yieldType'\).*?\('$modifierId'\s*,\s*'Amount'\s*,\s*1\)") {
                $issues.Add("Mali featureless Desert yield modifier is incomplete: $($maliYieldBinding[0])")
            }
            if ($bbgMaliSql -notmatch "\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'$modifierId'\)") {
                $issues.Add("Mali featureless Desert yield modifier is not attached to the civilization trait: $($maliYieldBinding[0])")
            }
        }
        if ($bbgMaliSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s+IN\s*\(\s*'SUGUBA_CHEAPER_BUILDING_PURCHASE'\s*,\s*'SUGUBA_CHEAPER_DISTRICT_PURCHASE'\s*\)") {
            $issues.Add('Suguba building/district purchase discount is not locked to 10%.')
        }
        if ($bbgMaliSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s*=\s*'SUGUBA_CHEAPER_UNIT_PURCHASE'") {
            $issues.Add('Suguba unit purchase discount is not locked to 10%.')
        }
    }

    $bbgKhmerPath = Join-Path $modRoot 'Components\BBG\sql\DLC_Indonesia_Khmer\Khmer.sql'
    if (-not (Test-Path -LiteralPath $bbgKhmerPath)) {
        $issues.Add('BBG Khmer gameplay SQL is missing.')
    }
    else {
        $bbgKhmerSql = Get-Content -LiteralPath $bbgKhmerPath -Raw
        if ($bbgKhmerSql -notmatch "(?s)DELETE\s+from\s+TraitModifiers\s+where\s+TraitType\s*=\s*'TRAIT_LEADER_MONASTERIES_KING'\s+and\s+ModifierId\s*=\s*'TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY'") {
            $issues.Add("Khmer source does not remove the old Jayavarman-only river Holy Site Faith modifier.")
        }
        if ($bbgKhmerSql -notmatch "(?s)\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'Amount'\s*,\s*1\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_HOLY_SITE'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'YieldType'\s*,\s*'YIELD_FAITH'\).*?\('TRAIT_CIVILIZATION_KHMER_BARAYS'\s*,\s*'ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\)") {
            $issues.Add('Khmer source does not attach the standard +1 river Holy Site Faith bonus to the civilization trait.')
        }
        if ($bbgKhmerSql -match "INSERT\s+(?:OR\s+IGNORE\s+)?INTO\s+TraitModifiers[^;]*TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY") {
            $issues.Add('Khmer source still grants the river Holy Site Faith modifier to Jayavarman.')
        }
    }

    $bbgCreePath = Join-Path $modRoot 'Components\BBG\sql\XP1\Cree.sql'
    if (-not (Test-Path -LiteralPath $bbgCreePath)) {
        $issues.Add('BBG Cree gameplay SQL is missing.')
    }
    else {
        $bbgCreeSql = Get-Content -LiteralPath $bbgCreePath -Raw
        if ($bbgCreeSql -notmatch "(?s)UPDATE\s+ModifierArguments\s+SET\s+Value\s*=\s*1\s+WHERE\s+ModifierId\s+IN\s*\(\s*'TRAIT_TRADE_FOOD_FROM_CAMPS'\s*,\s*'TRAIT_TRADE_FOOD_FROM_PASTURES'\s*\)\s+AND\s+Name\s*=\s*'Amount'") {
            $issues.Add('Cree source does not restore outgoing Camp/Pasture Trade Route Food to +1.')
        }
        if ($bbgCreeSql -match "(?s)UPDATE\s+Modifiers\s+SET(?:(?!;).)*SubjectStackLimit(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_CAMPS'(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_PASTURES'(?:(?!;).)*;") {
            $issues.Add('Cree source incorrectly uses a modifier stack limit as an improvement-count cap.')
        }
    }

    $bbgGranColombiaPath = Join-Path $modRoot 'Components\BBG\sql\NFP\GranColombia.sql'
    if (-not (Test-Path -LiteralPath $bbgGranColombiaPath)) {
        $issues.Add('BBG Gran Colombia gameplay SQL is missing.')
    }
    else {
        $bbgGranColombiaSql = Get-Content -LiteralPath $bbgGranColombiaPath -Raw
        if ($bbgGranColombiaSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s+AND\s+ModifierId\s*=\s*'BBG_COLUMBIA_MOVEMENT_BONUS'.*?INSERT\s+OR\s+IGNORE\s+INTO\s+TraitModifiers\s*\(\s*TraitType\s*,\s*ModifierId\s*\)\s+VALUES\s*\(\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s*,\s*'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT'\s*\)") {
            $issues.Add('Gran Colombia source does not restore the original all-unit movement trait attachment.')
        }
        if ($bbgGranColombiaSql -match "BBG_UTILS_PLAYER_HAS_CIVIC_POLITICAL_PHILOSOPHY_REQSET|BBG_REQUIREMENT_UNIT_IS_NAVAL_OR_LAND|BBG_COLUMBIA_MOVEMENT_BONUS_MODIFIER") {
            $issues.Add('Gran Colombia source still defines the Political Philosophy military-only movement replacement.')
        }
        if ($bbgGranColombiaSql -notmatch "(?s)UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_PROMOTE_NO_FINISH_MOVES'") {
            $issues.Add('Gran Colombia no longer preserves the Cavalry/Air/Spy promote-and-move restriction.')
        }
    }

    $bbgGaulPath = Join-Path $modRoot 'Components\BBG\sql\NFP\Gaul.sql'
    if (-not (Test-Path -LiteralPath $bbgGaulPath)) {
        $issues.Add('BBG Gaul gameplay SQL is missing.')
    }
    else {
        $bbgGaulSql = Get-Content -LiteralPath $bbgGaulPath -Raw
        if ($bbgGaulSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SUK_GALLIC_WAR'.*?ModifierId\s*=\s*'GAUL_MINE_CULTURE'.*?INSERT\s+OR\s+IGNORE\s+INTO\s+TraitModifiers\s*\(\s*TraitType\s*,\s*ModifierId\s*\)\s+VALUES\s*\(\s*'TRAIT_CIVILIZATION_GAUL'\s*,\s*'GAUL_MINE_CULTURE'\s*\).*?UPDATE\s+Modifiers\s+SET\s+OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING'\s*,\s*SubjectRequirementSetId\s*=\s*'PLOT_HAS_MINE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'GAUL_MINE_CULTURE'") {
            $issues.Add('Gaul source does not move GAUL_MINE_CULTURE to the civilization trait with the Bronze Working/Mine requirements.')
        }
        if ($bbgGaulSql -match "ZYL_GAUL_MINE_CULTURE_CRAFTSMANSHIP|BBG_UTILS_PLAYER_HAS_CIVIC_CRAFTSMANSHIP_REQSET") {
            $issues.Add('Gaul source still contains the superseded standalone Craftsmanship Mine Culture modifier.')
        }
    }

    $bbgVercingetorixPath = Join-Path $modRoot 'Components\BBG\sql\BBG_Expanded\Vercingetorix.sql'
    if (-not (Test-Path -LiteralPath $bbgVercingetorixPath)) {
        $issues.Add('BBG Vercingetorix gameplay SQL is missing.')
    }
    else {
        $bbgVercingetorixSql = Get-Content -LiteralPath $bbgVercingetorixPath -Raw
        if ($bbgVercingetorixSql -match "INSERT\s+INTO\s+TraitModifiers[^;]*GAUL_MINE_CULTURE|OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING'[^;]*GAUL_MINE_CULTURE") {
            $issues.Add('Vercingetorix source still grants GAUL_MINE_CULTURE as a separate leader ability.')
        }
    }

    $bbgRomePath = Join-Path $modRoot 'Components\BBG\sql\Base\Rome.sql'
    if (-not (Test-Path -LiteralPath $bbgRomePath)) {
        $issues.Add('BBG Rome gameplay SQL is missing.')
    }
    else {
        $bbgRomeSql = Get-Content -LiteralPath $bbgRomePath -Raw
        if ($bbgRomeSql -notmatch "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING'\s*;") {
            $issues.Add('Trajan free City Center building is not unlocked by Foreign Trade in the Rome source SQL.')
        }
        if ($bbgRomeSql -match "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET'") {
            $issues.Add("Rome source SQL still unlocks Trajan's free building at Early Empire.")
        }
    }

    foreach ($gaulTextSpec in @(
        @('Components\BBG\lang\english.xml', 'en_US', 'Bronze Working', '+1 [ICON_CULTURE] Culture'),
        @('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '铸铜术', '+1 [ICON_CULTURE] 文化'),
        @('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '铸铜术', '+1 [ICON_CULTURE] 文化'),
        @('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', 'Bronze Working', '+1 [ICON_CULTURE] Culture'),
        @('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '铸铜术', '+1 [ICON_CULTURE] 文化')
    )) {
        $gaulTextPath = Join-Path $modRoot $gaulTextSpec[0]
        if (-not (Test-Path -LiteralPath $gaulTextPath)) {
            $issues.Add("Gaul localization file is missing: $($gaulTextSpec[0])")
            continue
        }
        $gaulTextXml = Load-XmlDocument $gaulTextPath
        $gaulTextNode = $gaulTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_GAUL_DESCRIPTION' and @Language='$($gaulTextSpec[1])']/Text")
        if ($null -eq $gaulTextNode -or
            -not $gaulTextNode.InnerText.Contains($gaulTextSpec[2]) -or
            -not $gaulTextNode.InnerText.Contains($gaulTextSpec[3])) {
            $issues.Add("Gaul $($gaulTextSpec[1]) text does not describe the Bronze Working Mine +1 Culture bonus: $($gaulTextSpec[0])")
        }
    }

    foreach ($vercingetorixTextSpec in @(
        @('Components\BBG\lang\english.xml', 'en_US', 'Workshops grant'),
        @('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '工作坊'),
        @('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '工作坊'),
        @('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '工作坊'),
        @('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', 'Workshops grant')
    )) {
        $vercingetorixTextPath = Join-Path $modRoot $vercingetorixTextSpec[0]
        if (-not (Test-Path -LiteralPath $vercingetorixTextPath)) {
            $issues.Add("Vercingetorix localization file is missing: $($vercingetorixTextSpec[0])")
            continue
        }
        $vercingetorixTextXml = Load-XmlDocument $vercingetorixTextPath
        foreach ($vercingetorixTag in @(
            'LOC_TRAIT_LEADER_SUK_GALLIC_WAR_DESCRIPTION',
            'LOC_TRAIT_LEADER_SUK_GALLIC_WAR_DESCRIPTION_DLC'
        )) {
            $vercingetorixTextNode = $vercingetorixTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$vercingetorixTag' and @Language='$($vercingetorixTextSpec[1])']/Text")
            if ($null -eq $vercingetorixTextNode -or -not $vercingetorixTextNode.InnerText.Contains($vercingetorixTextSpec[2])) {
                $issues.Add("Vercingetorix $($vercingetorixTextSpec[1]) text does not retain the Workshop Influence ability: $vercingetorixTag")
                continue
            }
            foreach ($removedFragment in @('Bronze Working', '铸铜术', 'mines', '矿山', '[ICON_CULTURE]')) {
                if ($vercingetorixTextNode.InnerText.Contains($removedFragment)) {
                    $issues.Add("Vercingetorix $($vercingetorixTextSpec[1]) text still claims the transferred Mine Culture ability: $vercingetorixTag")
                    break
                }
            }
        }
    }

    foreach ($trajanTextSpec in @(
        @('Components\BBG\lang\english.xml', 'en_US', 'Foreign Trade', 'Early Empire'),
        @('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '对外贸易', '帝国初期'),
        @('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '对外贸易', '帝国初期'),
        @('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', 'Foreign Trade', 'Early Empire'),
        @('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '对外贸易', '帝国初期')
    )) {
        $trajanTextPath = Join-Path $modRoot $trajanTextSpec[0]
        if (-not (Test-Path -LiteralPath $trajanTextPath)) {
            $issues.Add("Trajan localization file is missing: $($trajanTextSpec[0])")
            continue
        }
        $trajanTextXml = Load-XmlDocument $trajanTextPath
        $trajanTextNode = $trajanTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_TRAJANS_COLUMN_DESCRIPTION' and @Language='$($trajanTextSpec[1])']/Text")
        if ($null -eq $trajanTextNode -or -not $trajanTextNode.InnerText.Contains($trajanTextSpec[2])) {
            $issues.Add("Trajan $($trajanTextSpec[1]) text does not mention Foreign Trade: $($trajanTextSpec[0])")
            continue
        }
        if ($trajanTextNode.InnerText.Contains($trajanTextSpec[3])) {
            $issues.Add("Trajan $($trajanTextSpec[1]) text still claims Early Empire: $($trajanTextSpec[0])")
        }
    }

    foreach ($granColombiaTextSpec in @(
        @('Components\BBG\lang\english.xml', 'en_US', 'all units', 'military units', 'Political Philosophy'),
        @('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '所有单位+1', '所有军事单位', '政治哲学')
    )) {
        $granColombiaTextPath = Join-Path $modRoot $granColombiaTextSpec[0]
        if (-not (Test-Path -LiteralPath $granColombiaTextPath)) {
            $issues.Add("Gran Colombia localization file is missing: $($granColombiaTextSpec[0])")
            continue
        }
        $granColombiaTextXml = Load-XmlDocument $granColombiaTextPath
        foreach ($granColombiaTag in @(
            'LOC_TRAIT_CIVILIZATION_EJERCITO_PATRIOTA_DESCRIPTION',
            'LOC_ABILITY_EJERCITO_PATRIOTA_EXTRA_MOVEMENT_DESCRIPTION'
        )) {
            $granColombiaTextNode = $granColombiaTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$granColombiaTag' and @Language='$($granColombiaTextSpec[1])']/Text")
            if ($null -eq $granColombiaTextNode -or -not $granColombiaTextNode.InnerText.Contains($granColombiaTextSpec[2])) {
                $issues.Add("Gran Colombia $($granColombiaTextSpec[1]) text does not say all units receive the movement bonus: $granColombiaTag")
                continue
            }
            foreach ($removedFragment in @($granColombiaTextSpec[3], $granColombiaTextSpec[4])) {
                if ($granColombiaTextNode.InnerText.Contains($removedFragment)) {
                    $issues.Add("Gran Colombia $($granColombiaTextSpec[1]) text still claims the removed military/Political Philosophy restriction: $granColombiaTag")
                }
            }
        }
    }

    return @($issues)
}
