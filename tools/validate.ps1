[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
$modInfoPath = Join-Path $modRoot 'ZYLPVPMOD.modinfo'
$expectedModId = '4dd01931-9d44-4a8a-8e74-712cba0f0072'
$validationErrors = [System.Collections.Generic.List[string]]::new()

function Add-ValidationError {
    param([string]$Message)
    $validationErrors.Add($Message)
}

function Normalize-RelativePath {
    param([string]$Path)
    return $Path.Trim().Replace('/', '\').ToLowerInvariant()
}

function Load-XmlDocument {
    param([string]$Path)
    $document = [System.Xml.XmlDocument]::new()
    $document.PreserveWhitespace = $false
    $document.Load($Path)
    return $document
}

if (-not (Test-Path -LiteralPath $modInfoPath)) {
    throw "ModInfo not found: $modInfoPath"
}

# Validate every XML-bearing artifact, including the BBM art dependency.
$xmlFiles = @(Get-ChildItem -LiteralPath $modRoot -Recurse -File | Where-Object {
    $_.Extension -in @('.xml', '.modinfo', '.dep')
})
foreach ($xmlFile in $xmlFiles) {
    try {
        [void](Load-XmlDocument $xmlFile.FullName)
    }
    catch {
        Add-ValidationError "Invalid XML: $($xmlFile.FullName) :: $($_.Exception.Message)"
    }
}

$modInfo = Load-XmlDocument $modInfoPath
if ($modInfo.DocumentElement.GetAttribute('id') -ne $expectedModId) {
    Add-ValidationError "Unexpected Mod ID: $($modInfo.DocumentElement.GetAttribute('id'))"
}
if ($modInfo.SelectSingleNode('/Mod/Properties/Name').InnerText -ne 'LOC_ZYLPVPMOD_TITLE') {
    Add-ValidationError 'The ModInfo title is not the ZYLPVPMOD localization key.'
}

# Build a case-insensitive manifest for Windows/macOS portability.
$listedFiles = [System.Collections.Generic.List[string]]::new()
$listedFileMap = @{}
foreach ($fileNode in @($modInfo.SelectNodes('/Mod/Files/File'))) {
    $relativePath = $fileNode.InnerText.Trim().Replace('/', '\')
    $key = Normalize-RelativePath $relativePath
    if ($listedFileMap.ContainsKey($key)) {
        Add-ValidationError "Duplicate <Files> entry (case-insensitive): $relativePath"
    }
    else {
        $listedFileMap[$key] = $relativePath
        $listedFiles.Add($relativePath)
    }
}
foreach ($relativePath in $listedFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot $relativePath))) {
        Add-ValidationError "Listed file missing on disk: $relativePath"
    }
}

$actionNodes = @(
    $modInfo.SelectNodes('/Mod/FrontEndActions/*') |
        Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
    $modInfo.SelectNodes('/Mod/InGameActions/*') |
        Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
)

$actionIdMap = @{}
foreach ($actionNode in $actionNodes) {
    $actionId = $actionNode.GetAttribute('id')
    if ([string]::IsNullOrWhiteSpace($actionId)) {
        Add-ValidationError "Action without id: $($actionNode.OuterXml)"
        continue
    }
    $actionKey = $actionId.ToLowerInvariant()
    if ($actionIdMap.ContainsKey($actionKey)) {
        Add-ValidationError "Duplicate action id: $actionId"
    }
    else {
        $actionIdMap[$actionKey] = $actionNode
    }
}

$criteriaMap = @{}
foreach ($criteriaNode in @($modInfo.SelectNodes('/Mod/ActionCriteria/Criteria'))) {
    $criteriaId = $criteriaNode.GetAttribute('id')
    $criteriaKey = $criteriaId.ToLowerInvariant()
    if ($criteriaMap.ContainsKey($criteriaKey)) {
        Add-ValidationError "Duplicate criteria id: $criteriaId"
    }
    else {
        $criteriaMap[$criteriaKey] = $criteriaNode
    }
}
foreach ($actionNode in $actionNodes) {
    $criteriaReferences = [System.Collections.Generic.List[string]]::new()
    foreach ($criteriaNode in @($actionNode.SelectNodes('./Criteria'))) {
        $criteriaReferences.Add($criteriaNode.InnerText.Trim())
    }
    foreach ($attributeName in @('criteria', 'Criteria')) {
        if ($actionNode.HasAttribute($attributeName)) {
            $criteriaReferences.Add($actionNode.GetAttribute($attributeName).Trim())
        }
    }
    foreach ($criteriaReference in $criteriaReferences) {
        if (-not $criteriaMap.ContainsKey($criteriaReference.ToLowerInvariant())) {
            Add-ValidationError "Unknown criteria '$criteriaReference' in action '$($actionNode.GetAttribute('id'))'."
        }
    }
}

$actionReferenceMap = @{}
foreach ($actionNode in $actionNodes) {
    foreach ($referenceNode in @($actionNode.SelectNodes('.//File') + $actionNode.SelectNodes('.//LuaReplace'))) {
        $relativePath = $referenceNode.InnerText.Trim().Replace('/', '\')
        $actionReferenceMap[(Normalize-RelativePath $relativePath)] = $relativePath
    }
}

# AddUserInterfaces loads a same-named Lua file beside its XML when present.
foreach ($actionNode in @($actionNodes | Where-Object { $_.LocalName -eq 'AddUserInterfaces' })) {
    foreach ($fileNode in @($actionNode.SelectNodes('.//File'))) {
        if ($fileNode.InnerText -notlike '*.xml') { continue }
        $pairedLua = [System.IO.Path]::ChangeExtension($fileNode.InnerText.Trim(), '.lua').Replace('/', '\')
        if (Test-Path -LiteralPath (Join-Path $modRoot $pairedLua)) {
            $actionReferenceMap[(Normalize-RelativePath $pairedLua)] = $pairedLua
        }
    }
}
foreach ($key in @($actionReferenceMap.Keys | Sort-Object)) {
    $relativePath = $actionReferenceMap[$key]
    if (-not (Test-Path -LiteralPath (Join-Path $modRoot $relativePath))) {
        Add-ValidationError "Action reference missing on disk: $relativePath"
    }
    if (-not $listedFileMap.ContainsKey($key)) {
        Add-ValidationError "Action reference absent from <Files>: $relativePath"
    }
}

# Multiple actions from one component may form an intentional include chain,
# but two integrated components must never own the same Lua context.
$contextOwners = @{}
foreach ($actionNode in @($actionNodes | Where-Object { $_.LocalName -eq 'ReplaceUIScript' })) {
    $contextNode = $actionNode.SelectSingleNode('./Properties/LuaContext')
    $replaceNode = $actionNode.SelectSingleNode('./Properties/LuaReplace')
    if ($null -eq $contextNode -or $null -eq $replaceNode) {
        Add-ValidationError "Incomplete ReplaceUIScript action: $($actionNode.GetAttribute('id'))"
        continue
    }
    $replacePath = $replaceNode.InnerText.Trim().Replace('\', '/')
    $owner = 'Toolbox'
    if ($replacePath.StartsWith('Components/BBG/', [System.StringComparison]::OrdinalIgnoreCase)) { $owner = 'BBG' }
    elseif ($replacePath.StartsWith('Components/BBM/', [System.StringComparison]::OrdinalIgnoreCase)) { $owner = 'BBM' }
    $contextKey = $contextNode.InnerText.Trim().ToLowerInvariant()
    if (-not $contextOwners.ContainsKey($contextKey)) {
        $contextOwners[$contextKey] = [System.Collections.Generic.List[string]]::new()
    }
    if (-not $contextOwners[$contextKey].Contains($owner)) {
        $contextOwners[$contextKey].Add($owner)
    }
}
foreach ($contextKey in $contextOwners.Keys) {
    if ($contextOwners[$contextKey].Count -gt 1) {
        Add-ValidationError "LuaReplace context has cross-component owners: $contextKey => $($contextOwners[$contextKey] -join ', ')"
    }
}

# MPH owns the complete EndGameMenu XML; BBG supplies only its Lua extension.
$mphEndGame = Normalize-RelativePath 'ui/Replacements/endgamemenu.xml'
$bbgEndGameXml = Normalize-RelativePath 'Components/BBG/ui/replacements/endgamemenu.xml'
$bbgEndGameLua = Normalize-RelativePath 'Components/BBG/ui/replacements/endgamemenu_bbg.lua'
if (-not $listedFileMap.ContainsKey($mphEndGame)) { Add-ValidationError 'MPH EndGameMenu XML is not published.' }
if ($listedFileMap.ContainsKey($bbgEndGameXml)) { Add-ValidationError 'BBG duplicate EndGameMenu XML is still published.' }
if ($actionReferenceMap.ContainsKey($bbgEndGameXml)) { Add-ValidationError 'BBG duplicate EndGameMenu XML is still loaded.' }
if (-not $actionReferenceMap.ContainsKey($bbgEndGameLua)) { Add-ValidationError 'BBG EndGameMenu Lua extension is not loaded.' }

# Confirm BBM art is rooted where NaturalWondersMod.dep expects it.
$artAction = @($actionNodes | Where-Object {
    $_.LocalName -eq 'UpdateArt' -and $_.SelectSingleNode('.//File').InnerText -ieq 'NaturalWondersMod.dep'
})
if ($artAction.Count -ne 1) {
    Add-ValidationError "Expected exactly one root NaturalWondersMod.dep UpdateArt action; found $($artAction.Count)."
}
$depPath = Join-Path $modRoot 'NaturalWondersMod.dep'
if (Test-Path -LiteralPath $depPath) {
    $dep = Load-XmlDocument $depPath
    $artDefNames = @($dep.SelectNodes('//*[local-name()="ArtDefPath" or local-name()="ArtDefDependencyPaths"]//Element') |
        ForEach-Object { $_.GetAttribute('text') } |
        Where-Object { $_ -like '*.artdef' } |
        Sort-Object -Unique)
    foreach ($artDefName in $artDefNames) {
        if (-not (Test-Path -LiteralPath (Join-Path $modRoot (Join-Path 'ArtDefs' $artDefName)))) {
            Add-ValidationError "BBM art definition dependency missing: ArtDefs\$artDefName"
        }
    }
    $packageNames = @($dep.SelectNodes('//*[local-name()="PackageDependencies"]/Element') |
        ForEach-Object { $_.GetAttribute('text') } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique)
    foreach ($platform in @('Windows', 'MacOS')) {
        foreach ($packageName in $packageNames) {
            $packagePath = Join-Path $modRoot ("Platforms\$platform\BLPs\$($packageName.Replace('/', '\'))")
            if (-not (Test-Path -LiteralPath $packagePath)) {
                Add-ValidationError "BBM art package dependency missing: $packagePath"
            }
        }
    }
}

# Guard the broken references removed from the two upstream ModInfos.
$removedReferences = @(
    'Components\BBG\sql\DLC_Indonesia_Khmer\_dlc_indo_khmer_utils.sql',
    'Components\BBG\sql\DLC_Indonesia_Khmer\Other.sql',
    'Components\BBG\sql\LP\lp_arabia_saladin_sultan.sql',
    'Components\BBM\Data\BBS_D.lua',
    'Components\BBM\Data\BBS Maps\Utility\BBS_Balance.lua'
)
foreach ($removedReference in $removedReferences) {
    $key = Normalize-RelativePath $removedReference
    if ($listedFileMap.ContainsKey($key) -or $actionReferenceMap.ContainsKey($key)) {
        Add-ValidationError "Removed upstream reference returned: $removedReference"
    }
}

# Scan only active runtime text files for dangerous or disabled behavior.
$dangerPatterns = @(
    @{ Name = 'dynamic loadstring'; Pattern = 'loadstring\s*\(' },
    @{ Name = 'Workshop auto-update'; Pattern = 'Modding\.UpdateSubscription\s*\(' },
    @{ Name = 'science/culture anti-stacking'; Pattern = 'NoMoreStack|NO_MORE_STACK' }
)
$oldRuntimeIds = @(
    '3cd7857e-b720-4a1b-a61d-930f58d5237e',
    'cb84075d-5007-4207-b662-c35a5f7be260',
    'cb84075d-5007-4207-b662-c35a5f7be250',
    'cb84075d-5007-4207-b662-c35a5f7be254',
    'c88cba8b-8311-4d35-90c3-51a4a5d66542',
    'c88cba8b-8311-4d35-90c3-51a4a5d66550',
    '619ac86e-d99d-4bf3-b8f0-8c5b8c402567',
    '00000000-0165-224C-A3AA-154BB4B9C1C5'
)
foreach ($key in @($actionReferenceMap.Keys | Sort-Object)) {
    $relativePath = $actionReferenceMap[$key]
    if ([System.IO.Path]::GetExtension($relativePath) -notin @('.lua', '.sql', '.xml')) { continue }
    $fullPath = Join-Path $modRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath)) { continue }
    foreach ($dangerPattern in $dangerPatterns) {
        foreach ($hit in @(Select-String -LiteralPath $fullPath -Pattern $dangerPattern.Pattern)) {
            Add-ValidationError "$($dangerPattern.Name) in active file ${relativePath}:$($hit.LineNumber)"
        }
    }
    foreach ($oldId in $oldRuntimeIds) {
        foreach ($hit in @(Select-String -LiteralPath $fullPath -SimpleMatch $oldId)) {
            Add-ValidationError "Old component Mod ID in active runtime file ${relativePath}:$($hit.LineNumber): $oldId"
        }
    }
}

if ($validationErrors.Count -gt 0) {
    foreach ($validationError in $validationErrors) { Write-Error $validationError }
    Write-Host "FAILED: $($validationErrors.Count) validation error(s)." -ForegroundColor Red
    exit 1
}

Write-Host ("PASS: {0} XML artifacts, {1} criteria, {2} actions, {3} listed files and {4} active references validated." -f `
    $xmlFiles.Count, $criteriaMap.Count, $actionNodes.Count, $listedFiles.Count, $actionReferenceMap.Count) -ForegroundColor Green
exit 0
