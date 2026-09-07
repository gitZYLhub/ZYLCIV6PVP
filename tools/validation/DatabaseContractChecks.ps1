function Get-ZylEraDurationSqlIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [string]$Label = 'Optional world-era duration SQL'
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $fixedEraDurations = [ordered]@{
        'ERA_ANCIENT' = 50
        'ERA_CLASSICAL' = 46
        'ERA_MEDIEVAL' = 46
        'ERA_RENAISSANCE' = 42
        'ERA_INDUSTRIAL' = 42
        'ERA_MODERN' = 40
        'ERA_ATOMIC' = 40
        'ERA_INFORMATION' = 40
    }
    foreach ($fixedEraDuration in $fixedEraDurations.GetEnumerator()) {
        $durationPattern = "WHEN\s+'$([regex]::Escape($fixedEraDuration.Key))'\s+THEN\s+$($fixedEraDuration.Value)"
        if ([regex]::Matches(
                $Source,
                $durationPattern,
                [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
            ).Count -ne 2) {
            $issues.Add(
                "$Label must set both minimum and maximum for " +
                "$($fixedEraDuration.Key) to $($fixedEraDuration.Value)."
            )
        }
    }
    if ($Source -notmatch 'GameEraMinimumTurns' -or
            $Source -notmatch 'GameEraMaximumTurns') {
        $issues.Add("$Label must set both the minimum and maximum duration columns.")
    }
    return @($issues)
}

function Get-ZylEraConfigurationContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [AllowNull()]
        [System.Xml.XmlDocument]$ZylConfig
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $eraLengthSqlPath = Join-Path $ProjectRoot 'sql\ZYL_EraLengthOptimization.sql'
    if (-not (Test-Path -LiteralPath $eraLengthSqlPath -PathType Leaf)) {
        $issues.Add('The optional world-era duration SQL is missing.')
    }
    else {
        $eraLengthSource = Get-Content -Raw -LiteralPath $eraLengthSqlPath
        foreach ($issue in @(Get-ZylEraDurationSqlIssues -Source $eraLengthSource)) {
            $issues.Add($issue)
        }
    }

    $eraThresholdSqlPath = Join-Path $ProjectRoot 'Components\BBG\sql\XP1\Other_XP1_or_XP2.sql'
    if (-not (Test-Path -LiteralPath $eraThresholdSqlPath -PathType Leaf)) {
        $issues.Add('The BBG era-threshold SQL is missing.')
    }
    else {
        $eraThresholdSource = Get-Content -Raw -LiteralPath $eraThresholdSqlPath
        foreach ($requiredEraThreshold in @(
                "UPDATE GlobalParameters SET Value=20 WHERE Name='DARK_AGE_SCORE_BASE_THRESHOLD';",
                "UPDATE GlobalParameters SET Value=25 WHERE Name='GOLDEN_AGE_SCORE_BASE_THRESHOLD';"
            )) {
            if (-not $eraThresholdSource.Contains($requiredEraThreshold)) {
                $issues.Add("The final era-threshold override is missing: $requiredEraThreshold")
            }
        }
    }

    if ($null -ne $ZylConfig) {
        $eraLengthOptions = @(
            $ZylConfig.SelectNodes(
                '/GameInfo/Parameters/Row[@ParameterId="ZYL_ERA_LENGTH_OPTIMIZATION"]'
            )
        )
        if ($eraLengthOptions.Count -ne 2 -or
                @($eraLengthOptions | Where-Object {
                    $_.GetAttribute('DefaultValue') -ne '1'
                }).Count -gt 0 -or
                @($eraLengthOptions | Where-Object {
                    $_.GetAttribute('Key2') -in @('RULESET_EXPANSION_1', 'RULESET_EXPANSION_2')
                }).Count -ne 2) {
            $issues.Add(
                'The optional world-era duration lobby toggle must exist for both ' +
                'expansion rulesets and default to enabled.'
            )
        }
    }

    $eraLengthCriterion = $ModInfo.SelectSingleNode(
        '/Mod/ActionCriteria/Criteria[@id="ZYL_EraLengthOptimization" and ' +
        'RuleSetInUse="RULESET_EXPANSION_1,RULESET_EXPANSION_2" and ' +
        'ConfigurationValueMatches[ConfigurationId="ZYL_ERA_LENGTH_OPTIMIZATION" and Value="1"]]'
    )
    if ($null -eq $eraLengthCriterion) {
        $issues.Add('The optional world-era duration action criterion is missing or malformed.')
    }
    $eraLengthAction = $ModInfo.SelectSingleNode(
        '/Mod/InGameActions/UpdateDatabase[@id="ZYL_EraLengthOptimization" and ' +
        'Criteria="ZYL_EraLengthOptimization" and File="sql/ZYL_EraLengthOptimization.sql"]'
    )
    if ($null -eq $eraLengthAction) {
        $issues.Add('The optional world-era duration gameplay action is missing or malformed.')
    }

    foreach ($timerTextPath in @('lang\Text_CN.xml', 'lang\Text_EN.xml')) {
        $fullTimerTextPath = Join-Path $ProjectRoot $timerTextPath
        if (-not (Test-Path -LiteralPath $fullTimerTextPath -PathType Leaf)) {
            continue
        }
        $timerText = Load-XmlDocument $fullTimerTextPath
        foreach ($timerTag in @(
                'TIMER_CASUAL_BALANCED_NAME',
                'TIMER_CASUAL_BALANCED_DESC',
                'TIMER_CASUAL_RELAXED_NAME',
                'TIMER_CASUAL_RELAXED_DESC'
            )) {
            if ($null -eq $timerText.SelectSingleNode(
                    "/GameData/LocalizedText/Replace[@Tag='$timerTag']/Text"
                )) {
                $issues.Add("$timerTextPath is missing $timerTag.")
            }
        }
    }
    return @($issues)
}
