[CmdletBinding()]
param(
    [string]$SuiteModInfo = 'D:\Civilization\Civ6mods\BBGZYL\ZYL_MultiplayerSuite\ZYL_MultiplayerSuite.modinfo',
    [string]$BBGModInfo = 'D:\Steam\steamapps\workshop\content\289070\2865001760\BetterBalancedGame.modinfo',
    [string]$BBMModInfo = 'D:\Steam\steamapps\workshop\content\289070\3179425402\BBM_139.modinfo'
)

$ErrorActionPreference = 'Stop'

$modRoot = Split-Path -Parent $PSScriptRoot
$outputPath = Join-Path $modRoot 'ZYLPVPMOD.modinfo'
$unifiedId = '4dd01931-9d44-4a8a-8e74-712cba0f0072'

function Load-XmlDocument {
    param([string]$Path)

    $document = [System.Xml.XmlDocument]::new()
    $document.PreserveWhitespace = $false
    $document.Load($Path)
    return $document
}

function Add-Property {
    param(
        [System.Xml.XmlDocument]$Document,
        [System.Xml.XmlElement]$Properties,
        [string]$Name,
        [string]$Value
    )

    $node = $Properties.SelectSingleNode($Name)
    if ($null -eq $node) {
        $node = $Document.CreateElement($Name)
        [void]$Properties.AppendChild($node)
    }
    $node.InnerText = $Value
}

function Prefix-CriteriaReference {
    param(
        [string]$Value,
        [hashtable]$Map
    )

    if ($Map.ContainsKey($Value)) {
        return $Map[$Value]
    }
    return $Value
}

function Normalize-ComponentRelativePath {
    param(
        [string]$Component,
        [string]$Path
    )

    $normalized = $Path.Trim().Replace('\', '/')
    if ($Component -eq 'BBM' -and $normalized -ieq 'Data/BBS Maps/PerfectWorld6.lua') {
        # BBM 1.39.1 lists the same Windows file twice with different casing.
        return 'Data/BBS Maps/perfectworld6.lua'
    }
    return $normalized
}

function Remove-FileReference {
    param(
        [System.Xml.XmlElement]$Action,
        [string]$Path
    )

    foreach ($fileNode in @($Action.SelectNodes('.//File'))) {
        if ($fileNode.InnerText.Trim() -ieq $Path) {
            [void]$fileNode.ParentNode.RemoveChild($fileNode)
        }
    }
}

function Set-FileReference {
    param(
        [System.Xml.XmlElement]$Action,
        [string]$OldPath,
        [string]$NewPath
    )

    foreach ($fileNode in @($Action.SelectNodes('.//File'))) {
        if ($fileNode.InnerText.Trim() -ieq $OldPath) {
            $fileNode.InnerText = $NewPath
        }
    }
}

function Add-ComponentCriteria {
    param(
        [System.Xml.XmlDocument]$Target,
        [System.Xml.XmlDocument]$Source,
        [string]$Prefix,
        [string[]]$Skip = @()
    )

    $targetCriteria = $Target.SelectSingleNode('/Mod/ActionCriteria')
    $map = @{}
    foreach ($criteria in @($Source.SelectNodes('/Mod/ActionCriteria/Criteria'))) {
        $oldId = $criteria.GetAttribute('id')
        if ($oldId -in $Skip) {
            continue
        }
        $map[$oldId] = "$Prefix$oldId"
    }

    foreach ($criteria in @($Source.SelectNodes('/Mod/ActionCriteria/Criteria'))) {
        $oldId = $criteria.GetAttribute('id')
        if ($oldId -in $Skip) {
            continue
        }
        $copy = [System.Xml.XmlElement]$Target.ImportNode($criteria, $true)
        $copy.SetAttribute('id', $map[$oldId])
        [void]$targetCriteria.AppendChild($copy)
    }

    return $map
}

function Add-ComponentActions {
    param(
        [System.Xml.XmlDocument]$Target,
        [System.Xml.XmlDocument]$Source,
        [string]$Component,
        [string]$PathPrefix,
        [hashtable]$CriteriaMap
    )

    foreach ($sectionName in @('FrontEndActions', 'InGameActions')) {
        $targetSection = $Target.SelectSingleNode("/Mod/$sectionName")
        $sourceSection = $Source.SelectSingleNode("/Mod/$sectionName")
        $sectionCode = if ($sectionName -eq 'FrontEndActions') { 'FE' } else { 'IG' }
        $index = 0

        foreach ($sourceAction in @($sourceSection.ChildNodes | Where-Object NodeType -eq 'Element')) {
            $originalId = $sourceAction.GetAttribute('id')

            # BBM removed these implementations during its refactor but left stale
            # ModInfo references behind. Loading either reference breaks the action.
            if ($Component -eq 'BBM' -and $sourceAction.LocalName -eq 'AddGameplayScripts' -and $originalId -eq 'D') {
                continue
            }

            $action = [System.Xml.XmlElement]$Target.ImportNode($sourceAction, $true)

            if ($Component -eq 'BBG') {
                switch ($originalId) {
                    'bbg_preload_db_indokhmer_updated' {
                        Set-FileReference $action 'sql/DLC_Indonesia_Khmer/_dlc_indo_khmer_utils.sql' 'sql/DLC_Indonesia_Khmer/Base.sql'
                    }
                    'BBG_Indonesia_Khmer' {
                        Remove-FileReference $action 'sql/DLC_Indonesia_Khmer/Other.sql'
                    }
                    'BBG_Negotiators' {
                        # This deleted file contained comments only; Sultan.sql owns
                        # the active Sultan Saladin implementation in BBG 7.4.6.
                        Remove-FileReference $action 'sql/LP/lp_arabia_saladin_sultan.sql'
                    }
                    'bbg_files' {
                        # MPH owns the complete EndGameMenu XML. BBG contributes only
                        # its EndGameMenu_ extension that adds the traditional victory.
                        Remove-FileReference $action 'ui/replacements/endgamemenu.xml'
                    }
                    'bbg_preload_db_bbs_updated' {
                        # BBM is embedded in this package, so the compatibility rows
                        # must always load even though the original BBM Mod ID is blocked.
                        foreach ($criteriaNode in @($action.SelectNodes('./Criteria'))) {
                            if ($criteriaNode.InnerText.Trim() -eq 'BBS') {
                                [void]$action.RemoveChild($criteriaNode)
                            }
                        }
                    }
                }
            }
            elseif ($Component -eq 'BBM' -and $originalId -eq 'ArtDep') {
                # NaturalWondersMod.dep resolves ArtDefs/ and Platforms/ from the
                # mod root.  Keep those paths at root even though BBM's scripts
                # remain namespaced under Components/BBM.
                Set-FileReference $action 'NaturalWondersMod.dep' 'NaturalWondersMod.dep'
            }
            elseif ($Component -eq 'BBM' -and $originalId -eq 'Map_BBS') {
                Remove-FileReference $action 'Data/BBS Maps/Utility/BBS_Balance.lua'
            }
            elseif ($Component -eq 'BBM' -and $sourceAction.LocalName -eq 'UpdateText') {
                # These three files are zero bytes in BBM 1.39.1.  Feeding an
                # empty file to UpdateText produces an XML import failure.
                foreach ($emptyText in @('Lang/italian.xml', 'Lang/polish.xml', 'Lang/spanish.xml')) {
                    Remove-FileReference $action $emptyText
                }
            }

            foreach ($criteriaNode in @($action.SelectNodes('./Criteria'))) {
                $criteriaNode.InnerText = Prefix-CriteriaReference $criteriaNode.InnerText.Trim() $CriteriaMap
            }
            foreach ($attributeName in @('criteria', 'Criteria')) {
                if ($action.HasAttribute($attributeName)) {
                    $action.SetAttribute(
                        $attributeName,
                        (Prefix-CriteriaReference $action.GetAttribute($attributeName).Trim() $CriteriaMap)
                    )
                }
            }

            foreach ($fileNode in @($action.SelectNodes('.//File'))) {
                $sourcePath = Normalize-ComponentRelativePath $Component $fileNode.InnerText
                if ($Component -eq 'BBM' -and ($sourcePath -ieq 'NaturalWondersMod.dep' -or $sourcePath -imatch '^(ArtDefs|Platforms)/')) {
                    $fileNode.InnerText = $sourcePath
                }
                else {
                    $fileNode.InnerText = "$PathPrefix/$sourcePath"
                }
            }
            foreach ($replaceNode in @($action.SelectNodes('.//LuaReplace'))) {
                $replaceNode.InnerText = "$PathPrefix/$($replaceNode.InnerText.Trim())"
            }

            $index++
            $safeId = $originalId -replace '[^A-Za-z0-9_]+', '_'
            if ([string]::IsNullOrWhiteSpace($safeId)) {
                $safeId = $sourceAction.LocalName
            }
            $action.SetAttribute('id', ('ZYLPVP_{0}_{1}_{2:D3}_{3}' -f $Component, $sectionCode, $index, $safeId))
            [void]$targetSection.AppendChild($action)
        }
    }
}

function Add-ComponentFiles {
    param(
        [System.Xml.XmlDocument]$Target,
        [System.Xml.XmlDocument]$Source,
        [string]$Component,
        [string]$PathPrefix,
        [string[]]$Skip = @(),
        [string[]]$Add = @()
    )

    $targetFiles = $Target.SelectSingleNode('/Mod/Files')
    $existing = @{}
    foreach ($existingNode in @($targetFiles.SelectNodes('./File'))) {
        $existing[$existingNode.InnerText.Trim().Replace('\\','/').ToLowerInvariant()] = $true
    }
    function Add-UniqueFileNode {
        param([string]$Path)
        $normalized = $Path.Trim().Replace('\\','/')
        $key = $normalized.ToLowerInvariant()
        if ($existing.ContainsKey($key)) { return }
        $copy = $Target.CreateElement('File')
        $copy.InnerText = $normalized
        [void]$targetFiles.AppendChild($copy)
        $existing[$key] = $true
    }
    foreach ($fileNode in @($Source.SelectNodes('/Mod/Files/File'))) {
        $relativePath = Normalize-ComponentRelativePath $Component $fileNode.InnerText
        if ($relativePath -in $Skip) {
            continue
        }
        if ($Component -eq 'BBM' -and $relativePath -imatch '^(ArtDefs|Platforms)/') {
            Add-UniqueFileNode $relativePath
        }
        elseif ($Component -eq 'BBM' -and $relativePath -ieq 'NaturalWondersMod.dep') {
            Add-UniqueFileNode $relativePath
        }
        else {
            Add-UniqueFileNode "$PathPrefix/$relativePath"
        }
    }
    foreach ($relativePath in $Add) {
        Add-UniqueFileNode "$PathPrefix/$relativePath"
    }
}

$target = Load-XmlDocument $SuiteModInfo
$bbg = Load-XmlDocument $BBGModInfo
$bbm = Load-XmlDocument $BBMModInfo

$target.DocumentElement.SetAttribute('id', $unifiedId)
$target.DocumentElement.SetAttribute('version', '100')

$properties = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/Properties')
Add-Property $target $properties 'Name' 'LOC_ZYLPVPMOD_TITLE'
Add-Property $target $properties 'Description' 'LOC_ZYLPVPMOD_DESCRIPTION'
Add-Property $target $properties 'Teaser' 'LOC_ZYLPVPMOD_TEASER'
Add-Property $target $properties 'Authors' 'BBG Team, BBM Team, Cisco, D. / Jack The Narrator, Team PVP Tools contributors; integrated by ZYL'
Add-Property $target $properties 'SpecialThanks' 'Civilization VI BBG, BBM, CPL, MPH and Team PVP communities'
Add-Property $target $properties 'Version' '100'
Add-Property $target $properties 'BBGVersion' '7.4.6'
Add-Property $target $properties 'BBMVersion' '1.39.1'
Add-Property $target $properties 'ToolboxVersion' '1.0.0'
Add-Property $target $properties 'AffectsSavedGames' '1'

$blocks = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/Blocks')
$blockedMods = @(
    @('3cd7857e-b720-4a1b-a61d-930f58d5237e', 'ZYL Multiplayer Suite 1.0.0'),
    @('cb84075d-5007-4207-b662-c35a5f7be260', 'Better Balanced Game release'),
    @('cb84075d-5007-4207-b662-c35a5f7be250', 'Better Balanced Game beta'),
    @('cb84075d-5007-4207-b662-c35a5f7be254', 'Better Balanced Game WIP'),
    @('c88cba8b-8311-4d35-90c3-51a4a5d66542', 'Better Balanced Map'),
    @('c88cba8b-8311-4d35-90c3-51a4a5d66550', 'Better Balanced Starts'),
    @('8af4fe8e-5406-7d72-d9d6-a8f5d1b66e10', 'CCB Maps (BBM replacement)'),
    @('6f2888d4-79dc-415f-a8ff-f9d81d7afb53', 'Better Report Screen (included)'),
    @('13E8BCDF-98EC-4C03-3641-72D519B0047C', 'Better City States (included)'),
    @('8446e6e9-7703-434d-ba10-0bd70a291d28', 'Tech Civic Progress Plus (included)'),
    @('c6477d9f-6bad-4d24-9e76-49cda4f0a966', 'Better Builder Charges Tracking (included)'),
    @('6a18ae19-df93-4322-a3d5-33c5a5087b36', 'Real Great People (conflicting UI)'),
    @('aa42d206-0aa1-4bbf-9ac0-27d338e2d91e', 'Real Stylish Great People (conflicting UI)'),
    @('4ecfcc62-5471-4435-b295-590df213e8d8', 'Detailed Map Tacks (conflicting map-pin UI)')
)
foreach ($blockedMod in $blockedMods) {
    if ($null -ne $blocks.SelectSingleNode("Mod[@id='$($blockedMod[0])']")) {
        continue
    }
    $mod = $target.CreateElement('Mod')
    $mod.SetAttribute('id', $blockedMod[0])
    $mod.SetAttribute('title', $blockedMod[1])
    [void]$blocks.AppendChild($mod)
}

$dependencies = $target.CreateElement('Dependencies')
foreach ($dependency in @($bbg.SelectNodes('/Mod/Dependencies/Mod'))) {
    [void]$dependencies.AppendChild($target.ImportNode($dependency, $true))
}
[void]$target.DocumentElement.InsertBefore($dependencies, $blocks)

$localizedText = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/LocalizedText')
$localizedUpdates = @{}
$utf8 = [System.Text.Encoding]::UTF8
$teaserZh = $utf8.GetString([System.Convert]::FromBase64String('QkJHIDcuNC42ICsgQkJNIDEuMzkuMSArIFpZTCDogZTmnLrmr5TotZvmjqfliLbkuI4gVUkg5bel5YW3566x44CC'))
$descriptionZh = $utf8.GetString([System.Convert]::FromBase64String('5LiA5L2T5YyW6IGU5py65YyF77yaQmV0dGVyIEJhbGFuY2VkIEdhbWUgNy40LjbjgIFCZXR0ZXIgQmFsYW5jZWQgTWFwIDEuMzkuMeOAgU1QSCDmr5TotZvmjqfliLblkoznu4/lhrLnqoHlpITnkIbnmoQgVGVhbSBQVlAgVUkvUW9M44CC6Zi75q2i5Y6f57uE5Lu26YeN5aSN5Yqg6L2977yM5bm25L+d55WZ5Y+v5Y2h56eR5oqA5LiO5biC5pS/55qE5Y6f54mI6KGM5Li644CC'))
$localizedUpdates['LOC_ZYL_MPS_TITLE'] = @('LOC_ZYLPVPMOD_TITLE', 'ZYLPVPMOD 1.0.0', 'ZYLPVPMOD 1.0.0')
$localizedUpdates['LOC_ZYL_MPS_TEASER'] = @('LOC_ZYLPVPMOD_TEASER', 'BBG 7.4.6 + BBM 1.39.1 + ZYL multiplayer tournament and quality-of-life suite.', $teaserZh)
$localizedUpdates['LOC_ZYL_MPS_DESCRIPTION'] = @('LOC_ZYLPVPMOD_DESCRIPTION', 'One self-contained multiplayer package: Better Balanced Game 7.4.6, Better Balanced Map 1.39.1, MPH tournament controls and selected Team PVP UI/QoL. Component Mod IDs are blocked to prevent double loading. Science and culture stacking remain enabled.', $descriptionZh)
foreach ($oldId in $localizedUpdates.Keys) {
    $textNode = [System.Xml.XmlElement]$localizedText.SelectSingleNode("Text[@id='$oldId']")
    if ($null -eq $textNode) {
        continue
    }
    $update = $localizedUpdates[$oldId]
    $textNode.SetAttribute('id', $update[0])
    $textNode.SelectSingleNode('en_US').InnerText = $update[1]
    $textNode.SelectSingleNode('zh_Hans_CN').InnerText = $update[2]
}
foreach ($textNode in @($bbm.SelectNodes('/Mod/LocalizedText/Text'))) {
    [void]$localizedText.AppendChild($target.ImportNode($textNode, $true))
}

# BBG has three mutually exclusive Expanded package IDs but its 7.4.6
# ModInfo references an undefined aggregate criterion. Define the intended OR.
$bbgExpanded = $bbg.CreateElement('Criteria')
$bbgExpanded.SetAttribute('id', 'BBGExpanded')
$bbgExpanded.SetAttribute('any', '1')
foreach ($expandedId in @(
    '2a0aa96a-a31c-4ce2-87ec-09144f6f3e00',
    '2a0aa96a-a31c-4ce2-87ec-09152f6f3888',
    '2a0aa96a-a31c-4ce2-87ec-09152f6f3e00'
)) {
    $modInUse = $bbg.CreateElement('ModInUse')
    $modInUse.InnerText = $expandedId
    [void]$bbgExpanded.AppendChild($modInUse)
}
[void]$bbg.SelectSingleNode('/Mod/ActionCriteria').AppendChild($bbgExpanded)

$bbgCriteria = Add-ComponentCriteria $target $bbg 'ZYLPVP_BBG_' @('BBS')
$bbmCriteria = Add-ComponentCriteria $target $bbm 'ZYLPVP_BBM_'

Add-ComponentActions $target $bbg 'BBG' 'Components/BBG' $bbgCriteria
Add-ComponentActions $target $bbm 'BBM' 'Components/BBM' $bbmCriteria

Add-ComponentFiles $target $bbg 'BBG' 'Components/BBG' @(
    'sql/DLC_Indonesia_Khmer/_dlc_indo_khmer_utils.sql',
    'sql/DLC_Indonesia_Khmer/Other.sql',
    'sql/LP/lp_arabia_saladin_sultan.sql',
    'ui/replacements/endgamemenu.xml'
) @('sql/DLC_Indonesia_Khmer/Base.sql')
Add-ComponentFiles $target $bbm 'BBM' 'Components/BBM' @(
    'Data/BBS_D.lua',
    'Data/BBS Maps/Utility/BBS_Balance.lua',
    'Lang/italian.xml',
    'Lang/polish.xml',
    'Lang/spanish.xml'
)

$filesNode = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/Files')
foreach ($newFile in @('CONFLICT_RESOLUTION.md', 'SOURCES.md', 'tools/assemble_modinfo.ps1', 'tools/validate.ps1')) {
    $fileNode = $target.CreateElement('File')
    $fileNode.InnerText = $newFile
    [void]$filesNode.AppendChild($fileNode)
}

# Source ModInfos occasionally contain duplicate paths (including case-only
# duplicates).  Civ VI treats them as the same file on Windows, so publish one
# canonical entry only.
$seenFiles = @{}
foreach ($fileNode in @($filesNode.SelectNodes('./File'))) {
    $key = $fileNode.InnerText.Trim().Replace('\', '/').ToLowerInvariant()
    if ($seenFiles.ContainsKey($key)) {
        [void]$filesNode.RemoveChild($fileNode)
    }
    else {
        $seenFiles[$key] = $true
    }
}

# MPH preset dependencies target BBG/BBM parameters, so load the combined preset
# mappings after both component front-end databases have created their options.
$cplSettings = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/FrontEndActions/UpdateDatabase[@id="CPL_SETTINGS"]')
if ($null -ne $cplSettings) {
    $propertiesNode = [System.Xml.XmlElement]$cplSettings.SelectSingleNode('Properties')
    if ($null -eq $propertiesNode) {
        $propertiesNode = $target.CreateElement('Properties')
        [void]$cplSettings.PrependChild($propertiesNode)
    }
    $loadOrder = [System.Xml.XmlElement]$propertiesNode.SelectSingleNode('LoadOrder')
    if ($null -eq $loadOrder) {
        $loadOrder = $target.CreateElement('LoadOrder')
        [void]$propertiesNode.AppendChild($loadOrder)
    }
    $loadOrder.InnerText = '30000'
}

$writerSettings = [System.Xml.XmlWriterSettings]::new()
$writerSettings.Indent = $true
$writerSettings.IndentChars = "`t"
$writerSettings.NewLineChars = "`r`n"
$writerSettings.NewLineHandling = [System.Xml.NewLineHandling]::Replace
$writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false)
$writer = [System.Xml.XmlWriter]::Create($outputPath, $writerSettings)
try {
    $target.Save($writer)
}
finally {
    $writer.Dispose()
}

Write-Host "Generated $outputPath"
