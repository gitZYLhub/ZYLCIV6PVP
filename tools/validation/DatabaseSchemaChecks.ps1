function Get-ZylCiv6SchemaSnapshotIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Snapshot
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Snapshot.schemaVersion -ne 1 -or
            [string]$Snapshot.civ6AppId -ne '289070' -or
            [string]$Snapshot.civ6BuildId -notmatch '^\d+$' -or
            [string]$Snapshot.generator -ne 'tools/schema/export_civ6_schema_keys.py') {
        $issues.Add('Civ VI schema-key snapshot metadata is invalid.')
    }

    $sourcePathSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($sourceFile in @($Snapshot.sourceFiles)) {
        $path = [string]$sourceFile.path
        if ([string]::IsNullOrWhiteSpace($path) -or
                [System.IO.Path]::IsPathRooted($path) -or
                $path.Contains('\') -or
                -not $sourcePathSet.Add($path) -or
                [string]$sourceFile.sha256 -notmatch '^[0-9a-f]{64}$') {
            $issues.Add("Civ VI schema-key snapshot has an invalid source entry: $path")
        }
    }

    $requiredProfiles = @(
        'configuration',
        'gameplay-base',
        'gameplay-xp1',
        'gameplay-xp2'
    )
    foreach ($profileName in $requiredProfiles) {
        $profileProperty = $Snapshot.profiles.PSObject.Properties[$profileName]
        if ($null -eq $profileProperty) {
            $issues.Add("Civ VI schema-key snapshot is missing profile: $profileName")
            continue
        }
        $tableProperties = @($profileProperty.Value.PSObject.Properties)
        if ([int]$Snapshot.profileTableCounts.$profileName -ne $tableProperties.Count) {
            $issues.Add("Civ VI schema-key snapshot table count drifted for $profileName.")
        }
        $tableSet = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )
        foreach ($tableProperty in $tableProperties) {
            $tableName = [string]$tableProperty.Name
            $table = $tableProperty.Value
            if (-not $tableSet.Add($tableName)) {
                $issues.Add("Civ VI schema-key snapshot repeats table $tableName in $profileName.")
                continue
            }
            $columnSet = [System.Collections.Generic.HashSet[string]]::new(
                [System.StringComparer]::OrdinalIgnoreCase
            )
            foreach ($column in @($table.columns)) {
                if ([string]::IsNullOrWhiteSpace([string]$column) -or
                        -not $columnSet.Add([string]$column)) {
                    $issues.Add("Civ VI schema-key snapshot has invalid columns for $profileName/$tableName.")
                }
            }
            if ($columnSet.Count -eq 0) {
                $issues.Add("Civ VI schema-key snapshot has no columns for $profileName/$tableName.")
            }
            foreach ($key in @(@($table.primaryKey)) + @($table.uniqueKeys)) {
                $keyColumns = @($key)
                $keySet = [System.Collections.Generic.HashSet[string]]::new(
                    [System.StringComparer]::OrdinalIgnoreCase
                )
                foreach ($keyColumn in $keyColumns) {
                    if (-not $columnSet.Contains([string]$keyColumn) -or
                            -not $keySet.Add([string]$keyColumn)) {
                        $issues.Add("Civ VI schema-key snapshot has invalid key columns for $profileName/$tableName.")
                    }
                }
            }
        }
    }

    $gameplayTableNames = @(
        foreach ($profileName in @('gameplay-base', 'gameplay-xp1', 'gameplay-xp2')) {
            $profileProperty = $Snapshot.profiles.PSObject.Properties[$profileName]
            if ($null -ne $profileProperty) {
                $profileProperty.Value.PSObject.Properties.Name
            }
        }
    ) | Sort-Object -Unique
    foreach ($tableName in $gameplayTableNames) {
        $primaryKeys = @(
            foreach ($profileName in @('gameplay-base', 'gameplay-xp1', 'gameplay-xp2')) {
                $profileProperty = $Snapshot.profiles.PSObject.Properties[$profileName]
                if ($null -ne $profileProperty -and
                        $null -ne $profileProperty.Value.PSObject.Properties[$tableName]) {
                    @($profileProperty.Value.$tableName.primaryKey) -join '|'
                }
            }
        ) | Sort-Object -Unique
        if ($primaryKeys.Count -gt 1) {
            $issues.Add("Civ VI gameplay primary key differs across rulesets for table $tableName.")
        }
    }
    return @($issues)
}

function Get-ZylDatabaseSchemaCoverage {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Analysis,

        [Parameter(Mandatory = $true)]
        [object]$Snapshot
    )

    $records = [System.Collections.Generic.List[object]]::new()
    foreach ($table in @($Analysis.tables)) {
        $schemaProfiles = [System.Collections.Generic.List[string]]::new()
        if ($table.scopes -contains 'frontend' -and
                $null -ne $Snapshot.profiles.configuration.PSObject.Properties[$table.table]) {
            $schemaProfiles.Add('configuration')
        }
        if ($table.scopes -contains 'ingame') {
            foreach ($profileName in @('gameplay-base', 'gameplay-xp1', 'gameplay-xp2')) {
                if ($null -ne $Snapshot.profiles.$profileName.PSObject.Properties[$table.table]) {
                    $schemaProfiles.Add($profileName)
                }
            }
        }
        $primaryKeyVariants = @(
            @(
                foreach ($profileName in $schemaProfiles) {
                    @($Snapshot.profiles.$profileName.PSObject.Properties[$table.table].Value.primaryKey) -join '|'
                }
            ) | Sort-Object -Unique
        )
        $primaryKey = if ($primaryKeyVariants.Count -eq 1 -and
                -not [string]::IsNullOrWhiteSpace($primaryKeyVariants[0])) {
            @($primaryKeyVariants[0].Split('|'))
        }
        else {
            @()
        }
        $createdByMod = if ($table.operationCounts -is [System.Collections.IDictionary]) {
            $table.operationCounts.Contains('create-table')
        }
        else {
            $null -ne $table.operationCounts.PSObject.Properties['create-table']
        }
        $classification = if ($schemaProfiles.Count -gt 0) {
            'official'
        }
        elseif ($createdByMod) {
            'mod-created'
        }
        else {
            'external'
        }
        $records.Add([pscustomobject][ordered]@{
            table = [string]$table.table
            classification = $classification
            scopes = @($table.scopes)
            schemaProfiles = @($schemaProfiles)
            primaryKey = @($primaryKey)
            sources = @($table.sources)
        })
    }
    return [pscustomobject][ordered]@{
        counts = [pscustomobject][ordered]@{
            tables = $records.Count
            official = @($records | Where-Object classification -eq 'official').Count
            modCreated = @($records | Where-Object classification -eq 'mod-created').Count
            external = @($records | Where-Object classification -eq 'external').Count
            officialWithPrimaryKey = @($records | Where-Object {
                    $_.classification -eq 'official' -and $_.primaryKey.Count -gt 0
                }).Count
        }
        tables = @($records)
        externalTables = @($records | Where-Object classification -eq 'external')
    }
}

function Get-ZylExternalDatabaseTableIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Analysis,

        [Parameter(Mandatory = $true)]
        [object]$Coverage,

        [Parameter(Mandatory = $true)]
        [object]$Contract
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Contract.schemaVersion -ne 1) {
        $issues.Add('External database-table contract schemaVersion must be 1.')
        return @($issues)
    }
    $expectedNames = @($Contract.tables | ForEach-Object table | Sort-Object -Unique)
    $actualNames = @($Coverage.externalTables | ForEach-Object table | Sort-Object -Unique)
    if (($actualNames -join '|') -ne ($expectedNames -join '|')) {
        $issues.Add(
            "External database tables drifted: actual [$($actualNames -join ', ')], " +
            "expected [$($expectedNames -join ', ')]."
        )
    }
    foreach ($definition in @($Contract.tables)) {
        if ([string]::IsNullOrWhiteSpace([string]$definition.table) -or
                [string]$definition.scope -notin @('frontend', 'ingame') -or
                @($definition.providerCriteria).Count -eq 0 -or
                @($definition.providerModIds).Count -eq 0) {
            $issues.Add("External database-table contract entry is incomplete: $($definition.table)")
            continue
        }
        $coverageRecord = @($Coverage.externalTables | Where-Object table -eq $definition.table)
        if ($coverageRecord.Count -ne 1 -or
                $coverageRecord[0].scopes -notcontains [string]$definition.scope) {
            $issues.Add("External database-table scope drifted for $($definition.table).")
            continue
        }
        foreach ($sourcePath in @($coverageRecord[0].sources)) {
            $sourceFile = @($Analysis.sourceFiles | Where-Object path -eq $sourcePath)
            if ($sourceFile.Count -ne 1) {
                $issues.Add("External database-table source is missing from analysis: $sourcePath")
                continue
            }
            foreach ($reference in @($sourceFile[0].references | Where-Object {
                        $_.scope -eq [string]$definition.scope
                    })) {
                if (@($reference.criteria | Where-Object {
                            $definition.providerCriteria -contains $_
                        }).Count -eq 0) {
                    $issues.Add(
                        "External database-table source $sourcePath is not gated by its provider " +
                        "for action $($reference.actionId)."
                    )
                }
            }
        }
    }
    return @($issues)
}
