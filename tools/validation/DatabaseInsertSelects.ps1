function ConvertTo-ZylSqlKeywordSurface {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $surface = [System.Text.StringBuilder]::new($Text.Length)
    $state = 'normal'
    for ($index = 0; $index -lt $Text.Length; $index++) {
        $character = $Text[$index]
        $nextCharacter = if ($index + 1 -lt $Text.Length) {
            $Text[$index + 1]
        }
        else {
            [char]0
        }

        if ($state -eq 'line-comment') {
            if ($character -eq "`n") {
                [void]$surface.Append($character)
                $state = 'normal'
            }
            else {
                [void]$surface.Append(' ')
            }
            continue
        }
        if ($state -eq 'block-comment') {
            if ($character -eq '*' -and $nextCharacter -eq '/') {
                [void]$surface.Append('  ')
                $index++
                $state = 'normal'
            }
            elseif ($character -eq "`n") {
                [void]$surface.Append($character)
            }
            else {
                [void]$surface.Append(' ')
            }
            continue
        }
        if ($state -ne 'normal') {
            [void]$surface.Append($(if ($character -eq "`n") { $character } else { ' ' }))
            if ($state -eq 'single-quote' -and $character -eq "'") {
                if ($nextCharacter -eq "'") {
                    [void]$surface.Append(' ')
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            elseif ($state -eq 'double-quote' -and $character -eq '"') {
                if ($nextCharacter -eq '"') {
                    [void]$surface.Append(' ')
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            elseif ($state -eq 'backtick-quote' -and $character -eq '`') {
                if ($nextCharacter -eq '`') {
                    [void]$surface.Append(' ')
                    $index++
                }
                else {
                    $state = 'normal'
                }
            }
            elseif ($state -eq 'bracket-quote' -and $character -eq ']') {
                $state = 'normal'
            }
            continue
        }

        if ($character -eq '-' -and $nextCharacter -eq '-') {
            [void]$surface.Append('  ')
            $index++
            $state = 'line-comment'
        }
        elseif ($character -eq '/' -and $nextCharacter -eq '*') {
            [void]$surface.Append('  ')
            $index++
            $state = 'block-comment'
        }
        elseif ($character -eq "'") {
            [void]$surface.Append(' ')
            $state = 'single-quote'
        }
        elseif ($character -eq '"') {
            [void]$surface.Append(' ')
            $state = 'double-quote'
        }
        elseif ($character -eq '`') {
            [void]$surface.Append(' ')
            $state = 'backtick-quote'
        }
        elseif ($character -eq '[') {
            [void]$surface.Append(' ')
            $state = 'bracket-quote'
        }
        else {
            [void]$surface.Append($character)
        }
    }
    return $surface.ToString()
}

function Get-ZylSqlIdentifierAtOffset {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [int]$Offset
    )

    $cursor = $Offset
    while ($cursor -lt $Text.Length -and [char]::IsWhiteSpace($Text[$cursor])) {
        $cursor++
    }
    if ($cursor -ge $Text.Length -or $Text[$cursor] -eq '(') {
        return $null
    }

    $start = $cursor
    $opening = $Text[$cursor]
    $closing = switch ($opening) {
        '"' { '"' }
        "'" { "'" }
        '`' { '`' }
        '[' { ']' }
        default { [char]0 }
    }
    if ($closing -ne [char]0) {
        $cursor++
        $closed = $false
        while ($cursor -lt $Text.Length) {
            if ($Text[$cursor] -eq $closing) {
                if ($closing -ne ']' -and $cursor + 1 -lt $Text.Length -and
                        $Text[$cursor + 1] -eq $closing) {
                    $cursor += 2
                    continue
                }
                $cursor++
                $closed = $true
                break
            }
            $cursor++
        }
        if (-not $closed) {
            return $null
        }
    }
    else {
        while ($cursor -lt $Text.Length -and
                $Text[$cursor] -match '[A-Za-z0-9_.$]') {
            $cursor++
        }
        if ($cursor -eq $start) {
            return $null
        }
    }
    return ConvertFrom-ZylSqlIdentifier -Identifier $Text.Substring($start, $cursor - $start)
}

function Get-ZylSqlTopLevelKeywords {
    param(
        [Parameter(Mandatory = $true)]
        [string]$KeywordSurface
    )

    $keywords = [System.Collections.Generic.List[string]]::new()
    $depth = 0
    for ($index = 0; $index -lt $KeywordSurface.Length;) {
        $character = $KeywordSurface[$index]
        if ($character -eq '(') {
            $depth++
            $index++
            continue
        }
        if ($character -eq ')') {
            if ($depth -gt 0) { $depth-- }
            $index++
            continue
        }
        if ($depth -eq 0 -and ($character -match '[A-Za-z_]')) {
            $start = $index
            $index++
            while ($index -lt $KeywordSurface.Length -and
                    $KeywordSurface[$index] -match '[A-Za-z0-9_]') {
                $index++
            }
            $keywords.Add($KeywordSurface.Substring($start, $index - $start).ToLowerInvariant())
            continue
        }
        $index++
    }
    return @($keywords)
}

function Get-ZylSqlInsertSelectShape {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Statement,

        [Parameter(Mandatory = $true)]
        [string]$TargetTable
    )

    $surface = ConvertTo-ZylSqlKeywordSurface -Text $Statement
    $topLevelKeywords = @(Get-ZylSqlTopLevelKeywords -KeywordSurface $surface)
    $sourceTables = [System.Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($surface, '(?i)\b(?:FROM|JOIN)\b')) {
        $sourceTable = Get-ZylSqlIdentifierAtOffset `
            -Text $Statement `
            -Offset ($match.Index + $match.Length)
        if (-not [string]::IsNullOrWhiteSpace([string]$sourceTable) -and
                $sourceTable -notmatch '^(?i:SELECT|VALUES)$') {
            $sourceTables.Add([string]$sourceTable)
        }
    }
    $orderedSourceTables = @(Get-ZylOrdinalSortedUniqueStrings -Values @($sourceTables))
    $selectCount = [regex]::Matches($surface, '(?i)\bSELECT\b').Count
    $hasJoin = $surface -match '(?i)\bJOIN\b'
    $hasCompound = $surface -match '(?i)\b(?:UNION|INTERSECT|EXCEPT)\b'
    $hasGroupBy = $surface -match '(?i)\bGROUP\s+BY\b'
    $hasNestedSelect = $selectCount -gt 1
    $shape = if ($hasCompound) {
        'compound'
    }
    elseif ($hasJoin) {
        'joined'
    }
    elseif ($hasNestedSelect) {
        'nested'
    }
    elseif ($hasGroupBy) {
        'grouped'
    }
    else {
        'simple'
    }
    return [pscustomobject][ordered]@{
        shape = $shape
        sourceTables = @($orderedSourceTables)
        selectCount = $selectCount
        hasTopLevelFrom = 'from' -in $topLevelKeywords
        hasWith = $surface -match '(?i)\bWITH\b'
        hasJoin = $hasJoin
        hasWhere = $surface -match '(?i)\bWHERE\b'
        hasCompound = $hasCompound
        hasGroupBy = $hasGroupBy
        hasOrderBy = $surface -match '(?i)\bORDER\s+BY\b'
        hasLimit = $surface -match '(?i)\bLIMIT\b'
        hasDistinct = $surface -match '(?i)\bSELECT\s+DISTINCT\b'
        hasExists = $surface -match '(?i)\bEXISTS\b'
        hasNestedSelect = $hasNestedSelect
        readsTargetTable = @($orderedSourceTables | Where-Object {
                $_ -ieq $TargetTable
            }).Count -gt 0
    }
}

function Get-ZylDatabaseInsertSelectAnalysis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object]$WriteSetAnalysis,

        [Parameter(Mandatory = $true)]
        [object]$PrimaryKeyAnalysis
    )

    $primaryOperationByKey = @{}
    foreach ($operation in @($PrimaryKeyAnalysis.operations)) {
        $key = [string]$operation.path + '|' + [string]$operation.operationIndex
        $primaryOperationByKey[$key] = $operation
    }
    $records = [System.Collections.Generic.List[object]]::new()
    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($sourceFile in @($WriteSetAnalysis.sourceFiles | Where-Object format -eq 'sql')) {
        $actionKeys = @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $sourceFile.references | ForEach-Object { $_.scope + ':' + $_.actionId }
            ))
        $criteria = @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                $sourceFile.references | ForEach-Object { $_.criteria }
            ))
        $source = Get-Content -LiteralPath (Join-Path $ProjectRoot $sourceFile.path) -Raw
        $operationIndex = 0
        foreach ($statement in @(Split-ZylSqlStatements -Source $source)) {
            $writes = @(Get-ZylSqlWriteOperations -Source $statement.text)
            if ($writes.Count -ne 1 -or $writes[0].operation -notin @('insert', 'replace')) {
                continue
            }
            $operationIndex++
            $parsed = ConvertFrom-ZylSqlInsertStatement -Statement $statement.text
            if ($parsed.reason -ne 'insert-select') {
                continue
            }
            $targetTable = [string]$writes[0].table
            $shape = Get-ZylSqlInsertSelectShape `
                -Statement $statement.text `
                -TargetTable $targetTable
            $primaryKey = [string]$sourceFile.path + '|' + [string]$operationIndex
            if (-not $primaryOperationByKey.ContainsKey($primaryKey)) {
                $issues.Add(
                    "INSERT SELECT has no matching primary-key operation: " +
                    "$($sourceFile.path):$($statement.line) (operation $operationIndex)."
                )
                $primaryReason = 'missing-operation'
            }
            else {
                $primaryReason = [string]$primaryOperationByKey[$primaryKey].reason
            }
            if (@($shape.sourceTables).Count -eq 0) {
                $issues.Add(
                    "INSERT SELECT source-table extraction found no provider: " +
                    "$($sourceFile.path):$($statement.line)."
                )
            }
            $records.Add([pscustomobject][ordered]@{
                path = [string]$sourceFile.path
                line = [int]$statement.line
                operationIndex = $operationIndex
                targetTable = $targetTable
                conflictMode = $writes[0].conflictMode
                statementSha256 = [string]$writes[0].statementSha256
                primaryKeyReason = $primaryReason
                shape = [string]$shape.shape
                sourceTables = @($shape.sourceTables)
                selectCount = [int]$shape.selectCount
                hasTopLevelFrom = [bool]$shape.hasTopLevelFrom
                hasWith = [bool]$shape.hasWith
                hasJoin = [bool]$shape.hasJoin
                hasWhere = [bool]$shape.hasWhere
                hasCompound = [bool]$shape.hasCompound
                hasGroupBy = [bool]$shape.hasGroupBy
                hasOrderBy = [bool]$shape.hasOrderBy
                hasLimit = [bool]$shape.hasLimit
                hasDistinct = [bool]$shape.hasDistinct
                hasExists = [bool]$shape.hasExists
                hasNestedSelect = [bool]$shape.hasNestedSelect
                readsTargetTable = [bool]$shape.readsTargetTable
                actionKeys = @($actionKeys)
                criteria = @($criteria)
            })
        }
    }

    $duplicateGroups = @(
        $records |
            Group-Object statementSha256 |
            Where-Object Count -gt 1 |
            Sort-Object Name |
            ForEach-Object {
                [pscustomobject][ordered]@{
                    statementSha256 = [string]$_.Name
                    occurrences = @(
                        $_.Group |
                            Sort-Object path, operationIndex |
                            ForEach-Object {
                                [pscustomobject][ordered]@{
                                    path = [string]$_.path
                                    line = [int]$_.line
                                    operationIndex = [int]$_.operationIndex
                                    targetTable = [string]$_.targetTable
                                }
                            }
                    )
                }
            }
    )
    $sourceTableNames = @(Get-ZylOrdinalSortedUniqueStrings -Values @(
            $records | ForEach-Object { $_.sourceTables }
        ))
    $shapeCounts = [ordered]@{}
    foreach ($shapeName in @('compound', 'grouped', 'joined', 'nested', 'simple')) {
        $shapeCounts[$shapeName] = @($records | Where-Object shape -eq $shapeName).Count
    }
    return [pscustomobject][ordered]@{
        schemaVersion = 1
        counts = [pscustomobject][ordered]@{
            statements = $records.Count
            primaryReasonInsertSelect = @(
                $records | Where-Object primaryKeyReason -eq 'insert-select'
            ).Count
            maskedByEarlierPrimaryReason = @(
                $records | Where-Object primaryKeyReason -ne 'insert-select'
            ).Count
            files = @(Get-ZylOrdinalSortedUniqueStrings -Values @($records.path)).Count
            targetTables = @(Get-ZylOrdinalSortedUniqueStrings -Values @(
                    $records.targetTable
                )).Count
            sourceTables = $sourceTableNames.Count
            withCte = @($records | Where-Object hasWith).Count
            joins = @($records | Where-Object hasJoin).Count
            filtered = @($records | Where-Object hasWhere).Count
            compound = @($records | Where-Object hasCompound).Count
            grouped = @($records | Where-Object hasGroupBy).Count
            ordered = @($records | Where-Object hasOrderBy).Count
            limited = @($records | Where-Object hasLimit).Count
            distinct = @($records | Where-Object hasDistinct).Count
            existenceGuarded = @($records | Where-Object hasExists).Count
            nestedSelect = @($records | Where-Object hasNestedSelect).Count
            guardOnly = @($records | Where-Object {
                    -not $_.hasTopLevelFrom -and $_.hasExists
                }).Count
            readsTargetTable = @($records | Where-Object readsTargetTable).Count
            exactDuplicateGroups = $duplicateGroups.Count
            exactDuplicateOccurrences = @(
                $duplicateGroups | ForEach-Object occurrences
            ).Count
            sourceExtractionIssues = @($issues | Where-Object {
                    $_ -like 'INSERT SELECT source-table extraction*'
                }).Count
        }
        shapeCounts = [pscustomobject]$shapeCounts
        records = @($records)
        exactDuplicateGroups = @($duplicateGroups)
        issues = @($issues)
    }
}

function Get-ZylDatabaseInsertSelectSemanticView {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Analysis
    )

    return [pscustomobject][ordered]@{
        schemaVersion = 1
        records = @(
            foreach ($record in @($Analysis.records)) {
                [pscustomobject][ordered]@{
                    path = [string]$record.path
                    operationIndex = [int]$record.operationIndex
                    targetTable = [string]$record.targetTable
                    conflictMode = $record.conflictMode
                    statementSha256 = [string]$record.statementSha256
                    primaryKeyReason = [string]$record.primaryKeyReason
                    shape = [string]$record.shape
                    sourceTables = @($record.sourceTables)
                    selectCount = [int]$record.selectCount
                    hasTopLevelFrom = [bool]$record.hasTopLevelFrom
                    hasWith = [bool]$record.hasWith
                    hasJoin = [bool]$record.hasJoin
                    hasWhere = [bool]$record.hasWhere
                    hasCompound = [bool]$record.hasCompound
                    hasGroupBy = [bool]$record.hasGroupBy
                    hasOrderBy = [bool]$record.hasOrderBy
                    hasLimit = [bool]$record.hasLimit
                    hasDistinct = [bool]$record.hasDistinct
                    hasExists = [bool]$record.hasExists
                    hasNestedSelect = [bool]$record.hasNestedSelect
                    readsTargetTable = [bool]$record.readsTargetTable
                    actionKeys = @($record.actionKeys)
                    criteria = @($record.criteria)
                }
            }
        )
        exactDuplicateGroups = @(
            foreach ($group in @($Analysis.exactDuplicateGroups)) {
                [pscustomobject][ordered]@{
                    statementSha256 = [string]$group.statementSha256
                    occurrences = @(
                        foreach ($occurrence in @($group.occurrences)) {
                            [pscustomobject][ordered]@{
                                path = [string]$occurrence.path
                                operationIndex = [int]$occurrence.operationIndex
                                targetTable = [string]$occurrence.targetTable
                            }
                        }
                    )
                }
            }
        )
    }
}

function Get-ZylDatabaseInsertSelectContractIssues {
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
        $issues.Add('Database INSERT SELECT contract schemaVersion must be 1.')
    }
    if ([string]$Contract.expectedAnalysisSha256 -notmatch '^[0-9a-f]{64}$') {
        $issues.Add('Database INSERT SELECT contract has an invalid expectedAnalysisSha256.')
    }
    elseif ($AnalysisSha256 -ne [string]$Contract.expectedAnalysisSha256) {
        $issues.Add(
            'Database INSERT SELECT analysis drifted from expected fingerprint: ' +
            "$AnalysisSha256 (expected $($Contract.expectedAnalysisSha256))."
        )
    }
    foreach ($countProperty in @(
            'statements',
            'primaryReasonInsertSelect',
            'maskedByEarlierPrimaryReason',
            'files',
            'targetTables',
            'sourceTables',
            'withCte',
            'joins',
            'filtered',
            'compound',
            'grouped',
            'ordered',
            'limited',
            'distinct',
            'existenceGuarded',
            'nestedSelect',
            'guardOnly',
            'readsTargetTable',
            'exactDuplicateGroups',
            'exactDuplicateOccurrences',
            'sourceExtractionIssues'
        )) {
        if ($null -eq $Contract.expectedCounts.PSObject.Properties[$countProperty]) {
            $issues.Add("Database INSERT SELECT contract is missing count: $countProperty")
        }
        elseif ([int]$Analysis.counts.$countProperty -ne
                [int]$Contract.expectedCounts.$countProperty) {
            $issues.Add(
                "Database INSERT SELECT count drifted for ${countProperty}: " +
                "$($Analysis.counts.$countProperty) " +
                "(expected $($Contract.expectedCounts.$countProperty))."
            )
        }
    }
    foreach ($shapeName in @('compound', 'grouped', 'joined', 'nested', 'simple')) {
        if ($null -eq $Contract.expectedShapeCounts.PSObject.Properties[$shapeName]) {
            $issues.Add("Database INSERT SELECT contract is missing shape count: $shapeName")
        }
        elseif ([int]$Analysis.shapeCounts.$shapeName -ne
                [int]$Contract.expectedShapeCounts.$shapeName) {
            $issues.Add(
                "Database INSERT SELECT shape count drifted for ${shapeName}: " +
                "$($Analysis.shapeCounts.$shapeName) " +
                "(expected $($Contract.expectedShapeCounts.$shapeName))."
            )
        }
    }
    foreach ($analysisIssue in @($Analysis.issues)) {
        $issues.Add([string]$analysisIssue)
    }
    return @($issues)
}
