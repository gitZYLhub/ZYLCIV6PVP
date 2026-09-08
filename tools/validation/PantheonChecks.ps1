function Get-ZylPantheonContractIssues {
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
        [string]$PantheonSourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # The selected pantheon package must contain the requested thirteen
    # Lightweight Balance beliefs plus ZYL's Druid, with its gameplay, text and
    # icon actions wired into the generated ModInfo. Geothermal Mines are
    # Gathering Storm-only.
    $selectedPantheonPath = Join-Path $modRoot 'sql\ZYL_Pantheons.sql'
    $selectedPantheonTextPath = Join-Path $modRoot 'lang\ZYL_Pantheons_Text.xml'
    $selectedPantheonIconPath = Join-Path $modRoot 'icons\ZYL_Pantheon_Icons.xml'
    $geothermalMinePath = Join-Path $modRoot 'sql\ZYL_GeothermalMines.sql'
    $expectedPantheonIds = @(
        'BELIEF_ZYL_LBM_MOON_GODDESS',
        'BELIEF_ZYL_LBM_COMMERCE_GODDESS',
        'BELIEF_ZYL_LBM_SUN_GOD',
        'BELIEF_ZYL_LBM_ORAL_TRADITION',
        'BELIEF_ZYL_LBM_EARTH_SPIRITS',
        'BELIEF_ZYL_LBM_GARDEN_GODDESS',
        'BELIEF_ZYL_LBM_WEALTH_GODDESS',
        'BELIEF_ZYL_LBM_TRADE_GOD',
        'BELIEF_ZYL_LBM_PATH_OF_CONQUEST',
        'BELIEF_ZYL_LBM_SACRED_INSCRIPTIONS',
        'BELIEF_ZYL_LBM_GRANARY_GOD',
        'BELIEF_ZYL_LBM_REEF_PARADISE',
        'BELIEF_ZYL_LBM_SIREN',
        'BELIEF_ZYL_DRUID'
    )
    $excludedPantheonIds = @(
        'BELIEF_ZYL_LBM_CALM_SEA_GODDESS',
        'BELIEF_ZYL_LBM_TEARS_OF_THE_GODS',
        'BELIEF_ZYL_LBM_GEOTHERMAL_GOD',
        'BELIEF_ZYL_LBM_RIVER_GOD',
        'BELIEF_ZYL_LBM_DEEP_SEA_BEASTS',
        'BELIEF_ZYL_LBM_LIGHT_OF_LIGHTHOUSES',
        'BELIEF_ZYL_LBM_PALM_BEACH'
    )
    foreach ($requiredPantheonFile in @($selectedPantheonPath, $selectedPantheonTextPath, $selectedPantheonIconPath, $geothermalMinePath)) {
        if (-not (Test-Path -LiteralPath $requiredPantheonFile)) {
            $issues.Add("Selected pantheon/geothermal resource is missing: $requiredPantheonFile")
        }
    }
    if (Test-Path -LiteralPath $selectedPantheonPath) {
        $selectedPantheonSql = if ($PSBoundParameters.ContainsKey('PantheonSourceOverride')) {
            $PantheonSourceOverride
        }
        else {
            Get-Content -LiteralPath $selectedPantheonPath -Raw
        }
        foreach ($pantheonId in $expectedPantheonIds) {
            if (-not $selectedPantheonSql.Contains("('$pantheonId', 'KIND_BELIEF')")) {
                $issues.Add("Selected pantheon is not registered: $pantheonId")
            }
        }
        foreach ($pantheonId in $excludedPantheonIds) {
            if ($selectedPantheonSql.Contains($pantheonId)) {
                $issues.Add("Unselected Lightweight Balance pantheon was included: $pantheonId")
            }
        }
        if ($selectedPantheonSql -notmatch "(?s)'ZYL_LBM_PATH_OF_CONQUEST_ENCAMPMENT_CULTURE_MODIFIER'.*?'Amount',\s*1") {
            $issues.Add('Path of Conquest Culture is not set to the requested +1.')
        }
        foreach ($requiredPantheonToken in @(
            'MODIFIER_ZYL_LBM_PLAYER_ADJUST_DISTRICT_UNLOCK',
            'EFFECT_ADJUST_DISTRICT_PREREQ',
            'CLASS_ZYL_LBM_SUN_GOD_FAITH',
            'ZYL_LBM_CITY_HAS_MONUMENT_OR_OBELISK_REQUIREMENTS',
            'ZYL_LBM_PLOT_HAS_REEF_REQUIREMENTS',
            "BeliefType = 'BELIEF_SACRED_PATH'",
            "ModifierId = 'BBG_SACRED_PATH_WOODS_FAITH_ADJACENCY'",
            'ZYL_DRUID_WOODS_FAITH_ADJACENCY',
            "('BELIEF_ZYL_DRUID', 'ZYL_DRUID_WOODS_FAITH_ADJACENCY')"
        )) {
            if (-not $selectedPantheonSql.Contains($requiredPantheonToken)) {
                $issues.Add("Selected pantheon SQL is missing required behavior: $requiredPantheonToken")
            }
        }
    }
    if (Test-Path -LiteralPath $selectedPantheonTextPath) {
        $selectedPantheonText = Load-XmlDocument $selectedPantheonTextPath
        foreach ($pantheonId in $expectedPantheonIds) {
            foreach ($language in @('en_US', 'zh_Hans_CN', 'zh_Hant_HK')) {
                foreach ($suffix in @('NAME', 'DESCRIPTION')) {
                    $tag = "LOC_$($pantheonId)_$suffix"
                    if ($null -eq $selectedPantheonText.SelectSingleNode("/GameData/LocalizedText/Row[@Tag='$tag' and @Language='$language']/Text")) {
                        $issues.Add("Selected pantheon localization is missing: $tag / $language")
                    }
                }
            }
        }
    }
    if (Test-Path -LiteralPath $selectedPantheonIconPath) {
        $selectedPantheonIcons = Load-XmlDocument $selectedPantheonIconPath
        foreach ($pantheonId in $expectedPantheonIds) {
            if ($null -eq $selectedPantheonIcons.SelectSingleNode("/GameData/IconDefinitions/Row[@Name='ICON_$pantheonId']")) {
                $issues.Add("Selected pantheon icon is missing: ICON_$pantheonId")
            }
        }
    }
    if (Test-Path -LiteralPath $geothermalMinePath) {
        $geothermalMineSql = Get-Content -LiteralPath $geothermalMinePath -Raw
        foreach ($geothermalToken in @('Improvement_ValidFeatures', 'IMPROVEMENT_MINE', 'FEATURE_GEOTHERMAL_FISSURE', 'TECH_MINING')) {
            if (-not $geothermalMineSql.Contains($geothermalToken)) {
                $issues.Add("Geothermal Mine SQL is missing required behavior: $geothermalToken")
            }
        }
    }
    $expectedPantheonActions = @{
        'zyl_selectedpantheons' = 'sql/ZYL_Pantheons.sql'
        'zyl_selectedpantheonstext' = 'lang/ZYL_Pantheons_Text.xml'
        'zyl_selectedpantheonsicons' = 'icons/ZYL_Pantheon_Icons.xml'
        'zyl_geothermalmines' = 'sql/ZYL_GeothermalMines.sql'
    }
    foreach ($entry in $expectedPantheonActions.GetEnumerator()) {
        $action = $actionIdMap[$entry.Key]
        if ($null -eq $action -or $action.SelectSingleNode("./File[.='$($entry.Value)']") -eq $null) {
            $issues.Add("Selected pantheon/geothermal action is missing: $($entry.Key)")
        }
        if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $entry.Value))) {
            $issues.Add("Selected pantheon/geothermal file is absent from the manifest: $($entry.Value)")
        }
    }
    $geothermalMineAction = $actionIdMap['zyl_geothermalmines']
    if ($null -eq $geothermalMineAction -or $null -eq $geothermalMineAction.SelectSingleNode("./Criteria[.='ZYL_GatheringStorm']")) {
        $issues.Add('Geothermal Mine action is not limited to Gathering Storm.')
    }
    $gatheringStormCriterion = $criteriaMap['zyl_gatheringstorm']
    if ($null -eq $gatheringStormCriterion -or
            $null -eq $gatheringStormCriterion.SelectSingleNode("RuleSetInUse[.='RULESET_EXPANSION_2']")) {
        $issues.Add('Gathering Storm criterion for Geothermal Mines is missing or incorrect.')
    }
    $lightweightBalanceBlock = $modInfo.SelectSingleNode("/Mod/Blocks/Mod[@id='41493218-3632-421b-a1a3-367f7c7ba610']")
    if ($null -eq $lightweightBalanceBlock) {
        $issues.Add('Standalone ZYL Lightweight Balance is not blocked after selected features were integrated.')
    }

    return @($issues)
}
