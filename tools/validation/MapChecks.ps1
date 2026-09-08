function Add-ZylMapIssues {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$Issues,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$AdditionalIssues
    )

    foreach ($issue in $AdditionalIssues) {
        $Issues.Add([string]$issue)
    }
}

function Get-ZylRichMainlandAssignStartingPlotsIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredToken in @(
            '__PlaceMissingMinorCivsRelaxed',
            '__FindRelaxedMinorStart',
            'ZYL_RVC_MINOR_DISTANCE_TIERS',
            'MinMajor = 6, MinMinor = 3',
            'bError_minor == false',
            'Error Minor Player is still missing after relaxed fallback',
            'CUSTOM_HYDROPHOBIC',
            'ZYL_RVC_HYDROPHOBIC_MIN_WALKABLE_RATIO = 0.60',
            'ZYL_RVC_HYDROPHOBIC_COAST_FREE_RANGE = 3',
            'ZYL_RVC_HYDROPHOBIC_COAST_SCORE_RANGE = 5',
            'ZYL_RVC_EvaluateHydrophobicStart',
            'walkableRatio <= ZYL_RVC_HYDROPHOBIC_MIN_WALKABLE_RATIO',
            'ZYL_RVC_EW_COAST_START_BONUS = 50000000',
            'ZYL_RVC_TARGET_COAST_START_BONUS = 200000000',
            'ZYL_RVC_OTHER_EW_COAST_START_BONUS = 100000000',
            'ZYL_RVC_GetCoastOrientation',
            'ZYL_RVC_IsEastWestCoastOrientation',
            '__InitCoastalSideTargets',
            '__GetCoastalTargetSide',
            '__LogCoastalSideQuota',
            'coastalSideCounts = { WEST = 0, EAST = 0 }',
            'counts.WEST < counts.EAST',
            'counts.EAST < counts.WEST',
            'self.coastalSideCounts[ratedBias.CoastOrientation]',
            "SEAS_CIVILIZATION[row.CivilizationType] = true",
            "including BBG's land-start",
            'Areas.FindBiggestArea(false)',
            'plotArea:GetID() ~= ZYL_RVC_MAINLAND_AREA_ID',
            'eastWestSeaMargin',
            'northSouthSeaMargin = 6',
            'ratedPlot.CoastOrientation == targetSide',
            'targetSide = positiveSide and "EAST" or "WEST"',
            'index % 2 == 1 and firstSide',
            'ZYLRM_COAST_WEST_STARTS',
            'ZYLRM_COAST_EAST_STARTS',
            'ZYL RVC coastal side quota:',
            'bestUniformInstance:__LogCoastalSideQuota()',
            'self.oceanStartFallbackPlayers[iPlayer] == true',
            'ZYLRM_COAST_ORIENTATION_',
            'local categoryOrder = major == true and { "COAST", "INLAND" } or { "ALL" };',
            'ZYL_RVC_IsFFAUniformDistributionEnabled',
            'ZYL_RVC_ValidateFFAUniformDistribution',
            'ZYL_RICH_MAINLAND_VARIANT.ffa ~= true',
            'MapConfiguration.GetValue("ZYL_RVC_UniformDistribution")',
            'instance.iPlacementAttempt >= 17',
            'smallestZone > 0',
            'coverage >= requiredCoverage',
            'uniformDistributionOnlyFailure',
            'FFA uniform retry keeps major-civilization distance',
            'self.ffaUniformDistributionEnabled == true and regionIndex > 0',
            '20 attempts exhausted; using best saved placement',
            'for i = 1,20 do'
        )) {
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add("Rich Mainland city-state fallback is missing: $requiredToken")
        }
    }
    if ($Source -match 'Map\.GetPlotByIndex\(PlayerManager\.GetAliveMajorsCount\(\)\+PlayerManager\.GetAliveMinorsCount\(\)\+count\)') {
        $issues.Add('Rich Mainland still assigns missing city-states to an arbitrary map-index tile.')
    }
    if ($Source -match '(?m)^\s*GenerateMap\s*\(' -or
            $Source -match 'Network\.RestartGame\s*\(') {
        $issues.Add('FFA uniform distribution must use finite placement retries, not recursive map generation or a network restart.')
    }
    return @($issues)
}

function Get-ZylRichMainlandBalanceIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredToken in @(
            'ZYL_RVC_PlaceGuaranteedEarlyStrategic',
            'empty desert converted to plains',
            'ordinary bonus resource replaced',
            'protectedStartPlots',
            'ZYLRM_EARLY_STRATEGIC_FALLBACKS'
        )) {
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add("Rich Mainland strategic fallback is missing: $requiredToken")
        }
    }
    if ($Source -match 'Removing city-state player|has been eliminated \(too close to') {
        $issues.Add('Rich Mainland balance script still deletes city-states during post-placement distance checks.')
    }
    return @($issues)
}

function Get-ZylRichMainlandCoreIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredToken in @(
            'function ZYL_EnsureCoastalStartReefResource()',
            'startPlot:IsCoastalLand()',
            'RelocateRingTwoResource',
            'ZYL RVC ring-two Turtles or Fish',
            'ZYLRM_COASTAL_START_REEF_RESOURCE',
            'ZYL_RVC_EnforceSeaResourceRules();' + [Environment]::NewLine + "`tZYL_EnsureCoastalStartReefResource();",
            'local contentWidths = ZYL_RICH_MAINLAND_VARIANT.contentWidthsByHeight or baseWidths;',
            'g_iBaseW = math.min(g_iW, tonumber(contentWidths[g_iH]) or g_iLegacyW);',
            'g_iAddedOceanWidth = math.max(0, g_iW - g_iBaseW);',
            'g_iContentOffsetX = math.floor(g_iAddedOceanWidth / 2);',
            'g_fHorizontalScale = IS_FFA and (g_iLegacyW > 0 and g_iBaseW / g_iLegacyW or 1) or 1;',
            'ZYL_EnforceCentralOceanBarrier(terrainTypes);',
            'for _, y in ipairs({ 0, 1, g_iH - 1 }) do',
            'terrainTypes[index] = g_TERRAIN_TYPE_OCEAN;',
            'ZYL_RemovePolarShallowSea();',
            'local ZYL_RICH_MAINLAND_ISLAND_LAND_MULTIPLIER = 1.20;',
            'local ZYL_RICH_MAINLAND_ISLAND_GRAIN = 4;',
            'math.floor(100 - targetIslandLandPercent + 0.5)',
            'math.floor(wonderTarget + 0.5)'
        )) {
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add("Rich Mainland coastal/canvas invariant is missing: $requiredToken")
        }
    }
    foreach ($forbiddenToken in @(
            'g_iBaseW = g_iW;',
            'g_iAddedOceanWidth = 0;',
            'if IS_TEAM then ZYL_EnforceCentralOceanBarrier',
            'local isPolarRoute',
            'args.iWaterPercent = 67;'
        )) {
        if ($Source.Contains($forbiddenToken)) {
            $issues.Add("Old Rich Mainland central-ocean/polar/island behavior returned: $forbiddenToken")
        }
    }
    return @($issues)
}

function Get-ZylRichMainlandFfaEntryIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredToken in @(
            'contentWidthsByHeight = {',
            '[34] = 58,', '[42] = 60,', '[48] = 62,', '[56] = 64,',
            '[62] = 66,', '[68] = 68,', '[74] = 70,', '[80] = 72,',
            '[84] = 74,', '[88] = 78,', '[92] = 80,'
        )) {
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add("FFA preserved content width is missing: $requiredToken")
        }
    }
    return @($issues)
}

function Get-ZylRichMainlandFfaConfigurationIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredToken in @(
            'GridWidth=62, GridHeight=34', 'GridWidth=66, GridHeight=48',
            'GridWidth=70, GridHeight=62', 'GridWidth=74, GridHeight=74',
            'GridWidth=78, GridHeight=84', 'GridWidth=84, GridHeight=92',
            '3, 3, 64, 42, 3, 2)', '5, 4, 68, 56, 4, 3)',
            '7, 5, 72, 68, 4, 4)', '9, 6, 76, 80, 5, 5)',
            '11, 7, 82, 88, 6, 6)'
        )) {
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add("FFA runtime width must preserve the old content canvas plus four ocean columns: $requiredToken")
        }
    }
    return @($issues)
}

function Get-ZylRichMainlandConfigurationIssues {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ConfigurationXml,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [System.Xml.XmlDocument]$LocalizationXml
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $expectedMaps = @('zyl_team_rich_mainland.lua', 'zyl_ffa_rich_mainland.lua')
    $actualMaps = @($ConfigurationXml.SelectNodes('/GameInfo/Maps/Row') | ForEach-Object {
            $_.GetAttribute('File')
        })
    if (($actualMaps -join '|') -ne ($expectedMaps -join '|')) {
        $issues.Add("Unexpected Rich Mainland map entries: $($actualMaps -join ', ')")
    }

    $teamSizes = @($ConfigurationXml.SelectNodes(
            '/GameInfo/MapSizes/Row[@Domain="zyl_team_rich_mainland.lua"]'
        ))
    $ffaSizes = @($ConfigurationXml.SelectNodes(
            '/GameInfo/MapSizes/Row[@Domain="zyl_ffa_rich_mainland.lua"]'
        ))
    if ($teamSizes.Count -ne 6) {
        $issues.Add("Team Rich Mainland must expose 6 sizes; found $($teamSizes.Count).")
    }
    if ($ffaSizes.Count -ne 11) {
        $issues.Add("FFA Rich Mainland must expose 11 sizes; found $($ffaSizes.Count).")
    }
    $ffaPlayers = @($ffaSizes | ForEach-Object {
            [int]$_.GetAttribute('DefaultPlayers')
        } | Sort-Object)
    if (($ffaPlayers -join ',') -ne ((2..12) -join ',')) {
        $issues.Add("FFA Rich Mainland player-size coverage is not 2-12: $($ffaPlayers -join ',')")
    }

    $uniformParameters = @($ConfigurationXml.SelectNodes(
            '/GameInfo/Parameters/Row[@ConfigurationId="ZYL_RVC_UniformDistribution"]'
        ))
    if ($uniformParameters.Count -ne 1) {
        $issues.Add(
            "FFA Rich Mainland must own exactly one uniform-distribution option; " +
            "found $($uniformParameters.Count)."
        )
    }
    else {
        $uniformParameter = $uniformParameters[0]
        if ($uniformParameter.GetAttribute('Key2') -ne 'zyl_ffa_rich_mainland.lua' -or
                $uniformParameter.GetAttribute('ParameterId') -ne 'ZYLRM_FFA_UniformDistribution' -or
                $uniformParameter.GetAttribute('Domain') -ne 'bool' -or
                $uniformParameter.GetAttribute('DefaultValue') -ne '1' -or
                $uniformParameter.GetAttribute('Name') -ne 'LOC_ZYLRM_FFA_UNIFORM_DISTRIBUTION_NAME' -or
                $uniformParameter.GetAttribute('Description') -ne 'LOC_ZYLRM_FFA_UNIFORM_DISTRIBUTION_DESCRIPTION') {
            $issues.Add(
                'The experimental uniform-distribution option must be FFA-only, boolean, localized and enabled by default.'
            )
        }
    }

    if ($null -eq $LocalizationXml) {
        $issues.Add('Rich Mainland localization is missing.')
    }
    else {
        foreach ($language in @('zh_Hans_CN', 'en_US')) {
            foreach ($tag in @(
                    'LOC_ZYLRM_FFA_UNIFORM_DISTRIBUTION_NAME',
                    'LOC_ZYLRM_FFA_UNIFORM_DISTRIBUTION_DESCRIPTION'
                )) {
                $textNode = $LocalizationXml.SelectSingleNode(
                    "/GameData/LocalizedText/Row[@Tag='$tag' and @Language='$language']/Text"
                )
                if ($null -eq $textNode -or [string]::IsNullOrWhiteSpace($textNode.InnerText)) {
                    $issues.Add("FFA uniform-distribution localization is missing: $language / $tag")
                }
            }
        }
    }

    foreach ($ffaSize in $ffaSizes) {
        if ($ffaSize.GetAttribute('MaxPlayers') -ne $ffaSize.GetAttribute('DefaultPlayers')) {
            $issues.Add(
                "FFA size $($ffaSize.GetAttribute('MapSizeType')) allows more players than its land-area guarantee."
            )
        }
    }

    $parameterDefaults = @{
        'zyl_team_rich_mainland.lua|BBS_Team_Spawn' = '1'
        'zyl_ffa_rich_mainland.lua|BBS_Team_Spawn' = '0'
        'zyl_team_rich_mainland.lua|RouteLevel' = '1'
        'zyl_ffa_rich_mainland.lua|RouteLevel' = '1'
    }
    foreach ($entry in $parameterDefaults.GetEnumerator()) {
        $parts = $entry.Key.Split('|')
        $node = $ConfigurationXml.SelectSingleNode(
            "/GameInfo/Parameters/Row[@Key2='$($parts[0])' and @ConfigurationId='$($parts[1])']"
        )
        if ($null -eq $node -or $node.GetAttribute('DefaultValue') -ne $entry.Value) {
            $issues.Add("Rich Mainland default $($entry.Key) must be $($entry.Value).")
        }
    }

    $expectedCityStates = @{
        'zyl_team_rich_mainland.lua|MAPSIZE_DUEL' = 5
        'zyl_team_rich_mainland.lua|MAPSIZE_TINY' = 8
        'zyl_team_rich_mainland.lua|MAPSIZE_SMALL' = 10
        'zyl_team_rich_mainland.lua|MAPSIZE_STANDARD' = 12
        'zyl_team_rich_mainland.lua|MAPSIZE_LARGE' = 14
        'zyl_team_rich_mainland.lua|MAPSIZE_HUGE' = 17
        'zyl_ffa_rich_mainland.lua|MAPSIZE_DUEL' = 5
        'zyl_ffa_rich_mainland.lua|MAPSIZE_ZYL_FFA_3' = 6
        'zyl_ffa_rich_mainland.lua|MAPSIZE_TINY' = 8
        'zyl_ffa_rich_mainland.lua|MAPSIZE_ZYL_FFA_5' = 9
        'zyl_ffa_rich_mainland.lua|MAPSIZE_SMALL' = 10
        'zyl_ffa_rich_mainland.lua|MAPSIZE_ZYL_FFA_7' = 11
        'zyl_ffa_rich_mainland.lua|MAPSIZE_STANDARD' = 12
        'zyl_ffa_rich_mainland.lua|MAPSIZE_ZYL_FFA_9' = 13
        'zyl_ffa_rich_mainland.lua|MAPSIZE_LARGE' = 14
        'zyl_ffa_rich_mainland.lua|MAPSIZE_ZYL_FFA_11' = 16
        'zyl_ffa_rich_mainland.lua|MAPSIZE_HUGE' = 17
    }
    foreach ($entry in $expectedCityStates.GetEnumerator()) {
        $parts = $entry.Key.Split('|')
        $node = $ConfigurationXml.SelectSingleNode(
            "/GameInfo/MapSizes/Row[@Domain='$($parts[0])' and @MapSizeType='$($parts[1])']"
        )
        if ($null -eq $node -or
                [int]$node.GetAttribute('DefaultCityStates') -ne [int]$entry.Value) {
            $issues.Add("Rich Mainland default city states $($entry.Key) must be $($entry.Value).")
        }
    }
    return @($issues)
}

function Get-ZylBbmMapSizeConfigurationIssues {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ConfigurationXml
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $expectedCityStates = @{
        'ExtraStandardMapSizes|MAPSIZE_DUEL' = 5
        'ExtraStandardMapSizes|MAPSIZE_TINY' = 8
        'ExtraStandardMapSizes|MAPSIZE_SMALL' = 11
        'ExtraStandardMapSizes|MAPSIZE_STANDARD' = 14
        'ExtraStandardMapSizes|MAPSIZE_LARGE' = 17
        'ExtraStandardMapSizes|MAPSIZE_HUGE' = 20
        'ExtraStandardMapSizes|MAPSIZE_ENORMOUS' = 26
        'StandardMapSizes|MAPSIZE_DUEL' = 5
        'StandardMapSizes|MAPSIZE_TINY' = 8
        'StandardMapSizes|MAPSIZE_SMALL' = 11
        'StandardMapSizes|MAPSIZE_STANDARD' = 14
        'StandardMapSizes|MAPSIZE_LARGE' = 17
        'StandardMapSizes|MAPSIZE_HUGE' = 20
    }
    foreach ($entry in $expectedCityStates.GetEnumerator()) {
        $parts = $entry.Key.Split('|')
        $node = $ConfigurationXml.SelectSingleNode(
            "/GameInfo/MapSizes/Replace[@Domain='$($parts[0])' and @MapSizeType='$($parts[1])']"
        )
        if ($null -eq $node -or
                [int]$node.GetAttribute('DefaultCityStates') -ne [int]$entry.Value) {
            $issues.Add("BBM default city states $($entry.Key) must be $($entry.Value).")
        }
    }
    return @($issues)
}

function Get-ZylRichMainlandContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [Parameter(Mandatory = $true)]
        [object]$CriteriaMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $manifestFiles = @(
        'Components/BBM/Configuration/ZYL_RichMainland_Config.xml',
        'Components/BBM/Lang/ZYL_RichMainland_Text.xml',
        'Components/BBM/Data/BBS Maps/zyl_team_rich_mainland.lua',
        'Components/BBM/Data/BBS Maps/zyl_ffa_rich_mainland.lua',
        'Components/BBM/Data/BBS Maps/zyl_rich_mainland_core.lua',
        'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureCommon.sql',
        'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureTeam.sql',
        'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureFFA.sql',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_Balance.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_BBS_TerrainGenerator.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_CoastalLowlands.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_DW_TerrainGenerator.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_FeatureGenerator.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_MapUtilities.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_MountainsCliffs.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_ResourceGenerator.lua',
        'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_RiversLakes.lua'
    )
    foreach ($requiredFile in $manifestFiles) {
        if (-not $ListedFileMap.ContainsKey((Normalize-RelativePath $requiredFile))) {
            $issues.Add("Rich Mainland file absent from <Files>: $requiredFile")
        }
    }

    $sourceChecks = @(
        [pscustomobject]@{
            RelativePath = 'Components\BBM\Data\BBS Maps\Utility\ZYL_RVC_AssignStartingPlots.lua'
            Function = 'Get-ZylRichMainlandAssignStartingPlotsIssues'
            MissingMessage = $null
        },
        [pscustomobject]@{
            RelativePath = 'Components\BBM\Data\BBS Maps\Utility\ZYL_RVC_Balance.lua'
            Function = 'Get-ZylRichMainlandBalanceIssues'
            MissingMessage = $null
        },
        [pscustomobject]@{
            RelativePath = 'Components\BBM\Data\BBS Maps\zyl_rich_mainland_core.lua'
            Function = 'Get-ZylRichMainlandCoreIssues'
            MissingMessage = $null
        },
        [pscustomobject]@{
            RelativePath = 'Components\BBM\Data\BBS Maps\zyl_ffa_rich_mainland.lua'
            Function = 'Get-ZylRichMainlandFfaEntryIssues'
            MissingMessage = 'FFA Rich Mainland entry script is missing.'
        },
        [pscustomobject]@{
            RelativePath = 'Components\BBM\Data\BBS Maps\ZYLRM\ConfigureFFA.sql'
            Function = 'Get-ZylRichMainlandFfaConfigurationIssues'
            MissingMessage = 'FFA Rich Mainland runtime configuration is missing.'
        }
    )
    foreach ($sourceCheck in $sourceChecks) {
        $sourcePath = Join-Path $ProjectRoot $sourceCheck.RelativePath
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            if ($null -ne $sourceCheck.MissingMessage) {
                $issues.Add($sourceCheck.MissingMessage)
            }
            continue
        }
        $source = Get-Content -LiteralPath $sourcePath -Raw
        $checkFunction = $sourceCheck.Function
        Add-ZylMapIssues -Issues $issues -AdditionalIssues @(& $checkFunction -Source $source)
    }

    $configurationPath = Join-Path $ProjectRoot 'Components\BBM\Configuration\ZYL_RichMainland_Config.xml'
    if (-not (Test-Path -LiteralPath $configurationPath -PathType Leaf)) {
        $issues.Add('Rich Mainland configuration is missing.')
    }
    else {
        $configurationXml = Load-XmlDocument $configurationPath
        $localizationPath = Join-Path $ProjectRoot 'Components\BBM\Lang\ZYL_RichMainland_Text.xml'
        $localizationXml = $null
        if (Test-Path -LiteralPath $localizationPath -PathType Leaf) {
            $localizationXml = Load-XmlDocument $localizationPath
        }
        Add-ZylMapIssues -Issues $issues -AdditionalIssues @(
            Get-ZylRichMainlandConfigurationIssues `
                -ConfigurationXml $configurationXml `
                -LocalizationXml $localizationXml
        )
    }

    $bbmConfigurationPath = Join-Path $ProjectRoot 'Components\BBM\Configuration\Config.xml'
    if (-not (Test-Path -LiteralPath $bbmConfigurationPath -PathType Leaf)) {
        $issues.Add('BBM map-size configuration is missing.')
    }
    else {
        Add-ZylMapIssues -Issues $issues -AdditionalIssues @(
            Get-ZylBbmMapSizeConfigurationIssues `
                -ConfigurationXml (Load-XmlDocument $bbmConfigurationPath)
        )
    }

    foreach ($legacyReference in @(
            'zyl_mountainous_rich_mainland.lua',
            'ZYL_MountainousRichMainland_Config.xml',
            'ZYL_MountainousRichMainland_Text.xml',
            'ZYLMRM/ConfigureMap.sql'
        )) {
        if ($ModInfo.OuterXml -like "*$legacyReference*") {
            $issues.Add("Legacy Rich Mainland reference returned to ModInfo: $legacyReference")
        }
    }

    $criteria = @{
        'zyl_richmainland' = @('zyl_ffa_rich_mainland.lua', 'zyl_team_rich_mainland.lua')
        'zyl_richmainland_team' = @('zyl_team_rich_mainland.lua')
        'zyl_richmainland_ffa' = @('zyl_ffa_rich_mainland.lua')
    }
    foreach ($entry in $criteria.GetEnumerator()) {
        if (-not $CriteriaMap.ContainsKey($entry.Key)) {
            $issues.Add("Rich Mainland criterion is missing: $($entry.Key)")
            continue
        }
        $criterionNode = $CriteriaMap[$entry.Key]
        $actualMapScripts = @($criterionNode.SelectNodes('./ConfigurationValueMatches') | Where-Object {
                $_.SelectSingleNode('./Group').InnerText -eq 'Map' -and
                $_.SelectSingleNode('./ConfigurationId').InnerText -eq 'MAP_SCRIPT'
            } | ForEach-Object { $_.SelectSingleNode('./Value').InnerText } | Sort-Object)
        $expectedMapScripts = @($entry.Value | Sort-Object)
        if (($actualMapScripts -join '|') -ne ($expectedMapScripts -join '|')) {
            $issues.Add("Rich Mainland criterion $($entry.Key) has unexpected map scripts: $($actualMapScripts -join ', ')")
        }
    }
    if ($CriteriaMap.ContainsKey('zyl_richmainland') -and
            $CriteriaMap['zyl_richmainland'].GetAttribute('any') -ne '1') {
        $issues.Add('The shared Rich Mainland criterion must use OR semantics (any=1).')
    }

    $actions = @(
        @('zyl_richmainland_config', 'FrontEndActions', 'UpdateDatabase', 'Components/BBM/Configuration/ZYL_RichMainland_Config.xml', ''),
        @('zyl_richmainland_text', 'FrontEndActions', 'UpdateText', 'Components/BBM/Lang/ZYL_RichMainland_Text.xml', ''),
        @('zyl_richmainland_mapscripts', 'InGameActions', 'ImportFiles', 'Components/BBM/Data/BBS Maps/zyl_rich_mainland_core.lua', ''),
        @('zyl_richmainland_common', 'InGameActions', 'UpdateDatabase', 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureCommon.sql', 'ZYL_RichMainland'),
        @('zyl_richmainland_team_config', 'InGameActions', 'UpdateDatabase', 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureTeam.sql', 'ZYL_RichMainland_Team'),
        @('zyl_richmainland_ffa_config', 'InGameActions', 'UpdateDatabase', 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureFFA.sql', 'ZYL_RichMainland_FFA')
    )
    foreach ($requiredAction in $actions) {
        $actionKey = $requiredAction[0]
        if (-not $ActionIdMap.ContainsKey($actionKey)) {
            $issues.Add("Rich Mainland action is missing: $actionKey")
            continue
        }
        $actionNode = $ActionIdMap[$actionKey]
        if ($actionNode.ParentNode.LocalName -ne $requiredAction[1] -or
                $actionNode.LocalName -ne $requiredAction[2]) {
            $issues.Add("Rich Mainland action $actionKey is in the wrong section or has the wrong type.")
        }
        $expectedFileKey = Normalize-RelativePath $requiredAction[3]
        $actualFileKeys = @($actionNode.SelectNodes('./File') | ForEach-Object {
                Normalize-RelativePath $_.InnerText
            })
        if ($expectedFileKey -notin $actualFileKeys) {
            $issues.Add("Rich Mainland action $actionKey does not reference $($requiredAction[3]).")
        }
        if (-not [string]::IsNullOrWhiteSpace($requiredAction[4])) {
            $actualCriteria = @($actionNode.SelectNodes('./Criteria') | ForEach-Object {
                    $_.InnerText.Trim()
                })
            if ($requiredAction[4] -notin $actualCriteria) {
                $issues.Add("Rich Mainland action $actionKey is missing criterion $($requiredAction[4]).")
            }
        }
    }
    return @($issues)
}
