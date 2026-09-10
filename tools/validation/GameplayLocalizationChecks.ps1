function Get-ZylGameplayLocalizationContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowEmptyString()]
        [string]$GameplayTextSourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # ZYL's final text must describe the same final rules as the late gameplay
    # override layer across every language and embedded upstream copy.
    $gameplayOverrideTextPath = Join-Path $modRoot 'lang\ZYL_GameplayOverrides_Text.xml'
    if (-not (Test-Path -LiteralPath $gameplayOverrideTextPath)) {
        $issues.Add('ZYL gameplay override localization is missing.')
    }
    else {
        $gameplayOverrideText = if ($PSBoundParameters.ContainsKey('GameplayTextSourceOverride')) {
            $GameplayTextSourceOverride
        }
        else {
            [System.IO.File]::ReadAllText(
                $gameplayOverrideTextPath,
                [System.Text.Encoding]::UTF8
            )
        }
        if ($PSBoundParameters.ContainsKey('GameplayTextSourceOverride')) {
            $gameplayOverrideTextXml = [System.Xml.XmlDocument]::new()
            $gameplayOverrideTextXml.PreserveWhitespace = $false
            $gameplayOverrideTextXml.LoadXml($gameplayOverrideText)
        }
        else {
            $gameplayOverrideTextXml = Load-XmlDocument $gameplayOverrideTextPath
        }
        foreach ($requiredTextToken in @(
            'LOC_TRAIT_CIVILIZATION_MALI_GOLD_DESERT_DESCRIPTION',
            'LOC_TRAIT_LEADER_SAHEL_MERCHANTS_DESCRIPTION',
            'LOC_TRAIT_LEADER_SUNDIATA_KEITA_DESCRIPTION',
            'LOC_TRAIT_LEADER_RIGHTEOUSNESS_OF_FAITH_DESCRIPTION',
            'LOC_TRAIT_LEADER_SALADIN_ALT_DESCRIPTION',
            'LOC_BBG_SULTAN_COMBAT_ADJACENT_APOSTLE_ABILITY_DESC',
            'LOC_BBG_SULTAN_CS_FROM_APOSTLE_ABILITY_DESC',
            'LOC_BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_MODIFIER_DESC',
            'LOC_TRAIT_CIVILIZATION_NOBEL_PRIZE_DESCRIPTION',
            'LOC_TRAIT_LEADER_KRISTINA_AUTO_THEME_DESCRIPTION',
            'LOC_TRAIT_LEADER_RAMSES_DESCRIPTION',
            'LOC_TRAIT_CIVILIZATION_WONDER_TOURISM_DESCRIPTION',
            'LOC_TRAIT_LEADER_MAGNIFICENCES_DESCRIPTION',
            'LOC_TRAIT_CIVILIZATION_MOTHER_RUSSIA_DESCRIPTION',
            'LOC_TRAIT_CIVILIZATION_MOTHER_RUSSIA_EXPANSION2_DESCRIPTION',
            'LOC_TRAIT_CIVILIZATION_MAORI_MANA_DESCRIPTION',
            'LOC_TRAIT_LEADER_TRAJANS_COLUMN_DESCRIPTION',
            'LOC_TRAIT_CIVILIZATION_GAUL_DESCRIPTION',
            'LOC_TRAIT_CIVILIZATION_KHMER_BARAYS_EXPANSION2_DESCRIPTION',
            'LOC_LEADER_POUNDMAKER_ABILITY_DESCRIPTION'
        )) {
            if (-not $gameplayOverrideText.Contains($requiredTextToken)) {
                $issues.Add("Gameplay override localization is missing invariant: $requiredTextToken")
            }
        }
        foreach ($maoriTextSpec in @(
            @('en_US', 'with Sailing', 'with Early Empire', 'with Foreign Trade', 'with Ship Building', 'Resources cannot be harvested'),
            @('zh_Hans_CN', '“航海术”科技后', '“帝国初期”市政后', '“对外贸易”市政后', '“造船术”科技后', '无法收获资源')
        )) {
            $maoriTextNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_MAORI_MANA_DESCRIPTION' and @Language='$($maoriTextSpec[0])']/Text")
            if ($null -eq $maoriTextNode -or
                    -not $maoriTextNode.InnerText.Contains($maoriTextSpec[1]) -or
                    -not $maoriTextNode.InnerText.Contains($maoriTextSpec[2])) {
                $issues.Add("Maori $($maoriTextSpec[0]) text does not describe the Sailing / Early Empire unlocks.")
                continue
            }
            foreach ($obsoleteFragment in @($maoriTextSpec[3], $maoriTextSpec[4], $maoriTextSpec[5])) {
                if ($maoriTextNode.InnerText.Contains($obsoleteFragment)) {
                    $issues.Add("Maori $($maoriTextSpec[0]) text still contains obsolete unlock text: $obsoleteFragment")
                }
            }
        }
        $maliText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_MALI_GOLD_DESERT_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        foreach ($requiredFragment in @('+2 [ICON_FOOD]', '+1 [ICON_PRODUCTION]', '市中心+2 [ICON_FAITH]', '所有矿山-1 [ICON_PRODUCTION]', '+4 [ICON_GOLD]')) {
            if (-not $maliText.Contains($requiredFragment)) {
                $issues.Add("Mali Chinese text is missing: $requiredFragment")
            }
        }
        foreach ($removedFragment in @('-5%', '−5%', '对外贸易', '4 [ICON_FOOD]', '生产力和+1 [ICON_FAITH]', '沙漠或沙漠丘陵上的矿山+2')) {
            if ($maliText.Contains($removedFragment)) {
                $issues.Add("Mali Chinese text still claims a removed or global-only rule: $removedFragment")
            }
        }
        $sahelText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_SAHEL_MERCHANTS_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        foreach ($requiredFragment in @('黄金时代', '永久+1 [ICON_TRADEROUTE]', '+2 [ICON_GOLD]', '曼丁哥市场')) {
            if (-not $sahelText.Contains($requiredFragment)) {
                $issues.Add("Mansa Musa Chinese text is missing: $requiredFragment")
            }
        }
        if ($sahelText.Contains('银行业')) {
            $issues.Add('Mansa Musa Chinese text still claims the removed Banking unlock.')
        }
        if ($sahelText.Contains('大量相邻加成')) {
            $issues.Add('Mansa Musa Chinese text still uses a qualitative adjacency value instead of the final +2 Gold.')
        }
        if ($sahelText.Contains('+15%') -or $sahelText.Contains('建造圣地')) {
            $issues.Add('Mansa Musa Chinese text still claims the removed Holy Site Production bonus.')
        }

        foreach ($khmerTextSpec in @(
            @('Components\BBG\lang\english.xml', 'en_US', 'standard +1 [ICON_FAITH] Faith adjacency bonus from Rivers'),
            @('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '标准+1 [ICON_FAITH] 信仰值相邻加成'),
            @('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '标准+1 [ICON_FAITH] 信仰值相邻加成'),
            @('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', 'standard +1 [ICON_FAITH] Faith adjacency bonus from Rivers'),
            @('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '标准+1 [ICON_FAITH] 信仰值相邻加成'),
            @('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hant_HK', '標準+1 [ICON_FAITH] 信仰值相鄰加成')
        )) {
            $khmerTextPath = Join-Path $modRoot $khmerTextSpec[0]
            if (-not (Test-Path -LiteralPath $khmerTextPath)) {
                $issues.Add("Khmer localization file is missing: $($khmerTextSpec[0])")
                continue
            }
            $khmerTextXml = Load-XmlDocument $khmerTextPath
            $khmerTextNode = $khmerTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_KHMER_BARAYS_EXPANSION2_DESCRIPTION' and @Language='$($khmerTextSpec[1])']/Text")
            if ($null -eq $khmerTextNode -or -not $khmerTextNode.InnerText.Contains($khmerTextSpec[2])) {
                $issues.Add("Khmer $($khmerTextSpec[1]) text does not describe the standard river adjacency bonus: $($khmerTextSpec[0])")
                continue
            }
        }

        foreach ($creeperTextSpec in @(
            @('Components\BBG\lang\english.xml', 'en_US', '+1 [ICON_FOOD] Food', 'per Camp or Pasture', '+1 [ICON_GOLD] Gold'),
            @('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '+1 [ICON_FOOD] 食物', '每有一座营地或牧场', '+1 [ICON_GOLD] 金币'),
            @('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '+1 [ICON_FOOD] 食物', '每有一座营地或牧场', '+1 [ICON_GOLD] 金币'),
            @('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', '+1 [ICON_FOOD] Food', 'per Camp or Pasture', '+1 [ICON_GOLD] Gold'),
            @('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '+1 [ICON_FOOD] 食物', '每有一座营地或牧场', '+1 [ICON_GOLD] 金币'),
            @('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hant_HK', '+1 [ICON_FOOD] 食物', '每有一座露營地或牧場', '+1 [ICON_GOLD] 金幣')
        )) {
            $creeperTextPath = Join-Path $modRoot $creeperTextSpec[0]
            if (-not (Test-Path -LiteralPath $creeperTextPath)) {
                $issues.Add("Cree localization file is missing: $($creeperTextSpec[0])")
                continue
            }
            $creeperTextXml = Load-XmlDocument $creeperTextPath
            $creeperTextNode = $creeperTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_LEADER_POUNDMAKER_ABILITY_DESCRIPTION' and @Language='$($creeperTextSpec[1])']/Text")
            if ($null -eq $creeperTextNode -or -not $creeperTextNode.InnerText.Contains($creeperTextSpec[2]) -or -not $creeperTextNode.InnerText.Contains($creeperTextSpec[3]) -or -not $creeperTextNode.InnerText.Contains($creeperTextSpec[4])) {
                $issues.Add("Cree $($creeperTextSpec[1]) text does not describe +1 outgoing Food per Camp/Pasture and +1 incoming Gold: $($creeperTextSpec[0])")
                continue
            }
            if ($creeperTextNode.InnerText.Contains('最多') -or $creeperTextNode.InnerText.Contains('up to')) {
                $issues.Add("Cree $($creeperTextSpec[1]) text incorrectly claims an unsupported improvement-count cap: $($creeperTextSpec[0])")
            }
            $oldCreeFood = if ($creeperTextSpec[1] -eq 'en_US') { '+0.5 [ICON_FOOD] Food' } else { '+0.5 [ICON_FOOD] 食物' }
            if ($creeperTextNode.InnerText.Contains($oldCreeFood)) {
                $issues.Add("Cree $($creeperTextSpec[1]) text still claims +0.5 outgoing Food: $($creeperTextSpec[0])")
            }
        }
        foreach ($language in @('zh_Hans_CN', 'en_US')) {
            $sugubaNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_DISTRICT_SUGUBA_DESCRIPTION' and @Language='$language']/Text")
            if ($null -eq $sugubaNode -or -not $sugubaNode.InnerText.Contains('10%') -or $sugubaNode.InnerText.Contains('20%')) {
                $issues.Add("Suguba $language text must describe a 10% purchase discount and no obsolete 20% discount.")
            }
        }

        $vizierText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_RIGHTEOUSNESS_OF_FAITH_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        if (([regex]::Matches($vizierText, '5%')).Count -ne 3 -or $vizierText.Contains('20%')) {
            $issues.Add('Saladin (Vizier) Chinese text must describe three separate 5% stages and no obsolete 20% stage.')
        }
        $sultanText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_SALADIN_ALT_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        foreach ($requiredFragment in @('2', '+5', '-1', '[ICON_FAITH]', '[ICON_GOLD]')) {
            if (-not $sultanText.Contains($requiredFragment)) {
                $issues.Add("Saladin (Sultan) Chinese text is missing: $requiredFragment")
            }
        }
        foreach ($abilityTag in @('LOC_BBG_SULTAN_COMBAT_ADJACENT_APOSTLE_ABILITY_DESC', 'LOC_BBG_SULTAN_CS_FROM_APOSTLE_ABILITY_DESC')) {
            $abilityText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$abilityTag' and @Language='zh_Hans_CN']/Text").InnerText
            foreach ($requiredFragment in @('2', '+5', '[ICON_STRENGTH]')) {
                if (-not $abilityText.Contains($requiredFragment)) {
                    $issues.Add("Saladin (Sultan) ability tooltip $abilityTag is missing: $requiredFragment")
                }
            }
        }
        $sundiataText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_SUNDIATA_KEITA_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        foreach ($requiredFragment in @('30%', '+1', '2', '+2', '+4', '[ICON_GreatWriter]', '[ICON_GREATWORK_WRITING]')) {
            if (-not $sundiataText.Contains($requiredFragment)) {
                $issues.Add("Sundiata Keita Chinese text is missing: $requiredFragment")
            }
        }
        if ($sundiataText.Contains('20%')) {
            $issues.Add('Sundiata Keita Chinese text still contains the obsolete 20% purchase discount.')
        }
        $swedenText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_NOBEL_PRIZE_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        foreach ($requiredFragment in @('20', '+50%', '工厂每回合+1', '大学每回合+1', '北境之王')) {
            if (-not $swedenText.Contains($requiredFragment)) {
                $issues.Add("Sweden civilization Chinese text is missing: $requiredFragment")
            }
        }
        foreach ($leaderOnlyFragment in @('大作家', '大艺术家', '大音乐家')) {
            if ($swedenText.Contains($leaderOnlyFragment)) {
                $issues.Add("Sweden civilization text still claims Kristina's Government Plaza Great Person points: $leaderOnlyFragment")
            }
        }
        $kristinaText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_KRISTINA_AUTO_THEME_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        foreach ($requiredFragment in @('自动获得主题加成', '女王图书馆', '一级、二级、三级市政广场建筑', '大作家', '大艺术家', '大音乐家', '大科学家', '大工程师')) {
            if (-not $kristinaText.Contains($requiredFragment)) {
                $issues.Add("Kristina Chinese text is missing: $requiredFragment")
            }
        }
        $ramsesText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_RAMSES_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
        foreach ($requiredFragment in @('泛滥平原', '已改良', '+1 [ICON_FOOD]', '+1 [ICON_FAITH]', '+1 [ICON_PRODUCTION]', '+15%')) {
            if (-not $ramsesText.Contains($requiredFragment)) {
                $issues.Add("Ramses II Chinese text is missing: $requiredFragment")
            }
        }
        $magnificenceChineseNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_MAGNIFICENCES_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
        $magnificenceEnglishNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_MAGNIFICENCES_DESCRIPTION' and @Language='en_US']/Text")
        if ($null -eq $magnificenceChineseNode -or
                -not $magnificenceChineseNode.InnerText.Contains('“技艺”市政后，奢侈资源+1') -or
                -not $magnificenceChineseNode.InnerText.Contains('“封建主义”市政后，加成资源+1') -or
                -not $magnificenceChineseNode.InnerText.Contains('“城堡”科技后，战略资源+1')) {
            $issues.Add('Magnificence Chinese text does not describe the Luxury/Bonus/Strategic staggered Culture unlocks.')
        }
        if ($null -eq $magnificenceEnglishNode -or
                -not $magnificenceEnglishNode.InnerText.Contains('Luxury resources gain +1') -or
                -not $magnificenceEnglishNode.InnerText.Contains('Bonus resources gain +1') -or
                -not $magnificenceEnglishNode.InnerText.Contains('Strategic resources gain +1')) {
            $issues.Add('Magnificence English text does not describe the Luxury/Bonus/Strategic staggered Culture unlocks.')
        }
        $franceChineseNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_WONDER_TOURISM_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
        $franceEnglishNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_WONDER_TOURISM_DESCRIPTION' and @Language='en_US']/Text")
        if ($null -eq $franceChineseNode -or -not $franceChineseNode.InnerText.Contains('出生地关联：T4河流、T4奢侈资源')) {
            $issues.Add('France Chinese civilization text does not describe its T4 River and Luxury resource biases.')
        }
        if ($null -eq $franceEnglishNode -or -not $franceEnglishNode.InnerText.Contains('Bias: T4 Rivers, T4 Luxury resources')) {
            $issues.Add('France English civilization text does not describe its T4 River and Luxury resource biases.')
        }
        if ($magnificenceChineseNode.InnerText.Contains('出生地关联') -or $magnificenceEnglishNode.InnerText.Contains('Bias:')) {
            $issues.Add('France Luxury resource bias is still presented as a Magnificence-only leader rule.')
        }
        foreach ($russiaTag in @('LOC_TRAIT_CIVILIZATION_MOTHER_RUSSIA_DESCRIPTION', 'LOC_TRAIT_CIVILIZATION_MOTHER_RUSSIA_EXPANSION2_DESCRIPTION')) {
            $russiaEnglishNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$russiaTag' and @Language='en_US']/Text")
            $russiaChineseNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$russiaTag' and @Language='zh_Hans_CN']/Text")
            if ($null -eq $russiaEnglishNode -or -not $russiaEnglishNode.InnerText.Contains('tiles in a city with a Lavra provide +1') -or -not $russiaEnglishNode.InnerText.Contains('regardless of adjacency')) {
                $issues.Add("Russia English text does not describe city-wide Tundra Faith after building a Lavra: $russiaTag")
            }
            if ($null -eq $russiaChineseNode -or -not $russiaChineseNode.InnerText.Contains('拥有拉夫拉修道院的城市，其冻土和冻土丘陵提供+1') -or -not $russiaChineseNode.InnerText.Contains('无论是否相邻')) {
                $issues.Add("Russia Chinese text does not describe city-wide Tundra Faith after building a Lavra: $russiaTag")
            }
        }
    }

    return @($issues)
}
