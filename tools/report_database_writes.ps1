[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$modRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$metadataPath = Join-Path $PSScriptRoot 'project.json'
$writeSetHelpersPath = Join-Path $PSScriptRoot 'validation\DatabaseWriteSet.ps1'
$manifestGraphHelpersPath = Join-Path $PSScriptRoot 'validation\ManifestGraph.ps1'
$databaseSchemaHelpersPath = Join-Path $PSScriptRoot 'validation\DatabaseSchemaChecks.ps1'
$databasePrimaryKeyHelpersPath = Join-Path $PSScriptRoot 'validation\DatabasePrimaryKeys.ps1'
$writeSetContractPath = Join-Path $modRoot 'manifest\database-write-set-contract.json'
$externalDatabaseTablesPath = Join-Path $modRoot 'manifest\external-database-tables.json'
foreach ($requiredPath in @(
        $metadataPath,
        $writeSetHelpersPath,
        $manifestGraphHelpersPath,
        $databaseSchemaHelpersPath,
        $databasePrimaryKeyHelpersPath,
        $writeSetContractPath,
        $externalDatabaseTablesPath
    )) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Database write-set report dependency not found: $requiredPath"
    }
}
. $writeSetHelpersPath
. $manifestGraphHelpersPath
. $databaseSchemaHelpersPath
. $databasePrimaryKeyHelpersPath

$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
$modInfoPath = Join-Path $modRoot ([string]$metadata.modInfoFile)
if (-not (Test-Path -LiteralPath $modInfoPath -PathType Leaf)) {
    throw "ModInfo not found: $modInfoPath"
}

$artifactsRoot = [System.IO.Path]::GetFullPath((Join-Path $modRoot 'artifacts'))
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Join-Path $artifactsRoot 'reports') (
        "$([string]$metadata.packageName)-$([string]$metadata.semanticVersion)-database-writes.json"
    )
}
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$artifactsPrefix = $artifactsRoot.TrimEnd('\') + '\'
if (-not $resolvedOutputPath.StartsWith(
        $artifactsPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Database write-set report must stay inside artifacts: $resolvedOutputPath"
}

$modInfo = [System.Xml.XmlDocument]::new()
$modInfo.PreserveWhitespace = $false
$modInfo.Load($modInfoPath)
$analysis = Get-ZylDatabaseWriteSetAnalysis -ProjectRoot $modRoot -ModInfo $modInfo
if ($analysis.issues.Count -gt 0) {
    throw "Database write-set analysis failed:`n- $($analysis.issues -join "`n- ")"
}
$semanticView = Get-ZylDatabaseWriteSetSemanticView -Analysis $analysis
$analysisJson = ConvertTo-ZylCanonicalJson -InputObject $semanticView
$analysisSha256 = Get-ZylSha256ForText -Text $analysisJson
$schemaSnapshotPath = Join-Path $modRoot ([string]$metadata.civ6SchemaSnapshotFile)
$schemaSnapshot = Get-Content -LiteralPath $schemaSnapshotPath -Raw | ConvertFrom-Json
$schemaCoverage = Get-ZylDatabaseSchemaCoverage `
    -Analysis $analysis `
    -Snapshot $schemaSnapshot
$externalDatabaseTables = Get-Content `
    -LiteralPath $externalDatabaseTablesPath `
    -Raw | ConvertFrom-Json
$externalTableIssues = @(Get-ZylExternalDatabaseTableIssues `
    -Analysis $analysis `
    -Coverage $schemaCoverage `
    -Contract $externalDatabaseTables)
if ($externalTableIssues.Count -gt 0) {
    throw "External database-table contract failed:`n- $($externalTableIssues -join "`n- ")"
}
$primaryKeyAnalysis = Get-ZylDatabasePrimaryKeyAnalysis `
    -ProjectRoot $modRoot `
    -WriteSetAnalysis $analysis `
    -SchemaCoverage $schemaCoverage `
    -SchemaSnapshot $schemaSnapshot
$primaryKeySemanticView = Get-ZylDatabasePrimaryKeySemanticView `
    -Analysis $primaryKeyAnalysis
$primaryKeyAnalysisSha256 = Get-ZylSha256ForText -Text (
    ConvertTo-ZylCanonicalJson -InputObject $primaryKeySemanticView
)
$primaryKeyContractPath = Join-Path $modRoot (
    [string]$metadata.databasePrimaryKeyContractFile
)
$primaryKeyContract = Get-Content `
    -LiteralPath $primaryKeyContractPath `
    -Raw | ConvertFrom-Json
$primaryKeyContractIssues = @(Get-ZylDatabasePrimaryKeyContractIssues `
    -Analysis $primaryKeyAnalysis `
    -AnalysisSha256 $primaryKeyAnalysisSha256 `
    -Contract $primaryKeyContract)
if ($primaryKeyContractIssues.Count -gt 0) {
    throw "Database primary-key contract failed:`n- $($primaryKeyContractIssues -join "`n- ")"
}
$writeSetContract = Get-Content -LiteralPath $writeSetContractPath -Raw | ConvertFrom-Json
$contractIssues = @(Get-ZylDatabaseWriteSetContractIssues `
    -Analysis $analysis `
    -AnalysisSha256 $analysisSha256 `
    -Contract $writeSetContract)
if ($contractIssues.Count -gt 0) {
    throw "Database write-set contract failed:`n- $($contractIssues -join "`n- ")"
}
$report = [pscustomobject][ordered]@{
    schemaVersion = 1
    packageName = [string]$metadata.packageName
    semanticVersion = [string]$metadata.semanticVersion
    modInfoSha256 = (Get-FileHash -LiteralPath $modInfoPath -Algorithm SHA256).Hash.ToLowerInvariant()
    analysisSha256 = $analysisSha256
    frozenAnalysisSha256 = [string]$writeSetContract.frozenAnalysisSha256
    differsFromFrozen = $analysisSha256 -ne [string]$writeSetContract.frozenAnalysisSha256
    counts = $analysis.counts
    actionReferences = $analysis.actionReferences
    sourceFiles = $analysis.sourceFiles
    tables = $analysis.tables
    overlappingTables = $analysis.overlappingTables
    noWriteSources = $analysis.noWriteSources
    sameActionExactSqlDuplicateGroups = $analysis.sameActionExactSqlDuplicateGroups
    schemaCoverage = $schemaCoverage
    primaryKeyAnalysisSha256 = $primaryKeyAnalysisSha256
    primaryKeyAnalysis = $primaryKeyAnalysis
}

$outputDirectory = Split-Path -Parent $resolvedOutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $outputDirectory -Force)
}
[System.IO.File]::WriteAllText(
    $resolvedOutputPath,
    (ConvertTo-ZylCanonicalJson -InputObject $report) + "`n",
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Database write-set report created: $resolvedOutputPath"
Write-Host "Actions    : $($analysis.counts.databaseActions)"
Write-Host "References : $($analysis.counts.sourceReferences)"
Write-Host "Sources    : $($analysis.counts.uniqueSources) ($($analysis.counts.sqlSources) SQL, $($analysis.counts.xmlSources) XML)"
Write-Host "Writes     : $($analysis.counts.writeOperations) across $($analysis.counts.tables) tables"
Write-Host "Overlaps   : $($analysis.counts.overlappingTables) tables touched by multiple sources"
Write-Host "No writes  : $($analysis.counts.noWriteSources) active sources"
Write-Host "Duplicates : $($analysis.counts.sameActionExactSqlDuplicateGroups) exact SQL groups within one action"
Write-Host "Schema     : $($schemaCoverage.counts.official) official, $($schemaCoverage.counts.modCreated) mod-created, $($schemaCoverage.counts.external) external tables"
Write-Host "Custom keys: $($primaryKeyAnalysis.counts.modCreatedTablesWithPrimaryKey) of $($primaryKeyAnalysis.counts.modCreatedTables) mod-created tables"
Write-Host "Keys       : $($primaryKeyAnalysis.counts.rowCandidates) row candidates across $($primaryKeyAnalysis.counts.tablesWithCandidates) tables"
Write-Host "Key repeats: $($primaryKeyAnalysis.counts.duplicateKeyGroups) groups, $($primaryKeyAnalysis.counts.sameActionDuplicateKeyGroups) within one action"
Write-Host "SHA-256    : $($report.analysisSha256)"
