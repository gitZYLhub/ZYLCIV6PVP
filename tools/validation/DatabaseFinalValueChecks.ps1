function Get-ZylDatabaseFinalValueContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Contract,

        [Parameter(Mandatory = $true)]
        [object]$ProjectMetadata,

        [Parameter(Mandatory = $true)]
        [object]$DuplicateKeyAllowlist
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Contract.schemaVersion -ne 1) {
        $issues.Add('Database final-value contract schemaVersion must be 1.')
        return @($issues)
    }
    if ([string]$Contract.packageName -ne [string]$ProjectMetadata.packageName -or
            [string]$Contract.semanticVersion -ne [string]$ProjectMetadata.semanticVersion -or
            [string]$Contract.modId -ne [string]$ProjectMetadata.modId -or
            [string]$Contract.civ6BuildId -ne [string]$ProjectMetadata.civ6SchemaBuildId) {
        $issues.Add('Database final-value contract identity drifted from project metadata.')
    }

    $expectedDuplicateKeys = @(
        $DuplicateKeyAllowlist.groups | ForEach-Object {
            ([string]$_.keySha256).ToLowerInvariant()
        } | Sort-Object -Unique
    )
    if ([int]$Contract.coverage.retainedDuplicateKeyGroups -ne $expectedDuplicateKeys.Count -or
            [int]$Contract.coverage.dominatedRows -ne 7 -or
            [int]$Contract.coverage.finalOverrideProbes -ne 8 -or
            [int]$Contract.coverage.totalProbes -ne 28) {
        $issues.Add('Database final-value contract coverage metadata drifted.')
    }

    $profileIds = [System.Collections.Generic.List[string]]::new()
    foreach ($profile in @($Contract.profiles)) {
        $profileId = [string]$profile.id
        if ([string]::IsNullOrWhiteSpace($profileId) -or $profileIds.Contains($profileId)) {
            $issues.Add("Database final-value contract has an invalid profile id: $profileId")
            continue
        }
        $profileIds.Add($profileId)
        if ([string]::IsNullOrWhiteSpace([string]$profile.description)) {
            $issues.Add("Database final-value profile has no description: $profileId")
        }

        $probeIds = [System.Collections.Generic.List[string]]::new()
        $duplicateKeys = [System.Collections.Generic.List[string]]::new()
        $dominatedKeys = [System.Collections.Generic.List[string]]::new()
        $categoryCounts = @{
            'retained-duplicate' = 0
            'dominated-row-regression' = 0
            'final-override' = 0
        }
        foreach ($probe in @($profile.probes)) {
            $probeId = [string]$probe.id
            $category = [string]$probe.category
            $query = [string]$probe.query
            $columns = @($probe.expectedColumns | ForEach-Object { [string]$_ })
            $rows = @($probe.expectedRows)
            if ([string]::IsNullOrWhiteSpace($probeId) -or $probeIds.Contains($probeId)) {
                $issues.Add("Database final-value profile $profileId has an invalid probe id: $probeId")
                continue
            }
            $probeIds.Add($probeId)
            if (-not $categoryCounts.ContainsKey($category)) {
                $issues.Add("Database final-value probe has an invalid category: $probeId/$category")
            }
            else {
                $categoryCounts[$category]++
            }
            if ([string]::IsNullOrWhiteSpace([string]$probe.rationale)) {
                $issues.Add("Database final-value probe has no rationale: $probeId")
            }
            $trimmedQuery = $query.Trim()
            if ($trimmedQuery -notmatch '^(?i:SELECT|WITH)\s' -or
                    $trimmedQuery -notmatch '(?i)\bORDER\s+BY\b' -or
                    $trimmedQuery.TrimEnd(';').Contains(';')) {
                $issues.Add("Database final-value probe is not one deterministic read statement: $probeId")
            }
            if ($columns.Count -eq 0 -or
                    @($columns | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0 -or
                    @($columns | Sort-Object -Unique).Count -ne $columns.Count) {
                $issues.Add("Database final-value probe has invalid expected columns: $probeId")
            }
            foreach ($row in $rows) {
                $rowColumns = @($row.PSObject.Properties | ForEach-Object { $_.Name } | Sort-Object)
                $sortedColumns = @($columns | Sort-Object)
                if (($rowColumns -join '|') -ne ($sortedColumns -join '|')) {
                    $issues.Add("Database final-value probe row shape drifted: $probeId")
                }
            }

            $duplicateKey = [string]$probe.duplicateKeySha256
            $dominatedKey = [string]$probe.dominatedRowKeySha256
            if ($category -eq 'retained-duplicate') {
                if ($duplicateKey -notmatch '^[0-9a-f]{64}$' -or
                        $duplicateKeys.Contains($duplicateKey)) {
                    $issues.Add("Database final-value duplicate coverage is invalid: $probeId")
                }
                else {
                    $duplicateKeys.Add($duplicateKey)
                }
                if (-not [string]::IsNullOrWhiteSpace($dominatedKey)) {
                    $issues.Add("Database final-value retained duplicate has a dominated key: $probeId")
                }
            }
            elseif ($category -eq 'dominated-row-regression') {
                if ($dominatedKey -notmatch '^[0-9a-f]{64}$' -or
                        $dominatedKeys.Contains($dominatedKey)) {
                    $issues.Add("Database final-value dominated-row coverage is invalid: $probeId")
                }
                else {
                    $dominatedKeys.Add($dominatedKey)
                }
                if (-not [string]::IsNullOrWhiteSpace($duplicateKey)) {
                    $issues.Add("Database final-value dominated row has a retained duplicate key: $probeId")
                }
            }
            elseif (-not [string]::IsNullOrWhiteSpace($duplicateKey) -or
                    -not [string]::IsNullOrWhiteSpace($dominatedKey)) {
                $issues.Add("Database final-value override probe unexpectedly claims key coverage: $probeId")
            }
        }

        $actualDuplicateKeys = @($duplicateKeys | Sort-Object -Unique)
        if (($actualDuplicateKeys -join '|') -ne ($expectedDuplicateKeys -join '|')) {
            $issues.Add("Database final-value profile does not exactly cover retained duplicates: $profileId")
        }
        if ($dominatedKeys.Count -ne [int]$Contract.coverage.dominatedRows -or
                @($dominatedKeys | Sort-Object -Unique).Count -ne $dominatedKeys.Count -or
                $categoryCounts['retained-duplicate'] -ne [int]$Contract.coverage.retainedDuplicateKeyGroups -or
                $categoryCounts['dominated-row-regression'] -ne [int]$Contract.coverage.dominatedRows -or
                $categoryCounts['final-override'] -ne [int]$Contract.coverage.finalOverrideProbes -or
                $probeIds.Count -ne [int]$Contract.coverage.totalProbes) {
            $issues.Add("Database final-value profile coverage counts drifted: $profileId")
        }
    }
    if ($profileIds.Count -eq 0 -or
            -not $profileIds.Contains([string]$Contract.defaultProfile)) {
        $issues.Add('Database final-value default profile is missing.')
    }
    return @($issues)
}
