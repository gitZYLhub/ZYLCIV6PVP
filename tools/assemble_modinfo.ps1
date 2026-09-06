[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ZYLPVPMOD is self-contained. This script synchronizes package identity and
# required compatibility entries from tools/project.json. It deliberately has
# no parameters for upstream manifests and never reads Steam/Workshop caches or
# sibling projects. Action-graph generation is handled by the later M2 work.
$modRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$modRootPrefix = $modRoot.TrimEnd('\') + '\'
$projectMetadataPath = Join-Path $PSScriptRoot 'project.json'
if (-not (Test-Path -LiteralPath $projectMetadataPath -PathType Leaf)) {
    throw "Project metadata not found: $projectMetadataPath"
}
$projectMetadata = Get-Content -LiteralPath $projectMetadataPath -Raw | ConvertFrom-Json
if ($projectMetadata.schemaVersion -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$projectMetadata.modId) -or
        [string]::IsNullOrWhiteSpace([string]$projectMetadata.packageName) -or
        [string]::IsNullOrWhiteSpace([string]$projectMetadata.semanticVersion) -or
        [int]$projectMetadata.modInfoVersion -le 0) {
    throw 'tools/project.json is missing required schema-1 package metadata.'
}

$modInfoPath = Join-Path $modRoot ([string]$projectMetadata.modInfoFile)
$temporaryPath = Join-Path $modRoot ('.ZYLPVPMOD.modinfo.' + [System.Guid]::NewGuid().ToString('N') + '.tmp')

$unifiedId = [string]$projectMetadata.modId
$packageName = [string]$projectMetadata.packageName
$packageVersion = [string]$projectMetadata.semanticVersion
$modInfoVersion = ([int]$projectMetadata.modInfoVersion).ToString(
    [System.Globalization.CultureInfo]::InvariantCulture
)
$multiplayerHelperRelativePath = [string]$projectMetadata.multiplayerHelperFile
$vampireCastleScript = 'Components/TeamPVPSecretSocieties/Scripts/VampireCastle_Gameplay.lua'
$manifestChanged = $false

function Resolve-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $normalizedPath = $RelativePath.Trim().Replace('\', '/')
    if ([string]::IsNullOrWhiteSpace($normalizedPath) -or
            [System.IO.Path]::IsPathRooted($normalizedPath) -or
            $normalizedPath -match '(^|/)\.\.(/|$)') {
        throw "Manifest path must be project-relative: $RelativePath"
    }

    $fullPath = [System.IO.Path]::GetFullPath(
        (Join-Path $modRoot $normalizedPath.Replace('/', '\'))
    )
    if (-not $fullPath.StartsWith($modRootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Manifest path escapes the project root: $RelativePath"
    }
    return $fullPath
}

function Set-ChildText {
    param(
        [System.Xml.XmlDocument]$Document,
        [System.Xml.XmlElement]$Parent,
        [string]$Name,
        [string]$Value
    )

    $node = [System.Xml.XmlElement]$Parent.SelectSingleNode($Name)
    if ($null -eq $node) {
        $node = $Document.CreateElement($Name)
        [void]$Parent.AppendChild($node)
        $script:manifestChanged = $true
    }
    if ($node.InnerText -ne $Value) {
        $node.InnerText = $Value
        $script:manifestChanged = $true
    }
}

function Ensure-VampireCastleAction {
    param([System.Xml.XmlDocument]$Document)

    $section = [System.Xml.XmlElement]$Document.SelectSingleNode('/Mod/InGameActions')
    if ($null -eq $section) {
        throw 'ZYLPVPMOD.modinfo is missing InGameActions.'
    }

    $action = [System.Xml.XmlElement]$section.SelectSingleNode("*[@id='ZYL_TPVP_VampireCastleGameplay']")
    if ($null -ne $action -and $action.LocalName -ne 'AddGameplayScripts') {
        [void]$section.RemoveChild($action)
        $action = $null
        $script:manifestChanged = $true
    }
    if ($null -eq $action) {
        $action = $Document.CreateElement('AddGameplayScripts')
        $action.SetAttribute('id', 'ZYL_TPVP_VampireCastleGameplay')
        [void]$section.AppendChild($action)
        $script:manifestChanged = $true
    }

    $properties = [System.Xml.XmlElement]$action.SelectSingleNode('Properties')
    if ($null -eq $properties) {
        $properties = $Document.CreateElement('Properties')
        [void]$action.PrependChild($properties)
        $script:manifestChanged = $true
    }
    Set-ChildText $Document $properties 'LoadOrder' '250000031'

    if ($null -eq $action.SelectSingleNode("Criteria[.='ZYL_SecretSocietiesXP2']")) {
        $criterion = $Document.CreateElement('Criteria')
        $criterion.InnerText = 'ZYL_SecretSocietiesXP2'
        [void]$action.AppendChild($criterion)
        $script:manifestChanged = $true
    }
    if ($null -eq $action.SelectSingleNode("File[.='$vampireCastleScript']")) {
        $file = $Document.CreateElement('File')
        $file.InnerText = $vampireCastleScript
        [void]$action.AppendChild($file)
        $script:manifestChanged = $true
    }
}

function Ensure-ListedFile {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$RelativePath
    )

    $files = [System.Xml.XmlElement]$Document.SelectSingleNode('/Mod/Files')
    if ($null -eq $files) {
        throw 'ZYLPVPMOD.modinfo is missing Files.'
    }
    foreach ($fileNode in @($files.SelectNodes('File'))) {
        if ($fileNode.InnerText.Trim().Replace('\', '/').Equals(
                $RelativePath,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            return
        }
    }
    $file = $Document.CreateElement('File')
    $file.InnerText = $RelativePath
    [void]$files.AppendChild($file)
    $script:manifestChanged = $true
}

if (-not (Test-Path -LiteralPath $modInfoPath -PathType Leaf)) {
    throw "Local ModInfo not found: $modInfoPath"
}

$modInfo = [System.Xml.XmlDocument]::new()
$modInfo.PreserveWhitespace = $false
$modInfo.Load($modInfoPath)

if ($modInfo.DocumentElement.LocalName -ne 'Mod') {
    throw 'ZYLPVPMOD.modinfo does not have a Mod root element.'
}
if ($modInfo.DocumentElement.GetAttribute('id') -ne $unifiedId) {
    $modInfo.DocumentElement.SetAttribute('id', $unifiedId)
    $manifestChanged = $true
}
if ($modInfo.DocumentElement.GetAttribute('version') -ne $modInfoVersion) {
    $modInfo.DocumentElement.SetAttribute('version', $modInfoVersion)
    $manifestChanged = $true
}

$properties = [System.Xml.XmlElement]$modInfo.SelectSingleNode('/Mod/Properties')
if ($null -eq $properties) {
    throw 'ZYLPVPMOD.modinfo is missing Properties.'
}
Set-ChildText $modInfo $properties 'Version' $modInfoVersion
Set-ChildText $modInfo $properties 'ToolboxVersion' $packageVersion

$title = [System.Xml.XmlElement]$modInfo.SelectSingleNode(
    "/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_TITLE']"
)
if ($null -eq $title) {
    throw 'ZYLPVPMOD.modinfo is missing LOC_ZYLPVPMOD_TITLE.'
}
Set-ChildText $modInfo $title 'en_US' "$packageName $packageVersion"
Set-ChildText $modInfo $title 'zh_Hans_CN' "$packageName $packageVersion"

Ensure-VampireCastleAction $modInfo
Ensure-ListedFile $modInfo $vampireCastleScript

# Every path consumed by the generated manifest must resolve inside this
# repository. This is the hard boundary that prevents external cache reads.
$listedFiles = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($fileNode in @($modInfo.SelectNodes('/Mod/Files/File'))) {
    $relativePath = $fileNode.InnerText.Trim().Replace('\', '/')
    if (-not $listedFiles.Add($relativePath)) {
        throw "Duplicate path in ModInfo Files: $relativePath"
    }
    $fullPath = Resolve-ProjectFile $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Listed project file is missing: $relativePath"
    }
}

foreach ($fileNode in @($modInfo.SelectNodes(
    '/Mod/FrontEndActions/*//File | /Mod/InGameActions/*//File'
))) {
    $relativePath = $fileNode.InnerText.Trim().Replace('\', '/')
    [void](Resolve-ProjectFile $relativePath)
    if (-not $listedFiles.Contains($relativePath)) {
        throw "Action file is absent from the local Files list: $relativePath"
    }
}

$writerSettings = [System.Xml.XmlWriterSettings]::new()
$writerSettings.Indent = $true
$writerSettings.IndentChars = "`t"
$writerSettings.NewLineChars = "`r`n"
$writerSettings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
$writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false)

if ($manifestChanged) {
    try {
        $writer = [System.Xml.XmlWriter]::Create($temporaryPath, $writerSettings)
        try {
            $modInfo.Save($writer)
        }
        finally {
            $writer.Dispose()
        }
        [System.IO.File]::AppendAllText($temporaryPath, $writerSettings.NewLineChars, $writerSettings.Encoding)
        Move-Item -LiteralPath $temporaryPath -Destination $modInfoPath -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

$multiplayerHelperPath = Resolve-ProjectFile $multiplayerHelperRelativePath

$helperSource = Get-Content -LiteralPath $multiplayerHelperPath -Raw
$helperVersionPattern = '(?m)^local g_version = "[^"\r\n]+"'
$helperVersionReplacement = "local g_version = `"$packageName v$packageVersion`""
$helperVersionMatches = [regex]::Matches($helperSource, $helperVersionPattern)
if ($helperVersionMatches.Count -ne 1) {
    throw "Expected exactly one multiplayer version declaration in $multiplayerHelperPath; found $($helperVersionMatches.Count)."
}
$updatedHelperSource = [regex]::Replace(
    $helperSource,
    $helperVersionPattern,
    $helperVersionReplacement
)
if ($updatedHelperSource -ne $helperSource) {
    [System.IO.File]::WriteAllText(
        $multiplayerHelperPath,
        $updatedHelperSource,
        [System.Text.UTF8Encoding]::new($false)
    )
}

Write-Host "Synchronized package metadata for $packageName $packageVersion."
