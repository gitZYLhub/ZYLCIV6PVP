[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
$modInfoPath = Join-Path $modRoot 'ZYLPVPMOD.modinfo'
$expectedModId = '4dd01931-9d44-4a8a-8e74-712cba0f0072'
$validationErrors = [System.Collections.Generic.List[string]]::new()

function Add-ValidationError {
    param([string]$Message)
    $validationErrors.Add($Message)
}

function Normalize-RelativePath {
    param([string]$Path)
    return $Path.Trim().Replace('/', '\').ToLowerInvariant()
}

function Load-XmlDocument {
    param([string]$Path)
    $document = [System.Xml.XmlDocument]::new()
    $document.PreserveWhitespace = $false
    $document.Load($Path)
    return $document
}

if (-not (Test-Path -LiteralPath $modInfoPath)) {
    throw "ModInfo not found: $modInfoPath"
}

# Validate every XML-bearing artifact, including the BBM art dependency.
$xmlFiles = @(Get-ChildItem -LiteralPath $modRoot -Recurse -File | Where-Object {
    $_.Extension -in @('.xml', '.modinfo', '.dep')
})
foreach ($xmlFile in $xmlFiles) {
    try {
        [void](Load-XmlDocument $xmlFile.FullName)
    }
    catch {
        Add-ValidationError "Invalid XML: $($xmlFile.FullName) :: $($_.Exception.Message)"
    }
}

$modInfo = Load-XmlDocument $modInfoPath
if ($modInfo.DocumentElement.GetAttribute('id') -ne $expectedModId) {
    Add-ValidationError "Unexpected Mod ID: $($modInfo.DocumentElement.GetAttribute('id'))"
}
if ($modInfo.DocumentElement.GetAttribute('version') -ne '125' -or
		$modInfo.SelectSingleNode('/Mod/Properties/Version').InnerText -ne '125' -or
		$modInfo.SelectSingleNode('/Mod/Properties/ToolboxVersion').InnerText -ne '1.2.5') {
	Add-ValidationError 'The integrated package version must be 1.2.5 / ModInfo 125.'
}
if ($modInfo.SelectSingleNode('/Mod/Properties/Name').InnerText -ne 'LOC_ZYLPVPMOD_TITLE') {
    Add-ValidationError 'The ModInfo title is not the ZYLPVPMOD localization key.'
}
$workshopTitleEnglish = $modInfo.SelectSingleNode("/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_TITLE']/en_US")
$workshopTitleChinese = $modInfo.SelectSingleNode("/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_TITLE']/zh_Hans_CN")
if ($null -eq $workshopTitleEnglish -or $workshopTitleEnglish.InnerText -ne 'ZYLPVPMOD 1.2.5' -or
		$null -eq $workshopTitleChinese -or $workshopTitleChinese.InnerText -ne 'ZYLPVPMOD 1.2.5') {
	Add-ValidationError 'The localized ModInfo / Steam Workshop title must be ZYLPVPMOD 1.2.5.'
}

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
    Add-ValidationError 'The Industries/Corporations balance SQL is missing.'
}
else {
    $monopoliesBalanceSource = Get-Content -LiteralPath $monopoliesBalancePath -Raw
    $amountPattern = @'
UPDATE\s+ModifierArguments\s+SET\s+Value\s*=\s*'(?<Value>\d+)'\s+WHERE\s+ModifierId\s*=\s*'(?<Id>[^']+)'\s+AND\s+Name\s*=\s*'Amount'\s*;
'@
    $actualMonopoliesAmounts = @{}
    foreach ($amountMatch in [regex]::Matches($monopoliesBalanceSource, $amountPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
        $modifierId = $amountMatch.Groups['Id'].Value.ToUpperInvariant()
        if ($actualMonopoliesAmounts.ContainsKey($modifierId)) {
            Add-ValidationError "Duplicate Industries/Corporations balance assignment: $modifierId"
        }
        $actualMonopoliesAmounts[$modifierId] = [int]$amountMatch.Groups['Value'].Value
    }
    foreach ($entry in $expectedMonopoliesAmounts.GetEnumerator()) {
        if (-not $actualMonopoliesAmounts.ContainsKey($entry.Key)) {
            Add-ValidationError "Industries/Corporations balance assignment is missing: $($entry.Key)"
        }
        elseif ($actualMonopoliesAmounts[$entry.Key] -ne $entry.Value) {
            Add-ValidationError "Industries/Corporations balance value is wrong for $($entry.Key): expected $($entry.Value), found $($actualMonopoliesAmounts[$entry.Key])"
        }
    }
    if ($actualMonopoliesAmounts.Count -ne $expectedMonopoliesAmounts.Count) {
        Add-ValidationError "Industries/Corporations balance assignment count is $($actualMonopoliesAmounts.Count), expected $($expectedMonopoliesAmounts.Count)."
    }
    if ($monopoliesBalanceSource.Contains('PRODUCT_CITY_GROWTH_HOUSING_MAPLE')) {
        Add-ValidationError 'The Maple product housing bonus must remain +3 and must not be changed by the balance layer.'
    }
}

$monopoliesDatabaseAction = $modInfo.SelectSingleNode('/Mod/InGameActions/UpdateDatabase[@id="ZYL_MonopoliesBalance" and Criteria="ZYL_MonopoliesMode"]')
if ($null -eq $monopoliesDatabaseAction -or
        $monopoliesDatabaseAction.SelectSingleNode('./File[.="sql/ZYL_MonopoliesBalance.sql"]') -eq $null -or
        $monopoliesDatabaseAction.SelectSingleNode('./Properties/LoadOrder').InnerText -ne '260000015') {
    Add-ValidationError 'The Industries/Corporations balance SQL is not registered as a late, Monopolies-only database action.'
}
$monopoliesTextAction = $modInfo.SelectSingleNode('/Mod/InGameActions/UpdateText[@id="ZYL_MonopoliesBalanceText" and Criteria="ZYL_MonopoliesMode"]')
if ($null -eq $monopoliesTextAction -or
        $monopoliesTextAction.SelectSingleNode('./File[.="lang/ZYL_MonopoliesBalance_Text.xml"]') -eq $null -or
        $monopoliesTextAction.SelectSingleNode('./Properties/LoadOrder').InnerText -ne '260000025') {
    Add-ValidationError 'The Industries/Corporations Chinese text is not registered as a late, Monopolies-only text action.'
}
if (-not (Test-Path -LiteralPath $monopoliesTextPath)) {
    Add-ValidationError 'The Industries/Corporations Simplified Chinese text layer is missing.'
}
else {
    $monopoliesText = Load-XmlDocument $monopoliesTextPath
    $monopoliesTextRows = @($monopoliesText.SelectNodes('/GameData/LocalizedText/*[@Tag]'))
    foreach ($row in $monopoliesTextRows) {
        if ($row.GetAttribute('Language') -ne 'zh_Hans_CN') {
            Add-ValidationError "Non-Simplified-Chinese row in Industries/Corporations text: $($row.GetAttribute('Tag'))"
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
            Add-ValidationError "Industries/Corporations Chinese row is missing: $($entry.Key)"
            continue
        }
        foreach ($fragment in $entry.Value) {
            if (-not $row.InnerText.Contains($fragment)) {
                Add-ValidationError "Industries/Corporations Chinese row $($entry.Key) is missing: $fragment"
            }
        }
    }
    $pediaRow = $monopoliesText.SelectSingleNode('/GameData/LocalizedText/*[@Tag="LOC_PEDIA_CONCEPTS_PAGE_MONOPOLIES_CHAPTER_INDUSTRIES_PARA_2" and @Language="zh_Hans_CN"]/Text')
    foreach ($resourceName in @('琥珀', '蜂蜜', '橄榄', '海龟', '企鹅', '石榴', '莎草纸', '枫糖', '蛋白石', '李子')) {
        if ($null -eq $pediaRow -or -not $pediaRow.InnerText.Contains("${resourceName}：")) {
            Add-ValidationError "Industries Civilopedia text is missing the balanced resource: $resourceName"
        }
    }
}

# The upstream Simplified Chinese file stopped following BBG's gameplay
# changes.  Keep the final 7.4.6 synchronization layer structurally safe and
# make missing Chinese rows impossible to reintroduce silently.
$bbgChineseOverlayPath = Join-Path $modRoot 'lang\ZYL_BBG74_Chinese_Text.xml'
$bbgChineseSourcePath = Join-Path $modRoot 'Components\BBG\lang\chinese.xml'
$bbgExpandedChinesePath = Join-Path $modRoot 'lang\ZYL_BBGExpanded_Chinese.sql'
if (-not (Test-Path -LiteralPath $bbgChineseOverlayPath)) {
    Add-ValidationError 'The BBG 7.4.6 Simplified Chinese synchronization layer is missing.'
}
else {
    $bbgChineseOverlay = Load-XmlDocument $bbgChineseOverlayPath
    $overlayRows = @($bbgChineseOverlay.SelectNodes('/GameData/LocalizedText/*[@Tag]'))
    foreach ($overlayRow in $overlayRows) {
        if ($overlayRow.GetAttribute('Language') -ne 'zh_Hans_CN') {
            Add-ValidationError "BBG Chinese overlay row is not zh_Hans_CN: $($overlayRow.GetAttribute('Tag'))"
        }
    }
    foreach ($duplicateTag in @($overlayRows | Group-Object { $_.GetAttribute('Tag').ToUpperInvariant() } | Where-Object Count -gt 1)) {
        Add-ValidationError "Duplicate Tag inside the BBG Chinese overlay: $($duplicateTag.Name)"
    }
    $overlayTextByTag = @{}
    foreach ($overlayRow in $overlayRows) {
        $overlayTextByTag[$overlayRow.GetAttribute('Tag').ToUpperInvariant()] = $overlayRow.SelectSingleNode('./Text').InnerText
    }
    if (-not (Test-Path -LiteralPath $bbgChineseSourcePath)) {
        Add-ValidationError 'The embedded upstream BBG Simplified Chinese source is missing.'
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
                Add-ValidationError "Latin-only text is still effective in the embedded BBG Simplified Chinese localization: $sourceTag"
            }
            elseif ($overlayTextByTag[$sourceKey] -notmatch '[\u3400-\u9FFF]') {
                Add-ValidationError "The BBG Chinese overlay did not translate the Latin-only source row: $sourceTag"
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
        'LOC_BELIEF_INITIATION_RITES_EXPANSION2_DESCRIPTION' = @('25%', '[ICON_FAITH]')
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
            Add-ValidationError "Critical BBG 7.4.6 Chinese correction is missing: $($entry.Key)"
            continue
        }
        foreach ($requiredFragment in $entry.Value) {
            if (-not $criticalRow.InnerText.Contains($requiredFragment)) {
                Add-ValidationError "Critical BBG Chinese correction $($entry.Key) is missing: $requiredFragment"
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
        'LOC_BELIEF_INITIATION_RITES_EXPANSION2_DESCRIPTION' = @('30%')
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
                Add-ValidationError "Critical BBG Chinese correction $($entry.Key) still contains obsolete text: $forbiddenFragment"
            }
        }
    }
}

$bbgEnglishPath = Join-Path $modRoot 'Components\BBG\lang\english.xml'
if (-not (Test-Path -LiteralPath $bbgEnglishPath)) {
    Add-ValidationError 'The embedded BBG English localization is missing.'
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
            Add-ValidationError "Critical BBG English row is missing: $($entry.Key)"
            continue
        }
        foreach ($requiredFragment in $entry.Value) {
            if (-not $englishTextNode.InnerText.Contains($requiredFragment)) {
                Add-ValidationError "Critical BBG English correction $($entry.Key) is missing: $requiredFragment"
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
                Add-ValidationError "Critical BBG English correction $($entry.Key) still contains obsolete text: $forbiddenFragment"
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
            Add-ValidationError "Untranslated placeholder in Simplified Chinese localization: $tag"
        }
    }
}
foreach ($englishTag in $englishLocalizationTags) {
    if (-not $chineseLocalizationTags.Contains($englishTag)) {
        Add-ValidationError "English localization Tag has no Simplified Chinese row anywhere in the package: $englishTag"
    }
}

# Build a case-insensitive manifest for Windows/macOS portability.
$listedFiles = [System.Collections.Generic.List[string]]::new()
$listedFileMap = @{}
foreach ($fileNode in @($modInfo.SelectNodes('/Mod/Files/File'))) {
    $relativePath = $fileNode.InnerText.Trim().Replace('/', '\')
    $key = Normalize-RelativePath $relativePath
    if ($listedFileMap.ContainsKey($key)) {
        Add-ValidationError "Duplicate <Files> entry (case-insensitive): $relativePath"
    }
    else {
        $listedFileMap[$key] = $relativePath
        $listedFiles.Add($relativePath)
    }
}
foreach ($relativePath in $listedFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot $relativePath))) {
        Add-ValidationError "Listed file missing on disk: $relativePath"
    }
}

# Reverse-audit the manifest as well. Most past omissions were valid files on
# disk that no action could ever see because they never reached <Files>.
# Keep intentionally dormant/conflicting upstream files explicit so a new
# unlisted file fails validation instead of silently disappearing at runtime.
$intentionallyUnlistedFiles = @(
    'BCS\UI\CityStates_SPEC.lua',
    'BCT\UnitFlagManager_BuilderCharges.lua',
    'BER\UnitFlagManager_GreatGeneralEraReminder.lua',
    'BSM\Text_CN.xml',
    'BSM\Text_EN.xml',
    'BSM\UI\DiplomacyRibbon_SP.lua',
    'BSM\UI\DiplomacyRibbon_SP.xml',
    'BSM\UI\diplomacyribbon_spec.lua',
    'Components\BBG\LICENSE',
    'Components\BBG\scripts\bbg_stateutils.lua',
    'Components\BBG\scripts\bbg_unitcommanddefs.lua',
    'Components\BBG\scripts\bbg_unitcommands.lua',
    'Components\BBG\sql\beta\ban_trade_treaty.sql',
    'Components\BBG\ui\bbg_customplacement.lua',
    'Components\BBG\ui\replacements\civ6common.lua',
    'Components\BBG\ui\replacements\productionpanel_bbg.lua',
    'Components\BBG\ui\replacements\strategicview_mapplacement.lua',
    'Components\BBG\ui\replacements\unitpanel_bbg_legacy.lua',
    'Components\BBM\Configuration\Config_option.xml',
    'Components\BBM\Configuration\ConfigText.xml',
    'Components\BBM\Data\BBS Maps\Utility\NaturalWonderGenerator.lua',
    'Components\BBM\Gameplay\Text.xml',
    'Components\BBM\license.txt',
    'Components\BBM\notice.txt',
    'Components\BBM\README.md',
    'Config\GameConfig_BASE.xml',
    'Config\GameConfig_MONOPOLIES.xml',
    'Config\GameConfig_SECRETSOCIETIES.xml',
    'configuration\readme.txt',
    'GPN\GreatPersonNames.sql',
    'icons\Anonymous_Portrait.dds',
    'icons\LastMove_44.dds',
    'icons\LastMove_Icons.xml',
    'mode\lastmove\LastMove_Background.dds',
    'mode\lastmove\LastMove_Portrait.dds',
    'mode\lastmove\lastmove_text.xml',
    'mode\lastmove\lastmove_UI.lua',
    'mode\lastmove\lastmove_UI.xml',
    'mode\lastmove\lastmove_unitabilities.xml',
    'mode\lastmove\lastmove.lua',
    'NHK\UI\TurnTime_HotKey.lua',
    'NHK\UI\TurnTime_HotKey.xml',
    'RMP\Config_Text.xml',
    'RMP\Config.xml',
    'ui\Replacements\chatpanel_ZYL.lua',
    'ui\Replacements\chatpanel_ZYL.xml',
    'ui\Replacements\diplomacydealview_MPH.lua'
)
$intentionallyUnlistedMap = @{}
foreach ($relativePath in $intentionallyUnlistedFiles) {
    $intentionallyUnlistedMap[(Normalize-RelativePath $relativePath)] = $relativePath
}
$diskFiles = @(Get-ChildItem -LiteralPath $modRoot -Recurse -File)
foreach ($diskFile in $diskFiles) {
    if ($diskFile.FullName -eq $modInfoPath) { continue }
    $relativePath = $diskFile.FullName.Substring($modRoot.Length + 1)
    $key = Normalize-RelativePath $relativePath
    if (-not $listedFileMap.ContainsKey($key) -and -not $intentionallyUnlistedMap.ContainsKey($key)) {
        Add-ValidationError "File exists on disk but is absent from <Files> and the dormant allowlist: $relativePath"
    }
}
foreach ($key in $intentionallyUnlistedMap.Keys) {
    $relativePath = $intentionallyUnlistedMap[$key]
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot $relativePath))) {
        Add-ValidationError "Dormant-file allowlist entry no longer exists; remove or update it: $relativePath"
    }
    if ($listedFileMap.ContainsKey($key)) {
        Add-ValidationError "A deliberately dormant/conflicting file was added to <Files>: $relativePath"
    }
}

$actionNodes = @(
    $modInfo.SelectNodes('/Mod/FrontEndActions/*') |
        Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
    $modInfo.SelectNodes('/Mod/InGameActions/*') |
        Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
)

$actionIdMap = @{}
foreach ($actionNode in $actionNodes) {
    $actionId = $actionNode.GetAttribute('id')
    if ([string]::IsNullOrWhiteSpace($actionId)) {
        Add-ValidationError "Action without id: $($actionNode.OuterXml)"
        continue
    }
    $actionKey = $actionId.ToLowerInvariant()
    if ($actionIdMap.ContainsKey($actionKey)) {
        Add-ValidationError "Duplicate action id: $actionId"
    }
    else {
        $actionIdMap[$actionKey] = $actionNode
    }
}

# Civ VI's UpdateArt handler accepts game-art dependency manifests, not raw
# ArtDef files.  Passing an .artdef here logs "Could not load file. Unknown
# extension" and silently skips the asset.
foreach ($updateArtAction in @($actionNodes | Where-Object { $_.LocalName -eq 'UpdateArt' })) {
    foreach ($fileNode in @($updateArtAction.SelectNodes('.//File'))) {
        if ([System.IO.Path]::GetExtension($fileNode.InnerText.Trim()) -ieq '.artdef') {
            Add-ValidationError "UpdateArt action $($updateArtAction.GetAttribute('id')) directly loads an ArtDef instead of a .dep manifest: $($fileNode.InnerText.Trim())"
        }
    }
}

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
        Add-ValidationError "Required gameplay override action is missing: $($entry.Key)"
        continue
    }
    $loadOrderNode = $actionIdMap[$entry.Key].SelectSingleNode('./Properties/LoadOrder')
    if ($null -eq $loadOrderNode -or $loadOrderNode.InnerText.Trim() -ne $entry.Value) {
        Add-ValidationError "Gameplay override action $($entry.Key) must load at $($entry.Value)."
    }
}

$requiredBbgChineseActions = @{
    'zyl_bbg74_chinesetextfrontend' = @('FrontEndActions', 'lang/ZYL_BBG74_Chinese_Text.xml')
    'zyl_bbg74_chinesetext' = @('InGameActions', 'lang/ZYL_BBG74_Chinese_Text.xml')
}
foreach ($entry in $requiredBbgChineseActions.GetEnumerator()) {
    $action = $actionIdMap[$entry.Key]
    if ($null -eq $action -or
            $action.ParentNode.LocalName -ne $entry.Value[0] -or
            $action.LocalName -ne 'UpdateText' -or
            $null -eq $action.SelectSingleNode("./File[.='$($entry.Value[1])']") -or
            $action.SelectSingleNode('./Properties/LoadOrder').InnerText.Trim() -ne '259999990') {
        Add-ValidationError "BBG 7.4.6 Simplified Chinese overlay action is missing or malformed: $($entry.Key)"
    }
}
if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'lang/ZYL_BBG74_Chinese_Text.xml'))) {
    Add-ValidationError 'BBG 7.4.6 Simplified Chinese overlay is absent from the ModInfo <Files> manifest.'
}

$disasterRangeAction = $actionIdMap['zyl_disablenaturaldisastersoption']
if ($null -eq $disasterRangeAction -or
        $disasterRangeAction.LocalName -ne 'UpdateDatabase' -or
        $null -eq $disasterRangeAction.SelectSingleNode("./File[.='configuration/ZYL_DisasterRange.sql']")) {
    Add-ValidationError 'The TPT no-natural-disasters lobby option is not loaded.'
}
$disasterRangePath = Join-Path $modRoot 'configuration\ZYL_DisasterRange.sql'
if (Test-Path -LiteralPath $disasterRangePath) {
    $disasterRangeSql = Get-Content -LiteralPath $disasterRangePath -Raw
    if (-not $disasterRangeSql.Contains("WHERE Domain = 'RealismRange'") -or
            -not $disasterRangeSql.Contains('MinimumValue = -1')) {
        Add-ValidationError 'The disaster-intensity range no longer exposes the -1/disabled value.'
    }
}

$bbgBasePath = Join-Path $modRoot 'Components\BBG\sql\Base\base.sql'
if (Test-Path -LiteralPath $bbgBasePath) {
    $activeBbgTechMultiplier = @(Get-Content -LiteralPath $bbgBasePath | Where-Object {
        $_ -notmatch '^\s*--' -and $_ -match 'Cost\s*=\s*Cost\s*\*\s*1\.05'
    })
    if ($activeBbgTechMultiplier.Count -gt 0) {
        Add-ValidationError 'BBG Medieval-and-later technology +5% base-cost multiplier is active.'
    }
}

# Improvement Housing is displayed as Housing / TilesRequired.  BBG's source
# comment calls the Colossal Head value +1, but the shipped SQL deliberately
# leaves the final database at 1 / 2, so the effective tooltip value is +0.5.
$bbgCityStatesPath = Join-Path $modRoot 'Components\BBG\sql\Base\CityStates.sql'
if (-not (Test-Path -LiteralPath $bbgCityStatesPath)) {
    Add-ValidationError 'BBG city-state gameplay SQL is missing.'
}
else {
    $bbgCityStatesSql = Get-Content -LiteralPath $bbgCityStatesPath -Raw
    if ($bbgCityStatesSql -notmatch "(?s)UPDATE\s+Improvements\s+SET\s+Housing\s*=\s*1\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_COLOSSAL_HEAD'.*?UPDATE\s+Improvements\s+SET\s+TilesRequired\s*=\s*2\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_COLOSSAL_HEAD'") {
        Add-ValidationError 'Colossal Head Housing must remain 1 / 2 (+0.5 per improvement) to match the final Chinese text.'
    }
}

$bbgMaliPath = Join-Path $modRoot 'Components\BBG\sql\XP2\Mali.sql'
if (-not (Test-Path -LiteralPath $bbgMaliPath)) {
	Add-ValidationError 'BBG Mali gameplay SQL is missing.'
}
else {
	$bbgMaliSql = Get-Content -LiteralPath $bbgMaliPath -Raw
	foreach ($removedMaliToken in @(
		'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION',
		'BBG_MALI_FAITH_NEXT_DESERT',
		'BBG_MALI_FAITH_NEXT_DESERT_HILLS',
		'BBG_MALI_FAITH_NEXT_CAPITAL',
		'TRAIT_BBG_MANSA_FREE_TRADER_BANKS'
	)) {
		if ($bbgMaliSql.Contains($removedMaliToken)) {
			Add-ValidationError "Mali source still defines a removed modifier: $removedMaliToken"
		}
	}
	if ($bbgMaliSql -match "(?is)DELETE\s+FROM\s+(?:TraitModifiers|Modifiers|ModifierArguments)\b[^;]*GOLDEN_AGE_TRADE_ROUTE[^;]*;") {
		Add-ValidationError 'Mansa Musa source still deletes the original Golden Age Trade Route modifier.'
	}
	if (-not $bbgMaliSql.Contains('GOLDEN_AGE_TRADE_ROUTE')) {
		Add-ValidationError 'Mansa Musa source does not document preservation of the original Golden Age Trade Route modifier.'
	}
	foreach ($maliYieldBinding in @(
		@('ZYL_MALI_PRODUCTION_DESERT', 'YIELD_PRODUCTION', 'BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET'),
		@('ZYL_MALI_PRODUCTION_DESERT_HILLS', 'YIELD_PRODUCTION', 'BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET'),
		@('ZYL_MALI_FAITH_DESERT', 'YIELD_FAITH', 'BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET'),
		@('ZYL_MALI_FAITH_DESERT_HILLS', 'YIELD_FAITH', 'BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET')
	)) {
		$modifierId = [regex]::Escape($maliYieldBinding[0])
		$yieldType = [regex]::Escape($maliYieldBinding[1])
		$requirementSetId = [regex]::Escape($maliYieldBinding[2])
		if ($bbgMaliSql -notmatch "(?s)\('$modifierId'\s*,\s*'MODIFIER_PLAYER_ADJUST_PLOT_YIELD'\s*,\s*'$requirementSetId'\).*?\('$modifierId'\s*,\s*'YieldType'\s*,\s*'$yieldType'\).*?\('$modifierId'\s*,\s*'Amount'\s*,\s*1\)") {
			Add-ValidationError "Mali featureless Desert yield modifier is incomplete: $($maliYieldBinding[0])"
		}
		if ($bbgMaliSql -notmatch "\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'$modifierId'\)") {
			Add-ValidationError "Mali featureless Desert yield modifier is not attached to the civilization trait: $($maliYieldBinding[0])"
		}
	}
	if ($bbgMaliSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s+IN\s*\(\s*'SUGUBA_CHEAPER_BUILDING_PURCHASE'\s*,\s*'SUGUBA_CHEAPER_DISTRICT_PURCHASE'\s*\)") {
		Add-ValidationError 'Suguba building/district purchase discount is not locked to 10%.'
	}
	if ($bbgMaliSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s*=\s*'SUGUBA_CHEAPER_UNIT_PURCHASE'") {
		Add-ValidationError 'Suguba unit purchase discount is not locked to 10%.'
	}
}

$gameplayOverridePath = Join-Path $modRoot 'sql\ZYL_GameplayOverrides.sql'
$governorOverridePath = Join-Path $modRoot 'sql\ZYL_GovernorOverrides.sql'

$bbgMaoriPath = Join-Path $modRoot 'Components\BBG\sql\XP2\Maori.sql'
if (-not (Test-Path -LiteralPath $bbgMaoriPath)) {
	Add-ValidationError 'BBG Maori gameplay SQL is missing.'
}
else {
	$bbgMaoriSql = Get-Content -LiteralPath $bbgMaoriPath -Raw
	if ($bbgMaoriSql -notmatch "(?s)UPDATE\s+Leaders_XP2\s+SET\s+OceanStart\s*=\s*0\s+WHERE\s+LeaderType\s*=\s*'LEADER_KUPE'") {
		Add-ValidationError 'Kupe is no longer locked to BBG land-based starting behavior.'
	}
	if ($bbgMaoriSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasTerrains.*?'CIVILIZATION_MAORI'\s*,\s*'TERRAIN_COAST'\s*,\s*'1'") {
		Add-ValidationError 'Maori no longer have the T1 Coast bias required by Rich Mainland shore placement.'
	}
}

if (-not (Test-Path -LiteralPath $gameplayOverridePath)) {
    Add-ValidationError 'ZYL gameplay override SQL is missing.'
}
else {
    $gameplayOverrideSql = Get-Content -LiteralPath $gameplayOverridePath -Raw
    foreach ($requiredToken in @(
        'CITY_POPULATION_NO_WATER',
        'CITY_POPULATION_COAST',
        'BBG_MAYA_CAPITAL_HOUSING',
        'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING',
        'TECH_COST_PERCENT_CHANGE_BEFORE_GAME_ERA',
        "('TECH_CELESTIAL_NAVIGATION', 'TECH_SAILING')",
        "('TECH_CELESTIAL_NAVIGATION', 'TECH_ASTROLOGY')",
        "WHERE TechnologyType = 'TECH_ARCHERY'",
        "WHERE TechnologyType = 'TECH_BRONZE_WORKING'",
        "WHERE TechnologyType = 'TECH_MILITARY_TACTICS'",
        "WHERE CivicType = 'CIVIC_GAMES_RECREATION'",
        "WHERE CivicType = 'CIVIC_RECORDED_HISTORY'",
        "WHERE CivicType = 'CIVIC_HUMANISM'",
        "WHERE CivicType = 'CIVIC_NAVAL_TRADITION'",
        "WHERE CivicType = 'CIVIC_FEUDALISM'",
        'ZYL_COMMERCIAL_HUB_LUXURY_GOLD',
		'BBG_MALI_FAITH_NEXT_DESERT',
		'BBG_MALI_FAITH_NEXT_DESERT_HILLS',
		'BBG_MALI_FAITH_NEXT_CAPITAL',
		'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION',
		'TRAIT_BBG_MANSA_FREE_TRADER_BANKS',
		'SUGUBA_CHEAPER_BUILDING_PURCHASE',
		'SUGUBA_CHEAPER_DISTRICT_PURCHASE',
		'SUGUBA_CHEAPER_UNIT_PURCHASE',
		'FEATURE_OASIS',
		'Feature_YieldChanges',
		'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER',
		'MISSION_NEWCONTINENT_FAITH',
		'MISSION_NEWCONTINENT_FOOD',
		'MISSION_NEWCONTINENT_PRODUCTION',
		'ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA',
		'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE',
		'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA',
		'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA',
		'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA',
		'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA',
		'BBG_SULEIMAN_COMBAT_BUFF',
		'OPPONENT_IS_IN_GOLDEN_AGE_REQUIREMENTS',
        'BBG_APPEAL_WYWH',
		'BBG_AUTOMATON_GDR_PROD',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX',
		'TRAIT_INCREASED_TUNDRA_HILLS_FAITH'
    )) {
        if (-not $gameplayOverrideSql.Contains($requiredToken)) {
            Add-ValidationError "Gameplay override SQL is missing invariant: $requiredToken"
        }
    }

    if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*'3'\s+WHERE\s+Name\s*=\s*'CITY_POPULATION_NO_WATER'") {
        Add-ValidationError 'No-water city base Housing is not locked to 3.'
    }
    if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*'4'\s+WHERE\s+Name\s*=\s*'CITY_POPULATION_COAST'") {
        Add-ValidationError 'Coast-only city base Housing is not locked to 4.'
    }
    if ($gameplayOverrideSql -notmatch "(?s)SET\s+ModifierType\s*=\s*'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING'\s+WHERE\s+ModifierId\s*=\s*'BBG_MAYA_CAPITAL_HOUSING'") {
        Add-ValidationError 'Maya Housing modifier is not scoped to all cities.'
    }
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_MALI_GOLD_DESERT'.*?'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION'.*?'BBG_MALI_FAITH_NEXT_DESERT'.*?'BBG_MALI_FAITH_NEXT_DESERT_HILLS'.*?'BBG_MALI_FAITH_NEXT_CAPITAL'") {
		Add-ValidationError 'Final Mali override does not remove the Production penalty and Foreign Trade city Faith package.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SAHEL_MERCHANTS'.*?ModifierId\s*=\s*'TRAIT_BBG_MANSA_FREE_TRADER_BANKS'") {
		Add-ValidationError 'Final Mansa Musa override does not remove the Banking Trade Route modifier.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s+IN\s*\(.*?'SUGUBA_CHEAPER_BUILDING_PURCHASE'.*?'SUGUBA_CHEAPER_DISTRICT_PURCHASE'.*?'SUGUBA_CHEAPER_UNIT_PURCHASE'.*?\)\s+AND\s+Name\s*=\s*'Amount'") {
		Add-ValidationError 'Final Suguba purchase discount override is not locked to 10%.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)Feature_YieldChanges\s*\(\s*FeatureType\s*,\s*YieldType\s*,\s*YieldChange\s*\).*?'FEATURE_OASIS'\s*,\s*'YIELD_FOOD'\s*,\s*4.*?'FEATURE_OASIS'\s*,\s*'YIELD_GOLD'\s*,\s*1") {
		Add-ValidationError 'Global Oasis feature yields do not seed the required 4 Food / 1 Gold values.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+YieldChange\s*=\s*4\s+WHERE\s+FeatureType\s*=\s*'FEATURE_OASIS'\s+AND\s+YieldType\s*=\s*'YIELD_FOOD'.*?SET\s+YieldChange\s*=\s*1\s+WHERE\s+FeatureType\s*=\s*'FEATURE_OASIS'\s+AND\s+YieldType\s*=\s*'YIELD_GOLD'") {
		Add-ValidationError 'Global Oasis feature yields are not forced to exactly 4 Food / 1 Gold.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE'\s*,\s*'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA'\s*,\s*'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_HOLY_SITE'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_LAVRA'") {
		Add-ValidationError 'Russia Tundra Faith adjacency must accept both Holy Sites and Lavras.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA'.*?'REQUIRES_PLOT_HAS_TUNDRA'.*?'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA'.*?'REQUIRES_PLOT_HAS_TUNDRA_HILLS'") {
		Add-ValidationError 'Russia Tundra Faith terrain requirement sets are not limited to adjacent Tundra/Tundra Hills.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_INCREASED_TUNDRA_FAITH'.*?SET\s+SubjectRequirementSetId\s*=\s*'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_INCREASED_TUNDRA_HILLS_FAITH'") {
		Add-ValidationError 'Russia Tundra Faith modifiers are not bound to the adjacency-aware terrain sets.'
	}
	if ($gameplayOverrideSql.Contains('ZYL_RUSSIA_CITY_HAS_HOLY_SITE')) {
		Add-ValidationError 'Russia Tundra Faith still contains the obsolete city-wide Holy Site requirement.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+StartBiasResources\s+WHERE\s+CivilizationType\s*=\s*'CIVILIZATION_FRANCE'.*?ResourceClassType\s*=\s*'RESOURCECLASS_LUXURY'") {
		Add-ValidationError 'France does not clear its existing Luxury resource biases before rebuilding them.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasResources\s*\(\s*CivilizationType\s*,\s*ResourceType\s*,\s*Tier\s*\)\s*SELECT\s*'CIVILIZATION_FRANCE'\s*,\s*ResourceType\s*,\s*4\s+FROM\s+Resources\s+WHERE\s+ResourceClassType\s*=\s*'RESOURCECLASS_LUXURY'") {
		Add-ValidationError 'France does not receive a civilization-wide T4 bias for every active Luxury resource.'
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
			Add-ValidationError "Magnificence resource Culture requirement is missing: $($binding[0]) -> $($binding[1])"
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
			Add-ValidationError "Magnificence resource Culture modifier has the wrong unlock: $($binding[0])"
		}
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s*=\s*'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER'.*?DELETE\s+FROM\s+Modifiers\s+WHERE\s+ModifierId\s*=\s*'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER'") {
		Add-ValidationError 'Malformed Scythia medieval ability giver is not removed.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ImprovementModifiers\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_MISSION'.*?'MISSION_NEWCONTINENT_FAITH'.*?'MISSION_NEWCONTINENT_FOOD'.*?'MISSION_NEWCONTINENT_PRODUCTION'") {
		Add-ValidationError 'Spain Mission orphan modifier links are not removed.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'OPPONENT_IS_IN_GOLDEN_AGE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'BBG_SULEIMAN_COMBAT_BUFF'") {
		Add-ValidationError 'Suleiman BBG combat bonus is not limited to opponents in Golden/Heroic Ages.'
	}
	if ($gameplayOverrideSql -match "(?s)SET\s+SubjectRequirementSetId\s*=\s*'OPPONENT_IS_NOT_IN_GOLDEN_AGE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'BBG_SULEIMAN_COMBAT_BUFF'") {
		Add-ValidationError 'Suleiman +2 and +4 combat modifiers would overlap against Normal/Dark-Age opponents.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+OwnerRequirementSetId\s*=\s*'PLAYER_HAS_GOLDEN_AGE'\s+WHERE\s+ModifierId\s+IN\s*\(\s*'BBG_APPEAL_WYWH'\s*,\s*'BBG_AUTOMATON_GDR_PROD'\s*\)") {
		Add-ValidationError 'Wish You Were Here Appeal and Automaton GDR production are not limited to Golden/Heroic Ages.'
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
			Add-ValidationError "Johannesburg attach modifier still risks consuming city-yield arguments: $modifierId"
		}
	}
	foreach ($modifierId in $johannesburgInnerModifiers) {
		$escapedModifierId = [regex]::Escape($modifierId)
		if ($gameplayOverrideSql -notmatch "\('$escapedModifierId'\s*,\s*'Amount'\s*,\s*'1'\)" -or
				$gameplayOverrideSql -notmatch "\('$escapedModifierId'\s*,\s*'YieldType'\s*,\s*'YIELD_PRODUCTION'\)") {
			Add-ValidationError "Johannesburg city-yield modifier is missing Amount=1 or YieldType=YIELD_PRODUCTION: $modifierId"
		}
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s*=\s*'UNIQUE_LEADER_SPIES_START_PROMOTED'\s+AND\s+Name\s*=\s*'Amount'") {
		Add-ValidationError "France's attach modifier still carries the child experience argument."
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s+IN\s*\(\s*'CHICHEN_ITZA_JUNGLE_CULTURE'\s*,\s*'CHICHEN_ITZA_JUNGLE_PRODUCTION'\s*\)\s+AND\s+Name\s*=\s*'ModifierId'") {
		Add-ValidationError 'Chichen Itza direct plot-yield modifiers still carry obsolete child-modifier links.'
	}
}

$bbgGovernorPath = Join-Path $modRoot 'Components\BBG\sql\XP1\Governors_XP1_or_XP2.sql'
if (-not (Test-Path -LiteralPath $bbgGovernorPath)) {
	Add-ValidationError 'BBG governor gameplay SQL is missing.'
}
else {
	$bbgGovernorSql = Get-Content -LiteralPath $bbgGovernorPath -Raw
	if ($bbgGovernorSql.Contains('BBG_MOKSHA_GREATPROPHET_POINT_FOR_HS')) {
		Add-ValidationError 'Moksha still contains the unbound duplicate Great Prophet point attach chain.'
	}
	if ($bbgGovernorSql -notmatch "\(\s*'BBG_MOKSHA_PROPHET_POINTS'\s*,\s*'Amount'\s*,\s*2\s*\)" -or
		$bbgGovernorSql -notmatch "\(\s*'GOVERNOR_PROMOTION_CARDINAL_CITADEL_OF_GOD'\s*,\s*'BBG_MOKSHA_PROPHET_POINTS'\s*\)") {
		Add-ValidationError 'Moksha Citadel of God must keep its effective local +2 Great Prophet point modifier.'
	}
}

# Every policy created by BBG needs an icon entry. The stock UI constructs
# secret-society Governor promotion keys which Firaxis did not ship, so keep
# explicit aliases for those keys as well. Missing entries flood
# UserInterface.log and leave blank icons throughout the Civics/Governor UI.
$bbgIconPath = Join-Path $modRoot 'Components\BBG\data\new_bbg_icons.xml'
if (-not (Test-Path -LiteralPath $bbgIconPath)) {
	Add-ValidationError 'BBG icon definitions are missing.'
}
else {
	$bbgIcons = Load-XmlDocument $bbgIconPath
	$requiredBbgIconAliases = @{
		'ICON_POLICY_EMPIRICAL_METHOD' = 'ICON_POLICY_ECONOMIC'
		'ICON_POLICY_MASTER_ARTISANS' = 'ICON_POLICY_MILITARY'
		'ICON_POLICY_BATTLEFIELD_MEDICINE' = 'ICON_POLICY_MILITARY'
		'ICON_POLICY_SCIENTIFIC_VANGUARD' = 'ICON_POLICY_WILDCARD'
		'ICON_POLICY_KOLKHOZ' = 'ICON_POLICY_MILITARY'
		'ICON_POLICY_PROSPERITY_PACT' = 'ICON_POLICY_DIPLOMATIC'
		'ICON_POLICY_MILITARY_COMMAND_CENTER' = 'ICON_POLICY_MILITARY'
		'ICON_POLICY_ARMS_RACE' = 'ICON_POLICY_MILITARY'
		'ICON_POLICY_SOVEREIGN_STATE' = 'ICON_POLICY_DIPLOMATIC'
		'ICON_GOVERNOR_OWLS_OF_MINERVA_PROMOTION' = 'ICON_GOVERNOR_GENERIC_PROMOTION'
		'ICON_GOVERNOR_HERMETIC_ORDER_PROMOTION' = 'ICON_GOVERNOR_GENERIC_PROMOTION'
		'ICON_GOVERNOR_VOIDSINGERS_PROMOTION' = 'ICON_GOVERNOR_GENERIC_PROMOTION'
		'ICON_GOVERNOR_SANGUINE_PACT_PROMOTION' = 'ICON_GOVERNOR_GENERIC_PROMOTION'
	}
	foreach ($entry in $requiredBbgIconAliases.GetEnumerator()) {
		$iconAlias = $bbgIcons.SelectSingleNode("/GameInfo/IconAliases/Row[@Name='$($entry.Key)' and @OtherName='$($entry.Value)']")
		if ($null -eq $iconAlias) {
			Add-ValidationError "BBG icon alias is missing or targets the wrong stock icon: $($entry.Key) -> $($entry.Value)"
		}
	}

	$bbgPolicyIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
	foreach ($bbgSqlFile in @(Get-ChildItem -LiteralPath (Join-Path $modRoot 'Components\BBG\sql') -Recurse -File -Filter '*.sql')) {
		$bbgSqlText = Get-Content -LiteralPath $bbgSqlFile.FullName -Raw
		foreach ($match in @([regex]::Matches($bbgSqlText, "\(\s*'(POLICY_[A-Z0-9_]+)'\s*,\s*'KIND_POLICY'\s*\)"))) {
			[void]$bbgPolicyIds.Add($match.Groups[1].Value)
		}
	}
	foreach ($policyId in $bbgPolicyIds) {
		$iconName = "ICON_$policyId"
		if ($null -eq $bbgIcons.SelectSingleNode("/GameInfo/IconDefinitions/Row[@Name='$iconName']") -and
				$null -eq $bbgIcons.SelectSingleNode("/GameInfo/IconAliases/Row[@Name='$iconName']")) {
			Add-ValidationError "BBG-created policy has no icon definition or alias: $policyId"
		}
	}

	$bbgIconAction = $modInfo.SelectSingleNode("/Mod/InGameActions/UpdateIcons[File='Components/BBG/data/new_bbg_icons.xml']")
	if ($null -eq $bbgIconAction) {
		Add-ValidationError 'The BBG icon file is not loaded by the expected InGame UpdateIcons action.'
	}
}

$gameplayOverrideTextPath = Join-Path $modRoot 'lang\ZYL_GameplayOverrides_Text.xml'
if (-not (Test-Path -LiteralPath $gameplayOverrideTextPath)) {
	Add-ValidationError 'ZYL gameplay override localization is missing.'
}
else {
	$gameplayOverrideText = Get-Content -LiteralPath $gameplayOverrideTextPath -Raw
	$gameplayOverrideTextXml = Load-XmlDocument $gameplayOverrideTextPath
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
		'LOC_TRAIT_CIVILIZATION_MOTHER_RUSSIA_EXPANSION2_DESCRIPTION'
	)) {
		if (-not $gameplayOverrideText.Contains($requiredTextToken)) {
			Add-ValidationError "Gameplay override localization is missing invariant: $requiredTextToken"
		}
	}
	$maliText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_MALI_GOLD_DESERT_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	foreach ($requiredFragment in @('+2 [ICON_FOOD]', '+1 [ICON_PRODUCTION]', '+1 [ICON_FAITH]', '+2 [ICON_GOLD]')) {
		if (-not $maliText.Contains($requiredFragment)) {
			Add-ValidationError "Mali Chinese text is missing: $requiredFragment"
		}
	}
	foreach ($removedFragment in @('-5%', '−5%', '对外贸易', '4 [ICON_FOOD]')) {
		if ($maliText.Contains($removedFragment)) {
			Add-ValidationError "Mali Chinese text still claims a removed or global-only rule: $removedFragment"
		}
	}
	$sahelText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_SAHEL_MERCHANTS_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	foreach ($requiredFragment in @('黄金时代', '永久+1 [ICON_TRADEROUTE]', '+2 [ICON_GOLD]', '曼丁哥市场', '+15%')) {
		if (-not $sahelText.Contains($requiredFragment)) {
			Add-ValidationError "Mansa Musa Chinese text is missing: $requiredFragment"
		}
	}
	if ($sahelText.Contains('银行业')) {
		Add-ValidationError 'Mansa Musa Chinese text still claims the removed Banking unlock.'
	}
	if ($sahelText.Contains('大量相邻加成')) {
		Add-ValidationError 'Mansa Musa Chinese text still uses a qualitative adjacency value instead of the final +2 Gold.'
	}
	foreach ($language in @('zh_Hans_CN', 'en_US')) {
		$sugubaNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_DISTRICT_SUGUBA_DESCRIPTION' and @Language='$language']/Text")
		if ($null -eq $sugubaNode -or -not $sugubaNode.InnerText.Contains('10%') -or $sugubaNode.InnerText.Contains('20%')) {
			Add-ValidationError "Suguba $language text must describe a 10% purchase discount and no obsolete 20% discount."
		}
	}

	$vizierText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_RIGHTEOUSNESS_OF_FAITH_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	if (([regex]::Matches($vizierText, '5%')).Count -ne 3 -or $vizierText.Contains('20%')) {
		Add-ValidationError 'Saladin (Vizier) Chinese text must describe three separate 5% stages and no obsolete 20% stage.'
	}
	$sultanText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_SALADIN_ALT_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	foreach ($requiredFragment in @('2', '+5', '-1', '[ICON_FAITH]', '[ICON_GOLD]')) {
		if (-not $sultanText.Contains($requiredFragment)) {
			Add-ValidationError "Saladin (Sultan) Chinese text is missing: $requiredFragment"
		}
	}
	foreach ($abilityTag in @('LOC_BBG_SULTAN_COMBAT_ADJACENT_APOSTLE_ABILITY_DESC', 'LOC_BBG_SULTAN_CS_FROM_APOSTLE_ABILITY_DESC')) {
		$abilityText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$abilityTag' and @Language='zh_Hans_CN']/Text").InnerText
		foreach ($requiredFragment in @('2', '+5', '[ICON_STRENGTH]')) {
			if (-not $abilityText.Contains($requiredFragment)) {
				Add-ValidationError "Saladin (Sultan) ability tooltip $abilityTag is missing: $requiredFragment"
			}
		}
	}
	$sundiataText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_SUNDIATA_KEITA_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	foreach ($requiredFragment in @('30%', '+1', '2', '+2', '+4', '[ICON_GreatWriter]', '[ICON_GREATWORK_WRITING]')) {
		if (-not $sundiataText.Contains($requiredFragment)) {
			Add-ValidationError "Sundiata Keita Chinese text is missing: $requiredFragment"
		}
	}
	if ($sundiataText.Contains('20%')) {
		Add-ValidationError 'Sundiata Keita Chinese text still contains the obsolete 20% purchase discount.'
	}
	$swedenText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_NOBEL_PRIZE_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	foreach ($requiredFragment in @('20', '+50%', '工厂每回合+1', '大学每回合+1', '北境之王')) {
		if (-not $swedenText.Contains($requiredFragment)) {
			Add-ValidationError "Sweden civilization Chinese text is missing: $requiredFragment"
		}
	}
	foreach ($leaderOnlyFragment in @('大作家', '大艺术家', '大音乐家')) {
		if ($swedenText.Contains($leaderOnlyFragment)) {
			Add-ValidationError "Sweden civilization text still claims Kristina's Government Plaza Great Person points: $leaderOnlyFragment"
		}
	}
	$kristinaText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_KRISTINA_AUTO_THEME_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	foreach ($requiredFragment in @('自动获得主题加成', '女王图书馆', '一级、二级、三级市政广场建筑', '大作家', '大艺术家', '大音乐家', '大科学家', '大工程师')) {
		if (-not $kristinaText.Contains($requiredFragment)) {
			Add-ValidationError "Kristina Chinese text is missing: $requiredFragment"
		}
	}
	$ramsesText = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_RAMSES_DESCRIPTION' and @Language='zh_Hans_CN']/Text").InnerText
	foreach ($requiredFragment in @('泛滥平原', '已改良', '+1 [ICON_FOOD]', '+1 [ICON_FAITH]', '+1 [ICON_PRODUCTION]', '+15%')) {
		if (-not $ramsesText.Contains($requiredFragment)) {
			Add-ValidationError "Ramses II Chinese text is missing: $requiredFragment"
		}
	}
	$magnificenceChineseNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_MAGNIFICENCES_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
	$magnificenceEnglishNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_MAGNIFICENCES_DESCRIPTION' and @Language='en_US']/Text")
	if ($null -eq $magnificenceChineseNode -or
			-not $magnificenceChineseNode.InnerText.Contains('“技艺”市政后，奢侈资源+1') -or
			-not $magnificenceChineseNode.InnerText.Contains('“封建主义”市政后，加成资源+1') -or
			-not $magnificenceChineseNode.InnerText.Contains('“城堡”科技后，战略资源+1')) {
		Add-ValidationError 'Magnificence Chinese text does not describe the Luxury/Bonus/Strategic staggered Culture unlocks.'
	}
	if ($null -eq $magnificenceEnglishNode -or
			-not $magnificenceEnglishNode.InnerText.Contains('Luxury resources gain +1') -or
			-not $magnificenceEnglishNode.InnerText.Contains('Bonus resources gain +1') -or
			-not $magnificenceEnglishNode.InnerText.Contains('Strategic resources gain +1')) {
		Add-ValidationError 'Magnificence English text does not describe the Luxury/Bonus/Strategic staggered Culture unlocks.'
	}
	$franceChineseNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_WONDER_TOURISM_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
	$franceEnglishNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_WONDER_TOURISM_DESCRIPTION' and @Language='en_US']/Text")
	if ($null -eq $franceChineseNode -or -not $franceChineseNode.InnerText.Contains('出生地关联：T4河流、T4奢侈资源')) {
		Add-ValidationError 'France Chinese civilization text does not describe its T4 River and Luxury resource biases.'
	}
	if ($null -eq $franceEnglishNode -or -not $franceEnglishNode.InnerText.Contains('Bias: T4 Rivers, T4 Luxury resources')) {
		Add-ValidationError 'France English civilization text does not describe its T4 River and Luxury resource biases.'
	}
	if ($magnificenceChineseNode.InnerText.Contains('出生地关联') -or $magnificenceEnglishNode.InnerText.Contains('Bias:')) {
		Add-ValidationError 'France Luxury resource bias is still presented as a Magnificence-only leader rule.'
	}
	foreach ($russiaTag in @('LOC_TRAIT_CIVILIZATION_MOTHER_RUSSIA_DESCRIPTION', 'LOC_TRAIT_CIVILIZATION_MOTHER_RUSSIA_EXPANSION2_DESCRIPTION')) {
		$russiaEnglishNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$russiaTag' and @Language='en_US']/Text")
		$russiaChineseNode = $gameplayOverrideTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$russiaTag' and @Language='zh_Hans_CN']/Text")
		if ($null -eq $russiaEnglishNode -or -not $russiaEnglishNode.InnerText.Contains('tiles adjacent to a Holy Site or Lavra')) {
			Add-ValidationError "Russia English text does not describe Holy Site/Lavra adjacency: $russiaTag"
		}
		if ($null -eq $russiaChineseNode -or -not $russiaChineseNode.InnerText.Contains('与圣地或拉夫拉修道院相邻的冻土和冻土丘陵')) {
			Add-ValidationError "Russia Chinese text does not describe Holy Site/Lavra adjacency: $russiaTag"
		}
	}
}

# Lock the embedded BBG leader/unit tooltips whose upstream localizations were
# stale or ambiguous relative to the gameplay database.
$bbgEnglishPath = Join-Path $modRoot 'Components\BBG\lang\english.xml'
$bbgChinesePath = Join-Path $modRoot 'Components\BBG\lang\chinese.xml'
if (-not (Test-Path -LiteralPath $bbgEnglishPath) -or -not (Test-Path -LiteralPath $bbgChinesePath)) {
	Add-ValidationError 'Embedded BBG English or Chinese localization is missing.'
}
else {
	$bbgEnglishXml = Load-XmlDocument $bbgEnglishPath
	$bbgChineseXml = Load-XmlDocument $bbgChinesePath

	$sultanEnglishNode = $bbgEnglishXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_BBG_SULTAN_COMBAT_ADJACENT_APOSTLE_ABILITY_DESC' and @Language='en_US']/Text")
	if ($null -eq $sultanEnglishNode -or -not $sultanEnglishNode.InnerText.Contains('within 2 tiles')) {
		Add-ValidationError 'Saladin (Sultan) English combat tooltip must target military units within 2 tiles of an Apostle.'
	}

	$tagmaChineseNode = $bbgChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_ABILITY_TAGMA_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
	foreach ($requiredFragment in @('普通陆地战斗单位', '+2 [ICON_Strength]', '宗教单位', '+2 [ICON_RELIGION]')) {
		if ($null -eq $tagmaChineseNode -or -not $tagmaChineseNode.InnerText.Contains($requiredFragment)) {
			Add-ValidationError "Tagma Chinese ability tooltip is missing: $requiredFragment"
		}
	}

	$norwayChineseNode = $bbgChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_THUNDERBOLT_EXPANSION2_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
	foreach ($requiredFragment in @('造船术', '海洋单元格', '营地')) {
		if ($null -eq $norwayChineseNode -or -not $norwayChineseNode.InnerText.Contains($requiredFragment)) {
			Add-ValidationError "Norway Chinese Gathering Storm tooltip is missing: $requiredFragment"
		}
	}

	$kublaiEnglishNode = $bbgEnglishXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_KUBLAI_DESCRIPTION' and @Language='en_US']/Text")
	if ($null -eq $kublaiEnglishNode -or -not $kublaiEnglishNode.InnerText.Contains('adjacent to another Great Wall') -or -not $kublaiEnglishNode.InnerText.Contains('+1 [ICON_CULTURE]')) {
		Add-ValidationError 'Kublai English tooltip is missing the conditional Great Wall Culture bonus.'
	}
	$kublaiChineseNode = $bbgChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_KUBLAI_DESCRIPTION' and @Language='zh_Hans_CN']/Text")
	foreach ($requiredFragment in @('与另一座长城相邻', '+1 [ICON_CULTURE]')) {
		if ($null -eq $kublaiChineseNode -or -not $kublaiChineseNode.InnerText.Contains($requiredFragment)) {
			Add-ValidationError "Kublai Chinese tooltip is missing: $requiredFragment"
		}
	}
}

$ramsesGameplayPath = Join-Path $modRoot 'Components\BBG\sql\LP\Ramses.sql'
if (-not (Test-Path -LiteralPath $ramsesGameplayPath)) {
	Add-ValidationError 'Ramses BBG gameplay SQL is missing.'
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
			Add-ValidationError "Ramses floodplain-resource modifier is not bound to his leader trait: $modifierId"
		}
	}
}

# Great People whose BBG actions were rewritten must not retain the obsolete
# vanilla tooltip details.  Aethelflaed now creates a plain Trebuchet (the
# modifier no longer grants a free promotion); Drake's production bonus is
# 25% in the final BBG rules, not the stale 20% value in the embedded source.
$greatPersonChinesePath = Join-Path $modRoot 'lang\ZYL_BBG74_Chinese_Text.xml'
if (-not (Test-Path -LiteralPath $greatPersonChinesePath)) {
	Add-ValidationError 'BBG Great People Chinese overlay is missing.'
}
else {
	$greatPersonChineseXml = Load-XmlDocument $greatPersonChinesePath
	$aethelflaedTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_GREATPERSON_AETHELFLAED_ACTIVE' and @Language='zh_Hans_CN']/Text")
	if ($null -eq $aethelflaedTextNode -or -not $aethelflaedTextNode.InnerText.Contains('投石机') -or $aethelflaedTextNode.InnerText.Contains('强化等级')) {
		Add-ValidationError 'Aethelflaed Chinese tooltip must describe only a Trebuchet in the capital.'
	}
	$drakeTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_GREATPERSON_FRANCIS_DRAKE_EXPANSION2_ACTIVE' and @Language='zh_Hans_CN']/Text")
	if ($null -eq $drakeTextNode -or -not $drakeTextNode.InnerText.Contains('+25%') -or $drakeTextNode.InnerText.Contains('+20%')) {
		Add-ValidationError 'Francis Drake Chinese tooltip must use the final +25% naval production bonus.'
	}
	foreach ($dharmaTag in @('LOC_TRAIT_CIVILIZATION_DHARMA_DESCRIPTION', 'LOC_TRAIT_CIVILIZATION_DHARMA_EXPANSION2_DESCRIPTION')) {
		$dharmaTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$dharmaTag' and @Language='zh_Hans_CN']/Text")
		if ($null -eq $dharmaTextNode -or -not $dharmaTextNode.InnerText.Contains('信奉您的主流宗教') -or -not $dharmaTextNode.InnerText.Contains('+1 [ICON_AMENITIES]') -or $dharmaTextNode.InnerText.Contains('拥有多个宗教')) {
			Add-ValidationError "India Dharma Chinese tooltip is stale or incomplete: $dharmaTag"
		}
	}
	foreach ($escorialTag in @('LOC_TRAIT_LEADER_EL_ESCORIAL_DESCRIPTION', 'LOC_TRAIT_LEADER_EL_ESCORIAL_EXPANSION2_DESCRIPTION')) {
		$escorialTextNode = $greatPersonChineseXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$escorialTag' and @Language='zh_Hans_CN']/Text")
		if ($null -eq $escorialTextNode -or -not $escorialTextNode.InnerText.Contains('信奉其他宗教的玩家') -or $escorialTextNode.InnerText.Contains('信仰其他宗教的单位')) {
			Add-ValidationError "Philip II Chinese tooltip must target players following other religions: $escorialTag"
		}
	}
}

$gameplayOverridePath = Join-Path $modRoot 'sql\ZYL_GameplayOverrides.sql'
if (-not (Test-Path -LiteralPath $gameplayOverridePath)) {
	Add-ValidationError 'ZYL gameplay override SQL is missing.'
}
else {
	$gameplayOverrideSql = Get-Content -LiteralPath $gameplayOverridePath -Raw
	foreach ($stadiumInvariant in @(
		"WHERE ModifierId = 'TRAIT_GRANT_CULTURE_UNIT_TRAINED'",
		"AND Name = 'UnitProductionPercent'",
		"WHERE ModifierId = 'FERRIS_WHEEL_TOURISM'",
		"WHERE ModifierId = 'AQUATICS_CENTER_WONDER_TOURISM'",
		"WHERE ModifierId = 'STADIUM_10_POPULATION_TOURISM'",
		"WHERE ModifierId = 'STADIUM_20_POPULATION_TOURISM'",
		"WHERE ModifierId = 'GREATPERSON_MOVEMENT_AOE_INFORMATION_SEA'",
		"AND Name = 'ModifierId'",
		"AND Value = 'ABILITY_GREAT_ADMIRAL_MOVEMENT'",
		"'MINOR_CIV_CARTHAGE_BARRACKS_STABLE_PURCHASE_BONUS'",
		"'MINOR_CIV_CARTHAGE_ARMORY_PURCHASE_BONUS'",
		"'MINOR_CIV_CARTHAGE_MILITARY_ACADEMY_PURCHASE_BONUS'",
		"SET Value = 'DOMAIN_LAND'",
		"AND Name = 'UnitDomain'",
		"SET Value = '25'",
		"SET Value = '6'",
		"SET Value = '15'"
	)) {
		if (-not $gameplayOverrideSql.Contains($stadiumInvariant)) {
			Add-ValidationError "Malformed BBG ModifierArguments repair is missing invariant: $stadiumInvariant"
		}
	}
}
if (-not (Test-Path -LiteralPath $governorOverridePath)) {
    Add-ValidationError 'ZYL governor override SQL is missing.'
}
else {
    $governorOverrideSql = Get-Content -LiteralPath $governorOverridePath -Raw
    foreach ($requiredToken in @(
		"GovernorType = 'GOVERNOR_THE_BUILDER'",
		'SET TransitionStrength = 150',
        'SURPLUS_LOGISTICS_EXTRA_GROWTH',
        'EXPEDITION_ADJUST_SETTLERS_CONSUME_POPULATION',
        'BBG_GOVERNOR_MAGNUS_PROD_IZ',
        "SET Value = '40'"
    )) {
        if (-not $governorOverrideSql.Contains($requiredToken)) {
            Add-ValidationError "Governor override SQL is missing invariant: $requiredToken"
        }
    }
}

$criteriaMap = @{}
foreach ($criteriaNode in @($modInfo.SelectNodes('/Mod/ActionCriteria/Criteria'))) {
    $criteriaId = $criteriaNode.GetAttribute('id')
    $criteriaKey = $criteriaId.ToLowerInvariant()
    if ($criteriaMap.ContainsKey($criteriaKey)) {
        Add-ValidationError "Duplicate criteria id: $criteriaId"
    }
    else {
        $criteriaMap[$criteriaKey] = $criteriaNode
    }
}
foreach ($actionNode in $actionNodes) {
    $criteriaReferences = [System.Collections.Generic.List[string]]::new()
    foreach ($criteriaNode in @($actionNode.SelectNodes('./Criteria'))) {
        $criteriaReferences.Add($criteriaNode.InnerText.Trim())
    }
    foreach ($attributeName in @('criteria', 'Criteria')) {
        if ($actionNode.HasAttribute($attributeName)) {
            $criteriaReferences.Add($actionNode.GetAttribute($attributeName).Trim())
        }
    }
    foreach ($criteriaReference in $criteriaReferences) {
        if (-not $criteriaMap.ContainsKey($criteriaReference.ToLowerInvariant())) {
            Add-ValidationError "Unknown criteria '$criteriaReference' in action '$($actionNode.GetAttribute('id'))'."
        }
    }
}

$actionReferenceMap = @{}
foreach ($actionNode in $actionNodes) {
    foreach ($referenceNode in @($actionNode.SelectNodes('.//File') + $actionNode.SelectNodes('.//LuaReplace'))) {
        $relativePath = $referenceNode.InnerText.Trim().Replace('/', '\')
        $actionReferenceMap[(Normalize-RelativePath $relativePath)] = $relativePath
    }
}

# AddUserInterfaces loads a same-named Lua file beside its XML when present.
foreach ($actionNode in @($actionNodes | Where-Object { $_.LocalName -eq 'AddUserInterfaces' })) {
    foreach ($fileNode in @($actionNode.SelectNodes('.//File'))) {
        if ($fileNode.InnerText -notlike '*.xml') { continue }
        $pairedLua = [System.IO.Path]::ChangeExtension($fileNode.InnerText.Trim(), '.lua').Replace('/', '\')
        if (Test-Path -LiteralPath (Join-Path $modRoot $pairedLua)) {
            $actionReferenceMap[(Normalize-RelativePath $pairedLua)] = $pairedLua
        }
    }
}
foreach ($key in @($actionReferenceMap.Keys | Sort-Object)) {
    $relativePath = $actionReferenceMap[$key]
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot $relativePath))) {
        Add-ValidationError "Action reference missing on disk: $relativePath"
    }
    if (-not $listedFileMap.ContainsKey($key)) {
        Add-ValidationError "Action reference absent from <Files>: $relativePath"
    }
}

# Rich Mainland split invariants: keep both public maps, all FFA player-count
# sizes and their gameplay defaults from regressing during future integrations.
$richMainlandManifestFiles = @(
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
foreach ($requiredFile in $richMainlandManifestFiles) {
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $requiredFile))) {
        Add-ValidationError "Rich Mainland file absent from <Files>: $requiredFile"
    }
}

$richMainlandCriteria = @{
    'zyl_richmainland' = @('zyl_ffa_rich_mainland.lua', 'zyl_team_rich_mainland.lua')
    'zyl_richmainland_team' = @('zyl_team_rich_mainland.lua')
    'zyl_richmainland_ffa' = @('zyl_ffa_rich_mainland.lua')
}

# Rich Mainland runtime safeguards: missing city-state starts are recovered by
# a distance-tiered full-map search, and the early horse/iron guarantee has a
# deterministic safe fallback.  These checks prevent a future source sync
# from silently restoring the old "temporary tile then delete the CS" path.
$richMainlandAssignPath = Join-Path $modRoot 'Components\BBM\Data\BBS Maps\Utility\ZYL_RVC_AssignStartingPlots.lua'
if (Test-Path -LiteralPath $richMainlandAssignPath) {
    $richMainlandAssignLua = Get-Content -LiteralPath $richMainlandAssignPath -Raw
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
        'ZYL_RVC_GetCoastOrientation',
		"SEAS_CIVILIZATION[row.CivilizationType] = true",
		"including BBG's land-start",
        'Areas.FindBiggestArea(false)',
        'plotArea:GetID() ~= ZYL_RVC_MAINLAND_AREA_ID',
        'eastWestSeaMargin',
        'northSouthSeaMargin = 6',
        'ratedPlot.CoastOrientation == "EW"',
        'self.oceanStartFallbackPlayers[iPlayer] == true',
        'ZYLRM_COAST_ORIENTATION_',
        'local categoryOrder = major == true and { "COAST", "INLAND" } or { "ALL" };'
    )) {
        if (-not $richMainlandAssignLua.Contains($requiredToken)) {
            Add-ValidationError "Rich Mainland city-state fallback is missing: $requiredToken"
        }
    }
    if ($richMainlandAssignLua -match 'Map\.GetPlotByIndex\(PlayerManager\.GetAliveMajorsCount\(\)\+PlayerManager\.GetAliveMinorsCount\(\)\+count\)') {
        Add-ValidationError 'Rich Mainland still assigns missing city-states to an arbitrary map-index tile.'
    }
}

$richMainlandBalancePath = Join-Path $modRoot 'Components\BBM\Data\BBS Maps\Utility\ZYL_RVC_Balance.lua'
if (Test-Path -LiteralPath $richMainlandBalancePath) {
    $richMainlandBalanceLua = Get-Content -LiteralPath $richMainlandBalancePath -Raw
    foreach ($requiredToken in @(
        'ZYL_RVC_PlaceGuaranteedEarlyStrategic',
        'empty desert converted to plains',
        'ordinary bonus resource replaced',
        'protectedStartPlots',
        'ZYLRM_EARLY_STRATEGIC_FALLBACKS'
    )) {
        if (-not $richMainlandBalanceLua.Contains($requiredToken)) {
            Add-ValidationError "Rich Mainland strategic fallback is missing: $requiredToken"
        }
    }
    if ($richMainlandBalanceLua -match 'Removing city-state player|has been eliminated \(too close to') {
        Add-ValidationError 'Rich Mainland balance script still deletes city-states during post-placement distance checks.'
    }
}
$richMainlandCorePath = Join-Path $modRoot 'Components\BBM\Data\BBS Maps\zyl_rich_mainland_core.lua'
if (Test-Path -LiteralPath $richMainlandCorePath) {
    $richMainlandCoreLua = Get-Content -LiteralPath $richMainlandCorePath -Raw
    foreach ($requiredToken in @(
        'function ZYL_EnsureCoastalStartReefResource()',
        'startPlot:IsCoastalLand()',
        'RelocateRingTwoResource',
        'ZYL RVC ring-two Turtles or Fish',
        'ZYLRM_COASTAL_START_REEF_RESOURCE',
        'ZYL_RVC_EnforceSeaResourceRules();' + [Environment]::NewLine + "`tZYL_EnsureCoastalStartReefResource();"
    )) {
        if (-not $richMainlandCoreLua.Contains($requiredToken)) {
            Add-ValidationError "Rich Mainland coastal-start reef guarantee is missing: $requiredToken"
        }
    }
}
foreach ($entry in $richMainlandCriteria.GetEnumerator()) {
    if (-not $criteriaMap.ContainsKey($entry.Key)) {
        Add-ValidationError "Rich Mainland criterion is missing: $($entry.Key)"
        continue
    }
    $criterionNode = $criteriaMap[$entry.Key]
    $actualMapScripts = @($criterionNode.SelectNodes('./ConfigurationValueMatches') | Where-Object {
        $_.SelectSingleNode('./Group').InnerText -eq 'Map' -and
        $_.SelectSingleNode('./ConfigurationId').InnerText -eq 'MAP_SCRIPT'
    } | ForEach-Object { $_.SelectSingleNode('./Value').InnerText } | Sort-Object)
    $expectedMapScripts = @($entry.Value | Sort-Object)
    if (($actualMapScripts -join '|') -ne ($expectedMapScripts -join '|')) {
        Add-ValidationError "Rich Mainland criterion $($entry.Key) has unexpected map scripts: $($actualMapScripts -join ', ')"
    }
}
if ($criteriaMap.ContainsKey('zyl_richmainland') -and
        $criteriaMap['zyl_richmainland'].GetAttribute('any') -ne '1') {
    Add-ValidationError 'The shared Rich Mainland criterion must use OR semantics (any=1).'
}

$richMainlandActions = @(
    @('zyl_richmainland_config', 'FrontEndActions', 'UpdateDatabase', 'Components/BBM/Configuration/ZYL_RichMainland_Config.xml', ''),
    @('zyl_richmainland_text', 'FrontEndActions', 'UpdateText', 'Components/BBM/Lang/ZYL_RichMainland_Text.xml', ''),
    @('zyl_richmainland_mapscripts', 'InGameActions', 'ImportFiles', 'Components/BBM/Data/BBS Maps/zyl_rich_mainland_core.lua', ''),
    @('zyl_richmainland_common', 'InGameActions', 'UpdateDatabase', 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureCommon.sql', 'ZYL_RichMainland'),
    @('zyl_richmainland_team_config', 'InGameActions', 'UpdateDatabase', 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureTeam.sql', 'ZYL_RichMainland_Team'),
    @('zyl_richmainland_ffa_config', 'InGameActions', 'UpdateDatabase', 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureFFA.sql', 'ZYL_RichMainland_FFA')
)
foreach ($requiredAction in $richMainlandActions) {
    $actionKey = $requiredAction[0]
    if (-not $actionIdMap.ContainsKey($actionKey)) {
        Add-ValidationError "Rich Mainland action is missing: $actionKey"
        continue
    }
    $actionNode = $actionIdMap[$actionKey]
    if ($actionNode.ParentNode.LocalName -ne $requiredAction[1] -or $actionNode.LocalName -ne $requiredAction[2]) {
        Add-ValidationError "Rich Mainland action $actionKey is in the wrong section or has the wrong type."
    }
    $expectedFileKey = Normalize-RelativePath $requiredAction[3]
    $actualFileKeys = @($actionNode.SelectNodes('./File') | ForEach-Object { Normalize-RelativePath $_.InnerText })
    if ($expectedFileKey -notin $actualFileKeys) {
        Add-ValidationError "Rich Mainland action $actionKey does not reference $($requiredAction[3])."
    }
    if (-not [string]::IsNullOrWhiteSpace($requiredAction[4])) {
        $actualCriteria = @($actionNode.SelectNodes('./Criteria') | ForEach-Object { $_.InnerText.Trim() })
        if ($requiredAction[4] -notin $actualCriteria) {
            Add-ValidationError "Rich Mainland action $actionKey is missing criterion $($requiredAction[4])."
        }
    }
}

# The local settings and README expose TPT's bottom-right force-end-turn
# button.  Keep its UI, text and paired Lua published and active; this catches
# the otherwise silent state where the setting exists but no button is loaded.
$forcedEndButtonFiles = @(
    'FEB/ForcedEndButton_Text.xml',
    'FEB/UI/ForcedEndButton.lua',
    'FEB/UI/ForcedEndButton.xml'
)
foreach ($requiredFile in $forcedEndButtonFiles) {
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $requiredFile))) {
        Add-ValidationError "Force-end-turn button file absent from <Files>: $requiredFile"
    }
}

$forcedEndTextAction = $actionIdMap['zyl_forcedendbuttontext']
if ($null -eq $forcedEndTextAction -or
        $forcedEndTextAction.LocalName -ne 'UpdateText' -or
        $null -eq $forcedEndTextAction.SelectSingleNode("./File[.='FEB/ForcedEndButton_Text.xml']")) {
    Add-ValidationError 'Force-end-turn button localization is not loaded by ModInfo.'
}

$forcedEndUiAction = $actionIdMap['zyl_forcedendbutton']
if ($null -eq $forcedEndUiAction -or $forcedEndUiAction.LocalName -ne 'AddUserInterfaces') {
    Add-ValidationError 'Force-end-turn button UI action is missing.'
}
else {
    if ($forcedEndUiAction.SelectSingleNode('./Properties/Context').InnerText -ne 'InGame') {
        Add-ValidationError 'Force-end-turn button must load in the InGame UI context.'
    }
    if ($null -eq $forcedEndUiAction.SelectSingleNode("./File[.='FEB/UI/ForcedEndButton.xml']")) {
        Add-ValidationError 'Force-end-turn button UI action references the wrong layout.'
    }
}

$forcedEndLuaPath = Join-Path $modRoot 'FEB\UI\ForcedEndButton.lua'
if (-not (Test-Path -LiteralPath $forcedEndLuaPath)) {
    Add-ValidationError 'Force-end-turn button Lua is missing.'
}
else {
    $forcedEndLua = Get-Content -LiteralPath $forcedEndLuaPath -Raw
    $requestCount = ([regex]::Matches(
        $forcedEndLua,
        'UI\.RequestAction\s*\(\s*ActionTypes\.ACTION_ENDTURN'
    )).Count
    if ($requestCount -ne 1) {
        Add-ValidationError "Force-end-turn button must issue exactly one end-turn request; found $requestCount."
    }
    foreach ($forbiddenToken in @(
        'ACTION_UNREADYTURN',
        'GameCoreEventPublishComplete.Add',
        'LuaEvents.ForcedEndTurn()'
    )) {
        if ($forcedEndLua.Contains($forbiddenToken)) {
            Add-ValidationError "Force-end-turn button restored an old retry/toggle path: $forbiddenToken"
        }
    }
}

# TPT front-end/QoL modules that are easy to leave on disk without activating.
# Validate both the ModInfo wiring and the behavior each file is meant to own.
$lanNameAction = $actionIdMap['zyl_lanplayernamelength']
if ($null -eq $lanNameAction -or
        $lanNameAction.ParentNode.LocalName -ne 'FrontEndActions' -or
        $lanNameAction.LocalName -ne 'ImportFiles' -or
        $null -eq $lanNameAction.SelectSingleNode("./File[.='Option/Options.xml']")) {
    Add-ValidationError 'The 128-character LAN player-name Options replacement is not active in FrontEndActions.'
}
$optionsPath = Join-Path $modRoot 'Option\Options.xml'
if (-not (Test-Path -LiteralPath $optionsPath)) {
    Add-ValidationError 'The LAN player-name Options replacement is missing.'
}
else {
    $optionsXml = Load-XmlDocument $optionsPath
    $lanNameEdit = $optionsXml.SelectSingleNode("//*[@ID='LANPlayerNameEdit']")
    if ($null -eq $lanNameEdit -or $lanNameEdit.GetAttribute('MaxLength') -ne '128') {
        Add-ValidationError 'LANPlayerNameEdit must retain MaxLength=128.'
    }
}

$noticeScriptAction = $actionIdMap['zyl_gamefeaturenotices']
if ($null -eq $noticeScriptAction -or
        $noticeScriptAction.LocalName -ne 'AddGameplayScripts' -or
        $null -eq $noticeScriptAction.SelectSingleNode("./File[.='NT/Notice.lua']")) {
    Add-ValidationError 'The TPT start-of-game feature notice script is not active.'
}
$noticeTextAction = $actionIdMap['zyl_gamefeaturenoticestext']
if ($null -eq $noticeTextAction -or
        $noticeTextAction.LocalName -ne 'UpdateText' -or
        $null -eq $noticeTextAction.SelectSingleNode("./File[.='NT/Notice_Text.xml']")) {
    Add-ValidationError 'The TPT start-of-game feature notice text is not active.'
}

$noPinsCriterion = $criteriaMap['zyl_nomappins']
if ($null -eq $noPinsCriterion) {
    Add-ValidationError 'The no-map-pins UI criterion is missing.'
}
else {
    $noPinsMatch = $noPinsCriterion.SelectSingleNode(
        "./ConfigurationValueMatches[Group='Game' and ConfigurationId='CPL_NO_PINS' and Value='1']"
    )
    if ($null -eq $noPinsMatch) {
        Add-ValidationError 'The no-map-pins UI criterion does not match CPL_NO_PINS=1.'
    }
}
$hidePinsAction = $actionIdMap['zyl_hidemappinlistbutton']
if ($null -eq $hidePinsAction -or
        $hidePinsAction.LocalName -ne 'AddUserInterfaces' -or
        $null -eq $hidePinsAction.SelectSingleNode("./Criteria[.='ZYL_NoMapPins']") -or
        $null -eq $hidePinsAction.SelectSingleNode("./File[.='RMP/UI/Hide_MapPinListButton.xml']")) {
    Add-ValidationError 'CPL_NO_PINS does not activate the map-pin list button hider.'
}
$hidePinsPanelAction = $actionIdMap['zyl_hidemappinlistpanel']
if ($null -eq $hidePinsPanelAction -or
        $hidePinsPanelAction.LocalName -ne 'ReplaceUIScript' -or
        $hidePinsPanelAction.SelectSingleNode('./Properties/LuaContext').InnerText -ne 'MapPinListPanel' -or
        $hidePinsPanelAction.SelectSingleNode('./Properties/LuaReplace').InnerText -ne 'RMP/UI/MapPinListPanel.lua' -or
        $null -eq $hidePinsPanelAction.SelectSingleNode("./Criteria[.='ZYL_NoMapPins']")) {
    Add-ValidationError 'CPL_NO_PINS does not replace MapPinListPanel with the empty implementation.'
}
$hidePinsPanelFilesAction = $actionIdMap['zyl_hidemappinlistpanelfiles']
if ($null -eq $hidePinsPanelFilesAction -or
        $hidePinsPanelFilesAction.LocalName -ne 'ImportFiles' -or
        $null -eq $hidePinsPanelFilesAction.SelectSingleNode("./File[.='RMP/UI/MapPinListPanel.xml']") -or
        $null -eq $hidePinsPanelFilesAction.SelectSingleNode("./File[.='RMP/UI/MapPinListPanel.lua']")) {
    Add-ValidationError 'The empty no-pins MapPinListPanel layout/script pair is not imported.'
}

$randomPromotionConfig = $actionIdMap['zyl_randompromotionhotkeyconfig']
if ($null -eq $randomPromotionConfig -or
        $randomPromotionConfig.ParentNode.LocalName -ne 'FrontEndActions' -or
        $randomPromotionConfig.LocalName -ne 'UpdateDatabase' -or
        $null -eq $randomPromotionConfig.SelectSingleNode("./File[.='NHK/Config_NewUnitOperation.xml']")) {
    Add-ValidationError 'The safe TPT random-promotion shortcut is absent from the front-end input configuration.'
}
$randomPromotionUi = $actionIdMap['zyl_randompromotionhotkey']
if ($null -eq $randomPromotionUi -or
        $randomPromotionUi.LocalName -ne 'AddUserInterfaces' -or
        $null -eq $randomPromotionUi.SelectSingleNode("./Criteria[.='TPT_NEW_HOTKEYS']") -or
        $null -eq $randomPromotionUi.SelectSingleNode("./File[.='NHK/UI/NewUnitOperation.xml']")) {
    Add-ValidationError 'The safe TPT random-promotion shortcut UI is not active when new hotkeys are enabled.'
}
$randomPromotionLuaPath = Join-Path $modRoot 'NHK\UI\NewUnitOperation.lua'
if (-not (Test-Path -LiteralPath $randomPromotionLuaPath)) {
    Add-ValidationError 'The safe random-promotion shortcut script is missing.'
}
else {
    $randomPromotionLua = Get-Content -LiteralPath $randomPromotionLuaPath -Raw
    foreach ($forbiddenToken in @(
        'Modding.UpdateSubscription',
        'function AntiCheat',
        'function KillCheat',
        'Events.TurnEnd.Add'
    )) {
        if ($randomPromotionLua.IndexOf($forbiddenToken, [System.StringComparison]::Ordinal) -ge 0) {
            Add-ValidationError "The removed NewUnitOperation anti-cheat/update path returned: $forbiddenToken"
        }
    }
}

$bbgUnitPanelPath = Join-Path $modRoot 'Components\BBG\ui\replacements\unitpanel_bbg.lua'
if (-not (Test-Path -LiteralPath $bbgUnitPanelPath) -or
        (Get-Content -LiteralPath $bbgUnitPanelPath -Raw).IndexOf(
            'function OnUnitActionClicked_FoundCity',
            [System.StringComparison]::Ordinal
        ) -lt 0) {
    Add-ValidationError 'TPT found-city confirmation removal is not merged into BBG UnitPanel ownership.'
}

$richMapConfigPath = Join-Path $modRoot 'Components\BBM\Configuration\ZYL_RichMainland_Config.xml'
if (-not (Test-Path -LiteralPath $richMapConfigPath)) {
    Add-ValidationError 'Rich Mainland configuration is missing.'
}
else {
    $richMapConfig = Load-XmlDocument $richMapConfigPath
    $expectedRichMaps = @('zyl_team_rich_mainland.lua', 'zyl_ffa_rich_mainland.lua')
    $actualRichMaps = @($richMapConfig.SelectNodes('/GameInfo/Maps/Row') | ForEach-Object { $_.GetAttribute('File') })
    if (($actualRichMaps -join '|') -ne ($expectedRichMaps -join '|')) {
        Add-ValidationError "Unexpected Rich Mainland map entries: $($actualRichMaps -join ', ')"
    }
    $teamSizes = @($richMapConfig.SelectNodes('/GameInfo/MapSizes/Row[@Domain="zyl_team_rich_mainland.lua"]'))
    $ffaSizes = @($richMapConfig.SelectNodes('/GameInfo/MapSizes/Row[@Domain="zyl_ffa_rich_mainland.lua"]'))
    if ($teamSizes.Count -ne 6) { Add-ValidationError "Team Rich Mainland must expose 6 sizes; found $($teamSizes.Count)." }
    if ($ffaSizes.Count -ne 11) { Add-ValidationError "FFA Rich Mainland must expose 11 sizes; found $($ffaSizes.Count)." }
    $ffaPlayers = @($ffaSizes | ForEach-Object { [int]$_.GetAttribute('DefaultPlayers') } | Sort-Object)
    if (($ffaPlayers -join ',') -ne ((2..12) -join ',')) {
        Add-ValidationError "FFA Rich Mainland player-size coverage is not 2-12: $($ffaPlayers -join ',')"
    }
    foreach ($ffaSize in $ffaSizes) {
        if ($ffaSize.GetAttribute('MaxPlayers') -ne $ffaSize.GetAttribute('DefaultPlayers')) {
            Add-ValidationError "FFA size $($ffaSize.GetAttribute('MapSizeType')) allows more players than its land-area guarantee."
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
        $node = $richMapConfig.SelectSingleNode("/GameInfo/Parameters/Row[@Key2='$($parts[0])' and @ConfigurationId='$($parts[1])']")
        if ($null -eq $node -or $node.GetAttribute('DefaultValue') -ne $entry.Value) {
            Add-ValidationError "Rich Mainland default $($entry.Key) must be $($entry.Value)."
        }
    }
}

$legacyRichMapReferences = @(
    'zyl_mountainous_rich_mainland.lua',
    'ZYL_MountainousRichMainland_Config.xml',
    'ZYL_MountainousRichMainland_Text.xml',
    'ZYLMRM/ConfigureMap.sql'
)
foreach ($legacyReference in $legacyRichMapReferences) {
    if ($modInfo.OuterXml -like "*$legacyReference*") {
        Add-ValidationError "Legacy Rich Mainland reference returned to ModInfo: $legacyReference"
    }
}

$zylConfigPath = Join-Path $modRoot 'configuration\Config_ZYL.xml'
if (Test-Path -LiteralPath $zylConfigPath) {
    $zylConfig = Load-XmlDocument $zylConfigPath
    $warningNode = $zylConfig.SelectSingleNode('/GameInfo/Parameters/Row[@ParameterId="TOOLS_15_TIME"]')
    if ($null -eq $warningNode -or $warningNode.GetAttribute('DefaultValue') -ne '1') {
        Add-ValidationError 'The 15-second warning must default to enabled.'
    }
    $zylConfigRows = @($zylConfig.SelectNodes('/GameInfo/Parameters/Row'))
    foreach ($parameterId in @('TOOLS_COMMAND', 'TOOLS_15_TIME')) {
        if ($null -eq ($zylConfigRows | Where-Object { $_.GetAttribute('ParameterId') -eq $parameterId })) {
            Add-ValidationError "Config_ZYL.xml is missing $parameterId."
        }
    }
	$ribbonModeOptions = @($zylConfig.SelectNodes('/GameInfo/Parameters/Row[@ParameterId="ZYL_DIPLOMACY_RIBBON_MODE"]'))
	if ($ribbonModeOptions.Count -ne 1 -or
		$ribbonModeOptions[0].GetAttribute('Key2') -ne 'RULESET_EXPANSION_2' -or
		$ribbonModeOptions[0].GetAttribute('Domain') -ne 'ZylDiplomacyRibbonModes' -or
		$ribbonModeOptions[0].GetAttribute('DefaultValue') -ne '0') {
		Add-ValidationError 'The diplomacy-ribbon mode must be an Expansion 2 lobby option using ZylDiplomacyRibbonModes and defaulting to FFA (0).'
	}
	$ribbonModeValues = @($zylConfig.SelectNodes('/GameInfo/DomainValues/Row[@Domain="ZylDiplomacyRibbonModes"]'))
	if ($ribbonModeValues.Count -ne 2 -or
		$null -eq ($ribbonModeValues | Where-Object { $_.GetAttribute('Value') -eq '0' }) -or
		$null -eq ($ribbonModeValues | Where-Object { $_.GetAttribute('Value') -eq '1' })) {
		Add-ValidationError 'The diplomacy-ribbon domain must contain exactly FFA (0) and Team (1).'
	}
}

# The balanced Casual timer is a distinct lobby option.  It must retain the
# original Casual baseline while using the highest individual city and unit
# counts, with cumulative midgame and late-game allowances.
$cplConfigPath = Join-Path $modRoot 'configuration\Config.xml'
$turnProcessingPath = Join-Path $modRoot 'ui\Additions\TurnProcessing.lua'
if (Test-Path -LiteralPath $cplConfigPath) {
    $cplConfig = Load-XmlDocument $cplConfigPath
	$smartTimerParameter = $cplConfig.SelectSingleNode('/GameInfo/Parameters/Row[@ParameterId="CPL_SMARTTIMER"]')
	if ($null -eq $smartTimerParameter -or $smartTimerParameter.GetAttribute('DefaultValue') -ne '8') {
		Add-ValidationError 'The base smart-timer lobby parameter must default to Casual (Balanced), value 8.'
	}
    $balancedTimerOption = $cplConfig.SelectSingleNode('/GameInfo/DomainValues/Row[@Domain="TimerLimits" and @Value="8"]')
    if ($null -eq $balancedTimerOption -or
        $balancedTimerOption.GetAttribute('Name') -ne 'TIMER_CASUAL_BALANCED_NAME' -or
        $balancedTimerOption.GetAttribute('Description') -ne 'TIMER_CASUAL_BALANCED_DESC') {
        Add-ValidationError 'The balanced Casual timer option (TimerLimits value 8) is missing or malformed.'
    }
}
if (Test-Path -LiteralPath $turnProcessingPath) {
    $turnProcessingSource = Get-Content -Raw -LiteralPath $turnProcessingPath
    foreach ($requiredCommandFragment in @(
        'local MAX_TIME_EXTENSIONS_PER_TURN = 3',
        'local g_timeCommandUses = 0',
        'if g_timeCommandUses >= MAX_TIME_EXTENSIONS_PER_TURN then return end',
        'g_timeCommandUses = g_timeCommandUses + 1',
        'g_timeCommandUses = 0'
    )) {
        if (-not $turnProcessingSource.Contains($requiredCommandFragment)) {
            Add-ValidationError "P++ per-turn limit logic is missing: $requiredCommandFragment"
        }
    }
    foreach ($requiredTimerFragment in @(
        'max_cities = math.max(max_cities, city_count)',
        'max_units = math.max(max_units, unit_count)',
        'GameConfiguration.GetValue("CPL_SMARTTIMER") == 8',
        'timer = 95 + max_cities * 4 + max_units + g_timeshift',
        'timer = timer + 40',
        'timer = timer + 20'
    )) {
        if (-not $turnProcessingSource.Contains($requiredTimerFragment)) {
            Add-ValidationError "Balanced Casual timer logic is missing: $requiredTimerFragment"
        }
    }
}

$eraLengthSqlPath = Join-Path $modRoot 'sql\ZYL_EraLengthOptimization.sql'
if (-not (Test-Path -LiteralPath $eraLengthSqlPath)) {
    Add-ValidationError 'The optional world-era duration SQL is missing.'
}
else {
    $eraLengthSource = Get-Content -Raw -LiteralPath $eraLengthSqlPath
    foreach ($requiredEraDurationFragment in @(
        "WHEN 'ERA_ANCIENT' THEN 40",
        "WHEN 'ERA_CLASSICAL' THEN 50",
        "WHEN 'ERA_MEDIEVAL' THEN 50",
        "WHEN 'ERA_ANCIENT' THEN 50",
        "WHEN 'ERA_CLASSICAL' THEN 60",
        "WHEN 'ERA_MEDIEVAL' THEN 60"
    )) {
        if (-not $eraLengthSource.Contains($requiredEraDurationFragment)) {
            Add-ValidationError "Optional world-era duration override is missing: $requiredEraDurationFragment"
        }
    }
}

if (Test-Path -LiteralPath $zylConfigPath) {
    $eraLengthOptions = @($zylConfig.SelectNodes('/GameInfo/Parameters/Row[@ParameterId="ZYL_ERA_LENGTH_OPTIMIZATION"]'))
    if ($eraLengthOptions.Count -ne 2 -or
        @($eraLengthOptions | Where-Object { $_.GetAttribute('DefaultValue') -ne '1' }).Count -gt 0 -or
        @($eraLengthOptions | Where-Object { $_.GetAttribute('Key2') -in @('RULESET_EXPANSION_1', 'RULESET_EXPANSION_2') }).Count -ne 2) {
        Add-ValidationError 'The optional world-era duration lobby toggle must exist for both expansion rulesets and default to enabled.'
    }
}

$eraLengthCriterion = $modInfo.SelectSingleNode('/Mod/ActionCriteria/Criteria[@id="ZYL_EraLengthOptimization" and RuleSetInUse="RULESET_EXPANSION_1,RULESET_EXPANSION_2" and ConfigurationValueMatches[ConfigurationId="ZYL_ERA_LENGTH_OPTIMIZATION" and Value="1"]]')
if ($null -eq $eraLengthCriterion) {
    Add-ValidationError 'The optional world-era duration action criterion is missing or malformed.'
}
$eraLengthAction = $modInfo.SelectSingleNode('/Mod/InGameActions/UpdateDatabase[@id="ZYL_EraLengthOptimization" and Criteria="ZYL_EraLengthOptimization" and File="sql/ZYL_EraLengthOptimization.sql"]')
if ($null -eq $eraLengthAction) {
    Add-ValidationError 'The optional world-era duration gameplay action is missing or malformed.'
}
foreach ($timerTextPath in @('lang\Text_CN.xml', 'lang\Text_EN.xml')) {
    $fullTimerTextPath = Join-Path $modRoot $timerTextPath
    if (Test-Path -LiteralPath $fullTimerTextPath) {
        $timerText = Load-XmlDocument $fullTimerTextPath
        foreach ($timerTag in @('TIMER_CASUAL_BALANCED_NAME', 'TIMER_CASUAL_BALANCED_DESC')) {
            if ($null -eq $timerText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='$timerTag']/Text")) {
                Add-ValidationError "$timerTextPath is missing $timerTag."
            }
        }
    }
}

# The final lobby defaults are deliberately a separate, late-loading action.
# Config_ZYL.xml also owns the two TPT rows, but its old mixed Update block ran
# before MPH/BBG had created their Parameters and therefore matched zero rows.
$lobbyDefaultsPath = Join-Path $modRoot 'configuration\ZYL_LobbyDefaults.xml'
if (-not (Test-Path -LiteralPath $lobbyDefaultsPath)) {
    Add-ValidationError 'The final lobby-default configuration is missing.'
}
else {
    $lobbyDefaults = Load-XmlDocument $lobbyDefaultsPath
    $expectedLobbyDefaults = @{
        'TOOLS_COMMAND' = '1'
        'TOOLS_15_TIME' = '1'
        'CPL_SMARTTIMER' = '8'
        'ZYL_ERA_LENGTH_OPTIMIZATION' = '1'
		'ZYL_DIPLOMACY_RIBBON_MODE' = '0'
        'BBCC_SETTING' = '0'
        'BBCC_SETTING_YIELD' = '2'
        'BarbariansSetting' = '-1'
        'NoBarbarians' = '1'
        'GameMode_Monopolies' = '1'
        'GameMode_SecretSocieties' = '1'
        'ZYLRM_TEAM_RouteLevel' = '1'
        'ZYLRM_FFA_RouteLevel' = '1'
    }
    foreach ($entry in $expectedLobbyDefaults.GetEnumerator()) {
        $node = $lobbyDefaults.SelectSingleNode("/GameInfo/Parameters/Update[Where/@ParameterId='$($entry.Key)']/Set")
        if ($null -eq $node -or $node.GetAttribute('DefaultValue') -ne $entry.Value) {
            Add-ValidationError "Final lobby default $($entry.Key) must be $($entry.Value)."
        }
    }
    $lobbyAction = $actionIdMap['zyl_lobbydefaults']
    if ($null -eq $lobbyAction) {
        Add-ValidationError 'Final lobby-default ModInfo action is missing.'
    }
    else {
        if ($lobbyAction.ParentNode.LocalName -ne 'FrontEndActions' -or $lobbyAction.LocalName -ne 'UpdateDatabase') {
            Add-ValidationError 'Final lobby-default action must be a FrontEndActions UpdateDatabase action.'
        }
        $loadOrderNode = $lobbyAction.SelectSingleNode('./Properties/LoadOrder')
        if ($null -eq $loadOrderNode -or [int64]$loadOrderNode.InnerText.Trim() -lt 300000000) {
            Add-ValidationError 'Final lobby-default action must load at or after 300000000.'
        }
        $cplAction = $actionIdMap['cpl_settings']
        if ($null -ne $cplAction) {
            $cplLoadOrderNode = $cplAction.SelectSingleNode('./Properties/LoadOrder')
            if ($null -ne $cplLoadOrderNode -and [int64]$loadOrderNode.InnerText.Trim() -le [int64]$cplLoadOrderNode.InnerText.Trim()) {
                Add-ValidationError 'Final lobby-default action must load after CPL_SETTINGS.'
            }
        }
        $lobbyActionFile = @($lobbyAction.SelectNodes('./File') | ForEach-Object { Normalize-RelativePath $_.InnerText })
        if ((Normalize-RelativePath 'configuration/ZYL_LobbyDefaults.xml') -notin $lobbyActionFile) {
            Add-ValidationError 'Final lobby-default action does not reference ZYL_LobbyDefaults.xml.'
        }
    }
}

$hostGamePath = Join-Path $modRoot 'ui\hostgame.lua'
if (Test-Path -LiteralPath $hostGamePath) {
    $kickVotingCalls = @(Select-String -LiteralPath $hostGamePath -SimpleMatch 'GameConfiguration.SetKickVoting(true);')
    if ($kickVotingCalls.Count -lt 2) {
        Add-ValidationError 'Kick voting must be enabled in fresh-host and restore-default flows.'
    }
    $hostGameLua = Get-Content -LiteralPath $hostGamePath -Raw
    $applyDefaultCalls = @([regex]::Matches($hostGameLua, 'ApplyZYLLobbyDefaults\s*\(\s*\)'))
    if ($applyDefaultCalls.Count -lt 4) {
        Add-ValidationError 'Host game must apply ZYLPVPMOD defaults for fresh rooms, Restore Defaults and MPH preset None.'
    }
	foreach ($requiredDefault in @(
		'{ "CPL_SMARTTIMER", 8 }',
		'{ "ZYL_ERA_LENGTH_OPTIMIZATION", 1 }',
		'{ "ZYL_DIPLOMACY_RIBBON_MODE", 0 }'
	)) {
		if (-not $hostGameLua.Contains($requiredDefault)) {
			Add-ValidationError "Host game is missing the requested lobby default: $requiredDefault"
		}
	}
}

# Secret Society promotions must refund their Governor Title. The BBG action
# which owns this SQL is already gated by the Ethiopia Pack and Gathering Storm.
$secretSocietiesPath = Join-Path $modRoot 'Components\BBG\sql\Secret_Societies.sql'
$secretSocietyPromotions = @(
    'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1',
    'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2',
    'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3',
    'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4',
    'GOVERNOR_PROMOTION_HERMETIC_ORDER_1',
    'GOVERNOR_PROMOTION_HERMETIC_ORDER_2',
    'GOVERNOR_PROMOTION_HERMETIC_ORDER_3',
    'GOVERNOR_PROMOTION_HERMETIC_ORDER_4',
    'GOVERNOR_PROMOTION_VOIDSINGERS_1',
    'GOVERNOR_PROMOTION_VOIDSINGERS_2',
    'GOVERNOR_PROMOTION_VOIDSINGERS_3',
    'GOVERNOR_PROMOTION_VOIDSINGERS_4',
    'GOVERNOR_PROMOTION_SANGUINE_PACT_1',
    'GOVERNOR_PROMOTION_SANGUINE_PACT_2',
    'GOVERNOR_PROMOTION_SANGUINE_PACT_3',
    'GOVERNOR_PROMOTION_SANGUINE_PACT_4'
)
if (-not (Test-Path -LiteralPath $secretSocietiesPath)) {
    Add-ValidationError 'BBG Secret Societies SQL is missing.'
}
else {
    $secretSocietiesSql = Get-Content -LiteralPath $secretSocietiesPath -Raw
    if ($secretSocietiesSql -notmatch '(?is)INSERT\s+OR\s+IGNORE\s+INTO\s+GovernorPromotionModifiers') {
        Add-ValidationError 'Secret Society title refunds are not inserted idempotently.'
    }
    if (-not $secretSocietiesSql.Contains('CIVIC_GRANT_PLAYER_GOVERNOR_POINTS')) {
        Add-ValidationError 'Secret Society promotions no longer refund a Governor Title.'
    }
    foreach ($secretSocietyPromotion in $secretSocietyPromotions) {
        $occurrences = ([regex]::Matches($secretSocietiesSql, "(?<![A-Z0-9_])$([regex]::Escape($secretSocietyPromotion))(?![A-Z0-9_])")).Count
        if ($occurrences -ne 1) {
            Add-ValidationError "Secret Society refund list must contain $secretSocietyPromotion exactly once; found $occurrences."
        }
    }

    $secretSocietyAction = $modInfo.SelectSingleNode('/Mod/InGameActions/UpdateDatabase[File="Components/BBG/sql/Secret_Societies.sql"]')
    if ($null -eq $secretSocietyAction -or
            $secretSocietyAction.SelectSingleNode("./File[.='Components/BBG/sql/Secret_Societies.sql']") -eq $null -or
            $secretSocietyAction.SelectSingleNode("./Criteria[.='ZYLPVP_BBG_Ethiopia']") -eq $null -or
            $secretSocietyAction.SelectSingleNode("./Criteria[.='ZYLPVP_BBG_XP2']") -eq $null -or
            $secretSocietyAction.SelectSingleNode("./Criteria[.='ZYL_SecretSocietiesXP2']") -eq $null) {
        Add-ValidationError 'BBG Secret Societies SQL is not gated by Ethiopia, Gathering Storm and the Secret Societies game mode.'
    }
}

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
}
foreach ($entry in $teamPvpSocietyPaths.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $entry.Value)) {
        Add-ValidationError "Team PVP Secret Societies $($entry.Key) resource is missing: $($entry.Value)"
    }
}

if (Test-Path -LiteralPath $teamPvpSocietyPaths.Dependency) {
    $teamPvpSocietyDep = Load-XmlDocument $teamPvpSocietyPaths.Dependency
    $teamPvpSocietyDepId = $teamPvpSocietyDep.SelectSingleNode('/*/ID/id')
    if ($null -eq $teamPvpSocietyDepId -or $teamPvpSocietyDepId.GetAttribute('text') -ne '8441e5c6-dae5-4fbc-b8d7-da3b9889df36') {
        Add-ValidationError 'Team PVP Secret Societies art dependency has an unexpected or missing ID.'
    }
    if ($null -eq $teamPvpSocietyDep.SelectSingleNode('/*/RequiredGameArtIDs/Element[name/@text="Ethiopia" and id/@text="50320198-92ec-444f-805c-1b6f81dfb918"]')) {
        Add-ValidationError 'Team PVP Secret Societies art dependency does not require the Ethiopia game-art package.'
    }
    if ($null -eq $teamPvpSocietyDep.SelectSingleNode('/*/ArtDefDependencies/Element[ArtDefPath/@text="Buildings.artdef"]')) {
        Add-ValidationError 'Team PVP Secret Societies .dep does not publish Buildings.artdef.'
    }
    foreach ($consumerName in @('Landmarks', 'StrategicView_Sprite')) {
        if ($null -eq $teamPvpSocietyDep.SelectSingleNode("/*/SystemDependencies/Element[ConsumerName/@text='$consumerName' and ArtDefDependencyPaths/Element/@text='Buildings.artdef']")) {
            Add-ValidationError "Team PVP Secret Societies .dep does not route Buildings.artdef to $consumerName."
        }
    }
}

if (Test-Path -LiteralPath $teamPvpSocietyPaths.Gameplay) {
    $teamPvpSocietySql = Get-Content -LiteralPath $teamPvpSocietyPaths.Gameplay -Raw
    $requiredSocietySqlTokens = @(
        'DiscoverAtCityStateBaseChance = 100000',
        'DiscoverAtGoodyHutBaseChance = 100000',
        "WHERE GovernorPromotionType = 'GOVERNOR_PROMOTION_SANGUINE_PACT_2'",
        "SET BaseMoves = 3",
        "('ROUTE_ANCIENT_ROAD', 'UNIT_VAMPIRE')",
        "('ROUTE_MEDIEVAL_ROAD', 'UNIT_VAMPIRE')",
        "('ROUTE_INDUSTRIAL_ROAD', 'UNIT_VAMPIRE')",
        "('ROUTE_MODERN_ROAD', 'UNIT_VAMPIRE')",
        "'SECRET_SOCIETIES_DISABLE_VAMPIRE_NORMAL_HEALING', 'Amount', -5",
        "'SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING', 'Amount', 50",
        "'SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING', 'Key', 'HEAL_ON_PILLAGE'",
        "'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT'",
        "'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT', 'Amount', 10",
        "'ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION', 'Amount', 50",
        "'ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION', 'Amount', 1",
        "'ZYL_TPVP_SANGUINE_STABLE_PRODUCTION', 'Amount', 1",
        "'ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION', 'Amount', 2",
        "'ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION', 'Amount', 4",
        "'ZYL_TPVP_SANGUINE_MILITARY_POLICY_SLOT', 'GovernmentSlotType', 'SLOT_MILITARY'",
        "('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING')",
        "('GOVERNOR_PROMOTION_SANGUINE_PACT_2', 'SECRET_SOCIETY_GRANT_TWO_VAMPIRE_BUILDS')",
        "('GOVERNOR_PROMOTION_SANGUINE_PACT_3', 'SECRET_SOCIETY_GRANT_ONE_VAMPIRE_BUILD')",
        "('GOVERNOR_PROMOTION_SANGUINE_PACT_4', 'SECRET_SOCIETY_GRANT_ONE_VAMPIRE_BUILD')",
        "SET EarliestGameEra = 'ERA_RENAISSANCE'",
        "SET EarliestGameEra = 'ERA_INDUSTRIAL'",
        "WHERE BuildingType = 'BUILDING_GILDED_VAULT'",
        "PurchaseYield = 'YIELD_GOLD'",
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
        "'UNIT_RETREAT_VAMPIRE_TO_CASTLE'",
        "'SECRET_SOCIETIES_ATTACH_PLAYER_CASTLES_GAIN_ADJACENT_YIELDS'",
        "'IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_FOOD', 9",
        "'IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_PRODUCTION', 5",
        "'RESOURCE_LEY_LINE', 'YIELD_GOLD', 40, NULL",
        "'IMPROVEMENT_FARM', 'RESOURCE_LEY_LINE', 0",
        "'BUILDING_GILDED_Shipyard', 'BBG_SHIPYARD_FISHERY_PRODUCTION'",
        "'ZYL_TPVP_MILITARYRESEARCH_GILDED_SHIPYARD_SCIENCE'",
        "'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION_ATTACH'",
        "'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD_ATTACH'",
        "'ZYL_TPVP_GILDED_SHIPYARD_ADJ_12'"
    )
    foreach ($token in $requiredSocietySqlTokens) {
        if (-not $teamPvpSocietySql.Contains($token)) {
            Add-ValidationError "Team PVP Secret Societies SQL is missing required behavior: $token"
        }
    }
    if ($teamPvpSocietySql -notmatch "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_1',\s*'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING'\)") {
        Add-ValidationError 'Sanguine Pact advanced pillaging is not attached to tier 1.'
    }
    if ($teamPvpSocietySql -match "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_3',\s*'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING'\)") {
        Add-ValidationError 'Sanguine Pact advanced pillaging must not remain attached to tier 3.'
    }
    if ($teamPvpSocietySql -notmatch "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_1',\s*'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT_ATTACH'\)") {
        Add-ValidationError 'Sanguine Pact combat-heal modifier is not attached to tier 1.'
    }
    if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT_ATTACH',\s*'MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER',\s*'THIS_UNIT_IS_A_VAMPIRE'\)") {
        Add-ValidationError 'Sanguine Pact combat healing is not restricted to Vampire units.'
    }
    if ($teamPvpSocietySql -notmatch "(?is)\('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT',\s*'MODIFIER_PLAYER_UNIT_ADJUST_HEAL_FROM_COMBAT',\s*NULL\)") {
        Add-ValidationError 'Sanguine Pact combat healing is not restricted to Vampire units.'
    }
    foreach ($sanguinePromotion in @(
        @{ Promotion = '1'; Modifier = 'ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION' },
        @{ Promotion = '1'; Modifier = 'ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION' },
        @{ Promotion = '1'; Modifier = 'ZYL_TPVP_SANGUINE_STABLE_PRODUCTION' },
        @{ Promotion = '2'; Modifier = 'ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION' },
        @{ Promotion = '2'; Modifier = 'ZYL_TPVP_SANGUINE_MILITARY_POLICY_SLOT' },
        @{ Promotion = '3'; Modifier = 'ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION' }
    )) {
        $sanguineBindingPattern = "(?is)\('GOVERNOR_PROMOTION_SANGUINE_PACT_$($sanguinePromotion.Promotion)',\s*'$([regex]::Escape($sanguinePromotion.Modifier))'\)"
        if ($teamPvpSocietySql -notmatch $sanguineBindingPattern) {
            Add-ValidationError "Sanguine Pact tier $($sanguinePromotion.Promotion) is missing $($sanguinePromotion.Modifier)."
        }
    }
    foreach ($buildingType in @('BUILDING_GILDED_VAULT', 'BUILDING_GILDED_Shipyard')) {
        $goldPurchasePattern = "(?is)UPDATE\s+Buildings\s+SET(?:(?!;).)*PurchaseYield\s*=\s*'YIELD_GOLD'(?:(?!;).)*WHERE\s+BuildingType\s*=\s*'$([regex]::Escape($buildingType))'\s*;"
        if ($teamPvpSocietySql -notmatch $goldPurchasePattern) {
            Add-ValidationError "$buildingType is not pinned to Gold purchasing in the final Team PVP gameplay layer."
        }
    }
    foreach ($outOfScopeToken in @(
        'TRAIT_LITHUANIANUNION_COMPLETE_RELIGION_RELIC_CPLMOD',
        'MESSENGER_GRANT_FREE_ENVOYS',
        'SIMULTANEUM_BUILDING_YIELDS_HIGH_ADJACENCY'
    )) {
        if ($teamPvpSocietySql.Contains($outOfScopeToken)) {
            Add-ValidationError "Unrelated upstream balance leaked into Secret Societies SQL: $outOfScopeToken"
        }
    }
    if ($teamPvpSocietySql.Contains('CIVIC_GRANT_PLAYER_GOVERNOR_POINTS')) {
        Add-ValidationError 'Secret Society title refunds are duplicated outside the BBG-owned integration file.'
    }
}

if (Test-Path -LiteralPath $teamPvpSocietyPaths.Building) {
    $gildedShipyard = Load-XmlDocument $teamPvpSocietyPaths.Building
    $gildedShipyardRow = $gildedShipyard.SelectSingleNode("/GameInfo/Buildings/Row[@BuildingType='BUILDING_GILDED_Shipyard']")
    if ($null -eq $gildedShipyardRow -or $gildedShipyardRow.GetAttribute('Cost') -ne '250') {
        Add-ValidationError 'The Team PVP Gilded Shipyard must exist at its effective 250 Production cost.'
    }
    if ($null -eq $gildedShipyardRow -or $gildedShipyardRow.GetAttribute('PurchaseYield') -ne 'YIELD_GOLD') {
        Add-ValidationError 'The Team PVP Gilded Shipyard must be purchasable with Gold.'
    }
    foreach ($yield in @{
        YIELD_FOOD = '1'
        YIELD_PRODUCTION = '1'
    }.GetEnumerator()) {
        $yieldRow = $gildedShipyard.SelectSingleNode("/GameInfo/Building_YieldChanges/Row[@BuildingType='BUILDING_GILDED_Shipyard' and @YieldType='$($yield.Key)']")
        if ($null -eq $yieldRow -or $yieldRow.GetAttribute('YieldChange') -ne $yield.Value) {
            Add-ValidationError "Gilded Shipyard base $($yield.Key) must be $($yield.Value)."
        }
    }
}

if (Test-Path -LiteralPath $teamPvpSocietyPaths.Text) {
    $teamPvpSocietyText = Load-XmlDocument $teamPvpSocietyPaths.Text
    foreach ($language in @('en_US', 'zh_Hans_CN', 'zh_Hant_HK')) {
        foreach ($tag in @(
            'LOC_BUILDING_GILDED_Shipyard_DESCRIPTION',
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
                Add-ValidationError "Team PVP Secret Societies localization is missing $tag for $language."
            }
        }
    }
    $sanguineTextChecks = @(
    [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'; Tokens = @('3 [ICON_Movement]', '10 HP', '50 HP', '1 [ICON_Movement]', '+50% [ICON_Production]') },
        [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'; Tokens = @('maximum of 2', '+2 [ICON_Production]', 'Military policy') },
        [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_3_DESCRIPTION'; Tokens = @('maximum to 3', '+4 [ICON_Production]') },
        [pscustomobject]@{ Language = 'en_US'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_4_DESCRIPTION'; Tokens = @('Industrial Era', 'maximum to 4') },
        [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'; Tokens = @('3 [ICON_Movement]', '10点生命值', '50点生命值', '1 [ICON_Movement]', '+50%') },
        [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'; Tokens = @('最多2座', '兵工厂+2', '军事政策槽位') },
        [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_3_DESCRIPTION'; Tokens = @('上限提高至3座', '军事学院+4') },
        [pscustomobject]@{ Language = 'zh_Hans_CN'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_4_DESCRIPTION'; Tokens = @('工业时代', '上限提高至4座') },
        [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_1_DESCRIPTION'; Tokens = @('3 [ICON_Movement]', '10生命', '50生命', '1 [ICON_Movement]', '+50%') },
        [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_2_DESCRIPTION'; Tokens = @('最多2座', '兵工廠+2', '軍事政策槽位') },
        [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_3_DESCRIPTION'; Tokens = @('上限提高至3座', '軍事學院+4') },
        [pscustomobject]@{ Language = 'zh_Hant_HK'; Tag = 'LOC_GOVERNOR_PROMOTION_SANGUINE_PACT_4_DESCRIPTION'; Tokens = @('工業時代', '上限提高至4座') }
    )
    foreach ($sanguineTextCheck in $sanguineTextChecks) {
        $sanguineTextNode = $teamPvpSocietyText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='$($sanguineTextCheck.Tag)' and @Language='$($sanguineTextCheck.Language)']/Text")
        if ($null -eq $sanguineTextNode) {
            Add-ValidationError "Sanguine Pact localization is missing $($sanguineTextCheck.Tag) for $($sanguineTextCheck.Language)."
        }
        else {
            foreach ($sanguineTextToken in $sanguineTextCheck.Tokens) {
                if (-not $sanguineTextNode.InnerText.Contains($sanguineTextToken)) {
                    Add-ValidationError "Sanguine Pact localization $($sanguineTextCheck.Tag) for $($sanguineTextCheck.Language) is missing: $sanguineTextToken"
                }
            }
        }
    }
    foreach ($entry in @{
        en_US = 'Fisheries'
        zh_Hans_CN = '渔场'
        zh_Hant_HK = '漁場'
    }.GetEnumerator()) {
        $gildedShipyardText = $teamPvpSocietyText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='LOC_BUILDING_GILDED_Shipyard_DESCRIPTION' and @Language='$($entry.Key)']/Text")
        if ($null -eq $gildedShipyardText -or -not $gildedShipyardText.InnerText.Contains($entry.Value)) {
            Add-ValidationError "Gilded Shipyard localization for $($entry.Key) does not mention its Fishery Production bonus."
        }
    }
}

$resourceHarvestPath = Join-Path $modRoot 'sql\ZYL_ResourceHarvests.sql'
if (-not (Test-Path -LiteralPath $resourceHarvestPath)) {
    Add-ValidationError 'LightweightBalance luxury/strategic resource harvest SQL is missing.'
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
            Add-ValidationError "Resource harvest SQL is missing required behavior: $token"
        }
    }
}

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
    Add-ValidationError 'BBG Expanded resource core SQL is missing.'
}
else {
    $expandedResourceCoreSql = Get-Content -LiteralPath $expandedResourceCorePath -Raw
    foreach ($resourceType in $expandedResourceTypes) {
        if (-not $expandedResourceCoreSql.Contains("('$resourceType'")) {
            Add-ValidationError "BBG Expanded resource core is missing $resourceType."
        }
    }
    foreach ($resourceTag in @(
        'CLASS_GODDESS_OF_FESTIVALS',
        'CLASS_ORAL_TRADITION',
        'CLASS_SCIENCE',
        'CLASS_PRODUCTION'
    )) {
        if (-not $expandedResourceCoreSql.Contains($resourceTag)) {
            Add-ValidationError "BBG Expanded resource core is missing Pantheon/yield tag $resourceTag."
        }
    }
}
if (-not (Test-Path -LiteralPath $expandedResourceBalancePath)) {
    Add-ValidationError 'BBG Expanded resource balance SQL is missing.'
}
else {
    $expandedResourceBalanceSql = Get-Content -LiteralPath $expandedResourceBalancePath -Raw
    foreach ($token in @(
        "('RESOURCE_P0K_PENGUINS', 'TERRAIN_COAST')",
        "('IMPROVEMENT_FISHING_BOATS', 'RESOURCE_P0K_PENGUINS', 1)",
        "('RESOURCE_P0K_PAPYRUS', 'YIELD_PRODUCTION', 1)"
    )) {
        if (-not $expandedResourceBalanceSql.Contains($token)) {
            Add-ValidationError "BBG Expanded resource balance is missing required behavior: $token"
        }
    }
}

$expandedResourceFiles = @(Get-ChildItem -LiteralPath $expandedResourceRoot -Recurse -File)
if ($expandedResourceFiles.Count -ne 325) {
    Add-ValidationError "BBG Expanded resource package must contain 324 upstream files plus its license; found $($expandedResourceFiles.Count)."
}
foreach ($resourceFile in $expandedResourceFiles) {
    $relativeResourceFile = $resourceFile.FullName.Substring($modRoot.Length + 1)
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $relativeResourceFile))) {
        Add-ValidationError "BBG Expanded resource asset is absent from the manifest: $relativeResourceFile"
    }
}

$resourceDepPath = Join-Path $expandedResourceRoot 'CIVITAS Resources.dep'
if (-not (Test-Path -LiteralPath $resourceDepPath)) {
    Add-ValidationError 'BBG Expanded resource art dependency is missing.'
}
else {
    $resourceDep = Load-XmlDocument $resourceDepPath
    $resourceArtDefs = @($resourceDep.SelectNodes('//*[local-name()="ArtDefPath" or local-name()="ArtDefDependencyPaths"]//Element') |
        ForEach-Object { $_.GetAttribute('text') } | Where-Object { $_ -like '*.artdef' } | Sort-Object -Unique)
    foreach ($resourceArtDef in $resourceArtDefs) {
        if (-not (Test-Path -LiteralPath (Join-Path $expandedResourceRoot (Join-Path 'ArtDefs' $resourceArtDef)))) {
            Add-ValidationError "BBG Expanded resource ArtDef is missing: $resourceArtDef"
        }
    }
    $resourcePackages = @($resourceDep.SelectNodes('//*[local-name()="PackageDependencies"]/Element') |
        ForEach-Object { $_.GetAttribute('text') } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    foreach ($platform in @('Windows', 'MacOS')) {
        foreach ($resourcePackage in $resourcePackages) {
            $resourcePackagePath = Join-Path $expandedResourceRoot ("Platforms\$platform\BLPs\$($resourcePackage.Replace('/', '\'))")
            if (-not (Test-Path -LiteralPath $resourcePackagePath)) {
                Add-ValidationError "BBG Expanded resource art package is missing: $resourcePackagePath"
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
    Add-ValidationError 'The external BBG Expanded hand-off criterion is missing.'
}
else {
    foreach ($expandedId in $externalExpandedIds) {
        $inverseNode = $noExternalExpandedCriterion.SelectSingleNode("./ModInUse[@inverse='1' and .='$expandedId']")
        if ($null -eq $inverseNode) {
            Add-ValidationError "The external BBG Expanded hand-off criterion is missing $expandedId."
        }
    }
}
$monopoliesCriterion = $criteriaMap['zyl_monopoliesmode']
if ($null -eq $monopoliesCriterion -or
        $null -eq $monopoliesCriterion.SelectSingleNode("./ConfigurationValueMatches[Group='Game' and ConfigurationId='GAMEMODE_MONOPOLIES' and Value='1']")) {
    Add-ValidationError 'BBG Expanded corporation content is not gated by the Monopolies mode.'
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
        Add-ValidationError "BBG Expanded resource action is missing or not hand-off gated: $($entry.Key)"
        continue
    }
    foreach ($expectedFile in $entry.Value) {
        if ($null -eq $action.SelectSingleNode("./File[.='$expectedFile']")) {
            Add-ValidationError "BBG Expanded resource action $($entry.Key) is missing $expectedFile."
        }
    }
    if ($entry.Key -like 'zyl_bbgexpandedresourcesmode*' -and
            $null -eq $action.SelectSingleNode("./Criteria[.='ZYL_MonopoliesMode']")) {
        Add-ValidationError "BBG Expanded company-mode action is not mode-gated: $($entry.Key)"
    }
}

# The upstream resource localizers generate English BaseGameText rows at
# runtime, so XML-only audits cannot see their Chinese counterparts.  Keep the
# final LocalizedText SQL active and verify every generated tag family.
if (-not (Test-Path -LiteralPath $bbgExpandedChinesePath)) {
    Add-ValidationError 'The BBG Expanded Simplified Chinese dynamic-text layer is missing.'
}
else {
    $expandedChineseSql = Get-Content -LiteralPath $bbgExpandedChinesePath -Raw
    if ($expandedChineseSql -notmatch '(?is)INSERT\s+OR\s+REPLACE\s+INTO\s+LocalizedText\s*\(\s*Language\s*,\s*Tag\s*,\s*Text\s*\)') {
        Add-ValidationError 'BBG Expanded Chinese SQL does not insert into LocalizedText(Language, Tag, Text).'
    }
    if ($expandedChineseSql.Contains('TO_TRANSLATE') -or $expandedChineseSql.Contains('???')) {
        Add-ValidationError 'BBG Expanded Chinese SQL contains an untranslated placeholder.'
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
            Add-ValidationError "BBG Expanded dynamic Simplified Chinese Tag is missing: $tag"
        }
    }

    $expandedChineseAction = $actionIdMap['zyl_bbgexpandedchinesetext']
    if ($null -eq $expandedChineseAction -or
            $expandedChineseAction.LocalName -ne 'UpdateText' -or
            $null -eq $expandedChineseAction.SelectSingleNode("./File[.='lang/ZYL_BBGExpanded_Chinese.sql']") -or
            $expandedChineseAction.SelectSingleNode('./Properties/LoadOrder').InnerText.Trim() -ne '259999995') {
        Add-ValidationError 'BBG Expanded Chinese SQL is not loaded as the final dynamic resource-text action.'
    }
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'lang/ZYL_BBGExpanded_Chinese.sql'))) {
        Add-ValidationError 'BBG Expanded Chinese SQL is absent from the ModInfo <Files> manifest.'
    }
}

$standaloneResourcesBlock = $modInfo.SelectSingleNode("/Mod/Blocks/Mod[@id='664d17a5-f3be-493a-9332-8e20da1166fa']")
if ($null -eq $standaloneResourcesBlock) {
    Add-ValidationError 'Standalone CIVITAS Resources Expanded is not blocked after being embedded.'
}

$secretSocietyCriterion = $criteriaMap['zyl_secretsocietiesxp2']
if ($null -eq $secretSocietyCriterion -or
        $secretSocietyCriterion.SelectSingleNode("./RuleSetInUse[.='RULESET_EXPANSION_2']") -eq $null -or
        $secretSocietyCriterion.SelectSingleNode("./ModInUse[.='1B394FE9-23DC-4868-8F0A-5220CB8FB427']") -eq $null -or
        $secretSocietyCriterion.SelectSingleNode("./ConfigurationValueMatches[ConfigurationId='GAMEMODE_SECRETSOCIETIES' and Value='1']") -eq $null) {
    Add-ValidationError 'Team PVP society integration is not gated by Gathering Storm, Ethiopia and the Secret Societies game mode.'
}

$expectedTeamPvpActions = @{
    'zyl_resourceharvests' = 'sql/ZYL_ResourceHarvests.sql'
    'zyl_tpvp_secretsocietiesart' = 'Components/TeamPVPSecretSocieties/TeamPVPSecretSocieties.dep'
    'zyl_tpvp_gildedshipyard' = 'Components/TeamPVPSecretSocieties/Build_GildedShipyard.xml'
    'zyl_tpvp_secretsocietiesgameplay' = 'Components/TeamPVPSecretSocieties/Gameplay.sql'
    'zyl_tpvp_secretsocietiestext' = 'Components/TeamPVPSecretSocieties/Text.xml'
    'zyl_tpvp_secretsocietiesicons' = 'Components/TeamPVPSecretSocieties/Icons.xml'
}
foreach ($entry in $expectedTeamPvpActions.GetEnumerator()) {
    $action = $actionIdMap[$entry.Key]
    if ($null -eq $action -or $action.SelectSingleNode("./File[.='$($entry.Value)']") -eq $null) {
        Add-ValidationError "Required Team PVP/LightweightBalance action is missing: $($entry.Key)"
    }
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $entry.Value))) {
        Add-ValidationError "Required Team PVP/LightweightBalance file is absent from the manifest: $($entry.Value)"
    }
}

$teamPvpArtAction = $actionIdMap['zyl_tpvp_secretsocietiesart']
if ($null -eq $teamPvpArtAction -or
        $teamPvpArtAction.LocalName -ne 'UpdateArt' -or
        $teamPvpArtAction.ParentNode.LocalName -ne 'InGameActions' -or
        $null -eq $teamPvpArtAction.SelectSingleNode("./Criteria[.='ZYL_SecretSocietiesXP2']")) {
    Add-ValidationError 'Team PVP Secret Societies art is not loaded in-game through its mode-gated .dep manifest.'
}
$teamPvpArtDefRelativePath = Normalize-RelativePath 'Components/TeamPVPSecretSocieties/Buildings.artdef'
if (-not $listedFileMap.ContainsKey($teamPvpArtDefRelativePath)) {
    Add-ValidationError 'Team PVP Secret Societies Buildings.artdef is absent from the manifest.'
}

$assemblerPath = Join-Path $modRoot 'tools\assemble_modinfo.ps1'
if (Test-Path -LiteralPath $assemblerPath) {
    $assembler = Get-Content -LiteralPath $assemblerPath -Raw
    foreach ($token in @(
        "'ZYL_ResourceHarvests' 'sql/ZYL_ResourceHarvests.sql'",
        "'ZYL_TPVP_GildedShipyard' 'Components/TeamPVPSecretSocieties/Build_GildedShipyard.xml'",
        "'ZYL_TPVP_SecretSocietiesGameplay' 'Components/TeamPVPSecretSocieties/Gameplay.sql'",
        "'ZYL_TPVP_SecretSocietiesArt' 'Components/TeamPVPSecretSocieties/TeamPVPSecretSocieties.dep'",
        "'Components/TeamPVPSecretSocieties/Buildings.artdef'"
    )) {
        if (-not $assembler.Contains($token)) {
            Add-ValidationError "ModInfo assembler would discard a Team PVP/LightweightBalance integration entry: $token"
        }
    }
}

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
        Add-ValidationError "Selected pantheon/geothermal resource is missing: $requiredPantheonFile"
    }
}
if (Test-Path -LiteralPath $selectedPantheonPath) {
    $selectedPantheonSql = Get-Content -LiteralPath $selectedPantheonPath -Raw
    foreach ($pantheonId in $expectedPantheonIds) {
        if (-not $selectedPantheonSql.Contains("('$pantheonId', 'KIND_BELIEF')")) {
            Add-ValidationError "Selected pantheon is not registered: $pantheonId"
        }
    }
    foreach ($pantheonId in $excludedPantheonIds) {
        if ($selectedPantheonSql.Contains($pantheonId)) {
            Add-ValidationError "Unselected Lightweight Balance pantheon was included: $pantheonId"
        }
    }
    if ($selectedPantheonSql -notmatch "(?s)'ZYL_LBM_PATH_OF_CONQUEST_ENCAMPMENT_CULTURE_MODIFIER'.*?'Amount',\s*1") {
        Add-ValidationError 'Path of Conquest Culture is not set to the requested +1.'
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
            Add-ValidationError "Selected pantheon SQL is missing required behavior: $requiredPantheonToken"
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
                    Add-ValidationError "Selected pantheon localization is missing: $tag / $language"
                }
            }
        }
    }
}
if (Test-Path -LiteralPath $selectedPantheonIconPath) {
    $selectedPantheonIcons = Load-XmlDocument $selectedPantheonIconPath
    foreach ($pantheonId in $expectedPantheonIds) {
        if ($null -eq $selectedPantheonIcons.SelectSingleNode("/GameData/IconDefinitions/Row[@Name='ICON_$pantheonId']")) {
            Add-ValidationError "Selected pantheon icon is missing: ICON_$pantheonId"
        }
    }
}
if (Test-Path -LiteralPath $geothermalMinePath) {
    $geothermalMineSql = Get-Content -LiteralPath $geothermalMinePath -Raw
    foreach ($geothermalToken in @('Improvement_ValidFeatures', 'IMPROVEMENT_MINE', 'FEATURE_GEOTHERMAL_FISSURE', 'TECH_MINING')) {
        if (-not $geothermalMineSql.Contains($geothermalToken)) {
            Add-ValidationError "Geothermal Mine SQL is missing required behavior: $geothermalToken"
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
        Add-ValidationError "Selected pantheon/geothermal action is missing: $($entry.Key)"
    }
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath $entry.Value))) {
        Add-ValidationError "Selected pantheon/geothermal file is absent from the manifest: $($entry.Value)"
    }
}
$geothermalMineAction = $actionIdMap['zyl_geothermalmines']
if ($null -eq $geothermalMineAction -or $null -eq $geothermalMineAction.SelectSingleNode("./Criteria[.='ZYL_GatheringStorm']")) {
    Add-ValidationError 'Geothermal Mine action is not limited to Gathering Storm.'
}
$gatheringStormCriterion = $criteriaMap['zyl_gatheringstorm']
if ($null -eq $gatheringStormCriterion -or
        $null -eq $gatheringStormCriterion.SelectSingleNode("RuleSetInUse[.='RULESET_EXPANSION_2']")) {
    Add-ValidationError 'Gathering Storm criterion for Geothermal Mines is missing or incorrect.'
}
$lightweightBalanceBlock = $modInfo.SelectSingleNode("/Mod/Blocks/Mod[@id='41493218-3632-421b-a1a3-367f7c7ba610']")
if ($null -eq $lightweightBalanceBlock) {
    Add-ValidationError 'Standalone ZYL Lightweight Balance is not blocked after selected features were integrated.'
}

$assemblerPath = Join-Path $modRoot 'tools\assemble_modinfo.ps1'
if (Test-Path -LiteralPath $assemblerPath) {
    $assembler = Get-Content -LiteralPath $assemblerPath -Raw
    foreach ($token in @(
        "'ZYL_SelectedPantheons' 'sql/ZYL_Pantheons.sql'",
        "'ZYL_SelectedPantheonsText' 'lang/ZYL_Pantheons_Text.xml'",
        "'ZYL_SelectedPantheonsIcons' 'icons/ZYL_Pantheon_Icons.xml'",
        "'ZYL_GeothermalMines' 'sql/ZYL_GeothermalMines.sql'",
        "'icons/ZYL_Pantheon_Icons.xml'"
    )) {
        if (-not $assembler.Contains($token)) {
            Add-ValidationError "ModInfo assembler would discard a selected pantheon/geothermal entry: $token"
        }
    }
}

# The initial Settler movement package must remain limited to the period before
# the first Palace exists. It intentionally includes all four parts of the
# LightweightBalance behavior: +1 movement, terrain, river and shore handling.
$startingSettlerPath = Join-Path $modRoot 'sql\ZYL_StartingSettler.sql'
$startingSettlerModifierIds = @(
    'ZYL_STARTING_SETTLER_MOVEMENT',
    'ZYL_STARTING_SETTLER_IGNORE_TERRAIN',
    'ZYL_STARTING_SETTLER_IGNORE_RIVERS',
    'ZYL_STARTING_SETTLER_IGNORE_SHORES'
)
if (-not (Test-Path -LiteralPath $startingSettlerPath)) {
    Add-ValidationError 'Initial Settler movement SQL is missing.'
}
else {
    $startingSettlerSql = Get-Content -LiteralPath $startingSettlerPath -Raw
    foreach ($startingSettlerModifierId in $startingSettlerModifierIds) {
        if (-not $startingSettlerSql.Contains("'TRAIT_LEADER_MAJOR_CIV', '$startingSettlerModifierId'")) {
            Add-ValidationError "Initial Settler modifier is not attached to major civilizations: $startingSettlerModifierId"
        }
    }
    foreach ($requiredStartingSettlerToken in @(
        'EFFECT_ADJUST_UNIT_IGNORE_TERRAIN_COST',
        'MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT',
        'MODIFIER_PLAYER_UNITS_ADJUST_IGNORE_RIVERS',
        'MODIFIER_PLAYER_UNITS_ADJUST_IGNORE_SHORES',
        'REQUIREMENT_UNIT_TYPE_MATCHES',
        'UNIT_SETTLER',
        'REQUIREMENT_PLAYER_HAS_AT_LEAST_NUM_BUILDINGS',
        'BUILDING_PALACE'
    )) {
        if (-not $startingSettlerSql.Contains($requiredStartingSettlerToken)) {
            Add-ValidationError "Initial Settler SQL is missing required behavior: $requiredStartingSettlerToken"
        }
    }
    if ($startingSettlerSql -notmatch "(?s)'ZYL_REQUIRES_PLAYER_HAS_NO_PALACE',\s*'REQUIREMENT_PLAYER_HAS_AT_LEAST_NUM_BUILDINGS',\s*1") {
        Add-ValidationError 'Initial Settler Palace requirement is not inverted; the bonus would affect later Settlers.'
    }

    $startingSettlerAction = $actionIdMap['zyl_startingsettlermovement']
    if ($null -eq $startingSettlerAction -or
            $startingSettlerAction.SelectSingleNode("./File[.='sql/ZYL_StartingSettler.sql']") -eq $null) {
        Add-ValidationError 'Initial Settler SQL is not loaded by ModInfo.'
    }
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'sql/ZYL_StartingSettler.sql'))) {
        Add-ValidationError 'Initial Settler SQL is absent from the ModInfo file manifest.'
    }

    $assemblerPath = Join-Path $modRoot 'tools\assemble_modinfo.ps1'
    if (Test-Path -LiteralPath $assemblerPath) {
        $assembler = Get-Content -LiteralPath $assemblerPath -Raw
        if (-not $assembler.Contains("'ZYL_StartingSettlerMovement' 'sql/ZYL_StartingSettler.sql'")) {
            Add-ValidationError 'ModInfo assembler would discard the initial Settler action.'
        }
        if (-not $assembler.Contains("'sql/ZYL_StartingSettler.sql'")) {
            Add-ValidationError 'ModInfo assembler would discard the initial Settler file manifest entry.'
        }
    }
}

$zylTextPath = Join-Path $modRoot 'lang\ZYL_Text.xml'
if (Test-Path -LiteralPath $zylTextPath) {
    $zylText = Load-XmlDocument $zylTextPath
    foreach ($language in @('en_US', 'zh_Hans_CN', 'zh_Hant_HK')) {
        $settlerText = $zylText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='LOC_UNIT_SETTLER_DESCRIPTION' and @Language='$language']/Text")
        if ($null -eq $settlerText -or -not $settlerText.InnerText.Contains('+1 [ICON_Movement]')) {
            Add-ValidationError "Initial Settler description is missing for $language."
        }
    }
}

# Coastal/inland leader variants must remain exact aliases of their source
# leaders.  Their only runtime distinction belongs in the map-placement Lua.
$leaderVariantRoot = Join-Path $modRoot 'LeaderVariants'
$leaderGameplayPath = Join-Path $leaderVariantRoot 'ZYL_CoastLeaderVariants_Gameplay.sql'
$leaderConfigPath = Join-Path $leaderVariantRoot 'ZYL_CoastLeaderVariants_Config.sql'
$leaderTextPath = Join-Path $leaderVariantRoot 'ZYL_CoastLeaderVariants_Text.sql'
$leaderIconPath = Join-Path $leaderVariantRoot 'ZYL_CoastLeaderVariants_Icons.sql'
$leaderColorPath = Join-Path $leaderVariantRoot 'ZYL_CoastLeaderVariants_Colors.sql'
$leaderVariantPaths = @(
    $leaderGameplayPath,
    $leaderConfigPath,
    $leaderTextPath,
    $leaderIconPath,
    $leaderColorPath
)
foreach ($leaderVariantPath in $leaderVariantPaths) {
    if (-not (Test-Path -LiteralPath $leaderVariantPath)) {
        Add-ValidationError "Leader variant resource is missing: $leaderVariantPath"
    }
}

if (($leaderVariantPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0) {
    $leaderGameplaySql = Get-Content -LiteralPath $leaderGameplayPath -Raw
    $leaderConfigSql = Get-Content -LiteralPath $leaderConfigPath -Raw
    $leaderTextSql = Get-Content -LiteralPath $leaderTextPath -Raw
    $leaderIconSql = Get-Content -LiteralPath $leaderIconPath -Raw
    $leaderColorSql = Get-Content -LiteralPath $leaderColorPath -Raw
    $leaderVariants = @(
        @{ Source = 'LEADER_HOJO'; Variant = 'LEADER_HOJO_INLAND' },
        @{ Source = 'LEADER_PHILIP_II'; Variant = 'LEADER_PHILIP_II_INLAND' },
        @{ Source = 'LEADER_WILHELMINA'; Variant = 'LEADER_WILHELMINA_INLAND' }
    )

    foreach ($leaderVariant in $leaderVariants) {
        $sourceLeader = $leaderVariant.Source
        $inlandLeader = $leaderVariant.Variant
        if ($leaderGameplaySql -notmatch "(?s)INSERT OR IGNORE INTO Types.*?'$([regex]::Escape($inlandLeader))'.*?'KIND_LEADER'") {
            Add-ValidationError "Gameplay SQL does not register $inlandLeader as a leader type."
        }
        if (-not $leaderGameplaySql.Contains("SELECT '$inlandLeader', TraitType") -or
                -not $leaderGameplaySql.Contains("FROM LeaderTraits WHERE LeaderType = '$sourceLeader';")) {
            Add-ValidationError "$inlandLeader no longer clones the final traits of $sourceLeader."
        }
        $gameplayDuplicatePattern = "\(\s*'$([regex]::Escape($sourceLeader))'\s*,\s*'$([regex]::Escape($inlandLeader))'\s*\)"
        if ($leaderGameplaySql -notmatch $gameplayDuplicatePattern) {
            Add-ValidationError "$sourceLeader and $inlandLeader are not gameplay duplicate leaders."
        }
        if (-not $leaderConfigSql.Contains("SELECT Domain, CivilizationType, '$inlandLeader',")) {
            Add-ValidationError "Config SQL does not clone lobby rows for $inlandLeader."
        }
        if (-not $leaderConfigSql.Contains("SELECT Map, '$inlandLeader'") -or
                -not $leaderConfigSql.Contains("source.Type, '$inlandLeader'")) {
            Add-ValidationError "Config SQL does not preserve true-start-map support for $inlandLeader."
        }
        if (-not $leaderConfigSql.Contains("AND d.OtherLeaderType = '$inlandLeader'")) {
            Add-ValidationError "Config duplicate-leader insertion for $inlandLeader is not idempotent."
        }
        if (-not $leaderTextSql.Contains("instr(Tag, '$inlandLeader') = 0")) {
            Add-ValidationError "Localization cloning for $inlandLeader can recursively clone itself."
        }
        $coastalLeader = $inlandLeader.Replace('_INLAND', '_COASTAL')
        if (-not $leaderTextSql.Contains("instr(Tag, '$coastalLeader') = 0")) {
            Add-ValidationError "Localization cloning for $inlandLeader can recursively clone its coastal label."
        }
        if (-not $leaderIconSql.Contains("'ICON_$inlandLeader'")) {
            Add-ValidationError "Icon alias is missing for $inlandLeader."
        }
        if (-not $leaderColorSql.Contains("SELECT '$inlandLeader', Usage")) {
            Add-ValidationError "Player-color alias is missing for $inlandLeader."
        }
    }

    if ($leaderTextSql -match '_INLAND_INLAND|_INLAND_COASTAL') {
        Add-ValidationError 'Recursive inland localization tags are present in leader variant SQL.'
    }
}

$leaderArtPaths = @(
    (Join-Path $modRoot 'ArtDefs\ZYL_CoastLeaderVariants_Leaders.artdef'),
    (Join-Path $modRoot 'ArtDefs\ZYL_CoastLeaderVariants_FallbackLeaders.artdef')
)
foreach ($leaderArtPath in $leaderArtPaths) {
    if (-not (Test-Path -LiteralPath $leaderArtPath)) {
        Add-ValidationError "Leader variant ArtDef is missing: $leaderArtPath"
        continue
    }
    $leaderArt = Load-XmlDocument $leaderArtPath
    foreach ($inlandLeader in @('LEADER_HOJO_INLAND', 'LEADER_PHILIP_II_INLAND', 'LEADER_WILHELMINA_INLAND')) {
        if ($null -eq $leaderArt.SelectSingleNode("//*[@text='$inlandLeader']")) {
            Add-ValidationError "$inlandLeader is missing from $([System.IO.Path]::GetFileName($leaderArtPath))."
        }
    }
}

foreach ($actionId in @(
    'ZYL_CoastLeaderVariants_Config',
    'ZYL_CoastLeaderVariants_ConfigText',
    'ZYL_CoastLeaderVariants_ConfigIcons',
    'ZYL_CoastLeaderVariants_ConfigColors',
    'ZYL_CoastLeaderVariants_Gameplay',
    'ZYL_CoastLeaderVariants_GameplayText',
    'ZYL_CoastLeaderVariants_GameplayIcons',
    'ZYL_CoastLeaderVariants_GameplayColors'
)) {
    if (-not $actionIdMap.ContainsKey($actionId.ToLowerInvariant())) {
        Add-ValidationError "Leader variant ModInfo action is missing: $actionId"
    }
}

$coastBiasLuaPaths = @(
    (Join-Path $modRoot 'Components\BBM\Data\BBS Maps\Utility\BBM_CivilizationAssign.lua'),
    (Join-Path $modRoot 'Components\BBM\Data\BBS Maps\Utility\ZYL_RVC_AssignStartingPlots.lua')
)
foreach ($coastBiasLuaPath in $coastBiasLuaPaths) {
    if (-not (Test-Path -LiteralPath $coastBiasLuaPath)) {
        Add-ValidationError "Coast-bias placement script is missing: $coastBiasLuaPath"
        continue
    }
    $coastBiasLua = Get-Content -LiteralPath $coastBiasLuaPath -Raw
    foreach ($inlandLeader in @('LEADER_HOJO_INLAND', 'LEADER_PHILIP_II_INLAND', 'LEADER_WILHELMINA_INLAND')) {
        if (-not $coastBiasLua.Contains($inlandLeader)) {
            Add-ValidationError "$inlandLeader is not recognized by $([System.IO.Path]::GetFileName($coastBiasLuaPath))."
        }
    }
    if (-not $coastBiasLua.Contains('row.TerrainType ~= "TERRAIN_COAST"')) {
        Add-ValidationError "$([System.IO.Path]::GetFileName($coastBiasLuaPath)) does not filter coast in the Firaxis fallback pass."
    }
}
if (Test-Path -LiteralPath $coastBiasLuaPaths[0]) {
    $bbmCoastBiasLua = Get-Content -LiteralPath $coastBiasLuaPaths[0] -Raw
    if (-not $bbmCoastBiasLua.Contains('and row.TerrainType == "TERRAIN_COAST"')) {
        Add-ValidationError 'BBM placement does not remove the coast row from inland variants.'
    }
}
if (Test-Path -LiteralPath $coastBiasLuaPaths[1]) {
    $richMapCoastBiasLua = Get-Content -LiteralPath $coastBiasLuaPaths[1] -Raw
    if (-not $richMapCoastBiasLua.Contains('and not ZYL_IsInlandCoastVariantPlayer(playerID)') -or
            -not $richMapCoastBiasLua.Contains('and not ZYL_IsInlandCoastVariant(civ.LeaderType)')) {
        Add-ValidationError 'Rich Mainland coast/inland distribution categories ignore the leader variant choice.'
    }
}

foreach ($coastBiasLuaPath in $coastBiasLuaPaths) {
    if (-not (Test-Path -LiteralPath $coastBiasLuaPath)) { continue }
    $coastBiasLua = Get-Content -LiteralPath $coastBiasLuaPath -Raw
    foreach ($obsoleteToken in @(
        'ZYL_MAGNIFICENCE_LUXURY_BIAS_TIER',
        'ZYL_FilterMagnificenceLuxuryStarts',
        'g_ZYL_MagnificenceLuxuryBiasPatchInstalled'
    )) {
        if ($coastBiasLua.Contains($obsoleteToken)) {
            Add-ValidationError "Obsolete leader-only France Luxury bias remains in $([System.IO.Path]::GetFileName($coastBiasLuaPath)): $obsoleteToken"
        }
    }
}

# Multiple actions from one component may form an intentional include chain,
# but two integrated components must never own the same Lua context.
$contextOwners = @{}
foreach ($actionNode in @($actionNodes | Where-Object { $_.LocalName -eq 'ReplaceUIScript' })) {
    $contextNode = $actionNode.SelectSingleNode('./Properties/LuaContext')
    $replaceNode = $actionNode.SelectSingleNode('./Properties/LuaReplace')
    if ($null -eq $contextNode -or $null -eq $replaceNode) {
        Add-ValidationError "Incomplete ReplaceUIScript action: $($actionNode.GetAttribute('id'))"
        continue
    }
    $replacePath = $replaceNode.InnerText.Trim().Replace('\', '/')
    $owner = 'Toolbox'
    if ($replacePath.StartsWith('Components/BBG/', [System.StringComparison]::OrdinalIgnoreCase)) { $owner = 'BBG' }
    elseif ($replacePath.StartsWith('Components/BBM/', [System.StringComparison]::OrdinalIgnoreCase)) { $owner = 'BBM' }
    $contextKey = $contextNode.InnerText.Trim().ToLowerInvariant()
    if (-not $contextOwners.ContainsKey($contextKey)) {
        $contextOwners[$contextKey] = [System.Collections.Generic.List[string]]::new()
    }
    if (-not $contextOwners[$contextKey].Contains($owner)) {
        $contextOwners[$contextKey].Add($owner)
    }
}
foreach ($contextKey in $contextOwners.Keys) {
    if ($contextOwners[$contextKey].Count -gt 1) {
        Add-ValidationError "LuaReplace context has cross-component owners: $contextKey => $($contextOwners[$contextKey] -join ', ')"
    }
}

# MPH owns the complete EndGameMenu XML; BBG supplies only its Lua extension.
$mphEndGame = Normalize-RelativePath 'ui/Replacements/endgamemenu.xml'
$bbgEndGameXml = Normalize-RelativePath 'Components/BBG/ui/replacements/endgamemenu.xml'
$bbgEndGameLua = Normalize-RelativePath 'Components/BBG/ui/replacements/endgamemenu_bbg.lua'
if (-not $listedFileMap.ContainsKey($mphEndGame)) { Add-ValidationError 'MPH EndGameMenu XML is not published.' }
if ($listedFileMap.ContainsKey($bbgEndGameXml)) { Add-ValidationError 'BBG duplicate EndGameMenu XML is still published.' }
if ($actionReferenceMap.ContainsKey($bbgEndGameXml)) { Add-ValidationError 'BBG duplicate EndGameMenu XML is still loaded.' }
if (-not $actionReferenceMap.ContainsKey($bbgEndGameLua)) { Add-ValidationError 'BBG EndGameMenu Lua extension is not loaded.' }

# Confirm BBM art is rooted where NaturalWondersMod.dep expects it.
$artAction = @($actionNodes | Where-Object {
    $_.LocalName -eq 'UpdateArt' -and $_.SelectSingleNode('.//File').InnerText -ieq 'NaturalWondersMod.dep'
})
if ($artAction.Count -ne 1) {
    Add-ValidationError "Expected exactly one root NaturalWondersMod.dep UpdateArt action; found $($artAction.Count)."
}
$depPath = Join-Path $modRoot 'NaturalWondersMod.dep'
if (Test-Path -LiteralPath $depPath) {
    $dep = Load-XmlDocument $depPath
    $artDefNames = @($dep.SelectNodes('//*[local-name()="ArtDefPath" or local-name()="ArtDefDependencyPaths"]//Element') |
        ForEach-Object { $_.GetAttribute('text') } |
        Where-Object { $_ -like '*.artdef' } |
        Sort-Object -Unique)
    foreach ($artDefName in $artDefNames) {
        if (-not (Test-Path -LiteralPath (Join-Path $modRoot (Join-Path 'ArtDefs' $artDefName)))) {
            Add-ValidationError "BBM art definition dependency missing: ArtDefs\$artDefName"
        }
    }
    $packageNames = @($dep.SelectNodes('//*[local-name()="PackageDependencies"]/Element') |
        ForEach-Object { $_.GetAttribute('text') } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique)
    foreach ($platform in @('Windows', 'MacOS')) {
        foreach ($packageName in $packageNames) {
            $packagePath = Join-Path $modRoot ("Platforms\$platform\BLPs\$($packageName.Replace('/', '\'))")
            if (-not (Test-Path -LiteralPath $packagePath)) {
                Add-ValidationError "BBM art package dependency missing: $packagePath"
            }
        }
    }
}

# Guard the broken references removed from the two upstream ModInfos.
$removedReferences = @(
    'Components\BBG\sql\DLC_Indonesia_Khmer\_dlc_indo_khmer_utils.sql',
    'Components\BBG\sql\DLC_Indonesia_Khmer\Other.sql',
    'Components\BBG\sql\LP\lp_arabia_saladin_sultan.sql',
    'Components\BBM\Data\BBS_D.lua',
    'Components\BBM\Data\BBS Maps\Utility\BBS_Balance.lua'
)
foreach ($removedReference in $removedReferences) {
    $key = Normalize-RelativePath $removedReference
    if ($listedFileMap.ContainsKey($key) -or $actionReferenceMap.ContainsKey($key)) {
        Add-ValidationError "Removed upstream reference returned: $removedReference"
    }
}

# Better Deal Window and Detailed Map Tacks are merged through one final owner
# per UI context. This guards against accidentally restoring their upstream
# replacement actions or the old, previously inert MPH deal-view file.
$integratedUiContexts = @{
    'diplomacydealview' = 'Components\BetterDealWindow\DiplomacyDealView_ZYLPVP_Expansion2.lua'
	'diplomacyribbon' = 'ui\Replacements\DiplomacyRibbon_ZYL.lua'
    'mappinmanager' = 'Components\DetailedMapTacks\ui\mappinmanager_dmt.lua'
    'mappinpopup' = 'Components\DetailedMapTacks\ui\mappinpopup_dmt.lua'
}
foreach ($entry in $integratedUiContexts.GetEnumerator()) {
    $matches = @($actionNodes | Where-Object {
        $_.LocalName -eq 'ReplaceUIScript' -and
        $_.SelectSingleNode('./Properties/LuaContext').InnerText.Trim().ToLowerInvariant() -eq $entry.Key
    })
    if ($matches.Count -ne 1) {
        Add-ValidationError "Expected exactly one $($entry.Key) replacement; found $($matches.Count)."
        continue
    }
    $actualPath = Normalize-RelativePath $matches[0].SelectSingleNode('./Properties/LuaReplace').InnerText
    if ($actualPath -ne (Normalize-RelativePath $entry.Value)) {
        Add-ValidationError "Unexpected $($entry.Key) replacement: $actualPath"
    }
}

foreach ($blockedId in @(
    'fbb7b86a-9ac9-4a8e-9439-9ded6aceda0e',
    '4ecfcc62-5471-4435-b295-590df213e8d8',
    '8d4fa23a-ef43-440c-8422-2bec11f8f5d7'
)) {
    if ($null -eq $modInfo.SelectSingleNode("/Mod/Blocks/Mod[@id='$blockedId']")) {
        Add-ValidationError "Integrated external UI Mod ID is not blocked: $blockedId"
    }
}

$requiredIntegratedUiFiles = @(
	'ui\Replacements\DiplomacyRibbon.xml',
	'ui\Replacements\DiplomacyRibbon_ZYL.lua',
    'Components\BetterDealWindow\DiplomacyDealView.lua',
    'Components\BetterDealWindow\DiplomacyDealView.xml',
    'Components\BetterDealWindow\DiplomacyDealView_Expansion2.lua',
    'Components\BetterDealWindow\DiplomacyDealView_ZYLPVP_Expansion2.lua',
    'Components\BetterDealWindow\ZYLPVP_BDW_MPH_Compatibility.lua',
    'Components\DetailedMapTacks\ui\dmt_yieldcalculator.lua',
    'Components\DetailedMapTacks\ui\dmt_yieldcalculator.xml',
    'Components\DetailedMapTacks\ui\mappinmanager.xml',
    'Components\DetailedMapTacks\ui\mappinmanager_dmt.lua',
    'Components\DetailedMapTacks\ui\mappinpopup_dmt.lua'
)
foreach ($requiredFile in $requiredIntegratedUiFiles) {
    $key = Normalize-RelativePath $requiredFile
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot $requiredFile))) {
        Add-ValidationError "Integrated UI file is missing: $requiredFile"
    }
    elseif (-not $listedFileMap.ContainsKey($key) -or -not $actionReferenceMap.ContainsKey($key)) {
        Add-ValidationError "Integrated UI file is not both published and active: $requiredFile"
    }
}

# Team PVP Tools Better Trade Screen Lite owns the complete trade UI chain.
# Keep its configuration, sort controls and BBG yield-display compatibility
# together, and prevent the old BBG TradeSupport/TradeOverview chain from
# silently returning during a future ModInfo regeneration.
$betterTradeScreenFiles = @(
    'BTS\Settings\BTS_Settings.sql',
    'BTS\Settings\BTS_SettingsPanel.lua',
    'BTS\Settings\BTS_SettingsPanel.xml',
    'BTS\Settings\BTS_SettingsSchema.sql',
    'BTS\Text\BTS_Text_EN.xml',
    'BTS\Text\BTS_Text_Hans_CN.xml',
    'BTS\UI\BTS_Serialize.lua',
    'BTS\UI\TradeOverview.lua',
    'BTS\UI\TradeOverview.xml',
    'BTS\UI\TradeSupport.lua',
    'BTS\UI\Choosers\TradeOriginChooser.lua',
    'BTS\UI\Choosers\TradeOriginChooser.xml',
    'BTS\UI\Choosers\TradeRouteChooser.lua',
    'BTS\UI\Choosers\TradeRouteChooser.xml'
)
foreach ($requiredFile in $betterTradeScreenFiles) {
    $key = Normalize-RelativePath $requiredFile
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot $requiredFile))) {
        Add-ValidationError "Better Trade Screen file is missing: $requiredFile"
    }
    elseif (-not $listedFileMap.ContainsKey($key) -or -not $actionReferenceMap.ContainsKey($key)) {
        Add-ValidationError "Better Trade Screen file is not both published and active: $requiredFile"
    }
}

$betterTradeCriterion = $criteriaMap['settings_ui_bettertradescreen']
if ($null -eq $betterTradeCriterion -or
        $betterTradeCriterion.GetAttribute('any') -ne '1' -or
        $null -eq $betterTradeCriterion.SelectSingleNode("./ConfigurationValueMatches[ConfigurationId='SETTINGS_UI_BTS' and Value='1']") -or
        $null -eq $betterTradeCriterion.SelectSingleNode("./ConfigurationValueMatches[ConfigurationId='SETTINGS_UI' and Value='SETTINGS_UI_ENABLE_ALL']")) {
    Add-ValidationError 'Better Trade Screen is not enabled by its custom toggle and the master UI preset.'
}

$configUiPath = Join-Path $modRoot 'Config\Config_UI.xml'
if (Test-Path -LiteralPath $configUiPath) {
    $configUi = Load-XmlDocument $configUiPath
    if ($null -eq $configUi.SelectSingleNode("/GameInfo/Parameters/Row[@ParameterId='SETTINGS_UI_BTS' and @ConfigurationId='SETTINGS_UI_BTS']")) {
        Add-ValidationError 'The custom UI list is missing its Better Trade Screen toggle.'
    }
    if ($null -eq $configUi.SelectSingleNode("/GameInfo/ParameterDependencies/Row[@ParameterId='SETTINGS_UI_BTS' and @ConfigurationId='SETTINGS_UI' and @ConfigurationValue='SETTINGS_UI_CUSTOM']")) {
        Add-ValidationError 'The Better Trade Screen toggle is not limited to custom UI mode.'
    }
}

$expectedBetterTradeActions = @{
    'zyl_bts_settingsschema' = @('UpdateDatabase', 'BTS/Settings/BTS_SettingsSchema.sql', '11008')
    'zyl_bts_settings' = @('UpdateDatabase', 'BTS/Settings/BTS_Settings.sql', '11009')
    'zyl_bts_settingspanel' = @('AddUserInterfaces', 'BTS/Settings/BTS_SettingsPanel.xml', '11010')
    'zyl_bts_ui' = @('ImportFiles', 'BTS/UI/TradeSupport.lua', '11011')
    'zyl_bts_text' = @('UpdateText', 'BTS/Text/BTS_Text_Hans_CN.xml', '11012')
}
foreach ($entry in $expectedBetterTradeActions.GetEnumerator()) {
    $action = $actionIdMap[$entry.Key]
    if ($null -eq $action -or
            $action.LocalName -ne $entry.Value[0] -or
            $null -eq $action.SelectSingleNode("./File[.='$($entry.Value[1])']") -or
            $action.SelectSingleNode('./Properties/LoadOrder').InnerText.Trim() -ne $entry.Value[2] -or
            $null -eq $action.SelectSingleNode("./Criteria[.='SETTINGS_UI_BetterTradeScreen']")) {
        Add-ValidationError "Better Trade Screen action is missing or malformed: $($entry.Key)"
    }
}

foreach ($oldBbgTradePath in @(
    'Components\BBG\ui\replacements\tradesupport.lua',
    'Components\BBG\ui\replacements\tradeoverview_bbg.lua',
    'Components\BBG\ui\replacements\compatibility\tradeoverview.lua',
    'Components\BBG\ui\replacements\compatibility\traderoutechooser.lua'
)) {
    if ($actionReferenceMap.ContainsKey((Normalize-RelativePath $oldBbgTradePath))) {
        Add-ValidationError "BBG trade UI is active alongside BTS: $oldBbgTradePath"
    }
}

$betterTradeSupportPath = Join-Path $modRoot 'BTS\UI\TradeSupport.lua'
if (Test-Path -LiteralPath $betterTradeSupportPath) {
    $betterTradeSupport = Get-Content -LiteralPath $betterTradeSupportPath -Raw
    foreach ($requiredToken in @(
        'include( "BTS_Serialize" )',
        'GetBBGAmaniTradeRouteYieldBonus',
        'LOC_GOVERNOR_THE_AMBASSADOR_NAME',
        'GetBBGAmaniTradeRouteYieldBonus(routeInfo, FOOD_INDEX)',
        'GetBBGAmaniTradeRouteYieldBonus(routeInfo, PRODUCTION_INDEX)',
        'BTS_Serialize(m_LocalPlayerRunningRoutes)',
        'BTS_Deserialize(dataDump)'
    )) {
        if (-not $betterTradeSupport.Contains($requiredToken)) {
            Add-ValidationError "Better Trade Screen lost BBG/cache compatibility: $requiredToken"
        }
    }
}

$betterTradeChooserPath = Join-Path $modRoot 'BTS\UI\Choosers\TradeRouteChooser.lua'
if (Test-Path -LiteralPath $betterTradeChooserPath) {
    $betterTradeChooser = Get-Content -LiteralPath $betterTradeChooserPath -Raw
    foreach ($sortHandler in @('OnSortByFood', 'OnSortByProduction', 'OnSortByGold', 'OnSortByScience', 'OnSortByCulture', 'OnSortByFaith', 'OnSortByTurnsToComplete')) {
        if (-not $betterTradeChooser.Contains($sortHandler)) {
            Add-ValidationError "Better Trade Screen route chooser is missing sort handler: $sortHandler"
        }
    }
}

$diplomacyRibbonPath = Join-Path $modRoot 'ui\Replacements\DiplomacyRibbon_ZYL.lua'
$diplomacyRibbonLayoutPath = Join-Path $modRoot 'ui\Replacements\DiplomacyRibbon.xml'
if (Test-Path -LiteralPath $diplomacyRibbonLayoutPath) {
	$diplomacyRibbonLayout = Load-XmlDocument $diplomacyRibbonLayoutPath
	foreach ($controlId in @(
		'LeaderContainer', 'StatStack', 'Score', 'Military', 'Science', 'Culture',
		'Gold', 'Faith', 'Favor', 'Food_Total', 'Production_Total', 'GoldPerTurn',
		'FaithperTurn', 'ScienceButton', 'ResearchIcon', 'ScienceProgressMeter',
		'CultureButton', 'CultureIcon', 'CultureProgressMeter', 'TPT_Control_1'
	)) {
		if ($null -eq $diplomacyRibbonLayout.SelectSingleNode("//*[@ID='$controlId']")) {
			Add-ValidationError "Diplomacy-ribbon layout is missing control $controlId."
		}
	}
	$tptControl = $diplomacyRibbonLayout.SelectSingleNode('//*[@ID="TPT_Control_1"]')
	if ($null -ne $tptControl -and $tptControl.GetAttribute('Hidden') -eq '1') {
		Add-ValidationError 'Diplomacy-ribbon page switch control is hidden.'
	}
	$playerNameControl = $diplomacyRibbonLayout.SelectSingleNode('//*[@ID="PlayerName"]')
	if ($null -eq $playerNameControl -or $playerNameControl.LocalName -ne 'ScrollTextField') {
		Add-ValidationError 'Diplomacy-ribbon PlayerName must retain the Team PVP Tools ScrollTextField control.'
	}
	$expectedStatOrder = @(
		'PlayerName', 'PlayerNameLen', 'CivName', 'Score', 'Military', 'Cities',
		'Science', 'Food_Total', 'Culture', 'Production_Total', 'Gold', 'GoldPerTurn',
		'Faith', 'FaithperTurn', 'Favor', 'FavorperTurn', 'ScienceButton', 'ScienceText',
		'ScienceTurnsLeft', 'CultureButton', 'CultureText', 'CultureTurnsLeft'
	)
	$actualStatOrder = @($diplomacyRibbonLayout.SelectNodes('//*[@ID="StatStack"]/*[@ID]') | ForEach-Object { $_.GetAttribute('ID') })
	if (($actualStatOrder -join '|') -ne ($expectedStatOrder -join '|')) {
		Add-ValidationError 'Diplomacy-ribbon StatStack control order no longer matches Team PVP Tools DPR.'
	}
	foreach ($hiddenControlId in @('Cities', 'Food_Total', 'Production_Total', 'GoldPerTurn', 'FaithperTurn', 'FavorperTurn', 'ScienceButton', 'ScienceText', 'ScienceTurnsLeft', 'CultureButton', 'CultureText', 'CultureTurnsLeft')) {
		$hiddenControl = $diplomacyRibbonLayout.SelectSingleNode("//*[@ID='$hiddenControlId']")
		if ($null -eq $hiddenControl -or $hiddenControl.GetAttribute('Hidden') -ne '1') {
			Add-ValidationError "Diplomacy-ribbon control $hiddenControlId must retain the Team PVP Tools default hidden state."
		}
	}
}
if (Test-Path -LiteralPath $diplomacyRibbonPath) {
	$diplomacyRibbonSource = Get-Content -Raw -LiteralPath $diplomacyRibbonPath
	foreach ($requiredToken in @(
		'include("InstanceManager")',
		'include("LeaderIcon")',
		'function LeaderIcon:GetToolTipString(playerID)',
		'local uiPortraitButton  = oLeaderIcon.Controls.SelectButton',
		'GameConfiguration.GetValue("ZYL_DIPLOMACY_RIBBON_MODE")',
		'localPlayerDiplomacy:GetVisibilityOn(playerID)',
		'Model == 1 and not IsTeamPlayer[playerID]',
		'iTeamAccessLevel = pPlayerDiplomacy:GetVisibilityOn(playerID)',
		'playerID == localplayerID or (Model == 1 and IsTeamPlayer[playerID])',
		'ZYLCanReveal(accessLevel, 1)',
		'ZYLCanReveal(accessLevel, 2)',
		'ZYLCanReveal(accessLevel, 3)',
		'ZYLCanReveal(accessLevel, 4)',
		'local Invisible = "?"',
		'uiLeader.Gold:SetText("[ICON_Gold]"',
		'uiLeader.Faith:SetText("[ICON_Faith]"',
		'local CanHide = m_TechCivisProgress or isMasked',
		'uiLeader.TPT_Control_1:RegisterCallback( Mouse.eLClick, OnMouseClick_TPT_Control_1L)',
		'uiLeader.TPT_Control_1:RegisterCallback( Mouse.eRClick, OnMouseClick_TPT_Control_1R)',
		'function ZYLSetResearchLocked',
		'LOC_ZYL_DIPLOMACY_RIBBON_RESEARCH_LOCKED_TT',
		'result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER");',
		'local isMasked = false;',
		'uiLeader.ActiveLeaderAndStats:SetSizeVal( pSize_LeaderContainer.x + LEADER_ART_OFFSET_X, pSize_StatStack.y + LEADER_ART_OFFSET_Y + 65 )'
	)) {
		if (-not $diplomacyRibbonSource.Contains($requiredToken)) {
			Add-ValidationError "Diplomacy-ribbon TPT layout or visibility overlay is missing: $requiredToken"
		}
	}
}

$ribbonImport = $modInfo.SelectSingleNode('/Mod/InGameActions/ImportFiles[@id="ZYL_DiplomacyRibbonFiles_XP2" and Criteria="Expansion2"]')
if ($null -eq $ribbonImport -or
	$null -eq $ribbonImport.SelectSingleNode('./File[.="ui/Replacements/DiplomacyRibbon.xml"]') -or
	$null -eq $ribbonImport.SelectSingleNode('./File[.="ui/Replacements/DiplomacyRibbon_ZYL.lua"]')) {
	Add-ValidationError 'The XP2 Team PVP Tools diplomacy-ribbon layout and visibility-overlaid script must be imported together.'
}

$oldMphDealPath = Normalize-RelativePath 'ui\Replacements\diplomacydealview_MPH.lua'
if ($listedFileMap.ContainsKey($oldMphDealPath) -or $actionReferenceMap.ContainsKey($oldMphDealPath)) {
    Add-ValidationError 'The old standalone MPH DiplomacyDealView script is still active.'
}
$dmtDuplicateConfig = Normalize-RelativePath 'Components\DetailedMapTacks\config\dmt_config.xml'
if ($listedFileMap.ContainsKey($dmtDuplicateConfig) -or $actionReferenceMap.ContainsKey($dmtDuplicateConfig)) {
    Add-ValidationError 'DMT duplicate hotkey database is active instead of the merged NHK config.'
}

$bdwEntryPath = Join-Path $modRoot 'Components\BetterDealWindow\DiplomacyDealView_ZYLPVP_Expansion2.lua'
$bdwCompatibilityPath = Join-Path $modRoot 'Components\BetterDealWindow\ZYLPVP_BDW_MPH_Compatibility.lua'
$dmtManagerPath = Join-Path $modRoot 'Components\DetailedMapTacks\ui\mappinmanager_dmt.lua'
$nhkMapPinPath = Join-Path $modRoot 'NHK\UI\MapPin_HotKey.lua'
if (Test-Path -LiteralPath $bdwEntryPath) {
    $bdwEntry = Get-Content -LiteralPath $bdwEntryPath -Raw
    foreach ($requiredToken in @(
        'include("DiplomacyDealView_Expansion2")',
        'GAMEMODE_MONOPOLIES',
        'GREATWORKOBJECT_PRODUCT',
        'include("ZYLPVP_BDW_MPH_Compatibility")'
    )) {
        if (-not $bdwEntry.Contains($requiredToken)) {
            Add-ValidationError "BDW entry point is missing compatibility token: $requiredToken"
        }
    }
}
if (Test-Path -LiteralPath $bdwCompatibilityPath) {
    $bdwCompatibility = Get-Content -LiteralPath $bdwCompatibilityPath -Raw
    foreach ($optionName in @(
        'DIPLOMATIC_DEAL', 'NO_TRADING_GOLD', 'NO_TRADING_FAVOR',
        'NO_TRADING_STRATEGICS', 'NO_TRADING_LUXURIES', 'NO_TRADING_CITIES',
        'NO_TRADING_CAPTIVES', 'NO_TRADING_GREATWORKS', 'NO_TRADING_AGREEMENTS'
    )) {
        if (-not $bdwCompatibility.Contains($optionName)) {
            Add-ValidationError "BDW/MPH compatibility is missing lobby option: $optionName"
        }
    }
}
if (Test-Path -LiteralPath $dmtManagerPath) {
    $dmtManager = Get-Content -LiteralPath $dmtManagerPath -Raw
    if (-not $dmtManager.Contains('GameConfiguration.GetValue("CPL_NO_PINS")')) {
        Add-ValidationError 'DMT input handling does not preserve the MPH no-pins rule.'
    }
}
if (Test-Path -LiteralPath $nhkMapPinPath) {
    $nhkMapPin = Get-Content -LiteralPath $nhkMapPinPath -Raw
    foreach ($duplicateListener in @('AddMapTack', 'DeleteMapTack', 'ToggleMapTackVisibility')) {
        if ($nhkMapPin.Contains($duplicateListener)) {
            Add-ValidationError "NHK still duplicates DMT's $duplicateListener listener."
        }
    }
    if (-not $nhkMapPin.Contains('AddMapMessage')) {
        Add-ValidationError 'NHK chat-map-pin shortcut was removed during DMT integration.'
    }
}

$pantheonChooserPath = Join-Path $modRoot 'BPC\UI\PantheonChooser_TPT.lua'
if (-not (Test-Path -LiteralPath $pantheonChooserPath)) {
	Add-ValidationError 'TPT Pantheon chooser replacement is missing.'
}
else {
	$pantheonChooserLua = Get-Content -LiteralPath $pantheonChooserPath -Raw
	foreach ($requiredPantheonChooserToken in @(
		'local beliefInst:table = InstanceButton[row.Index]',
		'if beliefInst == nil then',
		'InstanceButton = {}',
		'InstanceButton[row.Index] = beliefInst'
	)) {
		if (-not $pantheonChooserLua.Contains($requiredPantheonChooserToken)) {
			Add-ValidationError "TPT Pantheon chooser is missing the early-event/stable-index fix: $requiredPantheonChooserToken"
		}
	}
	if ($pantheonChooserLua.Contains('InstanceButton[row]')) {
		Add-ValidationError 'TPT Pantheon chooser still indexes instances by transient GameInfo row objects.'
	}
}

$stagingRoomXmlPath = Join-Path $modRoot 'ui\stagingroom.xml'
if (Test-Path -LiteralPath $stagingRoomXmlPath) {
	$stagingRoomXml = Get-Content -LiteralPath $stagingRoomXmlPath -Raw
	if ($stagingRoomXml -match '<Image\s+ID="BanPullDown_Icon"\s+Icon="Leaders45"') {
		Add-ValidationError 'MPH staging room still sends the Leaders45 texture name to IconManager.'
	}
	if ($stagingRoomXml -notmatch '<Image\s+ID="BanPullDown_Icon"\s+Texture="Leaders45"\s+Icon="ICON_LEADER_DEFAULT"') {
		Add-ValidationError 'MPH staging-room ban picker is missing its leader-texture fallback.'
	}
}

# Scan only active runtime text files for dangerous or disabled behavior.
$dangerPatterns = @(
    @{ Name = 'dynamic loadstring'; Pattern = 'loadstring\s*\(' },
    @{ Name = 'Workshop auto-update'; Pattern = 'Modding\.UpdateSubscription\s*\(' },
    @{ Name = 'science/culture anti-stacking'; Pattern = 'NoMoreStack|NO_MORE_STACK' }
)
$oldRuntimeIds = @(
    '3cd7857e-b720-4a1b-a61d-930f58d5237e',
    'cb84075d-5007-4207-b662-c35a5f7be260',
    'cb84075d-5007-4207-b662-c35a5f7be250',
    'cb84075d-5007-4207-b662-c35a5f7be254',
    'c88cba8b-8311-4d35-90c3-51a4a5d66542',
    'c88cba8b-8311-4d35-90c3-51a4a5d66550',
    '619ac86e-d99d-4bf3-b8f0-8c5b8c402567',
    '00000000-0165-224C-A3AA-154BB4B9C1C5'
)
foreach ($key in @($actionReferenceMap.Keys | Sort-Object)) {
    $relativePath = $actionReferenceMap[$key]
    if ([System.IO.Path]::GetExtension($relativePath) -notin @('.lua', '.sql', '.xml')) { continue }
    $fullPath = Join-Path $modRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath)) { continue }
    foreach ($dangerPattern in $dangerPatterns) {
        foreach ($hit in @(Select-String -LiteralPath $fullPath -Pattern $dangerPattern.Pattern)) {
            Add-ValidationError "$($dangerPattern.Name) in active file ${relativePath}:$($hit.LineNumber)"
        }
    }
    foreach ($oldId in $oldRuntimeIds) {
        foreach ($hit in @(Select-String -LiteralPath $fullPath -SimpleMatch $oldId)) {
            Add-ValidationError "Old component Mod ID in active runtime file ${relativePath}:$($hit.LineNumber): $oldId"
        }
    }
}

$descriptionZhNode = $modInfo.SelectSingleNode("/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_DESCRIPTION']/zh_Hans_CN")
if ($null -eq $descriptionZhNode -or $descriptionZhNode.InnerText.Contains('保教')) {
    Add-ValidationError 'The generated Chinese ModInfo description still contains the 保教/保留 typo.'
}

$blacklistLuaPath = Join-Path $modRoot 'ui\Additions\BlacklistPanel.lua'
$blacklistXmlPath = Join-Path $modRoot 'ui\Additions\BlacklistPanel.xml'
if ((Test-Path -LiteralPath $blacklistLuaPath) -and (Test-Path -LiteralPath $blacklistXmlPath)) {
    $blacklistLua = Get-Content -LiteralPath $blacklistLuaPath -Raw
    $blacklistXml = Get-Content -LiteralPath $blacklistXmlPath -Raw
    if (-not $blacklistLua.Contains('CopyBlackListToClipboard') -or
            -not $blacklistLua.Contains('UIManager:SetClipboardString') -or
            -not $blacklistLua.Contains('Controls.CopyBlackListButton:RegisterCallback') -or
            -not $blacklistXml.Contains('ID="CopyBlackListButton"')) {
        Add-ValidationError 'The blacklist manager no longer exposes the clipboard-export feature.'
    }
}

if ($validationErrors.Count -gt 0) {
    foreach ($validationError in $validationErrors) { Write-Error $validationError }
    Write-Host "FAILED: $($validationErrors.Count) validation error(s)." -ForegroundColor Red
    exit 1
}

Write-Host ("PASS: {0} XML artifacts, {1} criteria, {2} actions, {3} listed files, {4} active references and {5} intentionally dormant files validated." -f `
    $xmlFiles.Count, $criteriaMap.Count, $actionNodes.Count, $listedFiles.Count, $actionReferenceMap.Count, $intentionallyUnlistedFiles.Count) -ForegroundColor Green
exit 0
