function Get-ZylOrdinalSortedUniqueStrings {
    param(
        [AllowEmptyCollection()]
        [object[]]$Values
    )

    $set = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($value in @($Values)) {
        if ($null -eq $value) {
            continue
        }
        $text = ([string]$value).Trim()
        if (-not [string]::IsNullOrWhiteSpace($text)) {
            [void]$set.Add($text)
        }
    }
    $result = [string[]]@($set)
    [System.Array]::Sort($result, [System.StringComparer]::OrdinalIgnoreCase)
    return @($result)
}

function Split-ZylSqlStatements {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Source
    )

    $statements = [System.Collections.Generic.List[object]]::new()
    $buffer = [System.Text.StringBuilder]::new()
    $state = 'normal'
    $line = 1
    $statementLine = 0

    for ($index = 0; $index -lt $Source.Length; $index++) {
        $character = $Source[$index]
        $nextCharacter = if ($index + 1 -lt $Source.Length) {
            $Source[$index + 1]
        }
        else {
            [char]0
        }

        if ($state -eq 'line-comment') {
            if ($character -eq "`n") {
                [void]$buffer.Append($character)
                $line++
                $state = 'normal'
            }
            else {
                [void]$buffer.Append(' ')
            }
            continue
        }
        if ($state -eq 'block-comment') {
            if ($character -eq '*' -and $nextCharacter -eq '/') {
                [void]$buffer.Append('  ')
                $index++
                $state = 'normal'
            }
            elseif ($character -eq "`n") {
                [void]$buffer.Append($character)
                $line++
            }
            else {
                [void]$buffer.Append(' ')
            }
            continue
        }

        if ($state -eq 'single-quote') {
            [void]$buffer.Append($character)
            if ($character -eq "'") {
                if ($nextCharacter -eq "'") {
                    [void]$buffer.Append($nextCharacter)
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            if ($character -eq "`n") {
                $line++
            }
            continue
        }
        if ($state -eq 'double-quote') {
            [void]$buffer.Append($character)
            if ($character -eq '"') {
                if ($nextCharacter -eq '"') {
                    [void]$buffer.Append($nextCharacter)
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            if ($character -eq "`n") {
                $line++
            }
            continue
        }
        if ($state -eq 'backtick-quote') {
            [void]$buffer.Append($character)
            if ($character -eq '`') {
                if ($nextCharacter -eq '`') {
                    [void]$buffer.Append($nextCharacter)
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            if ($character -eq "`n") {
                $line++
            }
            continue
        }
        if ($state -eq 'bracket-quote') {
            [void]$buffer.Append($character)
            if ($character -eq ']') {
                $state = 'normal'
            }
            if ($character -eq "`n") {
                $line++
            }
            continue
        }

        if ($character -eq '-' -and $nextCharacter -eq '-') {
            [void]$buffer.Append('  ')
            $index++
            $state = 'line-comment'
            continue
        }
        if ($character -eq '/' -and $nextCharacter -eq '*') {
            [void]$buffer.Append('  ')
            $index++
            $state = 'block-comment'
            continue
        }
        if ($statementLine -eq 0 -and -not [char]::IsWhiteSpace($character) -and
                $character -ne ';') {
            $statementLine = $line
        }
        if ($character -eq "'") {
            $state = 'single-quote'
            [void]$buffer.Append($character)
            continue
        }
        if ($character -eq '"') {
            $state = 'double-quote'
            [void]$buffer.Append($character)
            continue
        }
        if ($character -eq '`') {
            $state = 'backtick-quote'
            [void]$buffer.Append($character)
            continue
        }
        if ($character -eq '[') {
            $state = 'bracket-quote'
            [void]$buffer.Append($character)
            continue
        }
        if ($character -eq ';') {
            $statement = $buffer.ToString().Trim()
            if (-not [string]::IsNullOrWhiteSpace($statement)) {
                $statements.Add([pscustomobject][ordered]@{
                    line = $statementLine
                    text = $statement
                })
            }
            [void]$buffer.Clear()
            $statementLine = 0
            continue
        }

        [void]$buffer.Append($character)
        if ($character -eq "`n") {
            $line++
        }
    }

    $lastStatement = $buffer.ToString().Trim()
    if (-not [string]::IsNullOrWhiteSpace($lastStatement)) {
        $statements.Add([pscustomobject][ordered]@{
            line = $statementLine
            text = $lastStatement
        })
    }
    return @($statements)
}

function ConvertFrom-ZylSqlIdentifier {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identifier
    )

    $value = $Identifier.Trim()
    if ($value.Length -ge 2) {
        if ($value[0] -eq '"' -and $value[$value.Length - 1] -eq '"') {
            return $value.Substring(1, $value.Length - 2).Replace('""', '"')
        }
        if ($value[0] -eq "'" -and $value[$value.Length - 1] -eq "'") {
            return $value.Substring(1, $value.Length - 2).Replace("''", "'")
        }
        if ($value[0] -eq '[' -and $value[$value.Length - 1] -eq ']') {
            return $value.Substring(1, $value.Length - 2)
        }
        if ($value[0] -eq '`' -and $value[$value.Length - 1] -eq '`') {
            return $value.Substring(1, $value.Length - 2).Replace('``', '`')
        }
    }
    return $value
}

function Get-ZylDatabaseStatementSha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Statement
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Statement.Trim())
        return ([System.BitConverter]::ToString(
            $sha256.ComputeHash($bytes)
        )).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-ZylSqlWriteOperations {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Source
    )

    $identifierPattern = '(?<table>"(?:[^"]|"")+"|''(?:[^'']|'''')+''|\[[^\]]+\]|`(?:[^`]|``)+`|[A-Za-z_][A-Za-z0-9_.$]*)'
    $conflictPattern = '(?<conflict>ROLLBACK|ABORT|REPLACE|FAIL|IGNORE)'
    $patterns = @(
        [pscustomobject]@{
            operation = 'insert'
            pattern = "(?is)^\s*INSERT\s+(?:OR\s+$conflictPattern\s+)?INTO\s+$identifierPattern"
        },
        [pscustomobject]@{
            operation = 'replace'
            pattern = "(?is)^\s*REPLACE\s+INTO\s+$identifierPattern"
        },
        [pscustomobject]@{
            operation = 'update'
            pattern = "(?is)^\s*UPDATE\s+(?:OR\s+$conflictPattern\s+)?$identifierPattern\s+SET\b"
        },
        [pscustomobject]@{
            operation = 'delete'
            pattern = "(?is)^\s*DELETE\s+FROM\s+$identifierPattern"
        },
        [pscustomobject]@{
            operation = 'create-table'
            pattern = "(?is)^\s*CREATE\s+(?:TEMP(?:ORARY)?\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?$identifierPattern"
        },
        [pscustomobject]@{
            operation = 'drop-table'
            pattern = "(?is)^\s*DROP\s+TABLE\s+(?:IF\s+EXISTS\s+)?$identifierPattern"
        },
        [pscustomobject]@{
            operation = 'alter-table'
            pattern = "(?is)^\s*ALTER\s+TABLE\s+$identifierPattern"
        }
    )

    $operations = [System.Collections.Generic.List[object]]::new()
    foreach ($statement in @(Split-ZylSqlStatements -Source $Source)) {
        $matchedOperation = $false
        foreach ($specification in $patterns) {
            $match = [regex]::Match($statement.text, $specification.pattern)
            if (-not $match.Success) {
                continue
            }
            $conflictMode = $null
            if ($match.Groups['conflict'].Success) {
                $conflictMode = $match.Groups['conflict'].Value.ToLowerInvariant()
            }
            elseif ($specification.operation -eq 'replace') {
                $conflictMode = 'replace'
            }
            $operations.Add([pscustomobject][ordered]@{
                line = [int]$statement.line
                operation = [string]$specification.operation
                conflictMode = $conflictMode
                table = ConvertFrom-ZylSqlIdentifier -Identifier $match.Groups['table'].Value
                statementSha256 = Get-ZylDatabaseStatementSha256 -Statement $statement.text
            })
            $matchedOperation = $true
            break
        }
        if (-not $matchedOperation) {
            $leadingVerbMatch = [regex]::Match(
                $statement.text,
                '(?is)^\s*(?<verb>INSERT|REPLACE|UPDATE|DELETE|CREATE|DROP|ALTER)\b'
            )
            if ($leadingVerbMatch.Success) {
                $operations.Add([pscustomobject][ordered]@{
                    line = [int]$statement.line
                    operation = 'unknown:' + $leadingVerbMatch.Groups['verb'].Value.ToLowerInvariant()
                    conflictMode = $null
                    table = ''
                    statementSha256 = Get-ZylDatabaseStatementSha256 -Statement $statement.text
                })
            }
        }
    }
    return @($operations)
}

function Get-ZylXmlWriteOperations {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$Document
    )

    $operationMap = @{
        'row' = [pscustomobject]@{ operation = 'insert'; conflictMode = $null }
        'insertorignore' = [pscustomobject]@{ operation = 'insert'; conflictMode = 'ignore' }
        'replace' = [pscustomobject]@{ operation = 'replace'; conflictMode = 'replace' }
        'update' = [pscustomobject]@{ operation = 'update'; conflictMode = $null }
        'delete' = [pscustomobject]@{ operation = 'delete'; conflictMode = $null }
    }
    $operations = [System.Collections.Generic.List[object]]::new()
    foreach ($tableNode in @($Document.DocumentElement.ChildNodes | Where-Object NodeType -eq Element)) {
        foreach ($operationNode in @($tableNode.ChildNodes | Where-Object NodeType -eq Element)) {
            $operationKey = $operationNode.LocalName.ToLowerInvariant()
            if (-not $operationMap.ContainsKey($operationKey)) {
                $operations.Add([pscustomobject][ordered]@{
                    line = $null
                    operation = 'unknown:' + $operationNode.LocalName
                    conflictMode = $null
                    table = $tableNode.LocalName
                    statementSha256 = $null
                })
                continue
            }
            $definition = $operationMap[$operationKey]
            $operations.Add([pscustomobject][ordered]@{
                line = $null
                operation = [string]$definition.operation
                conflictMode = $definition.conflictMode
                table = $tableNode.LocalName
                statementSha256 = $null
            })
        }
    }
    return @($operations)
}

function Get-ZylDatabaseActionReferences {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo
    )

    $references = [System.Collections.Generic.List[object]]::new()
    foreach ($sectionDefinition in @(
            [pscustomobject]@{ name = 'FrontEndActions'; scope = 'frontend' },
            [pscustomobject]@{ name = 'InGameActions'; scope = 'ingame' }
        )) {
        $section = $ModInfo.SelectSingleNode('/Mod/' + $sectionDefinition.name)
        if ($null -eq $section) {
            continue
        }
        $actionIndex = 0
        $databaseActionIndex = 0
        foreach ($action in @($section.ChildNodes | Where-Object NodeType -eq Element)) {
            $actionIndex++
            if ($action.LocalName -ne 'UpdateDatabase') {
                continue
            }
            $databaseActionIndex++
            $criteria = [System.Collections.Generic.List[string]]::new()
            foreach ($attribute in @($action.Attributes)) {
                if ($attribute.LocalName -ieq 'criteria') {
                    $criteria.Add($attribute.Value)
                }
            }
            foreach ($criterionNode in @($action.SelectNodes('./Criteria'))) {
                $criteria.Add($criterionNode.InnerText)
            }
            $fileIndex = 0
            foreach ($fileNode in @($action.SelectNodes('./File'))) {
                $fileIndex++
                $references.Add([pscustomobject][ordered]@{
                    scope = [string]$sectionDefinition.scope
                    actionId = [string]$action.GetAttribute('id')
                    actionIndex = $actionIndex
                    databaseActionIndex = $databaseActionIndex
                    fileIndex = $fileIndex
                    criteria = @(Get-ZylOrdinalSortedUniqueStrings -Values @($criteria))
                    path = $fileNode.InnerText.Replace('\', '/').Trim()
                })
            }
        }
    }
    return @($references)
}

function Get-ZylSameActionExactSqlDuplicateGroups {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$SourceFiles
    )

    $byStatement = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::Ordinal
    )
    foreach ($sourceFile in @($SourceFiles | Where-Object format -eq 'sql')) {
        foreach ($operation in @($sourceFile.operations)) {
            $statementSha256 = [string]$operation.statementSha256
            if ([string]::IsNullOrWhiteSpace($statementSha256) -or
                    $operation.operation.StartsWith('unknown:', [System.StringComparison]::Ordinal)) {
                continue
            }
            if (-not $byStatement.ContainsKey($statementSha256)) {
                $byStatement[$statementSha256] = [System.Collections.Generic.List[object]]::new()
            }
            $byStatement[$statementSha256].Add([pscustomobject][ordered]@{
                path = [string]$sourceFile.path
                line = $operation.line
                operation = [string]$operation.operation
                table = [string]$operation.table
                references = @($sourceFile.references)
            })
        }
    }

    $statementKeys = [string[]]@($byStatement.Keys)
    [System.Array]::Sort($statementKeys, [System.StringComparer]::Ordinal)
    $groups = [System.Collections.Generic.List[object]]::new()
    foreach ($statementSha256 in $statementKeys) {
        $occurrences = @($byStatement[$statementSha256])
        $sourcePaths = @(Get-ZylOrdinalSortedUniqueStrings -Values @($occurrences.path))
        if ($sourcePaths.Count -lt 2) {
            continue
        }

        $sharedActions = $null
        foreach ($sourcePath in $sourcePaths) {
            $actionKeys = @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $occurrences |
                    Where-Object path -ieq $sourcePath |
                    ForEach-Object references |
                    ForEach-Object { $_.scope + ':' + $_.actionId }
            ))
            if ($null -eq $sharedActions) {
                $sharedActions = $actionKeys
            }
            else {
                $sharedActions = @($sharedActions | Where-Object { $actionKeys -contains $_ })
            }
        }
        $sharedActions = @(Get-ZylOrdinalSortedUniqueStrings -Values @($sharedActions))
        if ($sharedActions.Count -eq 0) {
            continue
        }
        $groups.Add([pscustomobject][ordered]@{
            statementSha256 = $statementSha256
            operation = [string]$occurrences[0].operation
            table = [string]$occurrences[0].table
            sourceCount = $sourcePaths.Count
            occurrenceCount = $occurrences.Count
            sharedActions = $sharedActions
            occurrences = @(
                foreach ($occurrence in $occurrences) {
                    [pscustomobject][ordered]@{
                        path = [string]$occurrence.path
                        line = $occurrence.line
                    }
                }
            )
        })
    }
    return @($groups)
}

function Get-ZylDatabaseWriteSetAnalysis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $references = @(Get-ZylDatabaseActionReferences -ModInfo $ModInfo)
    $sourcePaths = @(Get-ZylOrdinalSortedUniqueStrings -Values @($references.path))
    $sourceFiles = [System.Collections.Generic.List[object]]::new()
    $tableBuckets = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($sourcePath in $sourcePaths) {
        $absolutePath = Join-Path $ProjectRoot $sourcePath
        $sourceReferences = @($references | Where-Object { $_.path -ieq $sourcePath })
        $extension = [System.IO.Path]::GetExtension($sourcePath).ToLowerInvariant()
        $operations = @()
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            $issues.Add("Database action source is missing: $sourcePath")
        }
        elseif ($extension -eq '.sql') {
            $operations = @(Get-ZylSqlWriteOperations -Source (
                Get-Content -LiteralPath $absolutePath -Raw
            ))
        }
        elseif ($extension -eq '.xml') {
            try {
                $document = [System.Xml.XmlDocument]::new()
                $document.PreserveWhitespace = $false
                $document.Load($absolutePath)
                $operations = @(Get-ZylXmlWriteOperations -Document $document)
            }
            catch {
                $issues.Add("Database action XML could not be loaded: $sourcePath ($($_.Exception.Message))")
            }
        }
        else {
            $issues.Add("Database action source has unsupported extension: $sourcePath")
        }

        foreach ($unknownOperation in @($operations | Where-Object {
                    $_.operation.StartsWith('unknown:', [System.StringComparison]::Ordinal)
                })) {
            $location = if ($null -ne $unknownOperation.line) {
                "$sourcePath`:$($unknownOperation.line)"
            }
            else {
                $sourcePath
            }
            $tableSuffix = if ([string]::IsNullOrWhiteSpace($unknownOperation.table)) {
                ''
            }
            else {
                " for table $($unknownOperation.table)"
            }
            $issues.Add(
                "Database action source uses unsupported operation " +
                "$($unknownOperation.operation)$tableSuffix`: $location"
            )
        }

        $sourceFiles.Add([pscustomobject][ordered]@{
            path = $sourcePath
            format = $extension.TrimStart('.')
            references = @($sourceReferences)
            operationCount = $operations.Count
            operations = @($operations)
        })

        foreach ($operation in $operations) {
            if ($operation.operation.StartsWith('unknown:', [System.StringComparison]::Ordinal)) {
                continue
            }
            $tableKey = $operation.table.ToLowerInvariant()
            if (-not $tableBuckets.ContainsKey($tableKey)) {
                $tableBuckets[$tableKey] = [pscustomobject]@{
                    names = [System.Collections.Generic.List[string]]::new()
                    sources = [System.Collections.Generic.List[string]]::new()
                    actions = [System.Collections.Generic.List[string]]::new()
                    scopes = [System.Collections.Generic.List[string]]::new()
                    operationCounts = @{}
                }
            }
            $bucket = $tableBuckets[$tableKey]
            $bucket.names.Add($operation.table)
            $bucket.sources.Add($sourcePath)
            foreach ($reference in $sourceReferences) {
                $bucket.actions.Add($reference.actionId)
                $bucket.scopes.Add($reference.scope)
            }
            if (-not $bucket.operationCounts.ContainsKey($operation.operation)) {
                $bucket.operationCounts[$operation.operation] = 0
            }
            $bucket.operationCounts[$operation.operation]++
        }
    }

    $tableKeys = [string[]]@($tableBuckets.Keys)
    [System.Array]::Sort($tableKeys, [System.StringComparer]::OrdinalIgnoreCase)
    $tables = [System.Collections.Generic.List[object]]::new()
    foreach ($tableKey in $tableKeys) {
        $bucket = $tableBuckets[$tableKey]
        $names = @(Get-ZylOrdinalSortedUniqueStrings -Values @($bucket.names))
        $sources = @(Get-ZylOrdinalSortedUniqueStrings -Values @($bucket.sources))
        $actions = @(Get-ZylOrdinalSortedUniqueStrings -Values @($bucket.actions))
        $scopes = @(Get-ZylOrdinalSortedUniqueStrings -Values @($bucket.scopes))
        $operationNames = [string[]]@($bucket.operationCounts.Keys)
        [System.Array]::Sort($operationNames, [System.StringComparer]::OrdinalIgnoreCase)
        $operationCounts = [ordered]@{}
        $operationCount = 0
        foreach ($operationName in $operationNames) {
            $count = [int]$bucket.operationCounts[$operationName]
            $operationCounts[$operationName] = $count
            $operationCount += $count
        }
        $tables.Add([pscustomobject][ordered]@{
            table = $names[0]
            aliases = @($names | Select-Object -Skip 1)
            sourceCount = $sources.Count
            actionCount = $actions.Count
            operationCount = $operationCount
            scopes = $scopes
            operationCounts = $operationCounts
            sources = $sources
            actions = $actions
        })
    }

    $databaseActionKeys = @(Get-ZylOrdinalSortedUniqueStrings -Values @(
        $references | ForEach-Object { $_.scope + ':' + $_.actionId }
    ))
    $sqlSources = @($sourceFiles | Where-Object format -eq 'sql').Count
    $xmlSources = @($sourceFiles | Where-Object format -eq 'xml').Count
    $operationCount = 0
    foreach ($sourceFile in $sourceFiles) {
        $operationCount += [int]$sourceFile.operationCount
    }
    $overlappingTables = @($tables | Where-Object sourceCount -gt 1)
    $noWriteSources = @($sourceFiles | Where-Object operationCount -eq 0 | ForEach-Object path)
    $sameActionExactSqlDuplicates = @(
        Get-ZylSameActionExactSqlDuplicateGroups -SourceFiles @($sourceFiles)
    )

    return [pscustomobject][ordered]@{
        schemaVersion = 1
        counts = [pscustomobject][ordered]@{
            databaseActions = $databaseActionKeys.Count
            sourceReferences = $references.Count
            uniqueSources = $sourceFiles.Count
            sqlSources = $sqlSources
            xmlSources = $xmlSources
            writeOperations = $operationCount
            tables = $tables.Count
            overlappingTables = $overlappingTables.Count
            noWriteSources = $noWriteSources.Count
            sameActionExactSqlDuplicateGroups = $sameActionExactSqlDuplicates.Count
            issues = $issues.Count
        }
        issues = @($issues)
        actionReferences = @($references)
        sourceFiles = @($sourceFiles)
        tables = @($tables)
        overlappingTables = @($overlappingTables)
        noWriteSources = @($noWriteSources)
        sameActionExactSqlDuplicateGroups = @($sameActionExactSqlDuplicates)
    }
}

function Get-ZylDatabaseWriteSetIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo
    )

    $analysis = Get-ZylDatabaseWriteSetAnalysis -ProjectRoot $ProjectRoot -ModInfo $ModInfo
    return @($analysis.issues)
}

function Get-ZylDatabaseWriteSetSemanticView {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Analysis
    )

    $semanticSources = @(
        foreach ($sourceFile in @($Analysis.sourceFiles)) {
            [pscustomobject][ordered]@{
                path = [string]$sourceFile.path
                format = [string]$sourceFile.format
                references = @($sourceFile.references)
                operations = @(
                    foreach ($operation in @($sourceFile.operations)) {
                        [pscustomobject][ordered]@{
                            operation = [string]$operation.operation
                            conflictMode = $operation.conflictMode
                            table = [string]$operation.table
                        }
                    }
                )
            }
        }
    )
    return [pscustomobject][ordered]@{
        schemaVersion = 1
        actionReferences = @($Analysis.actionReferences)
        sourceFiles = $semanticSources
    }
}

function Get-ZylDatabaseWriteSetContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Analysis,

        [Parameter(Mandatory = $true)]
        [string]$AnalysisSha256,

        [Parameter(Mandatory = $true)]
        [object]$Contract
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Contract.schemaVersion -ne 2) {
        $issues.Add('Database write-set contract schemaVersion must be 2.')
    }
    foreach ($hashProperty in @('frozenAnalysisSha256', 'expectedCurrentAnalysisSha256')) {
        $hash = [string]$Contract.$hashProperty
        if ($hash -notmatch '^[0-9a-f]{64}$') {
            $issues.Add("Database write-set contract has invalid $hashProperty.")
        }
    }
    if ($AnalysisSha256 -ne [string]$Contract.expectedCurrentAnalysisSha256) {
        $issues.Add(
            'Database write-set drifted from expected current fingerprint: ' +
            "$AnalysisSha256 (expected $($Contract.expectedCurrentAnalysisSha256))."
        )
    }

    foreach ($countProperty in @(
            'databaseActions',
            'sourceReferences',
            'uniqueSources',
            'sqlSources',
            'xmlSources',
            'writeOperations',
            'tables',
            'overlappingTables',
            'noWriteSources',
            'sameActionExactSqlDuplicateGroups'
        )) {
        if ($null -eq $Contract.frozenCounts.PSObject.Properties[$countProperty]) {
            $issues.Add("Database write-set contract is missing frozen count: $countProperty")
        }
        if ($null -eq $Contract.expectedCurrentCounts.PSObject.Properties[$countProperty]) {
            $issues.Add("Database write-set contract is missing count: $countProperty")
            continue
        }
        $expectedCount = [int]$Contract.expectedCurrentCounts.$countProperty
        $actualCount = [int]$Analysis.counts.$countProperty
        if ($actualCount -ne $expectedCount) {
            $issues.Add(
                "Database write-set count drifted for ${countProperty}: " +
                "$actualCount (expected $expectedCount)."
            )
        }
    }

    $expectedNoWriteSources = @(
        Get-ZylOrdinalSortedUniqueStrings -Values @($Contract.expectedCurrentNoWriteSources)
    )
    $actualNoWriteSources = @(
        Get-ZylOrdinalSortedUniqueStrings -Values @($Analysis.noWriteSources)
    )
    if (($actualNoWriteSources -join '|') -ne ($expectedNoWriteSources -join '|')) {
        $issues.Add(
            'Database write-set zero-write source list drifted: ' +
            "actual [$($actualNoWriteSources -join ', ')], " +
            "expected [$($expectedNoWriteSources -join ', ')]."
        )
    }
    return @($issues)
}
