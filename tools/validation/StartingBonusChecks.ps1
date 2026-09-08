function Get-ZylStartingBonusContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [AllowEmptyString()]
        [string]$StartingBonusScriptOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # Lobby parameters and domains select one human slot and one grant type.
    $zylConfigPath = Join-Path $modRoot 'configuration\Config_ZYL.xml'
    if (-not (Test-Path -LiteralPath $zylConfigPath -PathType Leaf)) {
        $issues.Add('The starting-bonus lobby configuration is missing.')
    }
    else {
        $zylConfig = Load-XmlDocument $zylConfigPath
        $startingBonusPlayerParameter = $zylConfig.SelectSingleNode('/GameInfo/Parameters/Row[@ParameterId="ZYL_STARTING_BONUS_PLAYER"]')
        if ($null -eq $startingBonusPlayerParameter -or
                $startingBonusPlayerParameter.GetAttribute('ConfigurationId') -ne 'ZYL_STARTING_BONUS_PLAYER' -or
                $startingBonusPlayerParameter.GetAttribute('Domain') -ne 'ZylStartingBonusPlayers' -or
                $startingBonusPlayerParameter.GetAttribute('DefaultValue') -ne '0' -or
                $startingBonusPlayerParameter.GetAttribute('ChangeableAfterGameStart') -ne '0') {
            $issues.Add('The starting-bonus player lobby option is missing or malformed.')
        }
        $startingBonusTypeParameter = $zylConfig.SelectSingleNode('/GameInfo/Parameters/Row[@ParameterId="ZYL_STARTING_BONUS_TYPE"]')
        if ($null -eq $startingBonusTypeParameter -or
                $startingBonusTypeParameter.GetAttribute('ConfigurationId') -ne 'ZYL_STARTING_BONUS_TYPE' -or
                $startingBonusTypeParameter.GetAttribute('Domain') -ne 'ZylStartingBonusTypes' -or
                $startingBonusTypeParameter.GetAttribute('DefaultValue') -ne '0' -or
                $startingBonusTypeParameter.GetAttribute('ChangeableAfterGameStart') -ne '0') {
            $issues.Add('The starting-bonus type lobby option is missing or malformed.')
        }
        $startingBonusPlayerValues = @(
            $zylConfig.SelectNodes('/GameInfo/DomainValues/Row[@Domain="ZylStartingBonusPlayers"]')
        )
        if ($startingBonusPlayerValues.Count -ne 13) {
            $issues.Add("The starting-bonus player domain must contain None plus players 1-12; found $($startingBonusPlayerValues.Count) rows.")
        }
        foreach ($value in 0..12) {
            if ($null -eq ($startingBonusPlayerValues | Where-Object {
                        $_.GetAttribute('Value') -eq $value.ToString()
                    })) {
                $issues.Add("The starting-bonus player domain is missing value $value.")
            }
        }
        $startingBonusTypeValues = @(
            $zylConfig.SelectNodes('/GameInfo/DomainValues/Row[@Domain="ZylStartingBonusTypes"]')
        )
        if ($startingBonusTypeValues.Count -ne 4) {
            $issues.Add("The starting-bonus type domain must contain exactly four choices; found $($startingBonusTypeValues.Count) rows.")
        }
        foreach ($value in 0..3) {
            if ($null -eq ($startingBonusTypeValues | Where-Object {
                        $_.GetAttribute('Value') -eq $value.ToString()
                    })) {
                $issues.Add("The starting-bonus type domain is missing value $value.")
            }
        }
    }

    $startingBonusScriptPath = Join-Path $modRoot 'scripts\ZYL_StartingPlayerBonus.lua'
    if (-not (Test-Path -LiteralPath $startingBonusScriptPath)) {
        $issues.Add('The starting-player bonus gameplay script is missing.')
    }
    else {
        $startingBonusScript = if ($PSBoundParameters.ContainsKey('StartingBonusScriptOverride')) {
            $StartingBonusScriptOverride
        }
        else {
            Get-Content -LiteralPath $startingBonusScriptPath -Raw
        }
        foreach ($requiredStartingBonusFragment in @(
            'ZYL_STARTING_BONUS_PLAYER',
            'ZYL_STARTING_BONUS_TYPE',
            'ZYL_STARTING_BONUS_APPLIED',
            'candidateConfig:IsHuman()',
            'table.sort(eligiblePlayerIDs)',
            'Game.GetCurrentGameTurn() ~= GameConfiguration.GetStartTurn()',
            'player:SetProperty(APPLIED_PROPERTY, selectedBonus)',
            'playerUnits:Create(unitTypeIndex',
            'GameEvents.OnGameTurnStarted.Add(TryGrantStartingBonus)'
        )) {
            if (-not $startingBonusScript.Contains($requiredStartingBonusFragment)) {
                $issues.Add("Starting-player bonus script is missing: $requiredStartingBonusFragment")
            }
        }
    }

    $startingBonusAction = $actionIdMap['zyl_startingplayerbonusgameplay']
    if ($null -eq $startingBonusAction -or
            $startingBonusAction.LocalName -ne 'AddGameplayScripts' -or
            $startingBonusAction.SelectSingleNode('./File[.="scripts/ZYL_StartingPlayerBonus.lua"]') -eq $null) {
        $issues.Add('The starting-player bonus script is not registered as a gameplay action.')
    }
    if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'scripts/ZYL_StartingPlayerBonus.lua'))) {
    $issues.Add('The starting-player bonus script is absent from the ModInfo file manifest.')
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
        $issues.Add('Initial Settler movement SQL is missing.')
    }
    else {
        $startingSettlerSql = Get-Content -LiteralPath $startingSettlerPath -Raw
        foreach ($startingSettlerModifierId in $startingSettlerModifierIds) {
            if (-not $startingSettlerSql.Contains("'TRAIT_LEADER_MAJOR_CIV', '$startingSettlerModifierId'")) {
                $issues.Add("Initial Settler modifier is not attached to major civilizations: $startingSettlerModifierId")
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
                $issues.Add("Initial Settler SQL is missing required behavior: $requiredStartingSettlerToken")
            }
        }
        if ($startingSettlerSql -notmatch "(?s)'ZYL_REQUIRES_PLAYER_HAS_NO_PALACE',\s*'REQUIREMENT_PLAYER_HAS_AT_LEAST_NUM_BUILDINGS',\s*1") {
            $issues.Add('Initial Settler Palace requirement is not inverted; the bonus would affect later Settlers.')
        }

        $startingSettlerAction = $actionIdMap['zyl_startingsettlermovement']
        if ($null -eq $startingSettlerAction -or
                $startingSettlerAction.SelectSingleNode("./File[.='sql/ZYL_StartingSettler.sql']") -eq $null) {
            $issues.Add('Initial Settler SQL is not loaded by ModInfo.')
        }
        if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'sql/ZYL_StartingSettler.sql'))) {
            $issues.Add('Initial Settler SQL is absent from the ModInfo file manifest.')
        }

    }

    $zylTextPath = Join-Path $modRoot 'lang\ZYL_Text.xml'
    if (Test-Path -LiteralPath $zylTextPath) {
        $zylText = Load-XmlDocument $zylTextPath
        $startingBonusTextTags = @(
            'LOC_ZYL_STARTING_BONUS_PLAYER_NAME',
            'LOC_ZYL_STARTING_BONUS_PLAYER_DESC',
            'LOC_ZYL_STARTING_BONUS_TYPE_NAME',
            'LOC_ZYL_STARTING_BONUS_TYPE_DESC',
            'LOC_ZYL_STARTING_BONUS_NONE',
            'LOC_ZYL_STARTING_BONUS_PLAYER_SLOT_DESC',
            'LOC_ZYL_STARTING_BONUS_BUILDER',
            'LOC_ZYL_STARTING_BONUS_SCOUT',
            'LOC_ZYL_STARTING_BONUS_BUILDER_SCOUT'
        )
        foreach ($language in @('en_US', 'zh_Hans_CN', 'zh_Hant_HK')) {
            foreach ($tag in $startingBonusTextTags) {
                if ($null -eq $zylText.SelectSingleNode("/GameData/LocalizedText/Row[@Tag='$tag' and @Language='$language']/Text")) {
                    $issues.Add("Starting-player bonus localization is missing $tag for $language.")
                }
            }
            foreach ($playerNumber in 1..12) {
                $playerTag = "LOC_ZYL_STARTING_BONUS_PLAYER_$playerNumber"
                if ($null -eq $zylText.SelectSingleNode("/GameData/LocalizedText/Row[@Tag='$playerTag' and @Language='$language']/Text")) {
                    $issues.Add("Starting-player bonus localization is missing $playerTag for $language.")
                }
            }
        }
        foreach ($language in @('en_US', 'zh_Hans_CN', 'zh_Hant_HK')) {
            $settlerText = $zylText.SelectSingleNode("/GameData/LocalizedText/Replace[@Tag='LOC_UNIT_SETTLER_DESCRIPTION' and @Language='$language']/Text")
            if ($null -eq $settlerText -or -not $settlerText.InnerText.Contains('+1 [ICON_Movement]')) {
                $issues.Add("Initial Settler description is missing for $language.")
            }
        }
    }

    return @($issues)
}
