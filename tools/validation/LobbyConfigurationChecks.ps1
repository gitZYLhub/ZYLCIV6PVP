function Get-ZylLobbyConfigurationContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap,

        [AllowNull()]
        [System.Xml.XmlDocument]$ZylConfig,

        [AllowNull()]
        [System.Xml.XmlDocument]$CplConfigOverride,

        [AllowNull()]
        [System.Xml.XmlDocument]$LobbyDefaultsOverride,

        [AllowNull()]
        [System.Xml.XmlDocument]$BbgConfigOverride,

        [AllowEmptyString()]
        [string]$TurnProcessingSourceOverride,

        [AllowEmptyString()]
        [string]$HostGameSourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()

    if ($null -eq $ZylConfig) {
        $issues.Add('The ZYLPVPMOD front-end configuration is missing.')
    }
    else {
        $warningNode = $ZylConfig.SelectSingleNode(
            '/GameInfo/Parameters/Row[@ParameterId="TOOLS_15_TIME"]'
        )
        if ($null -eq $warningNode -or $warningNode.GetAttribute('DefaultValue') -ne '1') {
            $issues.Add('The 15-second warning must default to enabled.')
        }
        $zylConfigRows = @($ZylConfig.SelectNodes('/GameInfo/Parameters/Row'))
        foreach ($parameterId in @('TOOLS_COMMAND', 'TOOLS_15_TIME')) {
            if ($null -eq ($zylConfigRows | Where-Object {
                        $_.GetAttribute('ParameterId') -eq $parameterId
                    })) {
                $issues.Add("Config_ZYL.xml is missing $parameterId.")
            }
        }

        $ribbonModeOptions = @($ZylConfig.SelectNodes(
                '/GameInfo/Parameters/Row[@ParameterId="ZYL_DIPLOMACY_RIBBON_MODE"]'
            ))
        if ($ribbonModeOptions.Count -ne 1 -or
                $ribbonModeOptions[0].GetAttribute('Key2') -ne 'RULESET_EXPANSION_2' -or
                $ribbonModeOptions[0].GetAttribute('Domain') -ne 'ZylDiplomacyRibbonModes' -or
                $ribbonModeOptions[0].GetAttribute('DefaultValue') -ne '0') {
            $issues.Add(
                'The diplomacy-ribbon mode must be an Expansion 2 lobby option ' +
                'using ZylDiplomacyRibbonModes and defaulting to FFA (0).'
            )
        }
        $ribbonModeValues = @($ZylConfig.SelectNodes(
                '/GameInfo/DomainValues/Row[@Domain="ZylDiplomacyRibbonModes"]'
            ))
        if ($ribbonModeValues.Count -ne 2 -or
                $null -eq ($ribbonModeValues | Where-Object {
                        $_.GetAttribute('Value') -eq '0'
                    }) -or
                $null -eq ($ribbonModeValues | Where-Object {
                        $_.GetAttribute('Value') -eq '1'
                    })) {
            $issues.Add(
                'The diplomacy-ribbon domain must contain exactly FFA (0) and Team (1).'
            )
        }
    }

    $cplConfigPath = Join-Path $ProjectRoot 'configuration\Config.xml'
    $cplConfig = if ($PSBoundParameters.ContainsKey('CplConfigOverride')) {
        $CplConfigOverride
    }
    elseif (Test-Path -LiteralPath $cplConfigPath -PathType Leaf) {
        Load-XmlDocument $cplConfigPath
    }
    else {
        $null
    }
    if ($null -eq $cplConfig) {
        $issues.Add('The CPL timer configuration is missing.')
    }
    else {
        $smartTimerParameter = $cplConfig.SelectSingleNode(
            '/GameInfo/Parameters/Row[@ParameterId="CPL_SMARTTIMER"]'
        )
        if ($null -eq $smartTimerParameter -or
                $smartTimerParameter.GetAttribute('DefaultValue') -ne '9') {
            $issues.Add(
                'The base smart-timer lobby parameter must default to Casual (Relaxed), value 9.'
            )
        }
        $balancedTimerOption = $cplConfig.SelectSingleNode(
            '/GameInfo/DomainValues/Row[@Domain="TimerLimits" and @Value="8"]'
        )
        if ($null -eq $balancedTimerOption -or
                $balancedTimerOption.GetAttribute('Name') -ne 'TIMER_CASUAL_BALANCED_NAME' -or
                $balancedTimerOption.GetAttribute('Description') -ne 'TIMER_CASUAL_BALANCED_DESC') {
            $issues.Add(
                'The balanced Casual timer option (TimerLimits value 8) is missing or malformed.'
            )
        }
        $relaxedTimerOption = $cplConfig.SelectSingleNode(
            '/GameInfo/DomainValues/Row[@Domain="TimerLimits" and @Value="9"]'
        )
        if ($null -eq $relaxedTimerOption -or
                $relaxedTimerOption.GetAttribute('Name') -ne 'TIMER_CASUAL_RELAXED_NAME' -or
                $relaxedTimerOption.GetAttribute('Description') -ne 'TIMER_CASUAL_RELAXED_DESC') {
            $issues.Add(
                'The relaxed Casual timer option (TimerLimits value 9) is missing or malformed.'
            )
        }
    }

    $turnProcessingPath = Join-Path $ProjectRoot 'ui\Additions\TurnProcessing.lua'
    $turnProcessingSource = if ($PSBoundParameters.ContainsKey(
            'TurnProcessingSourceOverride'
        )) {
        $TurnProcessingSourceOverride
    }
    elseif (Test-Path -LiteralPath $turnProcessingPath -PathType Leaf) {
        Get-Content -Raw -LiteralPath $turnProcessingPath
    }
    else {
        $null
    }
    if ($null -eq $turnProcessingSource) {
        $issues.Add('The turn-processing controller is missing.')
    }
    else {
        foreach ($issue in @(Get-ZylTurnProcessingContractIssues `
                -Source $turnProcessingSource)) {
            $issues.Add($issue)
        }
    }

    foreach ($issue in @(Get-ZylEraConfigurationContractIssues `
            -ProjectRoot $ProjectRoot `
            -ModInfo $ModInfo `
            -ZylConfig $ZylConfig)) {
        $issues.Add($issue)
    }

    $lobbyDefaultsPath = Join-Path $ProjectRoot 'configuration\ZYL_LobbyDefaults.xml'
    $lobbyDefaults = if ($PSBoundParameters.ContainsKey('LobbyDefaultsOverride')) {
        $LobbyDefaultsOverride
    }
    elseif (Test-Path -LiteralPath $lobbyDefaultsPath -PathType Leaf) {
        Load-XmlDocument $lobbyDefaultsPath
    }
    else {
        $null
    }
    if ($null -eq $lobbyDefaults) {
        $issues.Add('The final lobby-default configuration is missing.')
    }
    else {
        $expectedLobbyDefaults = [ordered]@{
            'TOOLS_COMMAND' = '1'
            'TOOLS_15_TIME' = '1'
            'CPL_SMARTTIMER' = '9'
            'ZYL_ERA_LENGTH_OPTIMIZATION' = '1'
            'ZYL_DIPLOMACY_RIBBON_MODE' = '0'
            'ZYL_STARTING_BONUS_PLAYER' = '0'
            'ZYL_STARTING_BONUS_TYPE' = '0'
            'BBCC_SETTING' = '0'
            'BBCC_SETTING_YIELD' = '2'
            'SettlersConfig' = '0'
            'BarbariansSetting' = '-1'
            'NoBarbarians' = '1'
            'GameMode_Monopolies' = '1'
            'GameMode_SecretSocieties' = '1'
            'ZYLRM_TEAM_RouteLevel' = '1'
            'ZYLRM_FFA_RouteLevel' = '1'
        }
        foreach ($entry in $expectedLobbyDefaults.GetEnumerator()) {
            $node = $lobbyDefaults.SelectSingleNode(
                "/GameInfo/Parameters/Update[Where/@ParameterId='$($entry.Key)']/Set"
            )
            if ($null -eq $node -or $node.GetAttribute('DefaultValue') -ne $entry.Value) {
                $issues.Add("Final lobby default $($entry.Key) must be $($entry.Value).")
            }
        }
    }

    $lobbyAction = $ActionIdMap['zyl_lobbydefaults']
    if ($null -eq $lobbyAction) {
        $issues.Add('Final lobby-default ModInfo action is missing.')
    }
    else {
        if ($lobbyAction.ParentNode.LocalName -ne 'FrontEndActions' -or
                $lobbyAction.LocalName -ne 'UpdateDatabase') {
            $issues.Add(
                'Final lobby-default action must be a FrontEndActions UpdateDatabase action.'
            )
        }
        $loadOrderNode = $lobbyAction.SelectSingleNode('./Properties/LoadOrder')
        $lobbyLoadOrder = 0L
        if ($null -eq $loadOrderNode -or
                -not [int64]::TryParse(
                    $loadOrderNode.InnerText.Trim(),
                    [ref]$lobbyLoadOrder
                ) -or
                $lobbyLoadOrder -lt 300000000) {
            $issues.Add('Final lobby-default action must load at or after 300000000.')
        }
        $cplAction = $ActionIdMap['cpl_settings']
        if ($null -ne $cplAction -and $null -ne $loadOrderNode) {
            $cplLoadOrderNode = $cplAction.SelectSingleNode('./Properties/LoadOrder')
            $cplLoadOrder = 0L
            if ($null -ne $cplLoadOrderNode -and
                    [int64]::TryParse(
                        $cplLoadOrderNode.InnerText.Trim(),
                        [ref]$cplLoadOrder
                    ) -and
                    $lobbyLoadOrder -le $cplLoadOrder) {
                $issues.Add('Final lobby-default action must load after CPL_SETTINGS.')
            }
        }
        $lobbyActionFiles = @($lobbyAction.SelectNodes('./File') | ForEach-Object {
                Normalize-RelativePath $_.InnerText
            })
        if ((Normalize-RelativePath 'configuration/ZYL_LobbyDefaults.xml') -notin
                $lobbyActionFiles) {
            $issues.Add('Final lobby-default action does not reference ZYL_LobbyDefaults.xml.')
        }
    }

    $hostGamePath = Join-Path $ProjectRoot 'ui\hostgame.lua'
    $hostGameSource = if ($PSBoundParameters.ContainsKey('HostGameSourceOverride')) {
        $HostGameSourceOverride
    }
    elseif (Test-Path -LiteralPath $hostGamePath -PathType Leaf) {
        Get-Content -LiteralPath $hostGamePath -Raw
    }
    else {
        $null
    }
    if ($null -eq $hostGameSource) {
        $issues.Add('The host-game replacement is missing.')
    }
    else {
        if ([regex]::Matches(
                $hostGameSource,
                'GameConfiguration\.SetKickVoting\(true\);'
            ).Count -lt 2) {
            $issues.Add(
                'Kick voting must be enabled in fresh-host and restore-default flows.'
            )
        }
        if ([regex]::Matches(
                $hostGameSource,
                'ApplyZYLLobbyDefaults\s*\(\s*\)'
            ).Count -lt 4) {
            $issues.Add(
                'Host game must apply ZYLPVPMOD defaults for fresh rooms, ' +
                'Restore Defaults and MPH preset None.'
            )
        }
        foreach ($requiredDefault in @(
                '{ "CPL_SMARTTIMER", 9 }',
                '{ "ZYL_ERA_LENGTH_OPTIMIZATION", 1 }',
                '{ "ZYL_DIPLOMACY_RIBBON_MODE", 0 }',
                '{ "ZYL_STARTING_BONUS_PLAYER", 0 }',
                '{ "ZYL_STARTING_BONUS_TYPE", 0 }',
                '{ "SettlersConfig", 0 }'
            )) {
            if (-not $hostGameSource.Contains($requiredDefault)) {
                $issues.Add("Host game is missing the requested lobby default: $requiredDefault")
            }
        }
        foreach ($requiredLifecycleFragment in @(
                'local b_debug = false;',
                'function OnFinishedGameplayContentConfigure(result)',
                'Events.FinishedGameplayContentConfigure.Add(OnFinishedGameplayContentConfigure);',
                'Events.FinishedGameplayContentConfigure.Remove(OnFinishedGameplayContentConfigure);',
                'hostID == nil or localID == nil or hostID < 0 or localID ~= hostID'
            )) {
            if (-not $hostGameSource.Contains($requiredLifecycleFragment)) {
                $issues.Add(
                    "Host-game lifecycle or authority guard is missing: $requiredLifecycleFragment"
                )
            }
        }
        foreach ($forbiddenFragment in @(
                'Events.FinishedGameplayContentConfigure.Add(function',
                'Network.BroadcastPlayerInfo()',
                'SpawnRecalculation',
                'OnUpdateUI()'
            )) {
            if ($hostGameSource.Contains($forbiddenFragment)) {
                $issues.Add(
                    "Host game restored a dead path or unrelated broadcast: $forbiddenFragment"
                )
            }
        }
        foreach ($issue in @(Get-ZylLuaEventLifecycleIssues `
                -Source $hostGameSource `
                -Label 'Host game')) {
            $issues.Add($issue)
        }
        foreach ($issue in @(Get-ZylLuaUnguardedPrintIssues `
                -Source $hostGameSource `
                -Label 'Host game')) {
            $issues.Add($issue)
        }
    }

    $bbgConfigPath = Join-Path $ProjectRoot 'Components\BBG\config\config.xml'
    $bbgConfig = if ($PSBoundParameters.ContainsKey('BbgConfigOverride')) {
        $BbgConfigOverride
    }
    elseif (Test-Path -LiteralPath $bbgConfigPath -PathType Leaf) {
        Load-XmlDocument $bbgConfigPath
    }
    else {
        $null
    }
    if ($null -eq $bbgConfig) {
        $issues.Add('BBG front-end configuration is missing.')
    }
    else {
        $settlersParameter = $bbgConfig.SelectSingleNode(
            '/GameInfo/Parameters/Row[@ParameterId="SettlersConfig"]'
        )
        if ($null -eq $settlersParameter -or
                $settlersParameter.GetAttribute('DefaultValue') -ne '0') {
            $issues.Add('BBG captured-settler option must default to Send Home (0).')
        }
    }

    return @($issues)
}
