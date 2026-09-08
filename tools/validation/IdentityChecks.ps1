function Get-ZylIdentityConfigurationIssues {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ConfigurationXml
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $parameterExpectations = @{
        'ZYL_IDENTITY_MODE' = @('bool', '0')
        'ZYL_IDENTITY_LOYALIST_COUNT' = @('ZylIdentityCounts', '2')
        'ZYL_IDENTITY_REBEL_COUNT' = @('ZylIdentityRebelCounts', '3')
        'ZYL_IDENTITY_SPY_COUNT' = @('ZylIdentityCounts', '1')
        'ZYL_IDENTITY_SEPARATE_PLAYER_1' = @('ZylStartingBonusPlayers', '0')
        'ZYL_IDENTITY_SEPARATE_PLAYER_2' = @('ZylStartingBonusPlayers', '0')
    }
    foreach ($entry in $parameterExpectations.GetEnumerator()) {
        $parameter = $ConfigurationXml.SelectSingleNode(
            "/GameInfo/Parameters/Row[@ParameterId='$($entry.Key)']"
        )
        if ($null -eq $parameter -or
                $parameter.GetAttribute('ConfigurationId') -ne $entry.Key -or
                $parameter.GetAttribute('ConfigurationGroup') -ne 'Game' -or
                $parameter.GetAttribute('Domain') -ne $entry.Value[0] -or
                $parameter.GetAttribute('DefaultValue') -ne $entry.Value[1] -or
                $parameter.GetAttribute('ChangeableAfterGameStart') -ne '0' -or
                $parameter.GetAttribute('SupportsSinglePlayer') -ne '0' -or
                $parameter.GetAttribute('SupportsPlayByCloud') -ne '0' -or
                $parameter.GetAttribute('SupportsHotSeat') -ne '0' -or
                $parameter.GetAttribute('SupportsLANMultiplayer') -ne '1' -or
                $parameter.GetAttribute('SupportsInternetMultiplayer') -ne '1') {
            $issues.Add("Identity-game lobby parameter is missing or malformed: $($entry.Key)")
        }
    }

    $dealParameter = $ConfigurationXml.SelectSingleNode(
        "/GameInfo/Parameters/Row[@ParameterId='ZYL_IDENTITY_DEAL']"
    )
    if ($null -eq $dealParameter -or
            $dealParameter.GetAttribute('ConfigurationId') -ne 'ZYL_IDENTITY_DEAL' -or
            $dealParameter.GetAttribute('ConfigurationGroup') -ne 'Game' -or
            $dealParameter.GetAttribute('Domain') -ne 'text' -or
            $dealParameter.GetAttribute('DefaultValue') -ne '' -or
            $dealParameter.GetAttribute('Visible') -ne '0' -or
            $dealParameter.GetAttribute('ChangeableAfterGameStart') -ne '0' -or
            $dealParameter.GetAttribute('SupportsSinglePlayer') -ne '0' -or
            $dealParameter.GetAttribute('SupportsPlayByCloud') -ne '0' -or
            $dealParameter.GetAttribute('SupportsHotSeat') -ne '0' -or
            $dealParameter.GetAttribute('SupportsLANMultiplayer') -ne '1' -or
            $dealParameter.GetAttribute('SupportsInternetMultiplayer') -ne '1') {
        $issues.Add('The hidden lobby identity-deal parameter is missing or malformed.')
    }

    foreach ($parameterId in @(
            'ZYL_IDENTITY_LOYALIST_COUNT',
            'ZYL_IDENTITY_REBEL_COUNT',
            'ZYL_IDENTITY_SPY_COUNT',
            'ZYL_IDENTITY_SEPARATE_PLAYER_1',
            'ZYL_IDENTITY_SEPARATE_PLAYER_2'
        )) {
        $dependency = $ConfigurationXml.SelectSingleNode(
            "/GameInfo/ParameterDependencies/Row[@ParameterId='$parameterId' " +
            "and @ConfigurationGroup='Game' and @ConfigurationId='ZYL_IDENTITY_MODE' " +
            "and @Operator='Equals' and @ConfigurationValue='1']"
        )
        if ($null -eq $dependency) {
            $issues.Add(
                "Identity-game dependent option is not gated by ZYL_IDENTITY_MODE: $parameterId"
            )
        }
    }

    $identityCountValues = @($ConfigurationXml.SelectNodes(
            '/GameInfo/DomainValues/Row[@Domain="ZylIdentityCounts"]'
        ))
    if ($identityCountValues.Count -ne 12) {
        $issues.Add(
            "The identity-count domain must contain values 0-11; " +
            "found $($identityCountValues.Count) rows."
        )
    }
    foreach ($value in 0..11) {
        if ($null -eq ($identityCountValues | Where-Object {
                    $_.GetAttribute('Value') -eq $value.ToString()
                })) {
            $issues.Add("The identity-count domain is missing value $value.")
        }
    }

    $rebelCountValues = @($ConfigurationXml.SelectNodes(
            '/GameInfo/DomainValues/Row[@Domain="ZylIdentityRebelCounts"]'
        ))
    if ($rebelCountValues.Count -ne 11) {
        $issues.Add(
            "The identity Rebel-count domain must contain values 1-11; " +
            "found $($rebelCountValues.Count) rows."
        )
    }
    foreach ($value in 1..11) {
        if ($null -eq ($rebelCountValues | Where-Object {
                    $_.GetAttribute('Value') -eq $value.ToString()
                })) {
            $issues.Add("The identity Rebel-count domain is missing value $value.")
        }
    }
    return @($issues)
}

function Get-ZylIdentityRolePanelSourceIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFragment in @(
            'ZYL_IDENTITY_DEAL',
            'local function ParseLobbyDeal()',
            'GameConfiguration.GetValue(DEAL_CONFIG)',
            'string.match(payload, "^(%d+)|(%d+)|([%d,]+)|([%d:,]+)$")',
            'counts[ROLE_LOYALIST] ~= loyalistCount',
            'CampFor(assignments[firstPlayerID], firstPlayerID)',
            'or (firstSelected > 0 and firstSelected == secondSelected)',
            'Game.GetLocalPlayer()',
            'LOC_ZYL_IDENTITY_NAME_SEPARATOR',
            'LOC_ZYL_IDENTITY_ERROR_DATA',
            'ContextPtr:SetInputHandler(OnInputHandler, true)',
            'Events.LocalPlayerChanged.Add(OnLocalPlayerChanged)'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("Identity-role UI is missing: $requiredFragment")
        }
    }
    if ($Source.Contains('table.concat(teammates, "、")')) {
        $issues.Add(
            'Identity-role UI hard-codes a Chinese teammate separator instead of using localization.'
        )
    }
    foreach ($forbiddenFragment in @(
            'Game:SetProperty(',
            'GameEvents.',
            'SetTeam(',
            'DiplomacyManager',
            'DiplomaticAI',
            'DeclareWar('
        )) {
        if ($Source.Contains($forbiddenFragment)) {
            $issues.Add(
                "The read-only identity panel contains gameplay mutation code: $forbiddenFragment"
            )
        }
    }
    return @($issues)
}

function Get-ZylIdentityContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ConfigurationXml,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($issue in @(Get-ZylIdentityConfigurationIssues `
            -ConfigurationXml $ConfigurationXml)) {
        $issues.Add($issue)
    }

    $gameplayPath = Join-Path $ProjectRoot 'scripts\ZYL_IdentityGame.lua'
    if (Test-Path -LiteralPath $gameplayPath -PathType Leaf) {
        $issues.Add('Lobby-only identity mode must not include a Gameplay identity script.')
    }
    if ($null -ne $ActionIdMap['zyl_identitygamegameplay']) {
        $issues.Add(
            'Lobby-only identity mode must not register an identity AddGameplayScripts action.'
        )
    }
    if ($ListedFileMap.ContainsKey((Normalize-RelativePath 'scripts/ZYL_IdentityGame.lua'))) {
        $issues.Add(
            'Lobby-only identity mode must not list a Gameplay identity script in ModInfo.'
        )
    }

    $panelLuaPath = Join-Path $ProjectRoot 'ui\Additions\IdentityRolePanel.lua'
    if (-not (Test-Path -LiteralPath $panelLuaPath -PathType Leaf)) {
        $issues.Add('The identity-role UI Lua file is missing.')
    }
    else {
        foreach ($issue in @(Get-ZylIdentityRolePanelSourceIssues `
                -Source (Get-Content -LiteralPath $panelLuaPath -Raw))) {
            $issues.Add($issue)
        }
    }

    $panelXmlPath = Join-Path $ProjectRoot 'ui\Additions\IdentityRolePanel.xml'
    if (-not (Test-Path -LiteralPath $panelXmlPath -PathType Leaf)) {
        $issues.Add('The identity-role UI XML file is missing.')
    }
    else {
        $panelXml = Load-XmlDocument $panelXmlPath
        foreach ($controlId in @(
                'RoleButtonContainer',
                'RoleButton',
                'Overlay',
                'PlayerOrder',
                'MaskContainer',
                'IdentityContainer',
                'ErrorContainer',
                'RevealButton',
                'HideButton',
                'CloseButton'
            )) {
            if ($null -eq $panelXml.SelectSingleNode("//*[@ID='$controlId']")) {
                $issues.Add("Identity-role UI XML is missing control: $controlId")
            }
        }
    }

    $uiAction = $ActionIdMap['zyl_identityrolepanel']
    if ($null -eq $uiAction -or
            $uiAction.LocalName -ne 'AddUserInterfaces' -or
            $null -eq $uiAction.SelectSingleNode('./Properties/Context[.="InGame"]') -or
            $null -eq $uiAction.SelectSingleNode(
                './File[.="ui/Additions/IdentityRolePanel.xml"]'
            )) {
        $issues.Add('The identity-role panel is not registered as an InGame UI action.')
    }
    foreach ($relativePath in @(
            'ui/Additions/IdentityRolePanel.lua',
            'ui/Additions/IdentityRolePanel.xml'
        )) {
        if (-not $ListedFileMap.ContainsKey((Normalize-RelativePath $relativePath))) {
            $issues.Add(
                "The identity-role UI file is absent from the ModInfo file manifest: $relativePath"
            )
        }
    }

    $stagingXmlPath = Join-Path $ProjectRoot 'ui\stagingroom.xml'
    if (-not (Test-Path -LiteralPath $stagingXmlPath -PathType Leaf)) {
        $issues.Add('The staging-room XML replacement is missing.')
    }
    else {
        $stagingXml = Load-XmlDocument $stagingXmlPath
        foreach ($controlId in @(
                'IdentityDealButton',
                'IdentityViewButton',
                'IdentityLobbyOverlay',
                'IdentityLobbyMaskContainer',
                'IdentityLobbyRevealButton',
                'IdentityLobbyRoleContainer',
                'IdentityLobbyHideButton',
                'IdentityLobbyCloseButton'
            )) {
            if ($null -eq $stagingXml.SelectSingleNode("//*[@ID='$controlId']")) {
                $issues.Add("Staging-room identity UI XML is missing control: $controlId")
            }
        }
    }

    $defaults = @{
        'ZYL_IDENTITY_MODE' = '0'
        'ZYL_IDENTITY_LOYALIST_COUNT' = '2'
        'ZYL_IDENTITY_REBEL_COUNT' = '3'
        'ZYL_IDENTITY_SPY_COUNT' = '1'
        'ZYL_IDENTITY_SEPARATE_PLAYER_1' = '0'
        'ZYL_IDENTITY_SEPARATE_PLAYER_2' = '0'
    }
    $defaultsPath = Join-Path $ProjectRoot 'configuration\ZYL_LobbyDefaults.xml'
    if (-not (Test-Path -LiteralPath $defaultsPath -PathType Leaf)) {
        $issues.Add('The lobby-defaults XML is missing.')
    }
    else {
        $defaultsXml = Load-XmlDocument $defaultsPath
        foreach ($entry in $defaults.GetEnumerator()) {
            $defaultNode = $defaultsXml.SelectSingleNode(
                "/GameInfo/Parameters/Update[Where/@ParameterId='$($entry.Key)']/Set"
            )
            if ($null -eq $defaultNode -or
                    $defaultNode.GetAttribute('DefaultValue') -ne $entry.Value) {
                $issues.Add(
                    "Identity-game lobby default is missing or incorrect: $($entry.Key)"
                )
            }
        }
        $dealDefaultNode = $defaultsXml.SelectSingleNode(
            "/GameInfo/Parameters/Update[Where/@ParameterId='ZYL_IDENTITY_DEAL']/Set"
        )
        if ($null -eq $dealDefaultNode -or
                $dealDefaultNode.GetAttribute('DefaultValue') -ne '') {
            $issues.Add('Identity-game lobby deal data does not reset to an empty value.')
        }
    }

    $hostGamePath = Join-Path $ProjectRoot 'ui\hostgame.lua'
    if (-not (Test-Path -LiteralPath $hostGamePath -PathType Leaf)) {
        $issues.Add('The host-game replacement is missing.')
    }
    else {
        $hostGameSource = Get-Content -LiteralPath $hostGamePath -Raw
        foreach ($entry in $defaults.GetEnumerator()) {
            $requiredDefault = '{ "' + $entry.Key + '", ' + $entry.Value + ' }'
            if (-not $hostGameSource.Contains($requiredDefault)) {
                $issues.Add(
                    "Host-game reset defaults are missing the identity setting: $($entry.Key)"
                )
            }
        }
        if (-not $hostGameSource.Contains('{ "ZYL_IDENTITY_DEAL", "" }')) {
            $issues.Add('Host-game reset defaults do not clear the identity lobby deal.')
        }
    }

    $textPath = Join-Path $ProjectRoot 'lang\ZYL_Text.xml'
    if (-not (Test-Path -LiteralPath $textPath -PathType Leaf)) {
        $issues.Add('The identity-game localization file is missing.')
    }
    else {
        $textXml = Load-XmlDocument $textPath
        $textTags = @(
            'LOC_ZYL_IDENTITY_MODE_NAME',
            'LOC_ZYL_IDENTITY_MODE_DESC',
            'LOC_ZYL_IDENTITY_DEAL_DATA_NAME',
            'LOC_ZYL_IDENTITY_DEAL_DATA_DESC',
            'LOC_ZYL_IDENTITY_DEAL_BUTTON',
            'LOC_ZYL_IDENTITY_REDEAL_BUTTON',
            'LOC_ZYL_IDENTITY_DEAL_BUTTON_TT',
            'LOC_ZYL_IDENTITY_VIEW_BUTTON',
            'LOC_ZYL_IDENTITY_WAITING_BUTTON',
            'LOC_ZYL_IDENTITY_PANEL_TITLE',
            'LOC_ZYL_IDENTITY_PLAYER_ORDER',
            'LOC_ZYL_IDENTITY_ROLE_LORD',
            'LOC_ZYL_IDENTITY_ROLE_LOYALIST',
            'LOC_ZYL_IDENTITY_ROLE_REBEL',
            'LOC_ZYL_IDENTITY_ROLE_SPY',
            'LOC_ZYL_IDENTITY_REBEL_TEAM_LABEL',
            'LOC_ZYL_IDENTITY_NAME_SEPARATOR',
            'LOC_ZYL_IDENTITY_ERROR_COUNT',
            'LOC_ZYL_IDENTITY_ERROR_SELECTION',
            'LOC_ZYL_IDENTITY_ERROR_NO_SOLUTION',
            'LOC_ZYL_IDENTITY_ERROR_NOT_DEALT',
            'LOC_ZYL_IDENTITY_ERROR_STALE',
            'LOC_ZYL_IDENTITY_ERROR_DATA'
        )
        foreach ($language in @('zh_Hans_CN', 'en_US', 'zh_Hant_HK')) {
            foreach ($tag in $textTags) {
                if ($null -eq $textXml.SelectSingleNode(
                        "/GameData/LocalizedText/Row[@Tag='$tag' and @Language='$language']/Text"
                    )) {
                    $issues.Add("Identity-game localization is missing $language / $tag.")
                }
            }
        }
    }
    return @($issues)
}
