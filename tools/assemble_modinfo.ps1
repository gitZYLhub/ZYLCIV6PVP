[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ZYLPVPMOD is self-contained. This script deliberately has no parameters for
# upstream manifests and never reads Steam/Workshop caches or sibling projects.
$modRoot = [System.IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$modRootPrefix = $modRoot.TrimEnd('\') + '\'
$modInfoPath = Join-Path $modRoot 'ZYLPVPMOD.modinfo'
$temporaryPath = Join-Path $modRoot ('.ZYLPVPMOD.modinfo.' + [System.Guid]::NewGuid().ToString('N') + '.tmp')

$unifiedId = '4dd01931-9d44-4a8a-8e74-712cba0f0072'
$packageVersion = '1.3.0'
$modInfoVersion = '130'
$vampireCastleScript = 'Components/TeamPVPSecretSocieties/Scripts/VampireCastle_Gameplay.lua'

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
    }
    $node.InnerText = $Value
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
    }
    if ($null -eq $action) {
        $action = $Document.CreateElement('AddGameplayScripts')
        $action.SetAttribute('id', 'ZYL_TPVP_VampireCastleGameplay')
        [void]$section.AppendChild($action)
    }

    $properties = [System.Xml.XmlElement]$action.SelectSingleNode('Properties')
    if ($null -eq $properties) {
        $properties = $Document.CreateElement('Properties')
        [void]$action.PrependChild($properties)
    }
    Set-ChildText $Document $properties 'LoadOrder' '250000031'

    if ($null -eq $action.SelectSingleNode("Criteria[.='ZYL_SecretSocietiesXP2']")) {
        $criterion = $Document.CreateElement('Criteria')
        $criterion.InnerText = 'ZYL_SecretSocietiesXP2'
        [void]$action.AppendChild($criterion)
    }
    if ($null -eq $action.SelectSingleNode("File[.='$vampireCastleScript']")) {
        $file = $Document.CreateElement('File')
        $file.InnerText = $vampireCastleScript
        [void]$action.AppendChild($file)
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
$modInfo.DocumentElement.SetAttribute('id', $unifiedId)
$modInfo.DocumentElement.SetAttribute('version', $modInfoVersion)

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
Set-ChildText $modInfo $title 'en_US' "ZYLPVPMOD $packageVersion"
Set-ChildText $modInfo $title 'zh_Hans_CN' "ZYLPVPMOD $packageVersion"

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

Write-Host "Updated local-only ModInfo: $modInfoPath"
