function Get-ZylLeaderVariantContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$ActionIdMap,

        [AllowEmptyString()]
        [string]$GameplaySourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

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
            $issues.Add("Leader variant resource is missing: $leaderVariantPath")
        }
    }

    if (($leaderVariantPaths | Where-Object { -not (Test-Path -LiteralPath $_) }).Count -eq 0) {
        $leaderGameplaySql = if ($PSBoundParameters.ContainsKey('GameplaySourceOverride')) {
            $GameplaySourceOverride
        }
        else {
            Get-Content -LiteralPath $leaderGameplayPath -Raw
        }
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
                $issues.Add("Gameplay SQL does not register $inlandLeader as a leader type.")
            }
            if (-not $leaderGameplaySql.Contains("SELECT '$inlandLeader', TraitType") -or
                    -not $leaderGameplaySql.Contains("FROM LeaderTraits WHERE LeaderType = '$sourceLeader';")) {
                $issues.Add("$inlandLeader no longer clones the final traits of $sourceLeader.")
            }
            $gameplayDuplicatePattern = "\(\s*'$([regex]::Escape($sourceLeader))'\s*,\s*'$([regex]::Escape($inlandLeader))'\s*\)"
            if ($leaderGameplaySql -notmatch $gameplayDuplicatePattern) {
                $issues.Add("$sourceLeader and $inlandLeader are not gameplay duplicate leaders.")
            }
            if (-not $leaderConfigSql.Contains("SELECT Domain, CivilizationType, '$inlandLeader',")) {
                $issues.Add("Config SQL does not clone lobby rows for $inlandLeader.")
            }
            if (-not $leaderConfigSql.Contains("SELECT Map, '$inlandLeader'") -or
                    -not $leaderConfigSql.Contains("source.Type, '$inlandLeader'")) {
                $issues.Add("Config SQL does not preserve true-start-map support for $inlandLeader.")
            }
            if (-not $leaderConfigSql.Contains("AND d.OtherLeaderType = '$inlandLeader'")) {
                $issues.Add("Config duplicate-leader insertion for $inlandLeader is not idempotent.")
            }
            if (-not $leaderTextSql.Contains("instr(Tag, '$inlandLeader') = 0")) {
                $issues.Add("Localization cloning for $inlandLeader can recursively clone itself.")
            }
            $coastalLeader = $inlandLeader.Replace('_INLAND', '_COASTAL')
            if (-not $leaderTextSql.Contains("instr(Tag, '$coastalLeader') = 0")) {
                $issues.Add("Localization cloning for $inlandLeader can recursively clone its coastal label.")
            }
            if (-not $leaderIconSql.Contains("'ICON_$inlandLeader'")) {
                $issues.Add("Icon alias is missing for $inlandLeader.")
            }
            if (-not $leaderColorSql.Contains("SELECT '$inlandLeader', Usage")) {
                $issues.Add("Player-color alias is missing for $inlandLeader.")
            }
        }

        if ($leaderTextSql -match '_INLAND_INLAND|_INLAND_COASTAL') {
            $issues.Add('Recursive inland localization tags are present in leader variant SQL.')
        }
    }

    $leaderArtPaths = @(
        (Join-Path $modRoot 'ArtDefs\ZYL_CoastLeaderVariants_Leaders.artdef'),
        (Join-Path $modRoot 'ArtDefs\ZYL_CoastLeaderVariants_FallbackLeaders.artdef')
    )
    foreach ($leaderArtPath in $leaderArtPaths) {
        if (-not (Test-Path -LiteralPath $leaderArtPath)) {
            $issues.Add("Leader variant ArtDef is missing: $leaderArtPath")
            continue
        }
        $leaderArt = Load-XmlDocument $leaderArtPath
        foreach ($inlandLeader in @('LEADER_HOJO_INLAND', 'LEADER_PHILIP_II_INLAND', 'LEADER_WILHELMINA_INLAND')) {
            if ($null -eq $leaderArt.SelectSingleNode("//*[@text='$inlandLeader']")) {
                $issues.Add("$inlandLeader is missing from $([System.IO.Path]::GetFileName($leaderArtPath)).")
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
            $issues.Add("Leader variant ModInfo action is missing: $actionId")
        }
    }

    $coastBiasLuaPaths = @(
        (Join-Path $modRoot 'Components\BBM\Data\BBS Maps\Utility\BBM_CivilizationAssign.lua'),
        (Join-Path $modRoot 'Components\BBM\Data\BBS Maps\Utility\ZYL_RVC_AssignStartingPlots.lua')
    )
    foreach ($coastBiasLuaPath in $coastBiasLuaPaths) {
        if (-not (Test-Path -LiteralPath $coastBiasLuaPath)) {
            $issues.Add("Coast-bias placement script is missing: $coastBiasLuaPath")
            continue
        }
        $coastBiasLua = Get-Content -LiteralPath $coastBiasLuaPath -Raw
        foreach ($inlandLeader in @('LEADER_HOJO_INLAND', 'LEADER_PHILIP_II_INLAND', 'LEADER_WILHELMINA_INLAND')) {
            if (-not $coastBiasLua.Contains($inlandLeader)) {
                $issues.Add("$inlandLeader is not recognized by $([System.IO.Path]::GetFileName($coastBiasLuaPath)).")
            }
        }
        if (-not $coastBiasLua.Contains('row.TerrainType ~= "TERRAIN_COAST"')) {
            $issues.Add("$([System.IO.Path]::GetFileName($coastBiasLuaPath)) does not filter coast in the Firaxis fallback pass.")
        }
    }
    if (Test-Path -LiteralPath $coastBiasLuaPaths[0]) {
        $bbmCoastBiasLua = Get-Content -LiteralPath $coastBiasLuaPaths[0] -Raw
        if (-not $bbmCoastBiasLua.Contains('and row.TerrainType == "TERRAIN_COAST"')) {
            $issues.Add('BBM placement does not remove the coast row from inland variants.')
        }
    }
    if (Test-Path -LiteralPath $coastBiasLuaPaths[1]) {
        $richMapCoastBiasLua = Get-Content -LiteralPath $coastBiasLuaPaths[1] -Raw
        if (-not $richMapCoastBiasLua.Contains('and not ZYL_IsInlandCoastVariantPlayer(playerID)') -or
                -not $richMapCoastBiasLua.Contains('and not ZYL_IsInlandCoastVariant(civ.LeaderType)')) {
            $issues.Add('Rich Mainland coast/inland distribution categories ignore the leader variant choice.')
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
                $issues.Add("Obsolete leader-only France Luxury bias remains in $([System.IO.Path]::GetFileName($coastBiasLuaPath)): $obsoleteToken")
            }
        }
    }

    return @($issues)
}
