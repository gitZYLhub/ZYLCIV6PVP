[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$modRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$metadataPath = Join-Path $PSScriptRoot 'project.json'
$manifestGraphHelpers = Join-Path $PSScriptRoot 'validation\ManifestGraph.ps1'
$actionGraphContractPath = Join-Path $modRoot 'manifest\baseline-1.3.0-action-graph.json'
if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    throw "Project metadata not found: $metadataPath"
}
if (-not (Test-Path -LiteralPath $manifestGraphHelpers -PathType Leaf)) {
    throw "Manifest graph helpers not found: $manifestGraphHelpers"
}
if (-not (Test-Path -LiteralPath $actionGraphContractPath -PathType Leaf)) {
    throw "Manifest action-graph contract not found: $actionGraphContractPath"
}
. $manifestGraphHelpers

$metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
$modInfoPath = Join-Path $modRoot ([string]$metadata.modInfoFile)
if (-not (Test-Path -LiteralPath $modInfoPath -PathType Leaf)) {
    throw "ModInfo not found: $modInfoPath"
}

$artifactsRoot = [System.IO.Path]::GetFullPath((Join-Path $modRoot 'artifacts'))
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Join-Path $artifactsRoot 'reports') (
        "$([string]$metadata.packageName)-$([string]$metadata.semanticVersion)-modinfo-graph.json"
    )
}
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
$artifactsPrefix = $artifactsRoot.TrimEnd('\') + '\'
if (-not $resolvedOutputPath.StartsWith($artifactsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "ModInfo graph report must stay inside artifacts: $resolvedOutputPath"
}

$document = [System.Xml.XmlDocument]::new()
$document.PreserveWhitespace = $false
$document.Load($modInfoPath)
$graph = Get-ZylModInfoActionGraph -Path $modInfoPath
$graphJson = ConvertTo-ZylCanonicalJson -InputObject $graph
$actionGraphSha256 = Get-ZylSha256ForText -Text $graphJson
$actionGraphContract = Get-Content -LiteralPath $actionGraphContractPath -Raw | ConvertFrom-Json
$report = [ordered]@{
    schemaVersion = 1
    packageName = [string]$metadata.packageName
    semanticVersion = [string]$metadata.semanticVersion
    actionGraphSha256 = $actionGraphSha256
    frozenActionGraphSha256 = [string]$actionGraphContract.frozenActionGraphSha256
    differsFromFrozen = $actionGraphSha256 -ne [string]$actionGraphContract.frozenActionGraphSha256
    counts = [ordered]@{
        criteria = @($document.SelectNodes('/Mod/ActionCriteria/Criteria')).Count
        frontEndActions = @($document.SelectNodes('/Mod/FrontEndActions/*')).Count
        inGameActions = @($document.SelectNodes('/Mod/InGameActions/*')).Count
        files = @($document.SelectNodes('/Mod/Files/File')).Count
    }
    graph = $graph
}

$outputDirectory = Split-Path -Parent $resolvedOutputPath
if (-not (Test-Path -LiteralPath $outputDirectory -PathType Container)) {
    [void](New-Item -ItemType Directory -Path $outputDirectory -Force)
}
$reportJson = $report | ConvertTo-Json -Depth 100
[System.IO.File]::WriteAllText(
    $resolvedOutputPath,
    $reportJson + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "ModInfo graph report created: $resolvedOutputPath"
Write-Host "Criteria  : $($report.counts.criteria)"
Write-Host "Actions   : $($report.counts.frontEndActions + $report.counts.inGameActions)"
Write-Host "Files     : $($report.counts.files)"
Write-Host "SHA-256   : $($report.actionGraphSha256)"
Write-Host "Frozen    : $($report.frozenActionGraphSha256)"
Write-Host "Changed   : $($report.differsFromFrozen)"
