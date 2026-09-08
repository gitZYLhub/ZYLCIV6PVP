function Get-ZylExpandedResourceContractIssues {
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
        [string]$BalanceSourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot
    $bbgExpandedChinesePath = Join-Path $modRoot 'lang\ZYL_BBGExpanded_Chinese.sql'

    # BBG Expanded's six resources are self-contained. Validate the complete art
    # manifest, the exact gameplay IDs, the BBG balance layer and the conditional
    # hand-off to a separately enabled full BBG Expanded package.
    $expandedResourceRoot = Join-Path $modRoot 'CIVITASResources'
    $expandedResourceTypes = @(
        'RESOURCE_P0K_PENGUINS',
        'RESOURCE_CVS_POMEGRANATES',
        'RESOURCE_P0K_PAPYRUS',
        'RESOURCE_P0K_MAPLE',
        'RESOURCE_P0K_OPAL',
        'RESOURCE_P0K_PLUMS'
    )
    $expandedResourceCorePath = Join-Path $expandedResourceRoot 'Core\p0k_Resources.sql'
    $expandedResourceBalancePath = Join-Path $modRoot 'Components\BBG\sql\BBG_Expanded\Resources.sql'
    if (-not (Test-Path -LiteralPath $expandedResourceCorePath)) {
        $issues.Add('BBG Expanded resource core SQL is missing.')
    }
    else {
        $expandedResourceCoreSql = Get-Content -LiteralPath $expandedResourceCorePath -Raw
        foreach ($resourceType in $expandedResourceTypes) {
            if (-not $expandedResourceCoreSql.Contains("('$resourceType'")) {
                $issues.Add("BBG Expanded resource core is missing $resourceType.")
            }
        }
        foreach ($resourceTag in @(
            'CLASS_GODDESS_OF_FESTIVALS',
            'CLASS_ORAL_TRADITION',
            'CLASS_SCIENCE',
            'CLASS_PRODUCTION'
        )) {
            if (-not $expandedResourceCoreSql.Contains($resourceTag)) {
                $issues.Add("BBG Expanded resource core is missing Pantheon/yield tag $resourceTag.")
            }
        }
    }
    if (-not (Test-Path -LiteralPath $expandedResourceBalancePath)) {
        $issues.Add('BBG Expanded resource balance SQL is missing.')
    }
    else {
        $expandedResourceBalanceSql = if ($PSBoundParameters.ContainsKey('BalanceSourceOverride')) {
            $BalanceSourceOverride
        }
        else {
            Get-Content -LiteralPath $expandedResourceBalancePath -Raw
        }
        foreach ($token in @(
            "('RESOURCE_P0K_PENGUINS', 'TERRAIN_COAST')",
            "('IMPROVEMENT_FISHING_BOATS', 'RESOURCE_P0K_PENGUINS', 1)",
            "('RESOURCE_P0K_PAPYRUS', 'YIELD_PRODUCTION', 1)"
        )) {
            if (-not $expandedResourceBalanceSql.Contains($token)) {
                $issues.Add("BBG Expanded resource balance is missing required behavior: $token")
            }
        }
    }

    $expandedResourceFiles = @()
    if (Test-Path -LiteralPath $expandedResourceRoot -PathType Container) {
        $expandedResourceFiles = @(
            Get-ChildItem -LiteralPath $expandedResourceRoot -Recurse -File
        )
    }
    if ($expandedResourceFiles.Count -ne 325) {
        $issues.Add("BBG Expanded resource package must contain 324 upstream files plus its license; found $($expandedResourceFiles.Count).")
    }
    foreach ($resourceFile in $expandedResourceFiles) {
        $relativeResourceFile = $resourceFile.FullName.Substring($modRoot.Length + 1)
        if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $relativeResourceFile))) {
            $issues.Add("BBG Expanded resource asset is absent from the manifest: $relativeResourceFile")
        }
    }

    $resourceDepPath = Join-Path $expandedResourceRoot 'CIVITAS Resources.dep'
    if (-not (Test-Path -LiteralPath $resourceDepPath)) {
        $issues.Add('BBG Expanded resource art dependency is missing.')
    }
    else {
        $resourceDep = Load-XmlDocument $resourceDepPath
        $resourceArtDefs = @($resourceDep.SelectNodes('//*[local-name()="ArtDefPath" or local-name()="ArtDefDependencyPaths"]//Element') |
            ForEach-Object { $_.GetAttribute('text') } | Where-Object { $_ -like '*.artdef' } | Sort-Object -Unique)
        foreach ($resourceArtDef in $resourceArtDefs) {
            if (-not (Test-Path -LiteralPath (Join-Path $expandedResourceRoot (Join-Path 'ArtDefs' $resourceArtDef)))) {
                $issues.Add("BBG Expanded resource ArtDef is missing: $resourceArtDef")
            }
        }
        $resourcePackages = @($resourceDep.SelectNodes('//*[local-name()="PackageDependencies"]/Element') |
            ForEach-Object { $_.GetAttribute('text') } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
        foreach ($platform in @('Windows', 'MacOS')) {
            foreach ($resourcePackage in $resourcePackages) {
                $resourcePackagePath = Join-Path $expandedResourceRoot ("Platforms\$platform\BLPs\$($resourcePackage.Replace('/', '\'))")
                if (-not (Test-Path -LiteralPath $resourcePackagePath)) {
                    $issues.Add("BBG Expanded resource art package is missing: $resourcePackagePath")
                }
            }
        }
    }

    $externalExpandedIds = @(
        '2a0aa96a-a31c-4ce2-87ec-09144f6f3e00',
        '2a0aa96a-a31c-4ce2-87ec-09152f6f3888',
        '2a0aa96a-a31c-4ce2-87ec-09152f6f3e00'
    )
    $noExternalExpandedCriterion = $criteriaMap['zyl_noexternalbbgexpanded']
    if ($null -eq $noExternalExpandedCriterion) {
        $issues.Add('The external BBG Expanded hand-off criterion is missing.')
    }
    else {
        foreach ($expandedId in $externalExpandedIds) {
            $inverseNode = $noExternalExpandedCriterion.SelectSingleNode("./ModInUse[@inverse='1' and .='$expandedId']")
            if ($null -eq $inverseNode) {
                $issues.Add("The external BBG Expanded hand-off criterion is missing $expandedId.")
            }
        }
    }
    $monopoliesCriterion = $criteriaMap['zyl_monopoliesmode']
    if ($null -eq $monopoliesCriterion -or
            $null -eq $monopoliesCriterion.SelectSingleNode("./ConfigurationValueMatches[Group='Game' and ConfigurationId='GAMEMODE_MONOPOLIES' and Value='1']")) {
        $issues.Add('BBG Expanded corporation content is not gated by the Monopolies mode.')
    }

    $expectedExpandedResourceActions = @{
        'zyl_bbgexpandedresources' = @('CIVITASResources/Core/p0k_Resources.sql')
        'zyl_bbgexpandedresourcesart' = @('CIVITASResources/CIVITAS Resources.dep')
        'zyl_bbgexpandedresourcesicons' = @('CIVITASResources/Core/CVS_Resource_Icon_Definitions.sql')
        'zyl_bbgexpandedresourcestext' = @('CIVITASResources/Core/p0k_Resources_Localisation.sql')
        'zyl_bbgexpandedresourcesmode' = @(
            'CIVITASResources/Core_MODE/p0k_Resources_MODE_Industries.sql',
            'CIVITASResources/Core_MODE/p0k_Resources_MODE_Products.sql',
            'CIVITASResources/Core_MODE/p0k_Resources_MODE_Projects.sql'
        )
        'zyl_bbgexpandedresourcesmodeicons' = @('CIVITASResources/Core_MODE/p0k_Resources_MODE_Icon_Definitions.sql')
        'zyl_bbgexpandedresourcesmodetext' = @('CIVITASResources/Core_MODE/p0k_Resources_MODE_Localisation.sql')
        'zyl_bbgexpandedresourcesbalance' = @('Components/BBG/sql/BBG_Expanded/Resources.sql')
    }
    foreach ($entry in $expectedExpandedResourceActions.GetEnumerator()) {
        $action = $actionIdMap[$entry.Key]
        if ($null -eq $action -or $null -eq $action.SelectSingleNode("./Criteria[.='ZYL_NoExternalBBGExpanded']")) {
            $issues.Add("BBG Expanded resource action is missing or not hand-off gated: $($entry.Key)")
            continue
        }
        foreach ($expectedFile in $entry.Value) {
            if ($null -eq $action.SelectSingleNode("./File[.='$expectedFile']")) {
                $issues.Add("BBG Expanded resource action $($entry.Key) is missing $expectedFile.")
            }
        }
        if ($entry.Key -like 'zyl_bbgexpandedresourcesmode*' -and
                $null -eq $action.SelectSingleNode("./Criteria[.='ZYL_MonopoliesMode']")) {
            $issues.Add("BBG Expanded company-mode action is not mode-gated: $($entry.Key)")
        }
    }

    # The upstream resource localizers generate English BaseGameText rows at
    # runtime, so XML-only audits cannot see their Chinese counterparts.  Keep the
    # final LocalizedText SQL active and verify every generated tag family.
    if (-not (Test-Path -LiteralPath $bbgExpandedChinesePath)) {
        $issues.Add('The BBG Expanded Simplified Chinese dynamic-text layer is missing.')
    }
    else {
        $expandedChineseSql = Get-Content -LiteralPath $bbgExpandedChinesePath -Raw
        if ($expandedChineseSql -notmatch '(?is)INSERT\s+OR\s+REPLACE\s+INTO\s+LocalizedText\s*\(\s*Language\s*,\s*Tag\s*,\s*Text\s*\)') {
            $issues.Add('BBG Expanded Chinese SQL does not insert into LocalizedText(Language, Tag, Text).')
        }
        if ($expandedChineseSql.Contains('TO_TRANSLATE') -or $expandedChineseSql.Contains('???')) {
            $issues.Add('BBG Expanded Chinese SQL contains an untranslated placeholder.')
        }

        $expectedExpandedChineseTags = [System.Collections.Generic.List[string]]::new()
        foreach ($resourceShort in @(
            'P0K_PENGUINS', 'CVS_POMEGRANATES', 'P0K_PAPYRUS',
            'P0K_MAPLE', 'P0K_OPAL', 'P0K_PLUMS'
        )) {
            $expectedExpandedChineseTags.Add("LOC_RESOURCE_${resourceShort}_NAME")
            $expectedExpandedChineseTags.Add("LOC_PEDIA_RESOURCES_PAGE_RESOURCE_${resourceShort}_CHAPTER_HISTORY_PARA_1")
            $expectedExpandedChineseTags.Add("LOC_PROJECT_CREATE_CORPORATION_PRODUCT_${resourceShort}_NAME")
            $expectedExpandedChineseTags.Add("LOC_PROJECT_CREATE_CORPORATION_PRODUCT_${resourceShort}_SHORT_NAME")
            $expectedExpandedChineseTags.Add("LOC_PROJECT_CREATE_CORPORATION_PRODUCT_${resourceShort}_DESCRIPTION")
            $expectedExpandedChineseTags.Add("LOC_PEDIA_CONCEPTS_${resourceShort}")
            foreach ($productIndex in 1..5) {
                $expectedExpandedChineseTags.Add("LOC_GREATWORK_PRODUCT_${resourceShort}_${productIndex}_NAME")
            }
        }
        foreach ($effect in @(
            'CITY_GROWTH_DISCOUNT', 'MILITARY_UNIT_DISCOUNT',
            'CIVILIAN_UNIT_DISCOUNT', 'BUILDING_DISCOUNT', 'GOLD_YIELD_BONUS',
            'FAITH_YIELD_BONUS', 'SCIENCE_YIELD_BONUS', 'CULTURE_YIELD_BONUS'
        )) {
            $expectedExpandedChineseTags.Add("LOC_P0K_RESOURCE_${effect}_DESCRIPTION")
            $expectedExpandedChineseTags.Add("LOC_INDUSTRY_${effect}_DESCRIPTION")
        }
        $expectedExpandedChineseTags.Add('LOC_BELIEF_GODDESS_OF_FESTIVALS_DESCRIPTION')
        $expectedExpandedChineseTags.Add('LOC_BELIEF_ORAL_TRADITION_DESCRIPTION')

        foreach ($tag in $expectedExpandedChineseTags) {
            $escapedTag = [regex]::Escape($tag)
            if ($expandedChineseSql -notmatch "(?i)'zh_Hans_CN'\s*,\s*'$escapedTag'") {
                $issues.Add("BBG Expanded dynamic Simplified Chinese Tag is missing: $tag")
            }
        }

        $expandedChineseAction = $actionIdMap['zyl_bbgexpandedchinesetext']
        $expandedChineseLoadOrderNode = if ($null -ne $expandedChineseAction) {
            $expandedChineseAction.SelectSingleNode('./Properties/LoadOrder')
        }
        else {
            $null
        }
        if ($null -eq $expandedChineseAction -or
                $expandedChineseAction.LocalName -ne 'UpdateText' -or
                $null -eq $expandedChineseAction.SelectSingleNode("./File[.='lang/ZYL_BBGExpanded_Chinese.sql']") -or
                $null -eq $expandedChineseLoadOrderNode -or
                $expandedChineseLoadOrderNode.InnerText.Trim() -ne '259999995') {
            $issues.Add('BBG Expanded Chinese SQL is not loaded as the final dynamic resource-text action.')
        }
        if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'lang/ZYL_BBGExpanded_Chinese.sql'))) {
            $issues.Add('BBG Expanded Chinese SQL is absent from the ModInfo <Files> manifest.')
        }
    }

    $standaloneResourcesBlock = $modInfo.SelectSingleNode("/Mod/Blocks/Mod[@id='664d17a5-f3be-493a-9332-8e20da1166fa']")
    if ($null -eq $standaloneResourcesBlock) {
        $issues.Add('Standalone CIVITAS Resources Expanded is not blocked after being embedded.')
    }

    return @($issues)
}
