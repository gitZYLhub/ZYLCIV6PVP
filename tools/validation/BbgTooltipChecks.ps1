function Get-ZylBbgTooltipContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [System.Xml.XmlDocument]$EnglishDocumentOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # Lock the embedded BBG leader/unit tooltips whose upstream localizations were
    # stale or ambiguous relative to the gameplay database.
    $bbgEnglishPath = Join-Path $modRoot 'Components\BBG\lang\english.xml'
    $bbgChinesePath = Join-Path $modRoot 'Components\BBG\lang\chinese.xml'
    if (-not (Test-Path -LiteralPath $bbgEnglishPath) -or -not (Test-Path -LiteralPath $bbgChinesePath)) {
        $issues.Add('Embedded BBG English or Chinese localization is missing.')
    }
    else {
        $bbgEnglishXml = if ($PSBoundParameters.ContainsKey('EnglishDocumentOverride')) {
            $EnglishDocumentOverride
        }
        else {
            Load-XmlDocument $bbgEnglishPath
        }
        $bbgChineseXml = Load-XmlDocument $bbgChinesePath

        $sultanEnglishNode = $bbgEnglishXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_BBG_SULTAN_COMBAT_ADJACENT_APOSTLE_ABILITY_DESC' and @Language='en_US']/Text")
        if ($null -eq $sultanEnglishNode -or -not $sultanEnglishNode.InnerText.Contains('within 2 tiles')) {
            $issues.Add('Saladin (Sultan) English combat tooltip must target military units within 2 tiles of an Apostle.')
        }

        $tagmaChineseNode = $bbgChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_ABILITY_TAGMA_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
        foreach ($requiredFragment in @('普通陆地战斗单位', '+2 [ICON_Strength]', '宗教单位', '+2 [ICON_RELIGION]')) {
            if ($null -eq $tagmaChineseNode -or -not $tagmaChineseNode.InnerText.Contains($requiredFragment)) {
                $issues.Add("Tagma Chinese ability tooltip is missing: $requiredFragment")
            }
        }

        $norwayChineseNode = $bbgChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_THUNDERBOLT_EXPANSION2_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
        foreach ($requiredFragment in @('造船术', '海洋单元格', '营地')) {
            if ($null -eq $norwayChineseNode -or -not $norwayChineseNode.InnerText.Contains($requiredFragment)) {
                $issues.Add("Norway Chinese Gathering Storm tooltip is missing: $requiredFragment")
            }
        }

        $kublaiEnglishNode = $bbgEnglishXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_KUBLAI_DESCRIPTION' and @Language='en_US']/Text")
        if ($null -eq $kublaiEnglishNode -or -not $kublaiEnglishNode.InnerText.Contains('adjacent to another Great Wall') -or -not $kublaiEnglishNode.InnerText.Contains('+1 [ICON_CULTURE]')) {
            $issues.Add('Kublai English tooltip is missing the conditional Great Wall Culture bonus.')
        }
        $kublaiChineseNode = $bbgChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_KUBLAI_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
        foreach ($requiredFragment in @('与另一座长城相邻', '+1 [ICON_CULTURE]')) {
            if ($null -eq $kublaiChineseNode -or -not $kublaiChineseNode.InnerText.Contains($requiredFragment)) {
                $issues.Add("Kublai Chinese tooltip is missing: $requiredFragment")
            }
        }
    }

    $ramsesGameplayPath = Join-Path $modRoot 'Components\BBG\sql\LP\Ramses.sql'
    if (-not (Test-Path -LiteralPath $ramsesGameplayPath)) {
        $issues.Add('Ramses BBG gameplay SQL is missing.')
    }
    else {
        $ramsesGameplaySql = Get-Content -LiteralPath $ramsesGameplayPath -Raw
        foreach ($modifierId in @(
            'BBG_RAMSES_FLOODPLAINS_RESOURCE_FAITH_ON_BONUS_RESOURCE',
            'BBG_RAMSES_FLOODPLAINS_RESOURCE_FAITH_ON_LUX_RESOURCE',
            'BBG_RAMSES_FLOODPLAINS_RESOURCE_FAITH_ON_STRAT_RESOURCE',
            'BBG_RAMSES_FLOODPLAINS_RESOURCE_FOOD_ON_BONUS_RESOURCE',
            'BBG_RAMSES_FLOODPLAINS_RESOURCE_FOOD_ON_LUX_RESOURCE',
            'BBG_RAMSES_FLOODPLAINS_RESOURCE_FOOD_ON_STRAT_RESOURCE'
        )) {
            $escapedModifierId = [regex]::Escape($modifierId)
            if ($ramsesGameplaySql -notmatch "(?s)\(\s*'TRAIT_LEADER_RAMSES'\s*,\s*'$escapedModifierId'\s*\)") {
                $issues.Add("Ramses floodplain-resource modifier is not bound to his leader trait: $modifierId")
            }
        }
    }

    # Great People whose BBG actions were rewritten must not retain the obsolete
    # vanilla tooltip details.  Aethelflaed now creates a plain Trebuchet (the
    # modifier no longer grants a free promotion); Drake's production bonus is
    # 25% in the final BBG rules, not the stale 20% value in the embedded source.
    $greatPersonChinesePath = Join-Path $modRoot 'lang\ZYL_BBG74_Chinese_Text.xml'
    if (-not (Test-Path -LiteralPath $greatPersonChinesePath)) {
        $issues.Add('BBG Great People Chinese overlay is missing.')
    }
    else {
        $greatPersonChineseXml = Load-XmlDocument $greatPersonChinesePath
        $aethelflaedTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_GREATPERSON_AETHELFLAED_ACTIVE' and @Language='zh_Hans_CN']/Text")
        if ($null -eq $aethelflaedTextNode -or -not $aethelflaedTextNode.InnerText.Contains('投石机') -or $aethelflaedTextNode.InnerText.Contains('强化等级')) {
            $issues.Add('Aethelflaed Chinese tooltip must describe only a Trebuchet in the capital.')
        }
        $drakeTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_GREATPERSON_FRANCIS_DRAKE_EXPANSION2_ACTIVE' and @Language='zh_Hans_CN']/Text")
        if ($null -eq $drakeTextNode -or -not $drakeTextNode.InnerText.Contains('+25%') -or $drakeTextNode.InnerText.Contains('+20%')) {
            $issues.Add('Francis Drake Chinese tooltip must use the final +25% naval production bonus.')
        }
        foreach ($dharmaTag in @('LOC_TRAIT_CIVILIZATION_DHARMA_DESCRIPTION', 'LOC_TRAIT_CIVILIZATION_DHARMA_EXPANSION2_DESCRIPTION')) {
            $dharmaTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$dharmaTag' and @Language='zh_Hans_CN']/Text")
            if ($null -eq $dharmaTextNode -or -not $dharmaTextNode.InnerText.Contains('信奉您的主流宗教') -or -not $dharmaTextNode.InnerText.Contains('+1 [ICON_AMENITIES]') -or $dharmaTextNode.InnerText.Contains('拥有多个宗教')) {
                $issues.Add("India Dharma Chinese tooltip is stale or incomplete: $dharmaTag")
            }
        }
        foreach ($escorialTag in @('LOC_TRAIT_LEADER_EL_ESCORIAL_DESCRIPTION', 'LOC_TRAIT_LEADER_EL_ESCORIAL_EXPANSION2_DESCRIPTION')) {
            $escorialTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$escorialTag' and @Language='zh_Hans_CN']/Text")
            if ($null -eq $escorialTextNode -or -not $escorialTextNode.InnerText.Contains('信奉其他宗教的玩家') -or $escorialTextNode.InnerText.Contains('信仰其他宗教的单位')) {
                $issues.Add("Philip II Chinese tooltip must target players following other religions: $escorialTag")
            }
        }
    }

    return @($issues)
}
