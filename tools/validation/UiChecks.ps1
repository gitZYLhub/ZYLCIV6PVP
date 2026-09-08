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
