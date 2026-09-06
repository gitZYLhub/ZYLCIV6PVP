[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ZYLPVPMOD is self-contained. This script synchronizes package identity and
# assembles migrated manifest sections from repository-owned sources. It has no
# parameters for upstream manifests and never reads Steam/Workshop caches or
# sibling projects. Criteria and actions are generated from manifest sources;
# file-list migration continues incrementally during M2.
$modRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$modRootPrefix = $modRoot.TrimEnd('\') + '\'
$projectMetadataPath = Join-Path $PSScriptRoot 'project.json'
$manifestSourcesPath = Join-Path $PSScriptRoot 'manifest\ManifestSources.ps1'
if (-not (Test-Path -LiteralPath $projectMetadataPath -PathType Leaf)) {
    throw "Project metadata not found: $projectMetadataPath"
}
if (-not (Test-Path -LiteralPath $manifestSourcesPath -PathType Leaf)) {
    throw "Manifest source helpers not found: $manifestSourcesPath"
}
. $manifestSourcesPath
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
$criteriaSourceDirectory = Join-Path $modRoot 'manifest\criteria'
$frontEndActionsSourceDirectory = Join-Path $modRoot 'manifest\actions\frontend'
$inGameActionsSourceDirectory = Join-Path $modRoot 'manifest\actions\ingame'
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

function Test-GeneratedSectionMatches {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlElement]$GeneratedSection,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlElement]$ExistingSection
    )

    # Human-facing comments may remain in the assembled ModInfo. The source
    # fragments own every runtime element, so compare that ordered element
    # sequence and avoid rewriting a semantically identical section.
    $generatedElements = @($GeneratedSection.ChildNodes | Where-Object NodeType -eq Element)
    $existingElements = @($ExistingSection.ChildNodes | Where-Object NodeType -eq Element)
    if ($generatedElements.Count -ne $existingElements.Count) {
        return $false
    }
    for ($index = 0; $index -lt $generatedElements.Count; $index++) {
        if ($generatedElements[$index].OuterXml -ne $existingElements[$index].OuterXml) {
            return $false
        }
    }
    return $true
}

function Sync-GeneratedSection {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$Document,

        [Parameter(Mandatory = $true)]
        [string]$SectionName,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlElement]$GeneratedSection,

        [Parameter(Mandatory = $true)]
        [string]$NextSectionName
    )

    $existingSection = [System.Xml.XmlElement]$Document.SelectSingleNode("/Mod/$SectionName")
    if ($null -eq $existingSection) {
        $nextSection = $Document.SelectSingleNode("/Mod/$NextSectionName")
        if ($null -eq $nextSection) {
            throw "ZYLPVPMOD.modinfo is missing both $SectionName and $NextSectionName."
        }
        [void]$Document.DocumentElement.InsertBefore($GeneratedSection, $nextSection)
        $script:manifestChanged = $true
    }
    elseif (-not (Test-GeneratedSectionMatches `
            -GeneratedSection $GeneratedSection `
            -ExistingSection $existingSection)) {
        [void]$existingSection.ParentNode.ReplaceChild($GeneratedSection, $existingSection)
        $script:manifestChanged = $true
    }
}

function Sync-ActionCriteria {
    param([System.Xml.XmlDocument]$Document)

    $generatedSection = New-ZylActionCriteriaSection `
        -OwnerDocument $Document `
        -SourceDirectory $criteriaSourceDirectory
    Sync-GeneratedSection `
        -Document $Document `
        -SectionName 'ActionCriteria' `
        -GeneratedSection $generatedSection `
        -NextSectionName 'FrontEndActions'
}

function Sync-ActionsSection {
    param(
        [System.Xml.XmlDocument]$Document,
        [ValidateSet('FrontEndActions', 'InGameActions')]
        [string]$SectionName,
        [string]$SourceDirectory,
        [string]$NextSectionName
    )

    $generatedSection = New-ZylActionsSection `
        -OwnerDocument $Document `
        -SectionName $SectionName `
        -SourceDirectory $SourceDirectory
    Sync-GeneratedSection `
        -Document $Document `
        -SectionName $SectionName `
        -GeneratedSection $generatedSection `
        -NextSectionName $NextSectionName
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

Sync-ActionCriteria $modInfo
Sync-ActionsSection `
    -Document $modInfo `
    -SectionName 'FrontEndActions' `
    -SourceDirectory $frontEndActionsSourceDirectory `
    -NextSectionName 'InGameActions'
Sync-ActionsSection `
    -Document $modInfo `
    -SectionName 'InGameActions' `
    -SourceDirectory $inGameActionsSourceDirectory `
    -NextSectionName 'Files'

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

Write-Host "Assembled ModInfo metadata and migrated sections for $packageName $packageVersion."
