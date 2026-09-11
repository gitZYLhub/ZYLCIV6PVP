<#
.SYNOPSIS
    校验"已安装的发布副本"与构建产物清单（manifest.json）完全对齐。

.DESCRIPTION
    构建脚本 build_workshop_release.ps1 每次发布都会生成
    artifacts/reports/ZYLPVPMOD-<版本>-<profile>.manifest.json，
    内含每个发布文件的 sha256/bytes 以及行有序聚合哈希 aggregateSha256。

    本脚本扫描一个已安装目录（默认是游戏实际加载的
    Documents\My Games\Sid Meier's Civilization VI\Mods\workshop-<profile>），
    与清单逐文件比对：缺失、多余、大小不一致、哈希不一致、文件数不一致、
    聚合哈希不一致，任一偏差即判定"未对齐"（exit 1）。

    判定"完全对齐"等价于：已安装目录 == 构建产物 == 本次开发树构建结果
    （构建产物由工作树确定性生成，见 build_workshop_release.ps1 与 validate.ps1）。

.PARAMETER Profile
    构建档案：windows / macos / universal。默认 windows。
    自动定位 artifacts/reports 下对应的清单文件。

.PARAMETER InstalledDir
    待校验的已安装目录。默认
    $env:USERPROFILE\Documents\My Games\Sid Meier's Civilization VI\Mods\workshop-<profile>。

.PARAMETER ManifestPath
    清单文件路径。默认按 -Profile 在 artifacts/reports 下自动查找。

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_deploy.ps1
    校验 windows 发布副本是否与最新构建产物一致。

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_deploy.ps1 `
        -InstalledDir "D:\some\manual\copy"
    校验任意目录与最新构建产物的一致性。

.NOTES
    只读操作，不修改任何文件。退出码：0=对齐，1=未对齐，2=用法/环境错误。
#>
[CmdletBinding()]
param(
    [ValidateSet('windows', 'macos', 'universal')]
    [string]$Profile = 'windows',

    [string]$InstalledDir,

    [string]$ManifestPath
)

$ErrorActionPreference = 'Stop'

$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$artifactsRoot = Join-Path $projectRoot 'artifacts'

if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $metadataPath = Join-Path $PSScriptRoot 'project.json'
    $metadata = Get-Content -LiteralPath $metadataPath -Raw | ConvertFrom-Json
    $expectedName = '{0}-{1}-{2}.manifest.json' -f [string]$metadata.packageName, [string]$metadata.semanticVersion, $Profile
    $ManifestPath = Join-Path $artifactsRoot ("reports\$expectedName")
}

if ([string]::IsNullOrWhiteSpace($InstalledDir)) {
    $InstalledDir = Join-Path $env:USERPROFILE "Documents\My Games\Sid Meier's Civilization VI\Mods\workshop-$Profile"
}

Write-Host "Manifest : $ManifestPath"
Write-Host "Installed: $InstalledDir"
Write-Host ''

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    Write-Host "ERROR: manifest not found: $ManifestPath" -ForegroundColor Red
    exit 2
}
if (-not (Test-Path -LiteralPath $InstalledDir -PathType Container)) {
    Write-Host "ERROR: installed directory not found: $InstalledDir" -ForegroundColor Red
    exit 2
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$manifestFiles = @($manifest.files)

# Scan the installed directory into a relative-path map ('/' separators, ordinal).
$installedMap = @{}
$installedFiles = @(Get-ChildItem -LiteralPath $InstalledDir -Recurse -Force -File)
foreach ($installedFile in $installedFiles) {
    $relative = $installedFile.FullName.Substring($InstalledDir.Length).TrimStart('\', '/').Replace('\', '/')
    $installedMap[$relative] = $installedFile
}

$manifestPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($entry in $manifestFiles) {
    [void]$manifestPaths.Add([string]$entry.path)
}

$missing = [System.Collections.Generic.List[string]]::new()
$extra = [System.Collections.Generic.List[string]]::new()
$hashMismatched = [System.Collections.Generic.List[string]]::new()
$sizeMismatched = [System.Collections.Generic.List[string]]::new()
$aggregateLines = [System.Collections.Generic.List[string]]::new()

foreach ($entry in $manifestFiles) {
    $path = [string]$entry.path
    if (-not $installedMap.ContainsKey($path)) {
        $missing.Add($path)
        continue
    }
    $installedFile = $installedMap[$path]
    $installedLength = [int64]$installedFile.Length
    $expectedLength = [int64]$entry.bytes
    if ($installedLength -ne $expectedLength) {
        $sizeMismatched.Add(('{0} (installed {1} B, manifest {2} B)' -f $path, $installedLength, $expectedLength))
    }
    $installedHash = (Get-FileHash -LiteralPath $installedFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($installedHash -ne [string]$entry.sha256) {
        $hashMismatched.Add(('{0} (installed {1}, manifest {2})' -f $path, $installedHash, [string]$entry.sha256))
    }
    $aggregateLines.Add(('{0} {1} {2}' -f $installedHash, $installedLength, $path))
}

foreach ($relative in @($installedMap.Keys)) {
    if (-not $manifestPaths.Contains($relative)) {
        $extra.Add($relative)
    }
}

# Recompute the aggregate exactly as build_workshop_release.ps1 does.
$aggregateText = ($aggregateLines -join "`n") + "`n"
$aggregateBytes = [System.Text.UTF8Encoding]::new($false).GetBytes($aggregateText)
$sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $computedAggregate = ([System.BitConverter]::ToString(
        $sha256.ComputeHash($aggregateBytes)
    )).Replace('-', '').ToLowerInvariant()
}
finally {
    $sha256.Dispose()
}

$expectedAggregate = [string]$manifest.aggregateSha256
$fileCountAligned = ($installedFiles.Count -eq $manifest.fileCount)
$aggregateAligned = ($computedAggregate -eq $expectedAggregate)

Write-Host '---- comparison ----'
Write-Host ('files        : installed {0} vs manifest {1}  {2}' -f $installedFiles.Count, $manifest.fileCount, $(if ($fileCountAligned) { 'OK' } else { 'MISMATCH' }))
Write-Host ('missing      : {0}' -f $missing.Count)
Write-Host ('extra        : {0}' -f $extra.Count)
Write-Host ('hash mismatch: {0}' -f $hashMismatched.Count)
Write-Host ('size mismatch: {0}' -f $sizeMismatched.Count)
Write-Host ('aggregate    : {0}' -f $computedAggregate)
Write-Host ('expected     : {0}  {1}' -f $expectedAggregate, $(if ($aggregateAligned) { 'OK' } else { 'MISMATCH' }))
Write-Host ''

if ($missing.Count -gt 0) {
    Write-Host '-- missing files --' -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  $_" }
}
if ($extra.Count -gt 0) {
    Write-Host '-- extra files --' -ForegroundColor Yellow
    $extra | ForEach-Object { Write-Host "  $_" }
}
if ($hashMismatched.Count -gt 0) {
    Write-Host '-- content mismatches --' -ForegroundColor Yellow
    $hashMismatched | ForEach-Object { Write-Host "  $_" }
}
if ($sizeMismatched.Count -gt 0) {
    Write-Host '-- size mismatches --' -ForegroundColor Yellow
    $sizeMismatched | ForEach-Object { Write-Host "  $_" }
}

$aligned = ($missing.Count -eq 0) -and ($extra.Count -eq 0) -and ($hashMismatched.Count -eq 0) -and ($sizeMismatched.Count -eq 0) -and $fileCountAligned -and $aggregateAligned

if ($aligned) {
    Write-Host 'PASS: installed release copy is fully aligned with the build manifest (== current development tree build).' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'FAIL: installed release copy is NOT aligned with the build manifest. Rebuild (build_workshop_release.ps1) and redeploy before testing.' -ForegroundColor Red
    exit 1
}
