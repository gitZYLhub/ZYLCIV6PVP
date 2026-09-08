function Get-ZylBbgIconContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [AllowNull()]
        [System.Xml.XmlDocument]$IconDocumentOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modRoot = $ProjectRoot

    # Every policy created by BBG needs an icon entry. The stock UI constructs
    # secret-society Governor promotion keys which Firaxis did not ship, so keep
    # explicit aliases for those keys as well. Missing entries flood
    # UserInterface.log and leave blank icons throughout the Civics/Governor UI.
    $bbgIconPath = Join-Path $modRoot 'Components\BBG\data\new_bbg_icons.xml'
    if (-not (Test-Path -LiteralPath $bbgIconPath)) {
        $issues.Add('BBG icon definitions are missing.')
    }
    else {
        $bbgIcons = if ($PSBoundParameters.ContainsKey('IconDocumentOverride')) {
            $IconDocumentOverride
        }
        else {
            Load-XmlDocument $bbgIconPath
        }
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
                $issues.Add("BBG icon alias is missing or targets the wrong stock icon: $($entry.Key) -> $($entry.Value)")
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
                $issues.Add("BBG-created policy has no icon definition or alias: $policyId")
            }
        }

        $bbgIconAction = $modInfo.SelectSingleNode("/Mod/InGameActions/UpdateIcons[File='Components/BBG/data/new_bbg_icons.xml']")
        if ($null -eq $bbgIconAction) {
            $issues.Add('The BBG icon file is not loaded by the expected InGame UpdateIcons action.')
        }
    }

    return @($issues)
}
