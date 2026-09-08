function Get-ZylMonopoliesContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [AllowEmptyString()]
        [string]$BalanceSourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # Keep the Team PVP Balanced Industries/Corporations nerf complete. The
    # upstream balance file omitted four DLC products, and this package adds six
    # more products through its embedded BBG Expanded resources.
    $monopoliesBalancePath = Join-Path $modRoot 'sql\ZYL_MonopoliesBalance.sql'
    $monopoliesTextPath = Join-Path $modRoot 'lang\ZYL_MonopoliesBalance_Text.xml'
    $expectedMonopoliesAmounts = @{
        'INDUSTRY_CITY_GROWTH' = 10
        'INDUSTRY_MILITARY_UNIT_DISCOUNT' = 15
        'INDUSTRY_CIVILIAN_UNIT_DISCOUNT' = 15
        'INDUSTRY_BUILDING_DISCOUNT' = 15
        'INDUSTRY_GOLD_YIELD_BONUS' = 15
        'INDUSTRY_FAITH_YIELD_BONUS' = 20
        'INDUSTRY_SCIENCE_YIELD_BONUS' = 7
        'INDUSTRY_CULTURE_YIELD_BONUS' = 7
        'CORPORATION_CITY_GROWTH' = 20
        'CORPORATION_MILITARY_UNIT_DISCOUNT' = 30
        'CORPORATION_CIVILIAN_UNIT_DISCOUNT' = 30
        'CORPORATION_BUILDING_DISCOUNT' = 30
        'CORPORATION_GOLD_YIELD_BONUS' = 30
        'CORPORATION_FAITH_YIELD_BONUS' = 40
        'CORPORATION_SCIENCE_YIELD_BONUS' = 15
        'CORPORATION_CULTURE_YIELD_BONUS' = 15
        'PRODUCT_BUILDING_DISCOUNT_GYPSUM' = 15
        'PRODUCT_BUILDING_DISCOUNT_MARBLE' = 15
        'PRODUCT_MILITARY_UNIT_DISCOUNT_CITRUS' = 15
        'PRODUCT_MILITARY_UNIT_DISCOUNT_COTTON' = 15
        'PRODUCT_MILITARY_UNIT_DISCOUNT_IVORY' = 15
        'PRODUCT_MILITARY_UNIT_DISCOUNT_TOBACCO' = 15
        'PRODUCT_MILITARY_UNIT_DISCOUNT_WHALES' = 15
        'PRODUCT_CITY_GROWTH_COCOA' = 10
        'PRODUCT_CITY_GROWTH_HONEY' = 10
        'PRODUCT_CITY_GROWTH_SALT' = 10
        'PRODUCT_CITY_GROWTH_SUGAR' = 10
        'PRODUCT_CULTURE_YIELD_BONUS_COFFEE' = 7
        'PRODUCT_CULTURE_YIELD_BONUS_SILK' = 7
        'PRODUCT_CULTURE_YIELD_BONUS_SPICES' = 7
        'PRODUCT_CULTURE_YIELD_BONUS_WINE' = 7
        'PRODUCT_GOLD_YIELD_BONUS_DIAMONDS' = 15
        'PRODUCT_GOLD_YIELD_BONUS_JADE' = 15
        'PRODUCT_GOLD_YIELD_BONUS_SILVER' = 15
        'PRODUCT_GOLD_YIELD_BONUS_TRUFFLES' = 15
        'PRODUCT_FAITH_YIELD_BONUS_AMBER' = 20
        'PRODUCT_FAITH_YIELD_BONUS_DYES' = 20
        'PRODUCT_FAITH_YIELD_BONUS_INCENSE' = 20
        'PRODUCT_FAITH_YIELD_BONUS_PEARLS' = 20
        'PRODUCT_SCIENCE_YIELD_BONUS_MERCURY' = 7
        'PRODUCT_SCIENCE_YIELD_BONUS_TEA' = 7
        'PRODUCT_SCIENCE_YIELD_BONUS_TURTLES' = 7
        'PRODUCT_CIVILIAN_UNIT_DISCOUNT_FURS' = 15
        'PRODUCT_CIVILIAN_UNIT_DISCOUNT_OLIVES' = 15
        'PRODUCT_SCIENCE_YIELD_BONUS_P0K_PENGUINS' = 7
        'PRODUCT_FAITH_YIELD_BONUS_CVS_POMEGRANATES' = 20
        'PRODUCT_SCIENCE_YIELD_BONUS_P0K_PAPYRUS' = 7
        'PRODUCT_CITY_GROWTH_MAPLE' = 10
        'PRODUCT_GOLD_YIELD_BONUS_P0K_OPAL' = 15
        'PRODUCT_CULTURE_YIELD_BONUS_P0K_PLUMS' = 7
    }
    if (-not (Test-Path -LiteralPath $monopoliesBalancePath)) {
        $issues.Add('The Industries/Corporations balance SQL is missing.')
    }
    else {
        $monopoliesBalanceSource = if ($PSBoundParameters.ContainsKey('BalanceSourceOverride')) {
            $BalanceSourceOverride
        }
        else {
            Get-Content -LiteralPath $monopoliesBalancePath -Raw
        }
        $amountPattern = "UPDATE\s+ModifierArguments\s+SET\s+Value\s*=\s*'(?<Value>\d+)'\s+WHERE\s+ModifierId\s*=\s*'(?<Id>[^']+)'\s+AND\s+Name\s*=\s*'Amount'\s*;"
        $actualMonopoliesAmounts = @{}
        foreach ($amountMatch in [regex]::Matches($monopoliesBalanceSource, $amountPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $modifierId = $amountMatch.Groups['Id'].Value.ToUpperInvariant()
            if ($actualMonopoliesAmounts.ContainsKey($modifierId)) {
                $issues.Add("Duplicate Industries/Corporations balance assignment: $modifierId")
            }
            $actualMonopoliesAmounts[$modifierId] = [int]$amountMatch.Groups['Value'].Value
        }
        foreach ($entry in $expectedMonopoliesAmounts.GetEnumerator()) {
            if (-not $actualMonopoliesAmounts.ContainsKey($entry.Key)) {
                $issues.Add("Industries/Corporations balance assignment is missing: $($entry.Key)")
            }
            elseif ($actualMonopoliesAmounts[$entry.Key] -ne $entry.Value) {
                $issues.Add("Industries/Corporations balance value is wrong for $($entry.Key): expected $($entry.Value), found $($actualMonopoliesAmounts[$entry.Key])")
            }
        }
        if ($actualMonopoliesAmounts.Count -ne $expectedMonopoliesAmounts.Count) {
            $issues.Add("Industries/Corporations balance assignment count is $($actualMonopoliesAmounts.Count), expected $($expectedMonopoliesAmounts.Count).")
        }
        if ($monopoliesBalanceSource.Contains('PRODUCT_CITY_GROWTH_HOUSING_MAPLE')) {
            $issues.Add('The Maple product housing bonus must remain +3 and must not be changed by the balance layer.')
        }
    }

    $monopoliesDatabaseAction = $modInfo.SelectSingleNode('/Mod/InGameActions/UpdateDatabase[@id="ZYL_MonopoliesBalance" and Criteria="ZYL_MonopoliesMode"]')
    $monopoliesDatabaseLoadOrderNode = if ($null -ne $monopoliesDatabaseAction) {
        $monopoliesDatabaseAction.SelectSingleNode('./Properties/LoadOrder')
    }
    else {
        $null
    }
    if ($null -eq $monopoliesDatabaseAction -or
            $monopoliesDatabaseAction.SelectSingleNode('./File[.="sql/ZYL_MonopoliesBalance.sql"]') -eq $null -or
            $null -eq $monopoliesDatabaseLoadOrderNode -or
            $monopoliesDatabaseLoadOrderNode.InnerText -ne '260000015') {
        $issues.Add('The Industries/Corporations balance SQL is not registered as a late, Monopolies-only database action.')
    }
    $monopoliesTextAction = $modInfo.SelectSingleNode('/Mod/InGameActions/UpdateText[@id="ZYL_MonopoliesBalanceText" and Criteria="ZYL_MonopoliesMode"]')
    $monopoliesTextLoadOrderNode = if ($null -ne $monopoliesTextAction) {
        $monopoliesTextAction.SelectSingleNode('./Properties/LoadOrder')
    }
    else {
        $null
    }
    if ($null -eq $monopoliesTextAction -or
            $monopoliesTextAction.SelectSingleNode('./File[.="lang/ZYL_MonopoliesBalance_Text.xml"]') -eq $null -or
            $null -eq $monopoliesTextLoadOrderNode -or
            $monopoliesTextLoadOrderNode.InnerText -ne '260000025') {
        $issues.Add('The Industries/Corporations Chinese text is not registered as a late, Monopolies-only text action.')
    }
    if (-not (Test-Path -LiteralPath $monopoliesTextPath)) {
        $issues.Add('The Industries/Corporations Simplified Chinese text layer is missing.')
    }
    else {
        $monopoliesText = Load-XmlDocument $monopoliesTextPath
        $monopoliesTextRows = @($monopoliesText.SelectNodes('/GameData/LocalizedText/*[@Tag]'))
        foreach ($row in $monopoliesTextRows) {
            if ($row.GetAttribute('Language') -ne 'zh_Hans_CN') {
                $issues.Add("Non-Simplified-Chinese row in Industries/Corporations text: $($row.GetAttribute('Tag'))")
            }
        }
        $requiredMonopoliesChinese = @{
            'LOC_INDUSTRY_CITY_GROWTH_DISCOUNT_DESCRIPTION' = @('+10%', '+3 [ICON_Housing]')
            'LOC_INDUSTRY_MILITARY_UNIT_DISCOUNT_DESCRIPTION' = @('+15%')
            'LOC_INDUSTRY_CIVILIAN_UNIT_DISCOUNT_DESCRIPTION' = @('+15%')
            'LOC_INDUSTRY_BUILDING_DISCOUNT_DESCRIPTION' = @('+15%')
            'LOC_INDUSTRY_GOLD_YIELD_BONUS_DESCRIPTION' = @('+15%')
            'LOC_INDUSTRY_FAITH_YIELD_BONUS_DESCRIPTION' = @('+20%')
            'LOC_INDUSTRY_SCIENCE_YIELD_BONUS_DESCRIPTION' = @('+7%')
            'LOC_INDUSTRY_CULTURE_YIELD_BONUS_DESCRIPTION' = @('+7%')
            'LOC_CORPORATION_CITY_GROWTH_DISCOUNT_DESCRIPTION' = @('+20%', '+6 [ICON_Housing]')
            'LOC_CORPORATION_MILITARY_UNIT_DISCOUNT_DESCRIPTION' = @('+30%')
            'LOC_CORPORATION_CIVILIAN_UNIT_DISCOUNT_DESCRIPTION' = @('+30%')
            'LOC_CORPORATION_BUILDING_DISCOUNT_DESCRIPTION' = @('+30%')
            'LOC_CORPORATION_GOLD_YIELD_BONUS_DESCRIPTION' = @('+30%')
            'LOC_CORPORATION_FAITH_YIELD_BONUS_DESCRIPTION' = @('+40%')
            'LOC_CORPORATION_SCIENCE_YIELD_BONUS_DESCRIPTION' = @('+15%')
            'LOC_CORPORATION_CULTURE_YIELD_BONUS_DESCRIPTION' = @('+15%')
            'LOC_P0K_RESOURCE_CITY_GROWTH_DISCOUNT_DESCRIPTION' = @('+10%', '+3 [ICON_HOUSING]')
            'LOC_P0K_RESOURCE_GOLD_YIELD_BONUS_DESCRIPTION' = @('+15%')
            'LOC_P0K_RESOURCE_FAITH_YIELD_BONUS_DESCRIPTION' = @('+20%')
            'LOC_P0K_RESOURCE_SCIENCE_YIELD_BONUS_DESCRIPTION' = @('+7%')
            'LOC_P0K_RESOURCE_CULTURE_YIELD_BONUS_DESCRIPTION' = @('+7%')
        }
        foreach ($entry in $requiredMonopoliesChinese.GetEnumerator()) {
            $row = $monopoliesText.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$($entry.Key)' and @Language='zh_Hans_CN']/Text")
            if ($null -eq $row) {
                $issues.Add("Industries/Corporations Chinese row is missing: $($entry.Key)")
                continue
            }
            foreach ($fragment in $entry.Value) {
                if (-not $row.InnerText.Contains($fragment)) {
                    $issues.Add("Industries/Corporations Chinese row $($entry.Key) is missing: $fragment")
                }
            }
        }
        $pediaRow = $monopoliesText.SelectSingleNode('/GameData/LocalizedText/*[@Tag="LOC_PEDIA_CONCEPTS_PAGE_MONOPOLIES_CHAPTER_INDUSTRIES_PARA_2" and @Language="zh_Hans_CN"]/Text')
        foreach ($resourceName in @('琥珀', '蜂蜜', '橄榄', '海龟', '企鹅', '石榴', '莎草纸', '枫糖', '蛋白石', '李子')) {
            if ($null -eq $pediaRow -or -not $pediaRow.InnerText.Contains("${resourceName}：")) {
                $issues.Add("Industries Civilopedia text is missing the balanced resource: $resourceName")
            }
        }
    }

    return @($issues)
}
