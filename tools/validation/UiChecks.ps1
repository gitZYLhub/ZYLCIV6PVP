function Get-ZylForcedEndButtonIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $requestCount = [regex]::Matches(
        $Source,
        'UI\.RequestAction\s*\(\s*ActionTypes\.ACTION_ENDTURN'
    ).Count
    if ($requestCount -ne 1) {
        $issues.Add("Force-end-turn button must issue exactly one end-turn request; found $requestCount.")
    }
    foreach ($forbiddenToken in @(
            'ACTION_UNREADYTURN',
            'GameCoreEventPublishComplete.Add',
            'LuaEvents.ForcedEndTurn()'
        )) {
        if ($Source.Contains($forbiddenToken)) {
            $issues.Add("Force-end-turn button restored an old retry/toggle path: $forbiddenToken")
        }
    }
    return @($issues)
}

function Get-ZylRandomPromotionHotkeyIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($forbiddenToken in @(
            'Modding.UpdateSubscription',
            'function AntiCheat',
            'function KillCheat',
            'Events.TurnEnd.Add'
        )) {
        if ($Source.IndexOf($forbiddenToken, [System.StringComparison]::Ordinal) -ge 0) {
            $issues.Add("The removed NewUnitOperation anti-cheat/update path returned: $forbiddenToken")
        }
    }
    return @($issues)
}

function Get-ZylTptUiContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [Parameter(Mandatory = $true)]
        [object]$CriteriaMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFile in @(
            'FEB/ForcedEndButton_Text.xml',
            'FEB/UI/ForcedEndButton.lua',
            'FEB/UI/ForcedEndButton.xml'
        )) {
        if (-not $ListedFileMap.ContainsKey((Normalize-RelativePath $requiredFile))) {
            $issues.Add("Force-end-turn button file absent from <Files>: $requiredFile")
        }
    }

    $forcedEndTextAction = $ActionIdMap['zyl_forcedendbuttontext']
    if ($null -eq $forcedEndTextAction -or
            $forcedEndTextAction.LocalName -ne 'UpdateText' -or
            $null -eq $forcedEndTextAction.SelectSingleNode(
                "./File[.='FEB/ForcedEndButton_Text.xml']"
            )) {
        $issues.Add('Force-end-turn button localization is not loaded by ModInfo.')
    }

    $forcedEndUiAction = $ActionIdMap['zyl_forcedendbutton']
    if ($null -eq $forcedEndUiAction -or $forcedEndUiAction.LocalName -ne 'AddUserInterfaces') {
        $issues.Add('Force-end-turn button UI action is missing.')
    }
    else {
        $contextNode = $forcedEndUiAction.SelectSingleNode('./Properties/Context')
        if ($null -eq $contextNode -or $contextNode.InnerText -ne 'InGame') {
            $issues.Add('Force-end-turn button must load in the InGame UI context.')
        }
        if ($null -eq $forcedEndUiAction.SelectSingleNode("./File[.='FEB/UI/ForcedEndButton.xml']")) {
            $issues.Add('Force-end-turn button UI action references the wrong layout.')
        }
    }

    $forcedEndLuaPath = Join-Path $ProjectRoot 'FEB\UI\ForcedEndButton.lua'
    if (-not (Test-Path -LiteralPath $forcedEndLuaPath -PathType Leaf)) {
        $issues.Add('Force-end-turn button Lua is missing.')
    }
    else {
        foreach ($issue in @(Get-ZylForcedEndButtonIssues `
                -Source (Get-Content -LiteralPath $forcedEndLuaPath -Raw))) {
            $issues.Add($issue)
        }
    }

    $lanNameAction = $ActionIdMap['zyl_lanplayernamelength']
    if ($null -eq $lanNameAction -or
            $lanNameAction.ParentNode.LocalName -ne 'FrontEndActions' -or
            $lanNameAction.LocalName -ne 'ImportFiles' -or
            $null -eq $lanNameAction.SelectSingleNode("./File[.='Option/Options.xml']")) {
        $issues.Add(
            'The 128-character LAN player-name Options replacement is not active in FrontEndActions.'
        )
    }
    $optionsPath = Join-Path $ProjectRoot 'Option\Options.xml'
    if (-not (Test-Path -LiteralPath $optionsPath -PathType Leaf)) {
        $issues.Add('The LAN player-name Options replacement is missing.')
    }
    else {
        $optionsXml = Load-XmlDocument $optionsPath
        $lanNameEdit = $optionsXml.SelectSingleNode("//*[@ID='LANPlayerNameEdit']")
        if ($null -eq $lanNameEdit -or $lanNameEdit.GetAttribute('MaxLength') -ne '128') {
            $issues.Add('LANPlayerNameEdit must retain MaxLength=128.')
        }
    }

    $noticeScriptAction = $ActionIdMap['zyl_gamefeaturenotices']
    if ($null -eq $noticeScriptAction -or
            $noticeScriptAction.LocalName -ne 'AddGameplayScripts' -or
            $null -eq $noticeScriptAction.SelectSingleNode("./File[.='NT/Notice.lua']")) {
        $issues.Add('The TPT start-of-game feature notice script is not active.')
    }
    $noticeTextAction = $ActionIdMap['zyl_gamefeaturenoticestext']
    if ($null -eq $noticeTextAction -or
            $noticeTextAction.LocalName -ne 'UpdateText' -or
            $null -eq $noticeTextAction.SelectSingleNode("./File[.='NT/Notice_Text.xml']")) {
        $issues.Add('The TPT start-of-game feature notice text is not active.')
    }

    $noPinsCriterion = $CriteriaMap['zyl_nomappins']
    if ($null -eq $noPinsCriterion) {
        $issues.Add('The no-map-pins UI criterion is missing.')
    }
    else {
        $noPinsMatch = $noPinsCriterion.SelectSingleNode(
            "./ConfigurationValueMatches[Group='Game' and ConfigurationId='CPL_NO_PINS' and Value='1']"
        )
        if ($null -eq $noPinsMatch) {
            $issues.Add('The no-map-pins UI criterion does not match CPL_NO_PINS=1.')
        }
    }
    $hidePinsAction = $ActionIdMap['zyl_hidemappinlistbutton']
    if ($null -eq $hidePinsAction -or
            $hidePinsAction.LocalName -ne 'AddUserInterfaces' -or
            $null -eq $hidePinsAction.SelectSingleNode("./Criteria[.='ZYL_NoMapPins']") -or
            $null -eq $hidePinsAction.SelectSingleNode(
                "./File[.='RMP/UI/Hide_MapPinListButton.xml']"
            )) {
        $issues.Add('CPL_NO_PINS does not activate the map-pin list button hider.')
    }
    $hidePinsPanelAction = $ActionIdMap['zyl_hidemappinlistpanel']
    $hidePinsLuaContext = if ($null -ne $hidePinsPanelAction) {
        $hidePinsPanelAction.SelectSingleNode('./Properties/LuaContext')
    }
    else { $null }
    $hidePinsLuaReplace = if ($null -ne $hidePinsPanelAction) {
        $hidePinsPanelAction.SelectSingleNode('./Properties/LuaReplace')
    }
    else { $null }
    if ($null -eq $hidePinsPanelAction -or
            $hidePinsPanelAction.LocalName -ne 'ReplaceUIScript' -or
            $null -eq $hidePinsLuaContext -or
            $hidePinsLuaContext.InnerText -ne 'MapPinListPanel' -or
            $null -eq $hidePinsLuaReplace -or
            $hidePinsLuaReplace.InnerText -ne 'RMP/UI/MapPinListPanel.lua' -or
            $null -eq $hidePinsPanelAction.SelectSingleNode("./Criteria[.='ZYL_NoMapPins']")) {
        $issues.Add('CPL_NO_PINS does not replace MapPinListPanel with the empty implementation.')
    }
    $hidePinsPanelFilesAction = $ActionIdMap['zyl_hidemappinlistpanelfiles']
    if ($null -eq $hidePinsPanelFilesAction -or
            $hidePinsPanelFilesAction.LocalName -ne 'ImportFiles' -or
            $null -eq $hidePinsPanelFilesAction.SelectSingleNode(
                "./File[.='RMP/UI/MapPinListPanel.xml']"
            ) -or
            $null -eq $hidePinsPanelFilesAction.SelectSingleNode(
                "./File[.='RMP/UI/MapPinListPanel.lua']"
            )) {
        $issues.Add('The empty no-pins MapPinListPanel layout/script pair is not imported.')
    }

    $randomPromotionConfig = $ActionIdMap['zyl_randompromotionhotkeyconfig']
    if ($null -eq $randomPromotionConfig -or
            $randomPromotionConfig.ParentNode.LocalName -ne 'FrontEndActions' -or
            $randomPromotionConfig.LocalName -ne 'UpdateDatabase' -or
            $null -eq $randomPromotionConfig.SelectSingleNode(
                "./File[.='NHK/Config_NewUnitOperation.xml']"
            )) {
        $issues.Add(
            'The safe TPT random-promotion shortcut is absent from the front-end input configuration.'
        )
    }
    $randomPromotionUi = $ActionIdMap['zyl_randompromotionhotkey']
    if ($null -eq $randomPromotionUi -or
            $randomPromotionUi.LocalName -ne 'AddUserInterfaces' -or
            $null -eq $randomPromotionUi.SelectSingleNode("./Criteria[.='TPT_NEW_HOTKEYS']") -or
            $null -eq $randomPromotionUi.SelectSingleNode(
                "./File[.='NHK/UI/NewUnitOperation.xml']"
            )) {
        $issues.Add(
            'The safe TPT random-promotion shortcut UI is not active when new hotkeys are enabled.'
        )
    }
    $randomPromotionLuaPath = Join-Path $ProjectRoot 'NHK\UI\NewUnitOperation.lua'
    if (-not (Test-Path -LiteralPath $randomPromotionLuaPath -PathType Leaf)) {
        $issues.Add('The safe random-promotion shortcut script is missing.')
    }
    else {
        foreach ($issue in @(Get-ZylRandomPromotionHotkeyIssues `
                -Source (Get-Content -LiteralPath $randomPromotionLuaPath -Raw))) {
            $issues.Add($issue)
        }
    }

    $bbgUnitPanelPath = Join-Path $ProjectRoot 'Components\BBG\ui\replacements\unitpanel_bbg.lua'
    if (-not (Test-Path -LiteralPath $bbgUnitPanelPath -PathType Leaf) -or
            (Get-Content -LiteralPath $bbgUnitPanelPath -Raw).IndexOf(
                'function OnUnitActionClicked_FoundCity',
                [System.StringComparison]::Ordinal
            ) -lt 0) {
        $issues.Add('TPT found-city confirmation removal is not merged into BBG UnitPanel ownership.')
    }
    return @($issues)
}

function Get-ZylBetterTradeSupportIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredToken in @(
            'include( "BTS_Serialize" )',
            'GetBBGAmaniTradeRouteYieldBonus',
            'LOC_GOVERNOR_THE_AMBASSADOR_NAME',
            'GetBBGAmaniTradeRouteYieldBonus(routeInfo, FOOD_INDEX)',
            'GetBBGAmaniTradeRouteYieldBonus(routeInfo, PRODUCTION_INDEX)',
            'BTS_Serialize(m_LocalPlayerRunningRoutes)',
            'BTS_Deserialize(dataDump)'
        )) {
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add("Better Trade Screen lost BBG/cache compatibility: $requiredToken")
        }
    }
    return @($issues)
}

function Get-ZylBetterTradeRouteChooserIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($sortHandler in @(
            'OnSortByFood',
            'OnSortByProduction',
            'OnSortByGold',
            'OnSortByScience',
            'OnSortByCulture',
            'OnSortByFaith',
            'OnSortByTurnsToComplete'
        )) {
        if (-not $Source.Contains($sortHandler)) {
            $issues.Add("Better Trade Screen route chooser is missing sort handler: $sortHandler")
        }
    }
    return @($issues)
}

function Get-ZylBetterTradeScreenContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionReferenceMap,

        [Parameter(Mandatory = $true)]
        [object]$CriteriaMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFile in @(
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
        )) {
        $key = Normalize-RelativePath $requiredFile
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $requiredFile) -PathType Leaf)) {
            $issues.Add("Better Trade Screen file is missing: $requiredFile")
        }
        elseif (-not $ListedFileMap.ContainsKey($key) -or
                -not $ActionReferenceMap.ContainsKey($key)) {
            $issues.Add("Better Trade Screen file is not both published and active: $requiredFile")
        }
    }

    $criterion = $CriteriaMap['settings_ui_bettertradescreen']
    if ($null -eq $criterion -or
            $criterion.GetAttribute('any') -ne '1' -or
            $null -eq $criterion.SelectSingleNode(
                "./ConfigurationValueMatches[ConfigurationId='SETTINGS_UI_BTS' and Value='1']"
            ) -or
            $null -eq $criterion.SelectSingleNode(
                "./ConfigurationValueMatches[ConfigurationId='SETTINGS_UI' and Value='SETTINGS_UI_ENABLE_ALL']"
            )) {
        $issues.Add(
            'Better Trade Screen is not enabled by its custom toggle and the master UI preset.'
        )
    }

    $configPath = Join-Path $ProjectRoot 'Config\Config_UI.xml'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $configXml = Load-XmlDocument $configPath
        if ($null -eq $configXml.SelectSingleNode(
                "/GameInfo/Parameters/Row[@ParameterId='SETTINGS_UI_BTS' and @ConfigurationId='SETTINGS_UI_BTS']"
            )) {
            $issues.Add('The custom UI list is missing its Better Trade Screen toggle.')
        }
        if ($null -eq $configXml.SelectSingleNode(
                "/GameInfo/ParameterDependencies/Row[@ParameterId='SETTINGS_UI_BTS' and @ConfigurationId='SETTINGS_UI' and @ConfigurationValue='SETTINGS_UI_CUSTOM']"
            )) {
            $issues.Add('The Better Trade Screen toggle is not limited to custom UI mode.')
        }
    }

    $expectedActions = @{
        'zyl_bts_settingsschema' = @('UpdateDatabase', 'BTS/Settings/BTS_SettingsSchema.sql', '11008')
        'zyl_bts_settings' = @('UpdateDatabase', 'BTS/Settings/BTS_Settings.sql', '11009')
        'zyl_bts_settingspanel' = @('AddUserInterfaces', 'BTS/Settings/BTS_SettingsPanel.xml', '11010')
        'zyl_bts_ui' = @('ImportFiles', 'BTS/UI/TradeSupport.lua', '11011')
        'zyl_bts_text' = @('UpdateText', 'BTS/Text/BTS_Text_Hans_CN.xml', '11012')
    }
    foreach ($entry in $expectedActions.GetEnumerator()) {
        $action = $ActionIdMap[$entry.Key]
        $loadOrderNode = if ($null -ne $action) {
            $action.SelectSingleNode('./Properties/LoadOrder')
        }
        else { $null }
        if ($null -eq $action -or
                $action.LocalName -ne $entry.Value[0] -or
                $null -eq $action.SelectSingleNode("./File[.='$($entry.Value[1])']") -or
                $null -eq $loadOrderNode -or
                $loadOrderNode.InnerText.Trim() -ne $entry.Value[2] -or
                $null -eq $action.SelectSingleNode(
                    "./Criteria[.='SETTINGS_UI_BetterTradeScreen']"
                )) {
            $issues.Add("Better Trade Screen action is missing or malformed: $($entry.Key)")
        }
    }

    foreach ($oldBbgTradePath in @(
            'Components\BBG\ui\replacements\tradesupport.lua',
            'Components\BBG\ui\replacements\tradeoverview_bbg.lua',
            'Components\BBG\ui\replacements\compatibility\tradeoverview.lua',
            'Components\BBG\ui\replacements\compatibility\traderoutechooser.lua'
        )) {
        if ($ActionReferenceMap.ContainsKey((Normalize-RelativePath $oldBbgTradePath))) {
            $issues.Add("BBG trade UI is active alongside BTS: $oldBbgTradePath")
        }
    }

    $supportPath = Join-Path $ProjectRoot 'BTS\UI\TradeSupport.lua'
    if (Test-Path -LiteralPath $supportPath -PathType Leaf) {
        foreach ($issue in @(Get-ZylBetterTradeSupportIssues `
                -Source (Get-Content -LiteralPath $supportPath -Raw))) {
            $issues.Add($issue)
        }
    }
    $chooserPath = Join-Path $ProjectRoot 'BTS\UI\Choosers\TradeRouteChooser.lua'
    if (Test-Path -LiteralPath $chooserPath -PathType Leaf) {
        foreach ($issue in @(Get-ZylBetterTradeRouteChooserIssues `
                -Source (Get-Content -LiteralPath $chooserPath -Raw))) {
            $issues.Add($issue)
        }
    }
    return @($issues)
}

function Get-ZylDiplomacyRibbonSourceIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
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
            'local value = ZYLCanReveal(accessLevel, 3) and tostring(math.floor(pPlayer:GetTreasury():GetGoldBalance())) or Invisible',
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
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add(
                "Diplomacy-ribbon TPT layout or visibility overlay is missing: $requiredToken"
            )
        }
    }
    return @($issues)
}

function Get-ZylBetterDealWindowEntryIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredToken in @(
            'include("DiplomacyDealView_Expansion2")',
            'GAMEMODE_MONOPOLIES',
            'GREATWORKOBJECT_PRODUCT',
            'include("ZYLPVP_BDW_MPH_Compatibility")'
        )) {
        if (-not $Source.Contains($requiredToken)) {
            $issues.Add("BDW entry point is missing compatibility token: $requiredToken")
        }
    }
    return @($issues)
}

function Get-ZylBetterDealWindowCompatibilityIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($optionName in @(
            'DIPLOMATIC_DEAL',
            'NO_TRADING_GOLD',
            'NO_TRADING_FAVOR',
            'NO_TRADING_STRATEGICS',
            'NO_TRADING_LUXURIES',
            'NO_TRADING_CITIES',
            'NO_TRADING_CAPTIVES',
            'NO_TRADING_GREATWORKS',
            'NO_TRADING_AGREEMENTS'
        )) {
        if (-not $Source.Contains($optionName)) {
            $issues.Add("BDW/MPH compatibility is missing lobby option: $optionName")
        }
    }
    return @($issues)
}

function Get-ZylIntegratedDealMapUiContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object[]]$ActionNodes,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionReferenceMap,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $integratedContexts = @{
        'diplomacydealview' = 'Components\BetterDealWindow\DiplomacyDealView_ZYLPVP_Expansion2.lua'
        'diplomacyribbon' = 'ui\Replacements\DiplomacyRibbon_ZYL.lua'
        'mappinmanager' = 'Components\DetailedMapTacks\ui\mappinmanager_dmt.lua'
        'mappinpopup' = 'Components\DetailedMapTacks\ui\mappinpopup_dmt.lua'
    }
    foreach ($entry in $integratedContexts.GetEnumerator()) {
        $matches = [System.Collections.Generic.List[object]]::new()
        foreach ($actionNode in $ActionNodes) {
            if ($actionNode.LocalName -ne 'ReplaceUIScript') { continue }
            $contextNode = $actionNode.SelectSingleNode('./Properties/LuaContext')
            if ($null -ne $contextNode -and
                    $contextNode.InnerText.Trim().ToLowerInvariant() -eq $entry.Key) {
                $matches.Add($actionNode)
            }
        }
        if ($matches.Count -ne 1) {
            $issues.Add("Expected exactly one $($entry.Key) replacement; found $($matches.Count).")
            continue
        }
        $replaceNode = $matches[0].SelectSingleNode('./Properties/LuaReplace')
        $actualPath = if ($null -ne $replaceNode) {
            Normalize-RelativePath $replaceNode.InnerText
        }
        else { '' }
        if ($actualPath -ne (Normalize-RelativePath $entry.Value)) {
            $issues.Add("Unexpected $($entry.Key) replacement: $actualPath")
        }
    }

    foreach ($blockedId in @(
            'fbb7b86a-9ac9-4a8e-9439-9ded6aceda0e',
            '4ecfcc62-5471-4435-b295-590df213e8d8',
            '8d4fa23a-ef43-440c-8422-2bec11f8f5d7'
        )) {
        if ($null -eq $ModInfo.SelectSingleNode("/Mod/Blocks/Mod[@id='$blockedId']")) {
            $issues.Add("Integrated external UI Mod ID is not blocked: $blockedId")
        }
    }

    foreach ($requiredFile in @(
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
        )) {
        $key = Normalize-RelativePath $requiredFile
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $requiredFile) -PathType Leaf)) {
            $issues.Add("Integrated UI file is missing: $requiredFile")
        }
        elseif (-not $ListedFileMap.ContainsKey($key) -or
                -not $ActionReferenceMap.ContainsKey($key)) {
            $issues.Add("Integrated UI file is not both published and active: $requiredFile")
        }
    }

    $ribbonLayoutPath = Join-Path $ProjectRoot 'ui\Replacements\DiplomacyRibbon.xml'
    if (Test-Path -LiteralPath $ribbonLayoutPath -PathType Leaf) {
        $layout = Load-XmlDocument $ribbonLayoutPath
        foreach ($controlId in @(
                'LeaderContainer', 'StatStack', 'Score', 'Military', 'Science', 'Culture',
                'Gold', 'Faith', 'Favor', 'Food_Total', 'Production_Total', 'GoldPerTurn',
                'FaithperTurn', 'ScienceButton', 'ResearchIcon', 'ScienceProgressMeter',
                'CultureButton', 'CultureIcon', 'CultureProgressMeter', 'TPT_Control_1'
            )) {
            if ($null -eq $layout.SelectSingleNode("//*[@ID='$controlId']")) {
                $issues.Add("Diplomacy-ribbon layout is missing control $controlId.")
            }
        }
        $tptControl = $layout.SelectSingleNode('//*[@ID="TPT_Control_1"]')
        if ($null -ne $tptControl -and $tptControl.GetAttribute('Hidden') -eq '1') {
            $issues.Add('Diplomacy-ribbon page switch control is hidden.')
        }
        $playerNameControl = $layout.SelectSingleNode('//*[@ID="PlayerName"]')
        if ($null -eq $playerNameControl -or $playerNameControl.LocalName -ne 'ScrollTextField') {
            $issues.Add(
                'Diplomacy-ribbon PlayerName must retain the Team PVP Tools ScrollTextField control.'
            )
        }
        $expectedStatOrder = @(
            'PlayerName', 'PlayerNameLen', 'CivName', 'Score', 'Military', 'Cities',
            'Science', 'Food_Total', 'Culture', 'Production_Total', 'Gold', 'GoldPerTurn',
            'Faith', 'FaithperTurn', 'Favor', 'FavorperTurn', 'ScienceButton', 'ScienceText',
            'ScienceTurnsLeft', 'CultureButton', 'CultureText', 'CultureTurnsLeft'
        )
        $actualStatOrder = @($layout.SelectNodes('//*[@ID="StatStack"]/*[@ID]') |
            ForEach-Object { $_.GetAttribute('ID') })
        if (($actualStatOrder -join '|') -ne ($expectedStatOrder -join '|')) {
            $issues.Add(
                'Diplomacy-ribbon StatStack control order no longer matches Team PVP Tools DPR.'
            )
        }
        foreach ($hiddenControlId in @(
                'Cities', 'Food_Total', 'Production_Total', 'GoldPerTurn',
                'FaithperTurn', 'FavorperTurn', 'ScienceButton', 'ScienceText',
                'ScienceTurnsLeft', 'CultureButton', 'CultureText', 'CultureTurnsLeft'
            )) {
            $hiddenControl = $layout.SelectSingleNode("//*[@ID='$hiddenControlId']")
            if ($null -eq $hiddenControl -or $hiddenControl.GetAttribute('Hidden') -ne '1') {
                $issues.Add(
                    "Diplomacy-ribbon control $hiddenControlId must retain the Team PVP Tools default hidden state."
                )
            }
        }
    }

    $ribbonSourcePath = Join-Path $ProjectRoot 'ui\Replacements\DiplomacyRibbon_ZYL.lua'
    if (Test-Path -LiteralPath $ribbonSourcePath -PathType Leaf) {
        foreach ($issue in @(Get-ZylDiplomacyRibbonSourceIssues `
                -Source (Get-Content -LiteralPath $ribbonSourcePath -Raw))) {
            $issues.Add($issue)
        }
    }
    $ribbonImport = $ModInfo.SelectSingleNode(
        '/Mod/InGameActions/ImportFiles[@id="ZYL_DiplomacyRibbonFiles_XP2" and Criteria="Expansion2"]'
    )
    if ($null -eq $ribbonImport -or
            $null -eq $ribbonImport.SelectSingleNode(
                './File[.="ui/Replacements/DiplomacyRibbon.xml"]'
            ) -or
            $null -eq $ribbonImport.SelectSingleNode(
                './File[.="ui/Replacements/DiplomacyRibbon_ZYL.lua"]'
            )) {
        $issues.Add(
            'The XP2 Team PVP Tools diplomacy-ribbon layout and visibility-overlaid script must be imported together.'
        )
    }

    $oldMphDealPath = Normalize-RelativePath 'ui\Replacements\diplomacydealview_MPH.lua'
    if ($ListedFileMap.ContainsKey($oldMphDealPath) -or
            $ActionReferenceMap.ContainsKey($oldMphDealPath)) {
        $issues.Add('The old standalone MPH DiplomacyDealView script is still active.')
    }
    $dmtDuplicateConfig = Normalize-RelativePath `
        'Components\DetailedMapTacks\config\dmt_config.xml'
    if ($ListedFileMap.ContainsKey($dmtDuplicateConfig) -or
            $ActionReferenceMap.ContainsKey($dmtDuplicateConfig)) {
        $issues.Add('DMT duplicate hotkey database is active instead of the merged NHK config.')
    }

    $bdwEntryPath = Join-Path $ProjectRoot `
        'Components\BetterDealWindow\DiplomacyDealView_ZYLPVP_Expansion2.lua'
    if (Test-Path -LiteralPath $bdwEntryPath -PathType Leaf) {
        foreach ($issue in @(Get-ZylBetterDealWindowEntryIssues `
                -Source (Get-Content -LiteralPath $bdwEntryPath -Raw))) {
            $issues.Add($issue)
        }
    }
    $bdwCompatibilityPath = Join-Path $ProjectRoot `
        'Components\BetterDealWindow\ZYLPVP_BDW_MPH_Compatibility.lua'
    if (Test-Path -LiteralPath $bdwCompatibilityPath -PathType Leaf) {
        foreach ($issue in @(Get-ZylBetterDealWindowCompatibilityIssues `
                -Source (Get-Content -LiteralPath $bdwCompatibilityPath -Raw))) {
            $issues.Add($issue)
        }
    }

    $dmtManagerPath = Join-Path $ProjectRoot `
        'Components\DetailedMapTacks\ui\mappinmanager_dmt.lua'
    if (Test-Path -LiteralPath $dmtManagerPath -PathType Leaf) {
        $dmtManager = Get-Content -LiteralPath $dmtManagerPath -Raw
        if (-not $dmtManager.Contains('GameConfiguration.GetValue("CPL_NO_PINS")')) {
            $issues.Add('DMT input handling does not preserve the MPH no-pins rule.')
        }
    }
    $nhkMapPinPath = Join-Path $ProjectRoot 'NHK\UI\MapPin_HotKey.lua'
    if (Test-Path -LiteralPath $nhkMapPinPath -PathType Leaf) {
        $nhkMapPin = Get-Content -LiteralPath $nhkMapPinPath -Raw
        foreach ($duplicateListener in @(
                'AddMapTack',
                'DeleteMapTack',
                'ToggleMapTackVisibility'
            )) {
            if ($nhkMapPin.Contains($duplicateListener)) {
                $issues.Add("NHK still duplicates DMT's $duplicateListener listener.")
            }
        }
        if (-not $nhkMapPin.Contains('AddMapMessage')) {
            $issues.Add('NHK chat-map-pin shortcut was removed during DMT integration.')
        }
    }
    return @($issues)
}

function Get-ZylUiContextOwnerIssues {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$ActionNodes
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $contextOwners = @{}
    foreach ($actionNode in @($ActionNodes | Where-Object {
                $_.LocalName -eq 'ReplaceUIScript'
            })) {
        $contextNode = $actionNode.SelectSingleNode('./Properties/LuaContext')
        $replaceNode = $actionNode.SelectSingleNode('./Properties/LuaReplace')
        if ($null -eq $contextNode -or $null -eq $replaceNode) {
            $issues.Add("Incomplete ReplaceUIScript action: $($actionNode.GetAttribute('id'))")
            continue
        }
        $replacePath = $replaceNode.InnerText.Trim().Replace('\', '/')
        $owner = 'Toolbox'
        if ($replacePath.StartsWith(
                'Components/BBG/',
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            $owner = 'BBG'
        }
        elseif ($replacePath.StartsWith(
                'Components/BBM/',
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            $owner = 'BBM'
        }
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
            $issues.Add(
                "LuaReplace context has cross-component owners: " +
                "$contextKey => $($contextOwners[$contextKey] -join ', ')"
            )
        }
    }
    return @($issues)
}

function Get-ZylEndGameUiOwnershipIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionReferenceMap
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $mphEndGame = Normalize-RelativePath 'ui/Replacements/endgamemenu.xml'
    $bbgEndGameXml = Normalize-RelativePath `
        'Components/BBG/ui/replacements/endgamemenu.xml'
    $bbgEndGameLua = Normalize-RelativePath `
        'Components/BBG/ui/replacements/endgamemenu_bbg.lua'
    if (-not $ListedFileMap.ContainsKey($mphEndGame)) {
        $issues.Add('MPH EndGameMenu XML is not published.')
    }
    if ($ListedFileMap.ContainsKey($bbgEndGameXml)) {
        $issues.Add('BBG duplicate EndGameMenu XML is still published.')
    }
    if ($ActionReferenceMap.ContainsKey($bbgEndGameXml)) {
        $issues.Add('BBG duplicate EndGameMenu XML is still loaded.')
    }
    if (-not $ActionReferenceMap.ContainsKey($bbgEndGameLua)) {
        $issues.Add('BBG EndGameMenu Lua extension is not loaded.')
    }
    return @($issues)
}
