[CmdletBinding()]
param(
	[string]$Destination
)

$ErrorActionPreference = 'Stop'

$sourceRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
if ([string]::IsNullOrWhiteSpace($Destination)) {
	$Destination = Join-Path (Split-Path -Parent $sourceRoot) 'ZYLPVPMOD_Workshop'
}
$destinationRoot = [System.IO.Path]::GetFullPath($Destination)
$destinationParent = Split-Path -Parent $destinationRoot
$sourcePrefix = $sourceRoot.TrimEnd('\') + '\'
$destinationPrefix = $destinationRoot.TrimEnd('\') + '\'

if ($destinationRoot.Equals($sourceRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
		$destinationRoot.StartsWith($sourcePrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
		$sourceRoot.StartsWith($destinationPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
		$destinationRoot.Equals([System.IO.Path]::GetPathRoot($destinationRoot), [System.StringComparison]::OrdinalIgnoreCase)) {
	throw "Unsafe workshop destination: $destinationRoot"
}
if (-not (Test-Path -LiteralPath $destinationParent -PathType Container)) {
	throw "Workshop destination parent does not exist: $destinationParent"
}
if (Test-Path -LiteralPath $destinationRoot) {
	$destinationItem = Get-Item -LiteralPath $destinationRoot -Force
	if (-not $destinationItem.PSIsContainer -or
			($destinationItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
		throw "Workshop destination must be a normal directory: $destinationRoot"
	}
}

$modInfoPath = Join-Path $sourceRoot 'ZYLPVPMOD.modinfo'
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
$excludedNodes = [System.Collections.Generic.List[System.Xml.XmlNode]]::new()

foreach ($fileNode in @($modInfo.SelectNodes('/Mod/Files/File'))) {
	$relativePath = $fileNode.InnerText.Trim().Replace('\', '/')
	if ([string]::IsNullOrWhiteSpace($relativePath) -or
			[System.IO.Path]::IsPathRooted($relativePath) -or
			$relativePath -match '(^|/)\.\.(/|$)') {
		throw "Unsafe path in ModInfo Files list: $relativePath"
	}
	if ($excludedPaths.Contains($relativePath)) {
		$excludedNodes.Add($fileNode)
		continue
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
		Length = (Get-Item -LiteralPath $sourcePath).Length
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
	if (-not $runtimePaths.Contains($actionPath)) {
		throw "Action file is absent from the runtime Files list: $actionPath"
	}
}

foreach ($excludedNode in $excludedNodes) {
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
	foreach ($entry in $runtimeEntries) {
		$targetPath = Join-Path $stageRoot $entry.RelativePath.Replace('/', '\')
		$targetParent = Split-Path -Parent $targetPath
		if (-not (Test-Path -LiteralPath $targetParent)) {
			[void](New-Item -ItemType Directory -Path $targetParent -Force)
		}
		Copy-Item -LiteralPath $entry.SourcePath -Destination $targetPath
	}

	$releaseModInfoPath = Join-Path $stageRoot 'ZYLPVPMOD.modinfo'
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
		if ((Get-Item -LiteralPath $targetPath).Length -ne $entry.Length) {
			throw "Copied file length mismatch: $($entry.RelativePath)"
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
	Write-Host ''
	Write-Host 'Workshop release created successfully.'
	Write-Host "Directory : $destinationRoot"
	Write-Host "Files     : $($releaseFiles.Count)"
	Write-Host ('Size      : {0:N2} MiB' -f ($releaseBytes / 1MB))
	Write-Host "Excluded  : $($excludedNodes.Count) source-only files, plus all unlisted project files"
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
