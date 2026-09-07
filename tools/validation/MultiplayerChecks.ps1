function Get-ZylStagingRoomContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredIdentityFragment in @(
            'function GetZYLIdentityHumanPlayers()',
            'and Network.IsPlayerConnected(playerID)',
            'local function ReadZYLIdentityInteger(parameterID:string)',
            'local function BuildZYLIdentityAssignments(',
            'local function ParseZYLIdentityDeal(',
            'function OnZYLDealIdentities()',
            'function InvalidateZYLIdentityLobbyDeal()',
            'function RefreshZYLIdentityLobbyControls()',
            'Network.BroadcastGameConfig()',
            'or (settings.First > 0 and settings.First == settings.Second)',
            'function CheckZYLIdentityConfig()',
            'g_identityConfigValid',
            'LOC_ZYL_IDENTITY_ERROR_COUNT',
            'LOC_ZYL_IDENTITY_ERROR_SELECTION'
        )) {
        if (-not $Source.Contains($requiredIdentityFragment)) {
            $issues.Add("Staging-room identity validation is missing: $requiredIdentityFragment")
        }
    }
    if ([regex]::Matches($Source, 'if\(not CheckZYLIdentityConfig\(\)\) then').Count -lt 2) {
        $issues.Add('Identity configuration must block both normal auto-start and host force-start paths.')
    }

    foreach ($requiredLifecycleFragment in @(
            'local function RefreshTickSettings()',
            'if now < g_last_tick_time + g_tick_size then',
            'Events.GameCoreEventPublishComplete.Remove(OnTick);',
            'LuaEvents.Multiplayer_ExitShell.Remove(OnHandleExitRequest);',
            'if GameConfiguration.GetValue(key) ~= value then',
            'local ZYL_NATIVE_PRINT = print',
            'local function ZYLDebugLog(...)',
            'local banFormat = GameConfiguration.GetValue("CPL_BAN_FORMAT")',
            'local previousStatus = player.Status',
            'local isConnected = Network.IsPlayerConnected(player.ID)',
            'for index = #shuffledVersion, 2, -1 do',
            'local swapIndex = math.random(index)'
        )) {
        if (-not $Source.Contains($requiredLifecycleFragment)) {
            $issues.Add("Staging-room refresh/lifecycle guard is missing: $requiredLifecycleFragment")
        }
    }
    foreach ($forbiddenFragment in @(
            "function OnTick()`r`n`tQuickRefresh()",
            "function OnTick()`n`tQuickRefresh()",
            'return fasle;',
            'local b_debug = true',
            'GameConfiguration.SetValue("MOD_BSM_ID",false)',
            'PlayerConfigurations[0]:SetValue("NICK_NAME","paf")',
            'g_test = GetNextID()',
            'local random_index = 1 + math.random (left_to_do)',
            'if Network.IsPlayerConnected(player.ID) and (g_phase == PHASE_DEFAULT or g_phase == PHASE_INIT) then',
            'function CheckStatusID(',
            'function ResetStatus_SpecificID(',
            'function OnGameSummaryTabClicked(',
            'function OnFriendsTabClicked('
        )) {
        if ($Source.Contains($forbiddenFragment)) {
            $issues.Add("Staging-room regression restored a hot-loop or typo: $forbiddenFragment")
        }
    }

    $quickRefreshMatch = [regex]::Match(
        $Source,
        '(?s)function QuickRefresh\(\)(.*?)\nend\s*\n\s*function Refresh\(\)'
    )
    $fullRefreshMatch = [regex]::Match(
        $Source,
        '(?s)function Refresh\(\)(.*?)\nend\s*\n\s*function OnHostLaunch\(\)'
    )
    if (-not $quickRefreshMatch.Success -or
            -not $fullRefreshMatch.Success -or
            [regex]::Matches(
                $quickRefreshMatch.Value,
                'GameConfiguration\.GetValue\("CPL_BAN_FORMAT"\)'
            ).Count -ne 1 -or
            [regex]::Matches(
                $fullRefreshMatch.Value,
                'GameConfiguration\.GetValue\("CPL_BAN_FORMAT"\)'
            ).Count -ne 1 -or
            [regex]::Matches(
                $fullRefreshMatch.Value,
                'GameConfiguration\.GetValue\("DRAFT_(?:SLOT_ORDER|TIMER)"\)'
            ).Count -ne 0 -or
            -not $fullRefreshMatch.Value.Contains('RefreshTickSettings()')) {
        $issues.Add('Staging-room periodic refresh restored duplicate tournament-setting reads.')
    }

    $refreshStatusMatch = [regex]::Match(
        $Source,
        '(?s)function RefreshStatus\(\)(.*?)\nend\s*\n\s*function OnModCheck\(\)'
    )
    if (-not $refreshStatusMatch.Success -or
            [regex]::Matches(
                $refreshStatusMatch.Value,
                'Network\.IsPlayerConnected\(player\.ID\)'
            ).Count -ne 1 -or
            [regex]::Matches(
                $refreshStatusMatch.Value,
                'UpdatePlayerEntry\(player\.ID\)'
            ).Count -ne 1 -or
            -not [regex]::IsMatch(
                $refreshStatusMatch.Value,
                '(?s)local previousStatus = player\.Status\s*' +
                'local isConnected = Network\.IsPlayerConnected\(player\.ID\).*?' +
                'if isConnected and player\.Status ~= previousStatus\s*' +
                'and \(g_phase == PHASE_DEFAULT or g_phase == PHASE_INIT\) then\s*' +
                'UpdatePlayerEntry\(player\.ID\)'
            )) {
        $issues.Add('Staging-room handshake polling must update player cards only on status transitions.')
    }

    foreach ($lifecycleIssue in @(Get-ZylLuaEventLifecycleIssues `
            -Source $Source `
            -Label 'Staging room')) {
        $issues.Add($lifecycleIssue)
    }
    if ([regex]::Matches($Source, '(?<![A-Za-z0-9_])print\s*\(').Count -ne 0) {
        $issues.Add('Staging room bypasses its opt-in debug logger with a direct print call.')
    }
    if ([regex]::Matches($Source, ',\s*GetNextID\s*\(\s*\)').Count -ne 0) {
        $issues.Add('Staging-room debug logging must not call the stateful GetNextID function.')
    }
    if (-not [regex]::IsMatch(
            $Source,
            '(?s)function OnZYLRandomTeams\(\).*?' +
            'for index, playerID in ipairs\(participants\) do\s*' +
            'PlayerConfigurations\[playerID\]:SetTeam\(\(index - 1\) % 2\)\s*' +
            'end\s*Network\.BroadcastPlayerInfo\(\)'
        )) {
        $issues.Add('Random-team assignment must batch all team mutations into one PlayerInfo broadcast.')
    }
    if (-not [regex]::IsMatch(
            $Source,
            '(?s)m_LeaderBan = GetShuffledCopyOfTable\(m_LeaderBan\).*?' +
            'for _, leader in ipairs\(m_LeaderBan\) do.*?' +
            'leader_rand = leader\.LeaderType\s*break'
        )) {
        $issues.Add('Forced random leader selection must consume the shuffled array in order.')
    }
    if (-not [regex]::IsMatch(
            $Source,
            '(?s)function OnZYLToggleEmptySlots\(\).*?' +
            'for _, playerID in ipairs\(openSlots\) do\s*' +
            'PlayerConfigurations\[playerID\]:SetSlotStatus\(SlotStatus\.SS_CLOSED\)\s*' +
            'end\s*Network\.BroadcastPlayerInfo\(\)'
        )) {
        $issues.Add('Bulk empty-slot closure must batch all slot mutations into one PlayerInfo broadcast.')
    }
    if ($Source.Contains('function Anonymise()')) {
        $issues.Add('Staging room restored the unused full-roster Anonymise implementation.')
    }
    if (-not [regex]::IsMatch(
            $Source,
            '(?s)function Anonymise_ID\(playerID:number\)\s*' +
            'local playerConfig = PlayerConfigurations\[playerID\]\s*' +
            'if playerConfig == nil or not Network\.IsPlayerConnected\(playerID\) then\s*' +
            'return\s*end'
        )) {
        $issues.Add('Per-player anonymisation must directly index and validate the requested player configuration.')
    }

    return @($issues)
}
