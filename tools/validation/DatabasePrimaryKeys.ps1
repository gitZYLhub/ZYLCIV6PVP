function Find-ZylSqlClosingParenthesis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [int]$OpenIndex
    )

    if ($OpenIndex -lt 0 -or $OpenIndex -ge $Text.Length -or $Text[$OpenIndex] -ne '(') {
        return -1
    }
    $depth = 0
    $state = 'normal'
    for ($index = $OpenIndex; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        $nextCharacter = if ($index + 1 -lt $Text.Length) {
            $Text[$index + 1]
        }
        else {
            [char]0
        }
        if ($state -eq 'single-quote') {
            if ($character -eq "'") {
                if ($nextCharacter -eq "'") {
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            continue
        }
        if ($state -eq 'double-quote') {
            if ($character -eq '"') {
                if ($nextCharacter -eq '"') {
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            continue
        }
        if ($state -eq 'backtick-quote') {
            if ($character -eq '`') {
                if ($nextCharacter -eq '`') {
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            continue
        }
        if ($state -eq 'bracket-quote') {
            if ($character -eq ']') {
                $state = 'normal'
            }
            continue
        }
        if ($character -eq "'") {
            $state = 'single-quote'
            continue
        }
        if ($character -eq '"') {
            $state = 'double-quote'
            continue
        }
        if ($character -eq '`') {
            $state = 'backtick-quote'
            continue
        }
        if ($character -eq '[') {
            $state = 'bracket-quote'
            continue
        }
        if ($character -eq '(') {
            $depth++
            continue
        }
        if ($character -eq ')') {
            $depth--
            if ($depth -eq 0) {
                return $index
            }
        }
    }
    return -1
}

function Split-ZylSqlTopLevelList {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $items = [System.Collections.Generic.List[string]]::new()
    $start = 0
    $depth = 0
    $state = 'normal'
    for ($index = 0; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        $nextCharacter = if ($index + 1 -lt $Text.Length) {
            $Text[$index + 1]
        }
        else {
            [char]0
        }
        if ($state -eq 'single-quote') {
            if ($character -eq "'") {
                if ($nextCharacter -eq "'") {
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            continue
        }
        if ($state -eq 'double-quote') {
            if ($character -eq '"') {
                if ($nextCharacter -eq '"') {
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            continue
        }
        if ($state -eq 'backtick-quote') {
            if ($character -eq '`') {
                if ($nextCharacter -eq '`') {
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            continue
        }
        if ($state -eq 'bracket-quote') {
            if ($character -eq ']') {
                $state = 'normal'
            }
            continue
        }
        if ($character -eq "'") {
            $state = 'single-quote'
            continue
        }
        if ($character -eq '"') {
            $state = 'double-quote'
            continue
        }
        if ($character -eq '`') {
            $state = 'backtick-quote'
            continue
        }
        if ($character -eq '[') {
            $state = 'bracket-quote'
            continue
        }
        if ($character -eq '(') {
            $depth++
            continue
        }
        if ($character -eq ')') {
            $depth--
            continue
        }
        if ($character -eq ',' -and $depth -eq 0) {
            $items.Add($Text.Substring($start, $index - $start).Trim())
            $start = $index + 1
        }
    }
    $items.Add($Text.Substring($start).Trim())
    return @($items)
}

function ConvertFrom-ZylSqlLiteral {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $value = $Text.Trim()
    if ($value -match '^(?i:NULL)$') {
        return [pscustomobject][ordered]@{ resolved = $true; kind = 'null'; value = $null }
    }
    if ($value -match "^'(?:[^']|'')*'$") {
        return [pscustomobject][ordered]@{
            resolved = $true
            kind = 'text'
            value = $value.Substring(1, $value.Length - 2).Replace("''", "'")
        }
    }
    if ($value -match '^"(?:[^"]|"")*"$') {
        return [pscustomobject][ordered]@{
            resolved = $true
            kind = 'text'
            value = $value.Substring(1, $value.Length - 2).Replace('""', '"')
        }
    }
    if ($value -match '^(?i:X''[0-9A-F]*'')$') {
        return [pscustomobject][ordered]@{
            resolved = $true
            kind = 'blob'
            value = $value.ToLowerInvariant()
        }
    }
    if ($value -match '^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$') {
        return [pscustomobject][ordered]@{
            resolved = $true
            kind = 'number'
            value = $value.ToLowerInvariant()
        }
    }
    if ($value -match '^(?i:TRUE|FALSE)$') {
        return [pscustomobject][ordered]@{
            resolved = $true
            kind = 'number'
            value = if ($value -ieq 'true') { '1' } else { '0' }
        }
    }
    return [pscustomobject][ordered]@{ resolved = $false; kind = 'expression'; value = $value }
}

function ConvertFrom-ZylSqlInsertStatement {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Statement
    )

    $identifierPattern = '(?<table>"(?:[^"]|"")+"|''(?:[^'']|'''')+''|\[[^\]]+\]|`(?:[^`]|``)+`|[A-Za-z_][A-Za-z0-9_.$]*)'
    $prefix = [regex]::Match(
        $Statement,
        "(?is)^\s*(?:INSERT\s+(?:OR\s+(?:ROLLBACK|ABORT|REPLACE|FAIL|IGNORE)\s+)?INTO|REPLACE\s+INTO)\s+$identifierPattern"
    )
    if (-not $prefix.Success) {
        return [pscustomobject][ordered]@{
            table = ''
            explicitColumns = $false
            columns = @()
            rows = @()
            reason = 'unsupported-insert-prefix'
        }
    }

    $cursor = $prefix.Length
    while ($cursor -lt $Statement.Length -and [char]::IsWhiteSpace($Statement[$cursor])) {
        $cursor++
    }
    $columns = @()
    $explicitColumns = $false
    if ($cursor -lt $Statement.Length -and $Statement[$cursor] -eq '(') {
        $columnEnd = Find-ZylSqlClosingParenthesis -Text $Statement -OpenIndex $cursor
        if ($columnEnd -lt 0) {
            return [pscustomobject][ordered]@{
                table = ConvertFrom-ZylSqlIdentifier -Identifier $prefix.Groups['table'].Value
                explicitColumns = $true
                columns = @()
                rows = @()
                reason = 'unterminated-column-list'
            }
        }
        $columns = @(
            Split-ZylSqlTopLevelList -Text (
                $Statement.Substring($cursor + 1, $columnEnd - $cursor - 1)
            ) | ForEach-Object { ConvertFrom-ZylSqlIdentifier -Identifier $_ }
        )
        $explicitColumns = $true
        $cursor = $columnEnd + 1
        while ($cursor -lt $Statement.Length -and [char]::IsWhiteSpace($Statement[$cursor])) {
            $cursor++
        }
    }

    $remainder = $Statement.Substring($cursor)
    $valuesMatch = [regex]::Match($remainder, '^(?is:VALUES)\b')
    if (-not $valuesMatch.Success) {
        $reason = if ($remainder -match '^(?is:SELECT|WITH)\b') {
            'insert-select'
        }
        else {
            'unsupported-insert-body'
        }
        return [pscustomobject][ordered]@{
            table = ConvertFrom-ZylSqlIdentifier -Identifier $prefix.Groups['table'].Value
            explicitColumns = $explicitColumns
            columns = @($columns)
            rows = @()
            reason = $reason
        }
    }
    $cursor += $valuesMatch.Length

    $rows = [System.Collections.Generic.List[object]]::new()
    $reason = $null
    while ($cursor -lt $Statement.Length) {
        while ($cursor -lt $Statement.Length -and [char]::IsWhiteSpace($Statement[$cursor])) {
            $cursor++
        }
        if ($cursor -ge $Statement.Length -or $Statement[$cursor] -ne '(') {
            $reason = 'unsupported-values-tail'
            break
        }
        $rowEnd = Find-ZylSqlClosingParenthesis -Text $Statement -OpenIndex $cursor
        if ($rowEnd -lt 0) {
            $reason = 'unterminated-values-row'
            break
        }
        $rows.Add([pscustomobject][ordered]@{
            values = @(Split-ZylSqlTopLevelList -Text (
                    $Statement.Substring($cursor + 1, $rowEnd - $cursor - 1)
                ))
        })
        $cursor = $rowEnd + 1
        while ($cursor -lt $Statement.Length -and [char]::IsWhiteSpace($Statement[$cursor])) {
            $cursor++
        }
        if ($cursor -ge $Statement.Length) {
            break
        }
        if ($Statement[$cursor] -ne ',') {
            $reason = 'unsupported-values-tail'
            break
        }
        $cursor++
    }
    return [pscustomobject][ordered]@{
        table = ConvertFrom-ZylSqlIdentifier -Identifier $prefix.Groups['table'].Value
        explicitColumns = $explicitColumns
        columns = @($columns)
        rows = @($rows)
        reason = $reason
    }
}

function Get-ZylCommonSchemaColumnOrder {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Snapshot,

        [Parameter(Mandatory = $true)]
        [object]$CoverageRecord
    )

    $variants = [System.Collections.Generic.List[string]]::new()
    $orders = [System.Collections.Generic.List[object]]::new()
    foreach ($profileName in @($CoverageRecord.schemaProfiles)) {
        $tableProperty = $Snapshot.profiles.$profileName.PSObject.Properties[
            [string]$CoverageRecord.table
        ]
        if ($null -eq $tableProperty) {
            continue
        }
        $columns = @($tableProperty.Value.columns)
        $variant = $columns -join ([char]31)
        if ($variants -notcontains $variant) {
            $variants.Add($variant)
            $orders.Add([pscustomobject][ordered]@{ columns = @($columns) })
        }
    }
    if ($orders.Count -eq 1) {
        return @($orders[0].columns)
    }
    return @()
}

function Get-ZylDatabaseKeySha256 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Table,

        [Parameter(Mandatory = $true)]
        [object[]]$KeyValues
    )

    $pieces = [System.Collections.Generic.List[string]]::new()
    $pieces.Add($Table.ToLowerInvariant())
    foreach ($keyValue in @($KeyValues)) {
        $column = ([string]$keyValue.column).ToLowerInvariant()
        $kind = [string]$keyValue.kind
        $value = if ($null -eq $keyValue.value) { '' } else { [string]$keyValue.value }
        $pieces.Add("$($column.Length):$column|$($kind.Length):$kind|$($value.Length):$value")
    }
    return Get-ZylDatabaseStatementSha256 -Statement ($pieces -join ([char]30))
}

function Get-ZylDatabasePrimaryKeyAnalysis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$WriteSetAnalysis,

        [Parameter(Mandatory = $true)]
        [object]$SchemaCoverage,

        [Parameter(Mandatory = $true)]
        [object]$SchemaSnapshot
    )

    $coverageByTable = @{}
    foreach ($record in @($SchemaCoverage.tables)) {
        $coverageByTable[[string]$record.table] = $record
    }
    $operations = [System.Collections.Generic.List[object]]::new()
    $candidates = [System.Collections.Generic.List[object]]::new()
    $reasonCounts = @{}

    foreach ($sourceFile in @($WriteSetAnalysis.sourceFiles)) {
        $actionKeys = @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $sourceFile.references | ForEach-Object { $_.scope + ':' + $_.actionId }
            ))
        $operationIndex = 0
        if ($sourceFile.format -eq 'sql') {
            $source = Get-Content -LiteralPath (Join-Path $ProjectRoot $sourceFile.path) -Raw
            foreach ($statement in @(Split-ZylSqlStatements -Source $source)) {
                $classified = @(Get-ZylSqlWriteOperations -Source $statement.text)
                if ($classified.Count -ne 1 -or
                        $classified[0].operation -notin @('insert', 'replace')) {
                    continue
                }
                $operationIndex++
                $operation = $classified[0]
                $parsed = ConvertFrom-ZylSqlInsertStatement -Statement $statement.text
                $table = [string]$operation.table
                $coverage = $coverageByTable[$table]
                $schemaReason = if ($null -eq $coverage) {
                    'unknown-table'
                }
                elseif ([string]$coverage.classification -eq 'external') {
                    'external-schema'
                }
                elseif ([string]$coverage.classification -eq 'mod-created') {
                    'mod-created-schema-pending'
                }
                elseif (@($coverage.primaryKey).Count -eq 0) {
                    'no-primary-key'
                }
                else {
                    $null
                }
                $columns = @($parsed.columns)
                $columnReason = $null
                if ($null -eq $schemaReason -and -not $parsed.explicitColumns) {
                    $columns = @(Get-ZylCommonSchemaColumnOrder `
                            -Snapshot $SchemaSnapshot `
                            -CoverageRecord $coverage)
                    if ($columns.Count -eq 0) {
                        $columnReason = 'ambiguous-implicit-column-order'
                    }
                }

                $resolvedRows = 0
                $unresolvedRows = 0
                $rowReason = $null
                $rowIndex = 0
                foreach ($row in @($parsed.rows)) {
                    $rowIndex++
                    $currentReason = $schemaReason
                    if ($null -eq $currentReason) {
                        $currentReason = $columnReason
                    }
                    if ($null -eq $currentReason -and @($row.values).Count -ne $columns.Count) {
                        $currentReason = 'column-value-count-mismatch'
                    }
                    $keyValues = [System.Collections.Generic.List[object]]::new()
                    if ($null -eq $currentReason) {
                        foreach ($keyColumn in @($coverage.primaryKey)) {
                            $keyIndex = -1
                            for ($columnIndex = 0; $columnIndex -lt $columns.Count; $columnIndex++) {
                                if ([string]$columns[$columnIndex] -ieq [string]$keyColumn) {
                                    $keyIndex = $columnIndex
                                    break
                                }
                            }
                            if ($keyIndex -lt 0) {
                                $currentReason = 'missing-primary-key-column'
                                break
                            }
                            $literal = ConvertFrom-ZylSqlLiteral -Text ([string]$row.values[$keyIndex])
                            if (-not $literal.resolved) {
                                $currentReason = 'nonliteral-primary-key'
                                break
                            }
                            $keyValues.Add([pscustomobject][ordered]@{
                                column = [string]$keyColumn
                                kind = [string]$literal.kind
                                value = $literal.value
                            })
                        }
                    }
                    if ($null -ne $currentReason) {
                        $unresolvedRows++
                        if ($null -eq $rowReason) {
                            $rowReason = $currentReason
                        }
                        continue
                    }
                    $resolvedRows++
                    $keySha256 = Get-ZylDatabaseKeySha256 -Table $table -KeyValues @($keyValues)
                    $candidates.Add([pscustomobject][ordered]@{
                        path = [string]$sourceFile.path
                        format = 'sql'
                        operationIndex = $operationIndex
                        line = [int]$statement.line
                        rowIndex = $rowIndex
                        operation = [string]$operation.operation
                        conflictMode = $operation.conflictMode
                        table = $table
                        keySha256 = $keySha256
                        keyValues = @($keyValues)
                        actionKeys = @($actionKeys)
                    })
                }
                $reason = $schemaReason
                if ($null -eq $reason) { $reason = $columnReason }
                if ($null -eq $reason) { $reason = $parsed.reason }
                if ($null -eq $reason) { $reason = $rowReason }
                if ($null -ne $reason -and -not $reasonCounts.ContainsKey($reason)) {
                    $reasonCounts[$reason] = 0
                }
                if ($null -ne $reason) { $reasonCounts[$reason]++ }
                $status = if ($resolvedRows -gt 0 -and $null -eq $reason) {
                    'resolved'
                }
                elseif ($resolvedRows -gt 0) {
                    'partial'
                }
                else {
                    'unresolved'
                }
                $operations.Add([pscustomobject][ordered]@{
                    path = [string]$sourceFile.path
                    format = 'sql'
                    operationIndex = $operationIndex
                    line = [int]$statement.line
                    operation = [string]$operation.operation
                    conflictMode = $operation.conflictMode
                    table = $table
                    status = $status
                    reason = $reason
                    rowCount = @($parsed.rows).Count
                    resolvedRows = $resolvedRows
                    unresolvedRows = $unresolvedRows
                })
            }
        }
        elseif ($sourceFile.format -eq 'xml') {
            $document = [System.Xml.XmlDocument]::new()
            $document.Load((Join-Path $ProjectRoot $sourceFile.path))
            foreach ($tableNode in @(
                    $document.DocumentElement.ChildNodes | Where-Object NodeType -eq Element
                )) {
                foreach ($node in @(
                        $tableNode.ChildNodes |
                            Where-Object NodeType -eq Element |
                            Where-Object LocalName -in @('Row', 'InsertOrIgnore', 'Replace')
                    )) {
                    $operationIndex++
                    $operationName = if ($node.LocalName -eq 'Replace') { 'replace' } else { 'insert' }
                    $conflictMode = if ($node.LocalName -eq 'Replace') {
                        'replace'
                    }
                    elseif ($node.LocalName -eq 'InsertOrIgnore') {
                        'ignore'
                    }
                    else {
                        $null
                    }
                    $table = [string]$tableNode.LocalName
                    $coverage = $coverageByTable[$table]
                    $reason = if ($null -eq $coverage) {
                        'unknown-table'
                    }
                    elseif ([string]$coverage.classification -eq 'external') {
                        'external-schema'
                    }
                    elseif ([string]$coverage.classification -eq 'mod-created') {
                        'mod-created-schema-pending'
                    }
                    elseif (@($coverage.primaryKey).Count -eq 0) {
                        'no-primary-key'
                    }
                    else {
                        $null
                    }
                    $keyValues = [System.Collections.Generic.List[object]]::new()
                    if ($null -eq $reason) {
                        foreach ($keyColumn in @($coverage.primaryKey)) {
                            $attribute = @($node.Attributes | Where-Object LocalName -ieq $keyColumn)
                            if ($attribute.Count -ne 1) {
                                $reason = 'missing-primary-key-column'
                                break
                            }
                            $keyValues.Add([pscustomobject][ordered]@{
                                column = [string]$keyColumn
                                kind = 'text'
                                value = [string]$attribute[0].Value
                            })
                        }
                    }
                    if ($null -eq $reason) {
                        $keySha256 = Get-ZylDatabaseKeySha256 -Table $table -KeyValues @($keyValues)
                        $candidates.Add([pscustomobject][ordered]@{
                            path = [string]$sourceFile.path
                            format = 'xml'
                            operationIndex = $operationIndex
                            line = $null
                            rowIndex = 1
                            operation = $operationName
                            conflictMode = $conflictMode
                            table = $table
                            keySha256 = $keySha256
                            keyValues = @($keyValues)
                            actionKeys = @($actionKeys)
                        })
                    }
                    else {
                        if (-not $reasonCounts.ContainsKey($reason)) {
                            $reasonCounts[$reason] = 0
                        }
                        $reasonCounts[$reason]++
                    }
                    $operations.Add([pscustomobject][ordered]@{
                        path = [string]$sourceFile.path
                        format = 'xml'
                        operationIndex = $operationIndex
                        line = $null
                        operation = $operationName
                        conflictMode = $conflictMode
                        table = $table
                        status = if ($null -eq $reason) { 'resolved' } else { 'unresolved' }
                        reason = $reason
                        rowCount = 1
                        resolvedRows = if ($null -eq $reason) { 1 } else { 0 }
                        unresolvedRows = if ($null -eq $reason) { 0 } else { 1 }
                    })
                }
            }
        }
    }

    $candidateGroups = @{}
    foreach ($candidate in @($candidates)) {
        $groupKey = $candidate.table.ToLowerInvariant() + ':' + $candidate.keySha256
        if (-not $candidateGroups.ContainsKey($groupKey)) {
            $candidateGroups[$groupKey] = [System.Collections.Generic.List[object]]::new()
        }
        $candidateGroups[$groupKey].Add($candidate)
    }
    $duplicateGroups = [System.Collections.Generic.List[object]]::new()
    foreach ($groupKey in @($candidateGroups.Keys | Sort-Object)) {
        $occurrences = @($candidateGroups[$groupKey])
        if ($occurrences.Count -lt 2) {
            continue
        }
        $sharedActions = $null
        foreach ($occurrence in $occurrences) {
            if ($null -eq $sharedActions) {
                $sharedActions = @($occurrence.actionKeys)
            }
            else {
                $sharedActions = @($sharedActions | Where-Object {
                        $occurrence.actionKeys -contains $_
                    })
            }
        }
        $sharedActions = @(Get-ZylOrdinalSortedUniqueStrings -Values @($sharedActions))
        $duplicateGroups.Add([pscustomobject][ordered]@{
            table = [string]$occurrences[0].table
            keySha256 = [string]$occurrences[0].keySha256
            keyValues = @($occurrences[0].keyValues)
            occurrenceCount = $occurrences.Count
            sourceCount = @(Get-ZylOrdinalSortedUniqueStrings -Values @($occurrences.path)).Count
            sameAction = $sharedActions.Count -gt 0
            sharedActions = @($sharedActions)
            occurrences = @(
                foreach ($occurrence in $occurrences) {
                    [pscustomobject][ordered]@{
                        path = [string]$occurrence.path
                        operationIndex = [int]$occurrence.operationIndex
                        line = $occurrence.line
                        rowIndex = [int]$occurrence.rowIndex
                        operation = [string]$occurrence.operation
                        conflictMode = $occurrence.conflictMode
                    }
                }
            )
        })
    }

    $orderedReasonCounts = [ordered]@{}
    foreach ($reason in @($reasonCounts.Keys | Sort-Object)) {
        $orderedReasonCounts[$reason] = [int]$reasonCounts[$reason]
    }
    return [pscustomobject][ordered]@{
        schemaVersion = 1
        counts = [pscustomobject][ordered]@{
            insertReplaceOperations = $operations.Count
            resolvedOperations = @($operations | Where-Object status -eq 'resolved').Count
            partiallyResolvedOperations = @($operations | Where-Object status -eq 'partial').Count
            unresolvedOperations = @($operations | Where-Object status -eq 'unresolved').Count
            rowCandidates = $candidates.Count
            tablesWithCandidates = @(Get-ZylOrdinalSortedUniqueStrings -Values @($candidates.table)).Count
            duplicateKeyGroups = $duplicateGroups.Count
            sameActionDuplicateKeyGroups = @($duplicateGroups | Where-Object sameAction).Count
        }
        unresolvedReasonCounts = $orderedReasonCounts
        operations = @($operations)
        rowCandidates = @($candidates)
        duplicateKeyGroups = @($duplicateGroups)
    }
}

function Get-ZylDatabasePrimaryKeySemanticView {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Analysis
    )

    return [pscustomobject][ordered]@{
        schemaVersion = 1
        operations = @($Analysis.operations)
        rowCandidates = @(
            foreach ($candidate in @($Analysis.rowCandidates)) {
                [pscustomobject][ordered]@{
                    path = [string]$candidate.path
                    format = [string]$candidate.format
                    operationIndex = [int]$candidate.operationIndex
                    line = $candidate.line
                    rowIndex = [int]$candidate.rowIndex
                    operation = [string]$candidate.operation
                    conflictMode = $candidate.conflictMode
                    table = [string]$candidate.table
                    keySha256 = [string]$candidate.keySha256
                    keyValues = @($candidate.keyValues)
                }
            }
        )
    }
}

function Get-ZylDatabasePrimaryKeyContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Analysis,

        [Parameter(Mandatory = $true)]
        [string]$AnalysisSha256,

        [Parameter(Mandatory = $true)]
        [object]$Contract
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Contract.schemaVersion -ne 1) {
        $issues.Add('Database primary-key contract schemaVersion must be 1.')
    }
    if ([string]$Contract.expectedAnalysisSha256 -notmatch '^[0-9a-f]{64}$') {
        $issues.Add('Database primary-key contract has an invalid expectedAnalysisSha256.')
    }
    elseif ($AnalysisSha256 -ne [string]$Contract.expectedAnalysisSha256) {
        $issues.Add(
            'Database primary-key analysis drifted from expected fingerprint: ' +
            "$AnalysisSha256 (expected $($Contract.expectedAnalysisSha256))."
        )
    }
    foreach ($countProperty in @(
            'insertReplaceOperations',
            'resolvedOperations',
            'partiallyResolvedOperations',
            'unresolvedOperations',
            'rowCandidates',
            'tablesWithCandidates',
            'duplicateKeyGroups',
            'sameActionDuplicateKeyGroups'
        )) {
        if ($null -eq $Contract.expectedCounts.PSObject.Properties[$countProperty]) {
            $issues.Add("Database primary-key contract is missing count: $countProperty")
            continue
        }
        if ([int]$Analysis.counts.$countProperty -ne [int]$Contract.expectedCounts.$countProperty) {
            $issues.Add(
                "Database primary-key count drifted for ${countProperty}: " +
                "$($Analysis.counts.$countProperty) (expected $($Contract.expectedCounts.$countProperty))."
            )
        }
    }
    $expectedReasonNames = if ($Contract.expectedUnresolvedReasonCounts -is
            [System.Collections.IDictionary]) {
        @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $Contract.expectedUnresolvedReasonCounts.Keys
            ))
    }
    else {
        @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $Contract.expectedUnresolvedReasonCounts.PSObject.Properties.Name
            ))
    }
    $actualReasonNames = if ($Analysis.unresolvedReasonCounts -is
            [System.Collections.IDictionary]) {
        @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $Analysis.unresolvedReasonCounts.Keys
            ))
    }
    else {
        @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $Analysis.unresolvedReasonCounts.PSObject.Properties.Name
            ))
    }
    $expectedReasons = @(
        foreach ($reasonName in $expectedReasonNames) {
            $reasonValue = if ($Contract.expectedUnresolvedReasonCounts -is
                    [System.Collections.IDictionary]) {
                $Contract.expectedUnresolvedReasonCounts[$reasonName]
            }
            else {
                $Contract.expectedUnresolvedReasonCounts.$reasonName
            }
            $reasonName + '=' + [string]$reasonValue
        }
    )
    $actualReasons = @(
        foreach ($reasonName in $actualReasonNames) {
            $reasonValue = if ($Analysis.unresolvedReasonCounts -is
                    [System.Collections.IDictionary]) {
                $Analysis.unresolvedReasonCounts[$reasonName]
            }
            else {
                $Analysis.unresolvedReasonCounts.$reasonName
            }
            $reasonName + '=' + [string]$reasonValue
        }
    )
    if (($actualReasons -join '|') -ne ($expectedReasons -join '|')) {
        $issues.Add(
            'Database primary-key unresolved reasons drifted: ' +
            "actual [$($actualReasons -join ', ')], expected [$($expectedReasons -join ', ')]."
        )
    }
    return @($issues)
}
