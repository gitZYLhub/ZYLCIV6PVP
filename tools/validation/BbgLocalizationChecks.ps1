function Get-ZylBbgLocalizationContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object[]]$XmlFiles,

        [AllowNull()]
        [System.Xml.XmlDocument]$ChineseOverlayOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # The upstream Simplified Chinese file stopped following BBG's gameplay
    # changes.  Keep the final 7.4.6 synchronization layer structurally safe and
    # make missing Chinese rows impossible to reintroduce silently.
    $bbgChineseOverlayPath = Join-Path $modRoot 'lang\ZYL_BBG74_Chinese_Text.xml'
    $bbgChineseSourcePath = Join-Path $modRoot 'Components\BBG\lang\chinese.xml'
    $bbgExpandedChinesePath = Join-Path $modRoot 'lang\ZYL_BBGExpanded_Chinese.sql'
    if (-not (Test-Path -LiteralPath $bbgChineseOverlayPath)) {
        $issues.Add('The BBG 7.4.6 Simplified Chinese synchronization layer is missing.')
    }
    else {
        $bbgChineseOverlay = if ($PSBoundParameters.ContainsKey('ChineseOverlayOverride')) {
            $ChineseOverlayOverride
        }
        else {
            Load-XmlDocument $bbgChineseOverlayPath
        }
        $overlayRows = @($bbgChineseOverlay.SelectNodes('/GameData/LocalizedText/*[@Tag]'))
        foreach ($overlayRow in $overlayRows) {
            if ($overlayRow.GetAttribute('Language') -ne 'zh_Hans_CN') {
                $issues.Add("BBG Chinese overlay row is not zh_Hans_CN: $($overlayRow.GetAttribute('Tag'))")
            }
        }
        foreach ($duplicateTag in @($overlayRows | Group-Object { $_.GetAttribute('Tag').ToUpperInvariant() } | Where-Object Count -gt 1)) {
            $issues.Add("Duplicate Tag inside the BBG Chinese overlay: $($duplicateTag.Name)")
        }
        $overlayTextByTag = @{}
        foreach ($overlayRow in $overlayRows) {
            $overlayTextNode = $overlayRow.SelectSingleNode('./Text')
            if ($null -eq $overlayTextNode) {
                $issues.Add("BBG Chinese overlay row is missing Text: $($overlayRow.GetAttribute('Tag'))")
                continue
            }
            $overlayTextByTag[$overlayRow.GetAttribute('Tag').ToUpperInvariant()] =
                $overlayTextNode.InnerText
        }
        if (-not (Test-Path -LiteralPath $bbgChineseSourcePath)) {
            $issues.Add('The embedded upstream BBG Simplified Chinese source is missing.')
        }
        else {
            $bbgChineseSource = Load-XmlDocument $bbgChineseSourcePath
            foreach ($sourceRow in @($bbgChineseSource.SelectNodes('/GameData/LocalizedText/*[@Tag and @Language="zh_Hans_CN"]/Text'))) {
                $sourceText = $sourceRow.InnerText.Trim()
                # BBG accidentally shipped a block of French dialogue as zh_Hans_CN.
                # A Latin-only source row is acceptable only when the final overlay
                # deliberately reviews it and supplies a Chinese rendering.
                if ($sourceText -notmatch '[A-Za-z]' -or $sourceText -match '[\u3400-\u9FFF]') { continue }
                $sourceTag = $sourceRow.ParentNode.GetAttribute('Tag')
                $sourceKey = $sourceTag.ToUpperInvariant()
                if (-not $overlayTextByTag.ContainsKey($sourceKey)) {
                    $issues.Add("Latin-only text is still effective in the embedded BBG Simplified Chinese localization: $sourceTag")
                }
                elseif ($overlayTextByTag[$sourceKey] -notmatch '[\u3400-\u9FFF]') {
                    $issues.Add("The BBG Chinese overlay did not translate the Latin-only source row: $sourceTag")
                }
            }
        }
        $criticalChineseText = @{
            'LOC_ABILITY_BYZANTIUM_COMBAT_UNITS_DESCRIPTION' = @('+2 [ICON_STRENGTH]', '宗教压力')
            'LOC_ABILITY_BYZANTIUM_RELIGIOUS_UNITS_DESCRIPTION' = @('+3 [ICON_RELIGION]', '宗教单位')
            'LOC_BBG_NORWAY_MELEE_BOAT_COMBAT_ABILITY_NAME' = @('北境惊雷')
            'LOC_BBG_ABILITY_SULEIMAN_ALT_COMBAT_NAME' = @('大帝')
            'LOC_BBG_ABILITY_STRENGTH_NEXT_TO_ANTI_AIR_NAME' = @('航母编队')
            'LOC_BBG_ABILITY_STRENGTH_DEFENDING_FRIENDLY_NAME' = @('固守')
            'LOC_BBG_ABILITY_STRENGTH_ATTACKING_UNFRIENDLY_NAME' = @('闪击战')
            'LOC_TRAIT_CIVILIZATION_BYZANTIUM_DESCRIPTION' = @('+2 [ICON_STRENGTH]', '+3 [ICON_RELIGION]', '拜占庭的圣城')
            'LOC_TRAIT_LEADER_CLEOPATRA_ALT_DESCRIPTION' = @('进入古典时代后', '河流带来的', '+15%')
            'LOC_FEATURE_WHITEDESERT_DESCRIPTION' = @('+2 [ICON_SCIENCE] 科技值', '+2 [ICON_CULTURE]', '+6 [ICON_GOLD]')
            'LOC_FEATURE_BARRIER_REEF_DESCRIPTION' = @('占2个单元格', '+3 [ICON_FOOD]', '+1 [ICON_PRODUCTION]', '+2 [ICON_SCIENCE]')
            'LOC_FEATURE_EYJAFJALLAJOKULL_DESCRIPTION' = @('占2个单元格', '每个奇观单元格', '+1 [ICON_CULTURE]', '+1 [ICON_FOOD]')
            'LOC_FEATURE_EYJAFJALLAJOKULL_XP2_DESCRIPTION' = @('占2个单元格', '每个奇观单元格', '+1 [ICON_CULTURE]', '+1 [ICON_FOOD]')
            'LOC_BUILDING_ELECTRONICS_FACTORY_DESCRIPTION' = @('+4 [ICON_CULTURE]', '+3 [ICON_PRODUCTION]', '6单元格')
            'LOC_BUILDING_TSIKHE_DESCRIPTION_XP2' = @('+1 [ICON_CULTURE]', '+3 [ICON_FAITH]', '“保护地球”', '+3 [ICON_TOURISM]', '黄金或英雄时代')
            'LOC_BUILDING_SYDNEY_OPERA_HOUSE_DESCRIPTION' = @('+8 [ICON_CULTURE]', '+5 [ICON_GREATMUSICIAN]', '[ICON_GreatWork_Music]')
            'LOC_DISTRICT_ROYAL_NAVY_DOCKYARD_EXPANSION2_DESCRIPTION' = @('+1 [ICON_HOUSING]')
            'LOC_DISTRICT_ROYAL_NAVY_DOCKYARD_DESCRIPTION' = @('+1 [ICON_HOUSING]', '+1 [ICON_TRADEROUTE]', '+2 [ICON_GOLD]', '+4忠诚度')
            'LOC_DISTRICT_ROYAL_NAVY_DOCKYARD_EXPANSION1_DESCRIPTION' = @('+1 [ICON_HOUSING]', '+2 [ICON_GOLD]', '+4忠诚度')
            'LOC_DISTRICT_SEOWON_DESCRIPTION_ADJACENCY' = @('+2 [ICON_SCIENCE]', '+2 [ICON_CULTURE]')
            'LOC_BELIEF_INITIATION_RITES_EXPANSION2_DESCRIPTION' = @('40%', '[ICON_GOLD]')
            'LOC_BELIEF_RELIGIOUS_COMMUNITY_DESCRIPTION' = @('+5 [ICON_GOLD]', '+10 [ICON_GOLD]')
            'LOC_BELIEF_RELIGIOUS_COMMUNITY_EXPANSION2_DESCRIPTION' = @('+5 [ICON_GOLD]', '+10 [ICON_GOLD]')
            'LOC_BUILDING_ELECTRONICS_FACTORY_EXPANSION2_DESCRIPTION' = @('+4 [ICON_CULTURE]', '+3', '+5 [ICON_PRODUCTION]', '6')
            'LOC_TRAIT_CIVILIZATION_NOBEL_PRIZE_DESCRIPTION' = @('20', '+50% [ICON_PRODUCTION]', '工厂每回合+1 [ICON_GreatEngineer]', '大学每回合+1 [ICON_GreatScientist]', '北境之王')
            'LOC_TRAIT_LEADER_KRISTINA_AUTO_THEME_DESCRIPTION' = @('自动获得主题加成', '女王图书馆', '一级、二级、三级市政广场建筑', '+2 [ICON_GreatWriter]', '+2 [ICON_GreatArtist]', '+2 [ICON_GreatMusician]', '+2 [ICON_GreatScientist]', '+2 [ICON_GreatEngineer]')
            'LOC_CIVILIZATION_JERUSALEM_BONUS_EXPANSION' = @('12', '4')
            'LOC_GOVERNOR_PROMOTION_PASHA_DESCRIPTION' = @('25%', '3')
            'LOC_IMPROVEMENT_OUTBACK_STATION_DESCRIPTION' = @('+1 [ICON_FOOD]', '+1 [ICON_PRODUCTION]', '+0.5 [ICON_HOUSING]', '“紧急部署”市政后，每相邻两个内陆牧场+1 [ICON_FOOD]', '每个与内陆牧场相邻的牧场+1 [ICON_PRODUCTION]')
            'LOC_CIVILIZATION_LA_VENTA_BONUS_XP2' = @('+1 [ICON_FOOD]', '+2 [ICON_FAITH]', '+0.5 [ICON_HOUSING]')
            'LOC_LEADER_TRAIT_LA_VENTA_EXPANSION2_DESCRIPTION' = @('+1 [ICON_FOOD]', '+2 [ICON_FAITH]', '+0.5 [ICON_HOUSING]')
            'LOC_IMPROVEMENT_COLOSSAL_HEAD_EXPANSION2_DESCRIPTION' = @('+1 [ICON_FOOD]', '+2 [ICON_FAITH]', '+0.5 [ICON_HOUSING]')
            'LOC_IMPROVEMENT_STEPWELL_EXPANSION2_DESCRIPTION' = @('+1 [ICON_Housing] 住房', '“卫生设备”科技后再+1 [ICON_Housing] 住房')
            'LOC_IMPROVEMENT_MOAI_DESCRIPTION' = @('“中世纪集市”', '每相邻1座摩艾石像', '“飞行”', '[ICON_TOURISM]')
            'LOC_CIVILIZATION_RAPA_NUI_BONUS' = @('“中世纪集市”', '每相邻1座摩艾石像', '“飞行”', '[ICON_TOURISM]')
            'LOC_LEADER_TRAIT_RAPA_NUI_DESCRIPTION' = @('“中世纪集市”', '每相邻1座摩艾石像', '“飞行”', '[ICON_TOURISM]')
            'LOC_MOMENT_CATEGORY_EXPLORATION_BONUS_GOLDEN_AGE' = @('+3', '+2 [ICON_MOVEMENT]', '上船单位', '2个区域', '+100% [ICON_PRODUCTION]')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_4' = @('[ICON_RESOURCE_HORSES] 马', '[ICON_RESOURCE_IRON] 铁', '[ICON_RESOURCE_NITER] 硝石', '40%', '[ICON_CULTURE]')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_6' = @('+3', '+1时代得分', '+2 [ICON_MOVEMENT]', '上船单位', '2个区域', '+100% [ICON_PRODUCTION]')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_8' = @('+1时代得分', '+10%', '+25%')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_9' = @('[ICON_RESOURCE_NITER] 硝石', '[ICON_RESOURCE_OIL] 石油', '[ICON_RESOURCE_COAL] 煤', '50%', '[ICON_GOLD]')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_13' = @('“机器人技术”', '+25% [ICON_PRODUCTION]', '+3 [ICON_RESOURCE_URANIUM]')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_NORMAL_AGE' = @('着力点加成', '+1时代得分')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_DARK_AGE' = @('着力点加成', '+1时代得分')
            'LOC_PEDIA_CONCEPTS_PAGE_ALLIANCES_1_CHAPTER_CONTENT_PARA_1' = @('30', '[ICON_ENVOY]', '[ICON_PRODUCTION]', '[ICON_RELIGION]')
            'LOC_TRAIT_LEADER_SATYAGRAHA_EXPANSION2_DESCRIPTION' = @('+5 [ICON_FAITH]', '+1 [ICON_MOVEMENT]', '+50%')
            'LOC_TRAIT_CIVILIZATION_PAX_BRITANNICA_EXPANSION2_DESCRIPTION' = @('10', '[ICON_CAPITAL]', '[ICON_GREATADMIRAL]')
        }
        foreach ($entry in $criticalChineseText.GetEnumerator()) {
            $criticalRow = $bbgChineseOverlay.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$($entry.Key)' and @Language='zh_Hans_CN']/Text")
            if ($null -eq $criticalRow) {
                $issues.Add("Critical BBG 7.4.6 Chinese correction is missing: $($entry.Key)")
                continue
            }
            foreach ($requiredFragment in $entry.Value) {
                if (-not $criticalRow.InnerText.Contains($requiredFragment)) {
                    $issues.Add("Critical BBG Chinese correction $($entry.Key) is missing: $requiredFragment")
                }
            }
        }
        $negativeChineseTextRules = @{
            'LOC_ABILITY_BYZANTIUM_RELIGIOUS_UNITS_DESCRIPTION' = @('+2 [ICON_Strength]', '+2 [ICON_STRENGTH]')
            'LOC_TRAIT_CIVILIZATION_BYZANTIUM_DESCRIPTION' = @('或 [ICON_Religion] 宗教战斗力')
            'LOC_TRAIT_LEADER_CLEOPATRA_ALT_DESCRIPTION' = @('通过科技或市政进入古典时期')
            'LOC_FEATURE_WHITEDESERT_DESCRIPTION' = @('[ICON_SCIENCE] 生产力')
            'LOC_FEATURE_BARRIER_REEF_DESCRIPTION' = @('占1个单元格')
            'LOC_FEATURE_EYJAFJALLAJOKULL_DESCRIPTION' = @('为相邻单元格')
            'LOC_FEATURE_EYJAFJALLAJOKULL_XP2_DESCRIPTION' = @('为相邻单元格')
            'LOC_BUILDING_ELECTRONICS_FACTORY_DESCRIPTION' = @('+4 [ICON_PRODUCTION]')
            'LOC_TRAIT_CIVILIZATION_NOBEL_PRIZE_DESCRIPTION' = @('市政广场建筑分别每回合', '市政广场建筑每提升一级')
            'LOC_BELIEF_INITIATION_RITES_EXPANSION2_DESCRIPTION' = @('25%', '30%', '[ICON_FAITH]')
            'LOC_BUILDING_TSIKHE_DESCRIPTION_XP2' = @('+1 [ICON_TOURISM]', '[ICON_TOURISM] 旅游业绩+100%')
            'LOC_CIVILIZATION_JERUSALEM_BONUS_EXPANSION' = @('10')
            'LOC_LEADER_TRAIT_JERUSALEM_DESCRIPTION_EXPANSION' = @('10')
            'LOC_TRAIT_LEADER_SATYAGRAHA_DESCRIPTION' = @('[ICON_FAVOR]')
            'LOC_TRAIT_LEADER_SATYAGRAHA_EXPANSION2_DESCRIPTION' = @('[ICON_FAVOR]')
            'LOC_IMPROVEMENT_OUTBACK_STATION_DESCRIPTION' = @('“紧急部署”市政后，每相邻一个内陆牧场+1 [ICON_FOOD]')
            'LOC_CIVILIZATION_LA_VENTA_BONUS_XP2' = @('+1 [ICON_HOUSING]')
            'LOC_LEADER_TRAIT_LA_VENTA_EXPANSION2_DESCRIPTION' = @('+1 [ICON_HOUSING]')
            'LOC_IMPROVEMENT_COLOSSAL_HEAD_EXPANSION2_DESCRIPTION' = @('+1 [ICON_HOUSING]')
            'LOC_MOMENT_CATEGORY_EXPLORATION_BONUS_GOLDEN_AGE' = @('忠诚度')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_6' = @('忠诚度')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_4' = @('已解锁的战略资源')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_8' = @('+2时代得分', '以后得建筑')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_NORMAL_AGE' = @('黄金时代')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_DARK_AGE' = @('黄金时代')
            'LOC_MOMENT_CATEGORY_MILITARY_BONUS_NORMAL_AGE' = @('击杀1一个')
            'LOC_MOMENT_CATEGORY_MILITARY_BONUS_DARK_AGE' = @('击杀1一个')
        }
        foreach ($entry in $negativeChineseTextRules.GetEnumerator()) {
            $negativeRow = $bbgChineseOverlay.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$($entry.Key)' and @Language='zh_Hans_CN']/Text")
            if ($null -eq $negativeRow) { continue }
            foreach ($forbiddenFragment in $entry.Value) {
                if ($negativeRow.InnerText.Contains($forbiddenFragment)) {
                    $issues.Add("Critical BBG Chinese correction $($entry.Key) still contains obsolete text: $forbiddenFragment")
                }
            }
        }
    }

    $bbgEnglishPath = Join-Path $modRoot 'Components\BBG\lang\english.xml'
    if (-not (Test-Path -LiteralPath $bbgEnglishPath)) {
        $issues.Add('The embedded BBG English localization is missing.')
    }
    else {
        $bbgEnglish = Load-XmlDocument $bbgEnglishPath
        $criticalEnglishText = @{
            'LOC_IMPROVEMENT_MOAI_DESCRIPTION' = @('Medieval Faires', 'Flight')
            'LOC_ABILITY_BYZANTIUM_RELIGIOUS_UNITS_DESCRIPTION' = @('+3 [ICON_RELIGION]')
            'LOC_TRAIT_CIVILIZATION_BYZANTIUM_DESCRIPTION' = @('+2 [ICON_STRENGTH]', '+3 [ICON_RELIGION]', 'including Byzantium''s Holy City')
            'LOC_UNIT_BYZANTINE_TAGMA_DESCRIPTION' = @('within 1 tile', 'Non-religious land combat units', '+2 [ICON_STRENGTH]', 'religious units', '+2 [ICON_RELIGION]')
            'LOC_CIVILIZATION_ZANZIBAR_BONUS' = @('Banking', '6 [ICON_AMENITIES]')
            'LOC_LEADER_TRAIT_LA_VENTA_EXPANSION2_DESCRIPTION' = @('+0.5 [ICON_HOUSING]')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_4' = @('Horses, Iron, and Niter')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_8' = @('Gain +1 Era Score')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_9' = @('Niter, Oil, and Coal', '[ICON_GOLD] Gold', '50%')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_13' = @('Robotics', '+25% [ICON_PRODUCTION]')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_NORMAL_AGE' = @('Dedication Bonus')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_DARK_AGE' = @('Dedication Bonus')
            'LOC_BUILDING_ELECTRONICS_FACTORY_DESCRIPTION' = @('+3 [ICON_PRODUCTION]', '+4 [ICON_CULTURE]', 'within 6 tiles')
            'LOC_BUILDING_ELECTRONICS_FACTORY_EXPANSION2_DESCRIPTION' = @('+3 [ICON_PRODUCTION]', '+4 [ICON_CULTURE]', '+5 [ICON_PRODUCTION]', 'when powered')
        }
        foreach ($entry in $criticalEnglishText.GetEnumerator()) {
            $englishTextNode = $bbgEnglish.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$($entry.Key)' and @Language='en_US']/Text")
            if ($null -eq $englishTextNode) {
                $issues.Add("Critical BBG English row is missing: $($entry.Key)")
                continue
            }
            foreach ($requiredFragment in $entry.Value) {
                if (-not $englishTextNode.InnerText.Contains($requiredFragment)) {
                    $issues.Add("Critical BBG English correction $($entry.Key) is missing: $requiredFragment")
                }
            }
        }
        $obsoleteEnglishText = @{
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_4' = @('of each type discovered')
            'LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_PARA_8' = @('Gain +2 Era Score')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_NORMAL_AGE' = @('Golden Age')
            'LOC_MOMENT_CATEGORY_INFRASTRUCTURE_BONUS_DARK_AGE' = @('Golden Age')
            'LOC_BUILDING_ELECTRONICS_FACTORY_DESCRIPTION' = @('+5 [ICON_Culture]', '+5 [ICON_CULTURE]')
        }
        foreach ($entry in $obsoleteEnglishText.GetEnumerator()) {
            $englishTextNode = $bbgEnglish.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$($entry.Key)' and @Language='en_US']/Text")
            if ($null -eq $englishTextNode) { continue }
            foreach ($forbiddenFragment in $entry.Value) {
                if ($englishTextNode.InnerText.Contains($forbiddenFragment)) {
                    $issues.Add("Critical BBG English correction $($entry.Key) still contains obsolete text: $forbiddenFragment")
                }
            }
        }
    }

    $englishLocalizationTags = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $chineseLocalizationTags = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($xmlFile in $xmlFiles) {
        try { $textDocument = Load-XmlDocument $xmlFile.FullName }
        catch { continue }
        foreach ($englishRow in @($textDocument.SelectNodes('//*[( @Language="en_US" or @language="en_US" ) and @Tag]'))) {
            [void]$englishLocalizationTags.Add($englishRow.GetAttribute('Tag'))
        }
        foreach ($chineseRow in @($textDocument.SelectNodes('//*[( @Language="zh_Hans_CN" or @language="zh_Hans_CN" ) and @Tag]'))) {
            $tag = $chineseRow.GetAttribute('Tag')
            [void]$chineseLocalizationTags.Add($tag)
            $textNode = $chineseRow.SelectSingleNode('./Text')
            if ($null -eq $textNode) { continue }
            $textValue = $textNode.InnerText.Trim()
            if ($textValue -match 'TO_TRANSLATE|\?\?\?' -or $textValue -match '^LOC_[A-Z0-9_]+$') {
                $issues.Add("Untranslated placeholder in Simplified Chinese localization: $tag")
            }
        }
    }
    foreach ($englishTag in $englishLocalizationTags) {
        if (-not $chineseLocalizationTags.Contains($englishTag)) {
            $issues.Add("English localization Tag has no Simplified Chinese row anywhere in the package: $englishTag")
        }
    }

    return @($issues)
}
