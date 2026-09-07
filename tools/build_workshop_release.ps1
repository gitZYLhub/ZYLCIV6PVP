[CmdletBinding()]
param(
	[string]$Destination,

	[ValidateSet('universal', 'windows', 'macos')]
	[string]$Profile = 'universal'
)

$ErrorActionPreference = 'Stop'
$Profile = $Profile.ToLowerInvariant()

$releaseChecksPath = Join-Path $PSScriptRoot 'validation\ReleaseChecks.ps1'
if (-not (Test-Path -LiteralPath $releaseChecksPath -PathType Leaf)) {
	throw "Release validation helpers not found: $releaseChecksPath"
}
. $releaseChecksPath

$releaseTextExtensions = [System.Collections.Generic.HashSet[string]]::new(
	[System.StringComparer]::OrdinalIgnoreCase
)
@(
	'.anm',
	'.artdef',
	'.dep',
	'.geo',
	'.lua',
	'.md',
	'.modinfo',
	'.mtl',
	'.ps1',
	'.psm1',
	'.sql',
	'.tex',
	'.txt',
	'.xlp',
	'.xml'
) | ForEach-Object { [void]$releaseTextExtensions.Add($_) }
$strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)

function Test-ZylReleaseTextPath {
	param([Parameter(Mandatory = $true)][string]$RelativePath)

	if ($RelativePath.Equals('LICENSE', [System.StringComparison]::OrdinalIgnoreCase)) {
		return $true
	}
	return $releaseTextExtensions.Contains(
		[System.IO.Path]::GetExtension($RelativePath)
	)
}

function ConvertTo-ZylReleaseTextBytes {
	param(
		[Parameter(Mandatory = $true)]
		[byte[]]$SourceBytes,

		[Parameter(Mandatory = $true)]
		[string]$RelativePath
	)

	try {
		$text = $strictUtf8.GetString($SourceBytes)
	}
	catch {
		throw "Release text file is not valid UTF-8: $RelativePath"
	}
	$normalizedText = $text.Replace("`r`n", "`n")
	$normalizedBytes = $utf8WithoutBom.GetBytes($normalizedText)
	Write-Output -NoEnumerate $normalizedBytes
}

$normalizationFixture = [byte[]](239, 187, 191, 65, 13, 10, 66, 10, 67, 13, 68)
[byte[]]$normalizedFixture = ConvertTo-ZylReleaseTextBytes `
	-SourceBytes $normalizationFixture `
	-RelativePath 'fixture.xml'
if ([System.BitConverter]::ToString($normalizedFixture) -ne 'EF-BB-BF-41-0A-42-0A-43-0D-44' -or
		-not (Test-ZylReleaseTextPath 'file.lua') -or
		-not (Test-ZylReleaseTextPath 'texture.tex') -or
		-not (Test-ZylReleaseTextPath 'LICENSE') -or
		(Test-ZylReleaseTextPath 'texture.dds')) {
	throw 'Release text-normalization helper failed its positive/binary-boundary self-test.'
}
if (-not (Test-ZylReleasePathIncluded -RelativePath 'common/file.xml' -Profile 'windows') -or
		-not (Test-ZylReleasePathIncluded -RelativePath 'Platforms/Windows/a.blp' -Profile 'windows') -or
		(Test-ZylReleasePathIncluded -RelativePath 'Platforms/MacOS/a.blp' -Profile 'windows') -or
		-not (Test-ZylReleasePathIncluded -RelativePath 'Nested/Platforms/MacOS/a.blp' -Profile 'macos') -or
		-not (Test-ZylReleasePathIncluded -RelativePath 'Platforms/MacOS/a.blp' -Profile 'universal')) {
	throw 'Release profile helper failed its positive/negative self-test.'
}
$invalidUtf8Rejected = $false
try {
	[void](ConvertTo-ZylReleaseTextBytes `
		-SourceBytes ([byte[]](195, 40)) `
		-RelativePath 'invalid-fixture.xml')
}
catch {
	$invalidUtf8Rejected = $true
}
if (-not $invalidUtf8Rejected) {
	throw 'Release text-normalization helper accepted invalid UTF-8.'
}

$sourceRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$projectMetadataPath = Join-Path $PSScriptRoot 'project.json'
if (-not (Test-Path -LiteralPath $projectMetadataPath -PathType Leaf)) {
	throw "Project metadata not found: $projectMetadataPath"
}
$projectMetadata = Get-Content -LiteralPath $projectMetadataPath -Raw | ConvertFrom-Json
$packageName = [string]$projectMetadata.packageName
$packageVersion = [string]$projectMetadata.semanticVersion
$artifactsRoot = [System.IO.Path]::GetFullPath((Join-Path $sourceRoot 'artifacts'))
if ([string]::IsNullOrWhiteSpace($Destination)) {
	$destinationName = if ($Profile -eq 'universal') {
		'workshop'
	}
	else {
		"workshop-$Profile"
	}
	$Destination = Join-Path $artifactsRoot $destinationName
}
$destinationRoot = [System.IO.Path]::GetFullPath($Destination)
$destinationParent = Split-Path -Parent $destinationRoot
$sourcePrefix = $sourceRoot.TrimEnd('\') + '\'
$destinationPrefix = $destinationRoot.TrimEnd('\') + '\'
$artifactsPrefix = $artifactsRoot.TrimEnd('\') + '\'
$destinationIsInsideSource = $destinationRoot.StartsWith(
	$sourcePrefix,
	[System.StringComparison]::OrdinalIgnoreCase
)

if ($destinationRoot.Equals($sourceRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
		$sourceRoot.StartsWith($destinationPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
		($destinationIsInsideSource -and
			-not $destinationRoot.StartsWith($artifactsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) -or
		$destinationRoot.Equals([System.IO.Path]::GetPathRoot($destinationRoot), [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Unsafe workshop destination: $destinationRoot"
}
if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
	[void](New-Item -ItemType Directory -Path $destinationParent -Force)
}
if (Test-Path -LiteralPath $destinationRoot) {
	$destinationItem = Get-Item -LiteralPath $destinationRoot -Force
	if (-not $destinationItem.PSIsContainer -or
			($destinationItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
		throw "Workshop destination must be a normal directory: $destinationRoot"
	}
}

$modInfoPath = Join-Path $sourceRoot ([string]$projectMetadata.modInfoFile)
$sourceValidator = Join-Path $sourceRoot 'tools\validate.ps1'

# These files are useful in the source repository but are not read by Civ VI.
$excludedPaths = [System.Collections.Generic.HashSet[string]]::new(
	[System.StringComparer]::OrdinalIgnoreCase
)
@(
	'CONFLICT_RESOLUTION.md',
	'README.md',
	'SOURCES.md',
	'TEST_CHECKLIST.md',
	'tools/assemble_modinfo.ps1',
	'tools/validate.ps1'
) | ForEach-Object { [void]$excludedPaths.Add($_) }

Write-Host 'Validating source package...'
& $sourceValidator

$modInfo = [System.Xml.XmlDocument]::new()
$modInfo.PreserveWhitespace = $true
$modInfo.Load($modInfoPath)

$runtimeEntries = [System.Collections.Generic.List[object]]::new()
$runtimePaths = [System.Collections.Generic.HashSet[string]]::new(
	[System.StringComparer]::OrdinalIgnoreCase
)
$sourceOnlyExcludedNodes = [System.Collections.Generic.List[System.Xml.XmlNode]]::new()
$platformExcludedNodes = [System.Collections.Generic.List[System.Xml.XmlNode]]::new()
$platformAssetIncludedCount = 0

foreach ($fileNode in @($modInfo.SelectNodes('/Mod/Files/File'))) {
	$relativePath = $fileNode.InnerText.Trim().Replace('\', '/')
	if ([string]::IsNullOrWhiteSpace($relativePath) -or
			[System.IO.Path]::IsPathRooted($relativePath) -or
			$relativePath -match '(^|/)\.\.(/|$)') {
		throw "Unsafe path in ModInfo Files list: $relativePath"
	}
	if ($excludedPaths.Contains($relativePath)) {
		$sourceOnlyExcludedNodes.Add($fileNode)
		continue
	}
	if (-not (Test-ZylReleasePathIncluded -RelativePath $relativePath -Profile $Profile)) {
		$platformExcludedNodes.Add($fileNode)
		continue
	}
	if ($null -ne (Get-ZylPlatformAssetDescriptor -RelativePath $relativePath)) {
		$platformAssetIncludedCount++
	}
	if (-not $runtimePaths.Add($relativePath)) {
		throw "Duplicate runtime path in ModInfo: $relativePath"
	}

	$sourcePath = [System.IO.Path]::GetFullPath(
		(Join-Path $sourceRoot $relativePath.Replace('/', '\'))
	)
	if (-not $sourcePath.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw "Runtime path escapes the project root: $relativePath"
	}
	if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
		throw "Runtime file is missing: $relativePath"
	}
	$runtimeEntries.Add([pscustomobject]@{
		RelativePath = $relativePath
		SourcePath = $sourcePath
		SourceLength = (Get-Item -LiteralPath $sourcePath).Length
		NormalizeText = Test-ZylReleaseTextPath $relativePath
		ExpectedLength = [int64]0
	})
}

# No file used by an action may be removed as documentation/development data.
foreach ($actionFileNode in @($modInfo.SelectNodes(
	'/Mod/FrontEndActions/*/File | /Mod/InGameActions/*/File'
))) {
	$actionPath = $actionFileNode.InnerText.Trim().Replace('\', '/')
	if ($excludedPaths.Contains($actionPath)) {
		throw "Excluded path is still referenced by a ModInfo action: $actionPath"
	}
	if (-not (Test-ZylReleasePathIncluded -RelativePath $actionPath -Profile $Profile)) {
		throw "Platform-pruned path is still referenced by a ModInfo action: $actionPath"
	}
	if (-not $runtimePaths.Contains($actionPath)) {
		throw "Action file is absent from the runtime Files list: $actionPath"
	}
}

foreach ($excludedNode in @($sourceOnlyExcludedNodes) + @($platformExcludedNodes)) {
	[void]$excludedNode.ParentNode.RemoveChild($excludedNode)
}

$stageRoot = Join-Path $destinationParent (
	'.' + [System.IO.Path]::GetFileName($destinationRoot) + '.staging-' +
	[System.Guid]::NewGuid().ToString('N')
)
$backupRoot = $null

try {
	[void](New-Item -ItemType Directory -Path $stageRoot)
	Write-Host "Copying $($runtimeEntries.Count) runtime files..."
	$normalizedTextFileCount = 0
	foreach ($entry in $runtimeEntries) {
		$targetPath = Join-Path $stageRoot $entry.RelativePath.Replace('/', '\')
		$targetParent = Split-Path -Parent $targetPath
		if (-not (Test-Path -LiteralPath $targetParent)) {
			[void](New-Item -ItemType Directory -Path $targetParent -Force)
		}
		if ($entry.NormalizeText) {
			[byte[]]$sourceBytes = [System.IO.File]::ReadAllBytes($entry.SourcePath)
			[byte[]]$normalizedBytes = ConvertTo-ZylReleaseTextBytes `
				-SourceBytes $sourceBytes `
				-RelativePath $entry.RelativePath
			[System.IO.File]::WriteAllBytes($targetPath, $normalizedBytes)
			$entry.ExpectedLength = $normalizedBytes.Length
			$normalizedTextFileCount++
		}
		else {
			Copy-Item -LiteralPath $entry.SourcePath -Destination $targetPath
			$entry.ExpectedLength = $entry.SourceLength
		}
	}

	$releaseModInfoPath = Join-Path $stageRoot ([string]$projectMetadata.modInfoFile)
	$xmlSettings = [System.Xml.XmlWriterSettings]::new()
	$xmlSettings.Encoding = [System.Text.UTF8Encoding]::new($false)
	$xmlSettings.Indent = $false
	$xmlWriter = [System.Xml.XmlWriter]::Create($releaseModInfoPath, $xmlSettings)
	try {
		$modInfo.Save($xmlWriter)
	}
	finally {
		$xmlWriter.Dispose()
	}

	# Verify that the staging directory contains exactly the pruned manifest and
	# its runtime files—nothing inherited from Git or the reference archive.
	$stagedFiles = @(Get-ChildItem -LiteralPath $stageRoot -Recurse -Force -File)
	$expectedFileCount = $runtimeEntries.Count + 1
	if ($stagedFiles.Count -ne $expectedFileCount) {
		throw "Unexpected staging file count: expected $expectedFileCount, found $($stagedFiles.Count)"
	}
	foreach ($entry in $runtimeEntries) {
		$targetPath = Join-Path $stageRoot $entry.RelativePath.Replace('/', '\')
		if ((Get-Item -LiteralPath $targetPath).Length -ne $entry.ExpectedLength) {
			throw "Staged file length mismatch: $($entry.RelativePath)"
		}
	}
	foreach ($forbiddenPath in @('.git', 'BBG', 'tools')) {
		if (Test-Path -LiteralPath (Join-Path $stageRoot $forbiddenPath)) {
			throw "Forbidden top-level path entered the workshop package: $forbiddenPath"
		}
	}
	foreach ($excludedPath in $excludedPaths) {
		if (Test-Path -LiteralPath (Join-Path $stageRoot $excludedPath.Replace('/', '\'))) {
			throw "Excluded source file entered the workshop package: $excludedPath"
		}
	}

	$releaseModInfo = [System.Xml.XmlDocument]::new()
	$releaseModInfo.Load($releaseModInfoPath)
	$releaseList = @($releaseModInfo.SelectNodes('/Mod/Files/File'))
	if ($releaseList.Count -ne $runtimeEntries.Count) {
		throw "Pruned ModInfo file count mismatch: expected $($runtimeEntries.Count), found $($releaseList.Count)"
	}

	# Replace only the fully resolved, safety-checked destination.  Keep the old
	# directory as a temporary rollback target until the new one is in place.
	if (Test-Path -LiteralPath $destinationRoot) {
		$backupRoot = $destinationRoot + '.previous-' + [System.Guid]::NewGuid().ToString('N')
		Move-Item -LiteralPath $destinationRoot -Destination $backupRoot
	}
	try {
		Move-Item -LiteralPath $stageRoot -Destination $destinationRoot
	}
	catch {
		if ($null -ne $backupRoot -and
				(Test-Path -LiteralPath $backupRoot) -and
				-not (Test-Path -LiteralPath $destinationRoot)) {
			Move-Item -LiteralPath $backupRoot -Destination $destinationRoot
			$backupRoot = $null
		}
		throw
	}
	if ($null -ne $backupRoot -and (Test-Path -LiteralPath $backupRoot)) {
		Remove-Item -LiteralPath $backupRoot -Recurse -Force
		$backupRoot = $null
	}

	$releaseFiles = @(Get-ChildItem -LiteralPath $destinationRoot -Recurse -Force -File)
	$releaseBytes = ($releaseFiles | Measure-Object -Property Length -Sum).Sum
	$releaseFileMap = @{}
	$releaseRelativePaths = [System.Collections.Generic.List[string]]::new()
	foreach ($releaseFile in $releaseFiles) {
		$relativePath = $releaseFile.FullName.Substring($destinationRoot.Length + 1).Replace('\', '/')
		$releaseFileMap[$relativePath] = $releaseFile
		$releaseRelativePaths.Add($relativePath)
	}
	$releaseRelativePaths.Sort([System.StringComparer]::Ordinal)
	$manifestEntries = [System.Collections.Generic.List[object]]::new()
	foreach ($relativePath in $releaseRelativePaths) {
		$releaseFile = $releaseFileMap[$relativePath]
		$manifestEntries.Add([pscustomobject][ordered]@{
			path = $relativePath
			bytes = $releaseFile.Length
			sha256 = (Get-FileHash -LiteralPath $releaseFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
		})
	}
	$aggregateLines = @($manifestEntries | ForEach-Object {
		'{0} {1} {2}' -f $_.sha256, $_.bytes, $_.path
	})
	$aggregateText = ($aggregateLines -join "`n") + "`n"
	$aggregateBytes = [System.Text.UTF8Encoding]::new($false).GetBytes($aggregateText)
	$sha256 = [System.Security.Cryptography.SHA256]::Create()
	try {
		$aggregateHash = ([System.BitConverter]::ToString(
			$sha256.ComputeHash($aggregateBytes)
		)).Replace('-', '').ToLowerInvariant()
	}
	finally {
		$sha256.Dispose()
	}
	$reportRoot = Join-Path $artifactsRoot 'reports'
	[void](New-Item -ItemType Directory -Path $reportRoot -Force)
	$reportPath = Join-Path $reportRoot "$packageName-$packageVersion-$Profile.manifest.json"
	$report = [pscustomobject][ordered]@{
		schemaVersion = 3
		packageName = $packageName
		semanticVersion = $packageVersion
		modId = [string]$projectMetadata.modId
		profile = $Profile
		textNormalization = 'utf8-lf'
		normalizedTextFileCount = $normalizedTextFileCount
		sourceOnlyExcludedCount = $sourceOnlyExcludedNodes.Count
		platformAssetIncludedCount = $platformAssetIncludedCount
		platformExcludedCount = $platformExcludedNodes.Count
		fileCount = $releaseFiles.Count
		totalBytes = [int64]$releaseBytes
		aggregateSha256 = $aggregateHash
		files = $manifestEntries
	}
	$reportJson = $report | ConvertTo-Json -Depth 5 -Compress
	[System.IO.File]::WriteAllText(
		$reportPath,
		$reportJson + "`n",
		[System.Text.UTF8Encoding]::new($false)
	)
	Write-Host ''
	Write-Host 'Workshop release created successfully.'
	Write-Host "Profile   : $Profile"
	Write-Host "Directory : $destinationRoot"
	Write-Host "Files     : $($releaseFiles.Count)"
	Write-Host ('Size      : {0:N2} MiB' -f ($releaseBytes / 1MB))
	Write-Host "SHA-256   : $aggregateHash"
	Write-Host "Text      : $normalizedTextFileCount UTF-8 files normalized to LF"
	Write-Host "Manifest  : $reportPath"
	Write-Host "Excluded  : $($sourceOnlyExcludedNodes.Count) source-only and $($platformExcludedNodes.Count) opposite-platform files, plus all unlisted project files"
}
finally {
	if (Test-Path -LiteralPath $stageRoot) {
		Remove-Item -LiteralPath $stageRoot -Recurse -Force
	}
	if ($null -ne $backupRoot -and
			(Test-Path -LiteralPath $backupRoot) -and
			-not (Test-Path -LiteralPath $destinationRoot)) {
		Move-Item -LiteralPath $backupRoot -Destination $destinationRoot
	}
}
