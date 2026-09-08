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

function Get-ZylVotePanelContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFragment in @(
            'local b_remap_armed = false',
            'local function SetRefreshTracking(enabled)',
            'local tick = Automation.GetTime()',
            'SetRefreshTracking(true)',
            'SetRefreshTracking(false)',
            'if GameConfiguration.GetValue("GAME_HOST_IS_JUST_RELOADING") ~= "Y" then'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("The remap/vote panel is missing its network lifecycle guard: $requiredFragment")
        }
    }
    foreach ($forbiddenFragment in @('b_RemapArmed', 'local tick_2')) {
        if ($Source.Contains($forbiddenFragment)) {
            $issues.Add("The remap/vote panel restored a global typo or dead timer: $forbiddenFragment")
        }
    }
    if ([regex]::IsMatch(
            $Source,
            '(?s)Network\.BroadcastGameConfig\(\);\s*' +
            'Network\.BroadcastPlayerInfo\(\);\s*' +
            'Network\.BroadcastGameConfig\(\);'
        )) {
        $issues.Add('The remap/vote panel restored its repeated GameConfig/PlayerInfo broadcast burst.')
    }
    if ([regex]::Matches(
            $Source,
            'GameCoreEventPublishComplete\.Add\(OnRefresh\)'
        ).Count -ne 1 -or
            [regex]::Matches(
                $Source,
                'GameCoreEventPublishComplete\.Remove\(OnRefresh\)'
            ).Count -ne 1) {
        $issues.Add('The remap/vote refresh callback must have exactly one guarded add/remove implementation.')
    }
    if (-not [regex]::IsMatch(
            $Source,
            '(?s)function OnLocalHostRestart\(\).*?' +
            'if localID ~= hostID then.*?return.*?' +
            'SetRefreshTracking\(true\).*?Network\.RestartGame\(\)'
        )) {
        $issues.Add('Only the current host may start a remap, and refresh tracking must be armed before restart.')
    }
    return @($issues)
}

function Get-ZylDropControlContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFragment in @(
            'local UIEvents = ExposedMembers.LuaEvents;',
            'local UpdateData',
            'not UpdateData(playerID, true)',
            'UpdateData(playerID, false)',
            'if player.IsDropped == true then',
            'player.ElapsedTime = 0',
            'RestoreHostPauseState()'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("The drop controller is missing its idempotency or pause-state guard: $requiredFragment")
        }
    }
    if (-not [regex]::IsMatch(
            $Source,
            '(?s)function OnShutdown\(\).*?' +
            'SetTicking\(false\).*?RestoreHostPauseState\(\)'
        )) {
        $issues.Add('The drop controller does not return a suite-requested pause during shutdown.')
    }
    if ([regex]::Matches(
            $Source,
            'GameCoreEventPublishComplete\.Add\s*\(\s*OnTimeTicks\s*\)'
        ).Count -ne 1 -or
            [regex]::Matches(
                $Source,
                'GameCoreEventPublishComplete\.Remove\s*\(\s*OnTimeTicks\s*\)'
            ).Count -ne 1) {
        $issues.Add('The drop controller timer must have exactly one guarded add/remove implementation.')
    }
    foreach ($printIssue in @(Get-ZylLuaUnguardedPrintIssues `
            -Source $Source `
            -Label 'Drop controller')) {
        $issues.Add($printIssue)
    }
    if ([regex]::IsMatch($Source, '(?m)^UIEvents\s*=')) {
        $issues.Add('The drop controller restored a global UIEvents alias.')
    }
    return @($issues)
}

function Get-ZylResyncControllerContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFragment in @(
            'local function SetResyncTicking(enabled)',
            'Events.SystemUpdateUI.Add(OnResyncTick)',
            'Events.SystemUpdateUI.Remove(OnResyncTick)',
            'if m_lastResyncTickSecond == now then',
            'm_cachedMapFingerprint = ComputeMapFingerprint()',
            'if m_cachedMapFingerprint == nil then',
            'if check_seed == nil then',
            'if b_debug and (string.lower(text)== ".mph_ui_requestsnap"'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("The multiplayer resync controller is missing its throttle/cache/input guard: $requiredFragment")
        }
    }
    foreach ($forbiddenFragment in @(
            'Events.GameCoreEventPublishComplete.Add( OnResyncTick )',
            'print(text)',
            'g_local_turn',
            'g_local_seed',
            '.mph_ui_checkseed_id'
        )) {
        if ($Source.Contains($forbiddenFragment)) {
            $issues.Add("The multiplayer resync controller restored a hot loop, chat log leak or dead seed protocol: $forbiddenFragment")
        }
    }
    if ([regex]::Matches(
            $Source,
            'Events\.SystemUpdateUI\.Add\(OnResyncTick\)'
        ).Count -ne 1 -or
            [regex]::Matches(
                $Source,
                'Events\.SystemUpdateUI\.Remove\(OnResyncTick\)'
            ).Count -ne 1) {
        $issues.Add('The resync timeout must have exactly one guarded SystemUpdateUI add/remove implementation.')
    }
    foreach ($printIssue in @(Get-ZylLuaUnguardedPrintIssues `
            -Source $Source `
            -Label 'Multiplayer options controller')) {
        $issues.Add($printIssue)
    }
    return @($issues)
}

function Get-ZylSuddenDeathContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFragment in @(
            'local function SetTicking(enabled)',
            'if m_lastBroadcastTurn == currentTurn then',
            'm_lastBroadcastTurn = currentTurn',
            'if adjustedTime == nil or adjustedTime <= 0 then',
            'if tmp_AI_ID ~= nil and Players[tmp_AI_ID] ~= nil',
            'SetTicking(false)',
            'SetTicking(true)'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("The sudden-death controller is missing its timer/input guard: $requiredFragment")
        }
    }
    foreach ($forbiddenFragment in @(
            'include("InstanceManager")',
            'include("PopupDialog")',
            'm_elapsed_time = m_elapsed_time',
            'Events.GameCoreEventPublishComplete.Add ( OnTimeTicks )'
        )) {
        if ($Source.Contains($forbiddenFragment)) {
            $issues.Add("The sudden-death controller restored an unused dependency, no-op or unmanaged tick: $forbiddenFragment")
        }
    }
    if ([regex]::Matches(
            $Source,
            'GameCoreEventPublishComplete\.Add\(OnTimeTicks\)'
        ).Count -ne 1 -or
            [regex]::Matches(
                $Source,
                'GameCoreEventPublishComplete\.Remove\(OnTimeTicks\)'
            ).Count -ne 1) {
        $issues.Add('The sudden-death timer must have exactly one guarded add/remove implementation.')
    }
    foreach ($printIssue in @(Get-ZylLuaUnguardedPrintIssues `
            -Source $Source `
            -Label 'Sudden-death controller')) {
        $issues.Add($printIssue)
    }
    return @($issues)
}

function Get-ZylTurnProcessingContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredFragment in @(
            'local MAX_TIME_EXTENSIONS_PER_TURN = 6',
            'local g_timeCommandUses = 0',
            'if g_timeCommandUses >= MAX_TIME_EXTENSIONS_PER_TURN then return end',
            'g_timeCommandUses = g_timeCommandUses + 1',
            'g_timeCommandUses = 0'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("P++ per-turn limit logic is missing: $requiredFragment")
        }
    }
    foreach ($requiredFragment in @(
            'max_cities = math.max(max_cities, city_count)',
            'max_units = math.max(max_units, unit_count)',
            'if timerMode == 8 then',
            'timer = 95 + max_cities * 4 + max_units + g_timeshift',
            'timer = timer + 40',
            'timer = timer + 20'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("Balanced Casual timer logic is missing: $requiredFragment")
        }
    }
    foreach ($requiredFragment in @(
            'if timerMode == 9 then',
            'local delta = g_timeshift',
            'delta = delta - 25',
            'delta = delta + 40',
            'delta = delta + 20',
            'timer = currentTurn + 70 + max_cities * 4 + max_units * 2 + delta'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("Relaxed Casual timer logic is missing: $requiredFragment")
        }
    }
    foreach ($requiredFragment in @(
            'local g_lastAppliedTimerType = nil',
            'local function IsTurnProcessingEnabled()',
            'local timerMode = tonumber(GameConfiguration.GetValue("CPL_SMARTTIMER")) or 1',
            'if timeValue ~= nil and tonumber(GameConfiguration.GetValue("TURN_TIMER_TIME")) ~= tonumber(timeValue) then',
            'if timerType ~= nil and timerType ~= g_lastAppliedTimerType then',
            'if changed then',
            'if g_temporaryNoTimer then return end',
            'local adjustedValue = tonumber(time_value)',
            'SetTicking(false)'
        )) {
        if (-not $Source.Contains($requiredFragment)) {
            $issues.Add("Turn-processing lifecycle or input guard is missing: $requiredFragment")
        }
    }
    foreach ($forbiddenFragment in @('g_startupGateActive', 'UpdateStartupGate')) {
        if ($Source.Contains($forbiddenFragment)) {
            $issues.Add("Turn-processing still references dead startup-gate state: $forbiddenFragment")
        }
    }
    foreach ($printIssue in @(Get-ZylLuaUnguardedPrintIssues `
            -Source $Source `
            -Label 'Turn processing')) {
        $issues.Add($printIssue)
    }
    return @($issues)
}
