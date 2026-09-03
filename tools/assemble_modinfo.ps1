[CmdletBinding()]
param(
    [string]$SuiteModInfo = 'D:\Civilization\Civ6mods\BBGZYL\ZYL_MultiplayerSuite\ZYL_MultiplayerSuite.modinfo',
    [string]$BBGModInfo = 'D:\Steam\steamapps\workshop\content\289070\2865001760\BetterBalancedGame.modinfo',
    [string]$BBMModInfo = 'D:\Steam\steamapps\workshop\content\289070\3179425402\BBM_139.modinfo',
    [string]$BDWModInfo = 'D:\Civilization\Civ6mods\BBGZYL\referencemods\Better Deal Window\Advanced Deal Window.modinfo',
    [string]$DMTModInfo = 'D:\Civilization\Civ6mods\BBGZYL\referencemods\DetailedMapTacks\DetailedMapTacks.modinfo'
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
        [hashtable]$CriteriaMap,
        [string[]]$SkipActionIds = @()
    )

    foreach ($sectionName in @('FrontEndActions', 'InGameActions')) {
        $targetSection = $Target.SelectSingleNode("/Mod/$sectionName")
        $sourceSection = $Source.SelectSingleNode("/Mod/$sectionName")
        $sectionCode = if ($sectionName -eq 'FrontEndActions') { 'FE' } else { 'IG' }
        $index = 0

        foreach ($sourceAction in @($sourceSection.ChildNodes | Where-Object NodeType -eq 'Element')) {
            $originalId = $sourceAction.GetAttribute('id')

            if ($originalId -in $SkipActionIds) {
                continue
            }

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

            $hadFileReferences = @($action.SelectNodes('.//File')).Count -gt 0
            foreach ($fileNode in @($action.SelectNodes('.//File'))) {
                $sourcePath = Normalize-ComponentRelativePath $Component $fileNode.InnerText
                if ($Component -eq 'BBM' -and ($sourcePath -ieq 'NaturalWondersMod.dep' -or $sourcePath -imatch '^(ArtDefs|Platforms)/')) {
                    $fileNode.InnerText = $sourcePath
                }
                else {
                    $fileNode.InnerText = "$PathPrefix/$sourcePath"
                }

                # The integrated development directory is authoritative.  An
                # upstream Workshop manifest can contain files intentionally
                # absent from this embedded snapshot; do not publish dead
                # references to them.
                $integratedPath = Join-Path $modRoot $fileNode.InnerText.Trim().Replace('/', '\')
                if (-not (Test-Path -LiteralPath $integratedPath)) {
                    [void]$fileNode.ParentNode.RemoveChild($fileNode)
                }
            }
            if ($hadFileReferences -and @($action.SelectNodes('.//File')).Count -eq 0) {
                continue
            }
            foreach ($replaceNode in @($action.SelectNodes('.//LuaReplace'))) {
                $replaceNode.InnerText = "$PathPrefix/$($replaceNode.InnerText.Trim())"
            }
			$missingLuaReplace = $false
			foreach ($replaceNode in @($action.SelectNodes('.//LuaReplace'))) {
				$integratedPath = Join-Path $modRoot $replaceNode.InnerText.Trim().Replace('/', '\')
				if (-not (Test-Path -LiteralPath $integratedPath)) {
					$missingLuaReplace = $true
					break
				}
			}
			if ($missingLuaReplace) {
				continue
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
        $integratedPath = Join-Path $modRoot $normalized.Replace('/', '\')
        if (-not (Test-Path -LiteralPath $integratedPath)) { return }
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
$target.DocumentElement.SetAttribute('version', '127')

$properties = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/Properties')
Add-Property $target $properties 'Name' 'LOC_ZYLPVPMOD_TITLE'
Add-Property $target $properties 'Description' 'LOC_ZYLPVPMOD_DESCRIPTION'
Add-Property $target $properties 'Teaser' 'LOC_ZYLPVPMOD_TEASER'
Add-Property $target $properties 'Authors' 'BBG Team, BBM Team, BBG Expanded and CIVITAS Resources contributors, Cisco, D. / Jack The Narrator, Team PVP Tools contributors, ~Venom~, wltk, DeepLogic and JamieNyanchi; integrated by ZYL'
Add-Property $target $properties 'SpecialThanks' 'Civilization VI BBG, BBM, BBG Expanded, CIVITAS, CPL, MPH, Team PVP, Better Deal Window and Detailed Map Tacks communities'
Add-Property $target $properties 'Version' '127'
Add-Property $target $properties 'BBGVersion' '7.4.6'
Add-Property $target $properties 'BBMVersion' '1.39.1'
Add-Property $target $properties 'ToolboxVersion' '1.2.7'
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
    @('8d4fa23a-ef43-440c-8422-2bec11f8f5d7', 'Better Trade Screen (included via Team PVP Tools)'),
    @('6a18ae19-df93-4322-a3d5-33c5a5087b36', 'Real Great People (conflicting UI)'),
    @('aa42d206-0aa1-4bbf-9ac0-27d338e2d91e', 'Real Stylish Great People (conflicting UI)'),
    @('4ecfcc62-5471-4435-b295-590df213e8d8', 'Detailed Map Tacks (integrated)'),
    @('fbb7b86a-9ac9-4a8e-9439-9ded6aceda0e', 'Better Deal Window (integrated)'),
    @('3cfbc742-30f5-480f-a938-e7b71f160d4e', 'Team PVP Balanced mod Secret Societies 3.93 (included)'),
    @('664d17a5-f3be-493a-9332-8e20da1166fa', 'CIVITAS Resources Expanded (included)'),
    @('41493218-3632-421b-a1a3-367f7c7ba610', 'ZYL Lightweight Balance (selected features included)')
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
$teaserZh = $utf8.GetString([System.Convert]::FromBase64String('QkJHIDcuNC42ICsgQkJNIDEuMzkuMSArIEJldHRlciBEZWFsIFdpbmRvdyArIERldGFpbGVkIE1hcCBUYWNrcyArIFpZTCDogZTmnLrmr5TotZvmjqfliLbkuI4gVUkg5bel5YW3566x44CC'))
$descriptionZh = $utf8.GetString([System.Convert]::FromBase64String('5LiA5L2T5YyW6IGU5py65YyF77yaQmV0dGVyIEJhbGFuY2VkIEdhbWUgNy40LjbjgIFCZXR0ZXIgQmFsYW5jZWQgTWFwIDEuMzkuMeOAgUJCRyBFeHBhbmRlZCDlha3np43lpaLkvojotYTmupDjgIHnsr7pgIkgTGlnaHR3ZWlnaHRCYWxhbmNlIOS4h+elnuauv+S4jiBaWUwg5b636bKB5LyK44CBQmV0dGVyIERlYWwgV2luZG9344CBRGV0YWlsZWQgTWFwIFRhY2tz44CBTVBIIOavlOi1m+aOp+WItuWSjOeyvumAiSBUZWFtIFBWUCBVSS9Rb0zjgILkuqTmmJPnlYzpnaLkv53nlZkgTVBIIOeahOemgeS6pOaYk+inhOWIme+8m+WcsOWbvumSieeDremUruS/neeVmSBNUEgg56aB6ZKJ6KeE5YiZ5LiOIE5ISyDogYrlpKnlnLDlm77pkonjgILpmLvmraLlt7LmlbTlkIjmiJblhrLnqoHnu4Tku7bph43lpI3liqDovb3vvJvnp5HmioDkuI7luILmlL/kv53mjIHljp/niYjlj6/loIbnp6/ooYzkuLrjgII='))
$localizedUpdates['LOC_ZYL_MPS_TITLE'] = @('LOC_ZYLPVPMOD_TITLE', 'ZYLPVPMOD 1.2.7', 'ZYLPVPMOD 1.2.7')
$localizedUpdates['LOC_ZYL_MPS_TEASER'] = @('LOC_ZYLPVPMOD_TEASER', 'BBG 7.4.6 + BBM 1.39.1 + Better Deal Window + Detailed Map Tacks + ZYL multiplayer tournament and quality-of-life suite.', $teaserZh)
$localizedUpdates['LOC_ZYL_MPS_DESCRIPTION'] = @('LOC_ZYLPVPMOD_DESCRIPTION', 'One self-contained multiplayer package: Better Balanced Game 7.4.6, Better Balanced Map 1.39.1, six BBG Expanded luxury resources, selected Lightweight Balance pantheons plus ZYL Druid, Better Deal Window, Detailed Map Tacks, MPH tournament controls and selected Team PVP UI/QoL. The deal window preserves MPH trade restrictions; map-tack hotkeys preserve the MPH no-pins rule and NHK chat pins. Conflicting component Mod IDs are blocked to prevent double loading. Science and culture stacking remain enabled.', $descriptionZh)
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
$bdw = Load-XmlDocument $BDWModInfo
$dmt = Load-XmlDocument $DMTModInfo
$bdwCriteria = Add-ComponentCriteria $target $bdw 'ZYLPVP_BDW_'
$dmtCriteria = Add-ComponentCriteria $target $dmt 'ZYLPVP_DMT_'

Add-ComponentActions $target $bbg 'BBG' 'Components/BBG' $bbgCriteria @(
    'BBG_LoadLast',
    # Team PVP Tools BTS is the single owner of all trade UI files below.
    # Do not leave BBG's compatibility chain active: both chains define the
    # same TradeOverview/TradeSupport symbols and the last-loaded one wins.
    'bbg_tradesupport',
    'bbg_basetradeui',
    'base_tradeoverview',
    'bbg_tradeoverview_import',
    'bbg_tradeoverview'
)
Add-ComponentActions $target $bbm 'BBM' 'Components/BBM' $bbmCriteria
Add-ComponentActions $target $bdw 'BetterDealWindow' 'Components/BetterDealWindow' $bdwCriteria @(
    'ADW_KublaiKhanVietnam_Files_MODE',
    'ADW_Replace_Base',
    'ADW_Replace_XP2',
    'ADW_Replace_Monopoly',
    'ADW_Replace_Monopoly_XP2'
)
Add-ComponentActions $target $dmt 'DetailedMapTacks' 'Components/DetailedMapTacks' $dmtCriteria @(
    'dmt_settings',
    'mappinmanager',
    'mappinpopup'
)

Add-ComponentFiles $target $bbg 'BBG' 'Components/BBG' @(
    'sql/DLC_Indonesia_Khmer/_dlc_indo_khmer_utils.sql',
    'sql/DLC_Indonesia_Khmer/Other.sql',
    'sql/LP/lp_arabia_saladin_sultan.sql',
	'sql/Base/LoadLast.sql',
    'ui/replacements/endgamemenu.xml'
) @('sql/DLC_Indonesia_Khmer/Base.sql')
Add-ComponentFiles $target $bbm 'BBM' 'Components/BBM' @(
    'Data/BBS_D.lua',
    'Data/BBS Maps/Utility/BBS_Balance.lua',
    'Lang/italian.xml',
    'Lang/polish.xml',
    'Lang/spanish.xml'
)
Add-ComponentFiles $target $bdw 'BetterDealWindow' 'Components/BetterDealWindow' @(
    'DiplomacyDealView_KublaiKhanVietnam_MODE.lua',
    'DiplomacyDealView_KublaiKhanVietnam_MODE_Expansion2.lua'
) @(
    'DiplomacyDealView_ZYLPVP_Expansion2.lua',
    'ZYLPVP_BDW_MPH_Compatibility.lua'
)
Add-ComponentFiles $target $dmt 'DetailedMapTacks' 'Components/DetailedMapTacks' @(
    'config/dmt_config.xml'
)

# MPH's old deal file is retained in the source tree for provenance but must
# not be imported: the BDW entry point below applies the same restrictions.
foreach ($actionNode in @($target.SelectNodes('/Mod/*/ImportFiles'))) {
    Remove-FileReference $actionNode 'ui/Replacements/diplomacydealview_MPH.lua'
}
foreach ($fileNode in @($target.SelectNodes('/Mod/Files/File'))) {
    if ($fileNode.InnerText.Trim().Replace('\\','/') -ieq 'ui/Replacements/diplomacydealview_MPH.lua') {
        [void]$fileNode.ParentNode.RemoveChild($fileNode)
    }
}

# ZYLPVPMOD-owned post-integration gameplay additions. Keep these actions here
# so regenerating the unified ModInfo cannot discard the local features.
$zylCriteria = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/ActionCriteria')

# The assembler normally starts from ZYL_MultiplayerSuite.modinfo, but remove
# any same-ID local criteria first so it remains deterministic if the suite
# later absorbs one of these definitions.
foreach ($criterionId in @(
    'ZYL_Ethiopia',
    'ZYL_SecretSocietiesXP2',
    'ZYL_NoExternalBBGExpanded',
    'ZYL_MonopoliesMode',
    'ZYL_GatheringStorm',
	'ZYL_EraLengthOptimization',
    'ZYL_NoMapPins',
    'SETTINGS_UI_BetterTradeScreen',
    'ZYL_RichMainland',
    'ZYL_RichMainland_Team',
    'ZYL_RichMainland_FFA'
)) {
    foreach ($existingCriterion in @($zylCriteria.SelectNodes("Criteria[@id='$criterionId']"))) {
        [void]$zylCriteria.RemoveChild($existingCriterion)
    }
}

$ethiopiaCriterion = $target.CreateElement('Criteria')
$ethiopiaCriterion.SetAttribute('id', 'ZYL_Ethiopia')
$ethiopiaModInUse = $target.CreateElement('ModInUse')
$ethiopiaModInUse.InnerText = '1B394FE9-23DC-4868-8F0A-5220CB8FB427'
[void]$ethiopiaCriterion.AppendChild($ethiopiaModInUse)
[void]$zylCriteria.AppendChild($ethiopiaCriterion)

$secretSocietiesCriterion = $target.CreateElement('Criteria')
$secretSocietiesCriterion.SetAttribute('id', 'ZYL_SecretSocietiesXP2')
$secretSocietiesRuleSet = $target.CreateElement('RuleSetInUse')
$secretSocietiesRuleSet.InnerText = 'RULESET_EXPANSION_2'
[void]$secretSocietiesCriterion.AppendChild($secretSocietiesRuleSet)
$secretSocietiesDlc = $target.CreateElement('ModInUse')
$secretSocietiesDlc.InnerText = '1B394FE9-23DC-4868-8F0A-5220CB8FB427'
[void]$secretSocietiesCriterion.AppendChild($secretSocietiesDlc)
$secretSocietiesMode = $target.CreateElement('ConfigurationValueMatches')
foreach ($configurationValue in @(
    @('Group', 'Game'),
    @('ConfigurationId', 'GAMEMODE_SECRETSOCIETIES'),
    @('Value', '1')
)) {
    $configurationNode = $target.CreateElement($configurationValue[0])
    $configurationNode.InnerText = $configurationValue[1]
    [void]$secretSocietiesMode.AppendChild($configurationNode)
}
[void]$secretSocietiesCriterion.AppendChild($secretSocietiesMode)
[void]$zylCriteria.AppendChild($secretSocietiesCriterion)

# The six resources are embedded directly, but a separately enabled BBG
# Expanded must remain usable for its civilizations and leaders. In that case
# its resource actions win and all bundled resource actions are skipped.
$noExternalExpandedCriterion = $target.CreateElement('Criteria')
$noExternalExpandedCriterion.SetAttribute('id', 'ZYL_NoExternalBBGExpanded')
foreach ($expandedId in @(
    '2a0aa96a-a31c-4ce2-87ec-09144f6f3e00',
    '2a0aa96a-a31c-4ce2-87ec-09152f6f3888',
    '2a0aa96a-a31c-4ce2-87ec-09152f6f3e00'
)) {
    $externalExpandedMod = $target.CreateElement('ModInUse')
    $externalExpandedMod.SetAttribute('inverse', '1')
    $externalExpandedMod.InnerText = $expandedId
    [void]$noExternalExpandedCriterion.AppendChild($externalExpandedMod)
}
[void]$zylCriteria.AppendChild($noExternalExpandedCriterion)

$monopoliesCriterion = $target.CreateElement('Criteria')
$monopoliesCriterion.SetAttribute('id', 'ZYL_MonopoliesMode')
$monopoliesMode = $target.CreateElement('ConfigurationValueMatches')
foreach ($configurationValue in @(
    @('Group', 'Game'),
    @('ConfigurationId', 'GAMEMODE_MONOPOLIES'),
    @('Value', '1')
)) {
    $configurationNode = $target.CreateElement($configurationValue[0])
    $configurationNode.InnerText = $configurationValue[1]
    [void]$monopoliesMode.AppendChild($configurationNode)
}
[void]$monopoliesCriterion.AppendChild($monopoliesMode)
[void]$zylCriteria.AppendChild($monopoliesCriterion)

$gatheringStormCriterion = $target.CreateElement('Criteria')
$gatheringStormCriterion.SetAttribute('id', 'ZYL_GatheringStorm')
$gatheringStormRuleSet = $target.CreateElement('RuleSetInUse')
$gatheringStormRuleSet.InnerText = 'RULESET_EXPANSION_2'
[void]$gatheringStormCriterion.AppendChild($gatheringStormRuleSet)
[void]$zylCriteria.AppendChild($gatheringStormCriterion)

$eraLengthCriterion = $target.CreateElement('Criteria')
$eraLengthCriterion.SetAttribute('id', 'ZYL_EraLengthOptimization')
$eraLengthRuleSet = $target.CreateElement('RuleSetInUse')
$eraLengthRuleSet.InnerText = 'RULESET_EXPANSION_1,RULESET_EXPANSION_2'
[void]$eraLengthCriterion.AppendChild($eraLengthRuleSet)
$eraLengthMatch = $target.CreateElement('ConfigurationValueMatches')
foreach ($configurationValue in @(
    @('Group', 'Game'),
    @('ConfigurationId', 'ZYL_ERA_LENGTH_OPTIMIZATION'),
    @('Value', '1')
)) {
    $configurationNode = $target.CreateElement($configurationValue[0])
    $configurationNode.InnerText = $configurationValue[1]
    [void]$eraLengthMatch.AppendChild($configurationNode)
}
[void]$eraLengthCriterion.AppendChild($eraLengthMatch)
[void]$zylCriteria.AppendChild($eraLengthCriterion)

$noMapPinsCriterion = $target.CreateElement('Criteria')
$noMapPinsCriterion.SetAttribute('id', 'ZYL_NoMapPins')
$noMapPinsMatch = $target.CreateElement('ConfigurationValueMatches')
foreach ($configurationValue in @(
    @('Group', 'Game'),
    @('ConfigurationId', 'CPL_NO_PINS'),
    @('Value', '1')
)) {
    $configurationNode = $target.CreateElement($configurationValue[0])
    $configurationNode.InnerText = $configurationValue[1]
    [void]$noMapPinsMatch.AppendChild($configurationNode)
}
[void]$noMapPinsCriterion.AppendChild($noMapPinsMatch)
[void]$zylCriteria.AppendChild($noMapPinsCriterion)

# Enable BTS through either its custom toggle or the suite-wide UI preset.
$betterTradeScreenCriterion = $target.CreateElement('Criteria')
$betterTradeScreenCriterion.SetAttribute('id', 'SETTINGS_UI_BetterTradeScreen')
$betterTradeScreenCriterion.SetAttribute('any', '1')
foreach ($configurationValues in @(
    @('SETTINGS_UI_BTS', '1'),
    @('SETTINGS_UI', 'SETTINGS_UI_ENABLE_ALL')
)) {
    $betterTradeScreenMatch = $target.CreateElement('ConfigurationValueMatches')
    foreach ($configurationValue in @(
        @('Group', 'Game'),
        @('ConfigurationId', $configurationValues[0]),
        @('Value', $configurationValues[1])
    )) {
        $configurationNode = $target.CreateElement($configurationValue[0])
        $configurationNode.InnerText = $configurationValue[1]
        [void]$betterTradeScreenMatch.AppendChild($configurationNode)
    }
    [void]$betterTradeScreenCriterion.AppendChild($betterTradeScreenMatch)
}
[void]$zylCriteria.AppendChild($betterTradeScreenCriterion)

# The two Rich Mainland maps share one generator but require different runtime
# map-size databases.  Front-end registration is unconditional; these criteria
# restrict gameplay database changes to the map selected in the lobby.
$richMainlandMaps = @(
    @('ZYL_RichMainland_Team', 'zyl_team_rich_mainland.lua'),
    @('ZYL_RichMainland_FFA', 'zyl_ffa_rich_mainland.lua')
)
foreach ($richMainlandMap in $richMainlandMaps) {
    $mapCriterion = $target.CreateElement('Criteria')
    $mapCriterion.SetAttribute('id', $richMainlandMap[0])
    $mapMatch = $target.CreateElement('ConfigurationValueMatches')
    foreach ($configurationValue in @(
        @('Group', 'Map'),
        @('ConfigurationId', 'MAP_SCRIPT'),
        @('Value', $richMainlandMap[1])
    )) {
        $configurationNode = $target.CreateElement($configurationValue[0])
        $configurationNode.InnerText = $configurationValue[1]
        [void]$mapMatch.AppendChild($configurationNode)
    }
    [void]$mapCriterion.AppendChild($mapMatch)
    [void]$zylCriteria.AppendChild($mapCriterion)
}

$richMainlandCriterion = $target.CreateElement('Criteria')
$richMainlandCriterion.SetAttribute('id', 'ZYL_RichMainland')
$richMainlandCriterion.SetAttribute('any', '1')
foreach ($richMainlandMap in $richMainlandMaps) {
    $mapMatch = $target.CreateElement('ConfigurationValueMatches')
    foreach ($configurationValue in @(
        @('Group', 'Map'),
        @('ConfigurationId', 'MAP_SCRIPT'),
        @('Value', $richMainlandMap[1])
    )) {
        $configurationNode = $target.CreateElement($configurationValue[0])
        $configurationNode.InnerText = $configurationValue[1]
        [void]$mapMatch.AppendChild($configurationNode)
    }
    [void]$richMainlandCriterion.AppendChild($mapMatch)
}
[void]$zylCriteria.AppendChild($richMainlandCriterion)

# BBG owns the single idempotent copy of the free-society-title refund. Gate
# that existing action by the same game-mode criterion as the Team PVP layer,
# so no Secret Society database edits run in matches where the mode is off.
$bbgSecretSocietiesAction = [System.Xml.XmlElement]$target.SelectSingleNode(
    '/Mod/InGameActions/UpdateDatabase[File="Components/BBG/sql/Secret_Societies.sql"]'
)
if ($null -ne $bbgSecretSocietiesAction -and
        $null -eq $bbgSecretSocietiesAction.SelectSingleNode("Criteria[.='ZYL_SecretSocietiesXP2']")) {
    $modeCriterionNode = $target.CreateElement('Criteria')
    $modeCriterionNode.InnerText = 'ZYL_SecretSocietiesXP2'
    $firstFileNode = $bbgSecretSocietiesAction.SelectSingleNode('File')
    if ($null -ne $firstFileNode) {
        [void]$bbgSecretSocietiesAction.InsertBefore($modeCriterionNode, $firstFileNode)
    }
    else {
        [void]$bbgSecretSocietiesAction.AppendChild($modeCriterionNode)
    }
}

function Add-ZylAction {
    param(
        [string]$SectionName,
        [string]$ActionName,
        [string]$Id,
        [string[]]$File,
        [string]$LoadOrder = '200000000',
        [string[]]$Criteria = @()
    )
    $section = [System.Xml.XmlElement]$target.SelectSingleNode("/Mod/$SectionName")
    foreach ($existingAction in @($section.SelectNodes("*[@id='$Id']"))) {
        [void]$section.RemoveChild($existingAction)
    }
    $action = $target.CreateElement($ActionName)
    $action.SetAttribute('id', $Id)
    $propertiesNode = $target.CreateElement('Properties')
    $loadOrderNode = $target.CreateElement('LoadOrder')
    $loadOrderNode.InnerText = $LoadOrder
    [void]$propertiesNode.AppendChild($loadOrderNode)
    [void]$action.AppendChild($propertiesNode)
    foreach ($criterion in $Criteria) {
        $criterionNode = $target.CreateElement('Criteria')
        $criterionNode.InnerText = $criterion
        [void]$action.AppendChild($criterionNode)
    }
    foreach ($filePath in $File) {
        $fileNode = $target.CreateElement('File')
        $fileNode.InnerText = $filePath
        [void]$action.AppendChild($fileNode)
    }
    [void]$section.AppendChild($action)
}

function Add-ZylReplaceUIScript {
    param(
        [string]$Id,
        [string]$LuaContext,
        [string]$LuaReplace,
        [string]$LoadOrder = '200000000',
        [string[]]$Criteria = @()
    )
    $section = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/InGameActions')
    foreach ($existingAction in @($section.SelectNodes("ReplaceUIScript[@id='$Id']"))) {
        [void]$section.RemoveChild($existingAction)
    }
    $action = $target.CreateElement('ReplaceUIScript')
    $action.SetAttribute('id', $Id)
    $propertiesNode = $target.CreateElement('Properties')
    foreach ($property in @(
        @('LoadOrder', $LoadOrder),
        @('LuaContext', $LuaContext),
        @('LuaReplace', $LuaReplace)
    )) {
        $propertyNode = $target.CreateElement($property[0])
        $propertyNode.InnerText = $property[1]
        [void]$propertiesNode.AppendChild($propertyNode)
    }
    [void]$action.AppendChild($propertiesNode)
    foreach ($criterion in $Criteria) {
        $criterionNode = $target.CreateElement('Criteria')
        $criterionNode.InnerText = $criterion
        [void]$action.AppendChild($criterionNode)
    }
    [void]$section.AppendChild($action)
}

function Add-ZylUserInterface {
    param(
        [string]$Id,
        [string]$File,
        [string]$LoadOrder = '200000000',
        [string[]]$Criteria = @()
    )
    $section = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/InGameActions')
    foreach ($existingAction in @($section.SelectNodes("AddUserInterfaces[@id='$Id']"))) {
        [void]$section.RemoveChild($existingAction)
    }
    $action = $target.CreateElement('AddUserInterfaces')
    $action.SetAttribute('id', $Id)
    $propertiesNode = $target.CreateElement('Properties')
    foreach ($property in @(
        @('LoadOrder', $LoadOrder),
        @('Context', 'InGame')
    )) {
        $propertyNode = $target.CreateElement($property[0])
        $propertyNode.InnerText = $property[1]
        [void]$propertiesNode.AppendChild($propertyNode)
    }
    [void]$action.AppendChild($propertiesNode)
    foreach ($criterion in $Criteria) {
        $criterionNode = $target.CreateElement('Criteria')
        $criterionNode.InnerText = $criterion
        [void]$action.AppendChild($criterionNode)
    }
    $fileNode = $target.CreateElement('File')
    $fileNode.InnerText = $File
    [void]$action.AppendChild($fileNode)
    [void]$section.AppendChild($action)
}

Add-ZylAction 'FrontEndActions' 'UpdateDatabase' 'ZYL_CoastLeaderVariants_Config' 'LeaderVariants/ZYL_CoastLeaderVariants_Config.sql'
Add-ZylAction 'FrontEndActions' 'UpdateText' 'ZYL_CoastLeaderVariants_ConfigText' 'LeaderVariants/ZYL_CoastLeaderVariants_Text.sql'
Add-ZylAction 'FrontEndActions' 'UpdateIcons' 'ZYL_CoastLeaderVariants_ConfigIcons' 'LeaderVariants/ZYL_CoastLeaderVariants_Icons.sql'
Add-ZylAction 'FrontEndActions' 'UpdateColors' 'ZYL_CoastLeaderVariants_ConfigColors' 'LeaderVariants/ZYL_CoastLeaderVariants_Colors.sql'
Add-ZylAction 'FrontEndActions' 'UpdateDatabase' 'ZYL_BBGExpandedDisableConfig' 'Components/BBG/sql/BBG_Expanded/Disable_new_config.sql' '100000000'
Add-ZylAction 'FrontEndActions' 'UpdateText' 'ZYL_GameplayOverridesFrontEndText' 'lang/ZYL_GameplayOverrides_Text.xml' '260000020'
Add-ZylAction 'FrontEndActions' 'UpdateText' 'ZYL_BBG74_ChineseTextFrontEnd' 'lang/ZYL_BBG74_Chinese_Text.xml' '259999990'
Add-ZylAction 'FrontEndActions' 'UpdateDatabase' 'ZYL_DisableNaturalDisastersOption' 'configuration/ZYL_DisasterRange.sql' '99999'
Add-ZylAction 'FrontEndActions' 'ImportFiles' 'ZYL_LANPlayerNameLength' 'Option/Options.xml' '1000'
Add-ZylAction 'FrontEndActions' 'UpdateDatabase' 'ZYL_RandomPromotionHotkeyConfig' 'NHK/Config_NewUnitOperation.xml' '1000'
Add-ZylAction 'FrontEndActions' 'UpdateText' 'ZYL_RandomPromotionHotkeyConfigText' 'NHK/Config_NewUnitOperation_Text.xml' '1000'
Add-ZylAction 'FrontEndActions' 'UpdateDatabase' 'ZYL_RichMainland_Config' 'Components/BBM/Configuration/ZYL_RichMainland_Config.xml' '200000100'
Add-ZylAction 'FrontEndActions' 'UpdateText' 'ZYL_RichMainland_Text' 'Components/BBM/Lang/ZYL_RichMainland_Text.xml' '200000100'
Add-ZylAction 'FrontEndActions' 'UpdateDatabase' 'ZYL_LobbyDefaults' 'configuration/ZYL_LobbyDefaults.xml' '300000000'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_CoastLeaderVariants_Gameplay' 'LeaderVariants/ZYL_CoastLeaderVariants_Gameplay.sql'
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_CoastLeaderVariants_GameplayText' 'LeaderVariants/ZYL_CoastLeaderVariants_Text.sql'
Add-ZylAction 'InGameActions' 'UpdateIcons' 'ZYL_CoastLeaderVariants_GameplayIcons' 'LeaderVariants/ZYL_CoastLeaderVariants_Icons.sql'
Add-ZylAction 'InGameActions' 'UpdateColors' 'ZYL_CoastLeaderVariants_GameplayColors' 'LeaderVariants/ZYL_CoastLeaderVariants_Colors.sql'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_StartingSettlerMovement' 'sql/ZYL_StartingSettler.sql' '50020'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_BBGExpandedDisableGameplay' 'Components/BBG/sql/BBG_Expanded/Disable_new.sql' '100000000'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_BBGExpandedResources' 'CIVITASResources/Core/p0k_Resources.sql' '5' @('ZYL_NoExternalBBGExpanded')
Add-ZylAction 'InGameActions' 'UpdateArt' 'ZYL_BBGExpandedResourcesArt' 'CIVITASResources/CIVITAS Resources.dep' '5' @('ZYL_NoExternalBBGExpanded')
Add-ZylAction 'InGameActions' 'UpdateIcons' 'ZYL_BBGExpandedResourcesIcons' 'CIVITASResources/Core/CVS_Resource_Icon_Definitions.sql' '5' @('ZYL_NoExternalBBGExpanded')
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_BBGExpandedResourcesText' 'CIVITASResources/Core/p0k_Resources_Localisation.sql' '5' @('ZYL_NoExternalBBGExpanded')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_BBGExpandedResourcesMode' @(
    'CIVITASResources/Core_MODE/p0k_Resources_MODE_Industries.sql',
    'CIVITASResources/Core_MODE/p0k_Resources_MODE_Products.sql',
    'CIVITASResources/Core_MODE/p0k_Resources_MODE_Projects.sql'
) '10' @('ZYL_NoExternalBBGExpanded', 'ZYL_MonopoliesMode')
Add-ZylAction 'InGameActions' 'UpdateIcons' 'ZYL_BBGExpandedResourcesModeIcons' 'CIVITASResources/Core_MODE/p0k_Resources_MODE_Icon_Definitions.sql' '10' @('ZYL_NoExternalBBGExpanded', 'ZYL_MonopoliesMode')
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_BBGExpandedResourcesModeText' 'CIVITASResources/Core_MODE/p0k_Resources_MODE_Localisation.sql' '10' @('ZYL_NoExternalBBGExpanded', 'ZYL_MonopoliesMode')
# BBG normally applies this only when an external Expanded Mod ID is present.
# Apply the same balance layer to the embedded resources after their base rows.
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_BBGExpandedResourcesBalance' 'Components/BBG/sql/BBG_Expanded/Resources.sql' '100000000' @('ZYL_NoExternalBBGExpanded')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_ResourceHarvests' 'sql/ZYL_ResourceHarvests.sql' '200000000'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_SelectedPantheons' 'sql/ZYL_Pantheons.sql' '210000000'
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_SelectedPantheonsText' 'lang/ZYL_Pantheons_Text.xml' '210000010'
Add-ZylAction 'InGameActions' 'UpdateIcons' 'ZYL_SelectedPantheonsIcons' 'icons/ZYL_Pantheon_Icons.xml' '210000010'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_GeothermalMines' 'sql/ZYL_GeothermalMines.sql' '210000020' @('ZYL_GatheringStorm')
Add-ZylAction 'InGameActions' 'ImportFiles' 'ZYL_RichMainland_MapScripts' @(
    'Components/BBM/Data/BBS Maps/zyl_team_rich_mainland.lua',
    'Components/BBM/Data/BBS Maps/zyl_ffa_rich_mainland.lua',
    'Components/BBM/Data/BBS Maps/zyl_rich_mainland_core.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_Balance.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_BBS_TerrainGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_CoastalLowlands.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_DW_TerrainGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_FeatureGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_MapUtilities.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_MountainsCliffs.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_ResourceGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_RiversLakes.lua'
) '1001'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_RichMainland_Common' 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureCommon.sql' '1002' @('ZYL_RichMainland')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_RichMainland_Team_Config' 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureTeam.sql' '1003' @('ZYL_RichMainland_Team')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_RichMainland_FFA_Config' 'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureFFA.sql' '1003' @('ZYL_RichMainland_FFA')
Add-ZylAction 'InGameActions' 'UpdateArt' 'ZYL_TPVP_SecretSocietiesArt' 'Components/TeamPVPSecretSocieties/TeamPVPSecretSocieties.dep' '250000000' @('ZYL_SecretSocietiesXP2')
Add-ZylAction 'InGameActions' 'UpdateArt' 'ZYL_TPVP_TaoistArt' 'Components/TeamPVPSecretSocieties/Taoist/Taoist.dep' '250000001' @('ZYL_SecretSocietiesXP2')
$taoistArtAction = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/InGameActions/UpdateArt[@id="ZYL_TPVP_TaoistArt"]')
$taoistArtContext = $target.CreateElement('Context')
$taoistArtContext.InnerText = 'InGame'
[void]$taoistArtAction.SelectSingleNode('./Properties').AppendChild($taoistArtContext)
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_TPVP_TaoistDatabase' 'Components/TeamPVPSecretSocieties/Taoist/Data/Taoist_unit.sql' '250000005' @('ZYL_SecretSocietiesXP2')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_TPVP_GildedShipyard' 'Components/TeamPVPSecretSocieties/Build_GildedShipyard.xml' '250000000' @('ZYL_SecretSocietiesXP2')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_TPVP_SecretSocietiesGameplay' 'Components/TeamPVPSecretSocieties/Gameplay.sql' '250000010' @('ZYL_SecretSocietiesXP2')
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_TPVP_SecretSocietiesText' @(
    'Components/TeamPVPSecretSocieties/Text.xml',
    'Components/TeamPVPSecretSocieties/Taoist/Text/Taoist_text.xml'
) '250000020' @('ZYL_SecretSocietiesXP2')
Add-ZylAction 'InGameActions' 'UpdateIcons' 'ZYL_TPVP_SecretSocietiesIcons' @(
    'Components/TeamPVPSecretSocieties/Icons.xml',
    'Components/TeamPVPSecretSocieties/Taoist/Data/Taoist_icon.xml'
) '250000020' @('ZYL_SecretSocietiesXP2')
Add-ZylUserInterface 'ZYL_TPVP_TaoistUI' 'Components/TeamPVPSecretSocieties/Taoist/UI/Taoist_UI.xml' '250000030' @('ZYL_SecretSocietiesXP2')
Add-ZylAction 'InGameActions' 'AddGameplayScripts' 'ZYL_TPVP_TaoistGameplay' 'Components/TeamPVPSecretSocieties/Taoist/Scripts/Taoist_Gameplay.lua' '250000030' @('ZYL_SecretSocietiesXP2')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_GameplayOverrides' 'sql/ZYL_GameplayOverrides.sql' '260000000'
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_EraLengthOptimization' 'sql/ZYL_EraLengthOptimization.sql' '260000005' @('ZYL_EraLengthOptimization')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_GovernorOverrides' 'sql/ZYL_GovernorOverrides.sql' '260000010' @('ZYLPVP_BBG_XP1_OR_XP2')
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_GameplayOverridesText' 'lang/ZYL_GameplayOverrides_Text.xml' '260000020'
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_BBG74_ChineseText' 'lang/ZYL_BBG74_Chinese_Text.xml' '259999990'
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_BBGExpandedChineseText' 'lang/ZYL_BBGExpanded_Chinese.sql' '259999995'
Add-ZylAction 'InGameActions' 'AddGameplayScripts' 'ZYL_GameFeatureNotices' 'NT/Notice.lua' '1000'
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_GameFeatureNoticesText' 'NT/Notice_Text.xml' '1000'
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_RandomPromotionHotkeyText' 'NHK/Config_NewUnitOperation_Text.xml' '1000'
Add-ZylUserInterface 'ZYL_RandomPromotionHotkey' 'NHK/UI/NewUnitOperation.xml' '1100' @('TPT_NEW_HOTKEYS')
# Team PVP Tools' Better Trade Screen Lite (BTS). Keep its proven import
# pattern: Civ VI replaces the stock trade partial screens with same-named
# imported XML/Lua files. BBG's conflicting trade chain is skipped above.
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_BTS_SettingsSchema' 'BTS/Settings/BTS_SettingsSchema.sql' '11008' @('SETTINGS_UI_BetterTradeScreen')
Add-ZylAction 'InGameActions' 'UpdateDatabase' 'ZYL_BTS_Settings' 'BTS/Settings/BTS_Settings.sql' '11009' @('SETTINGS_UI_BetterTradeScreen')
Add-ZylUserInterface 'ZYL_BTS_SettingsPanel' 'BTS/Settings/BTS_SettingsPanel.xml' '11010' @('SETTINGS_UI_BetterTradeScreen')
Add-ZylAction 'InGameActions' 'ImportFiles' 'ZYL_BTS_UI' @(
    'BTS/UI/TradeOverview.xml',
    'BTS/UI/TradeOverview.lua',
    'BTS/UI/BTS_Serialize.lua',
    'BTS/UI/TradeSupport.lua',
    'BTS/UI/Choosers/TradeRouteChooser.xml',
    'BTS/UI/Choosers/TradeRouteChooser.lua',
    'BTS/UI/Choosers/TradeOriginChooser.xml',
    'BTS/UI/Choosers/TradeOriginChooser.lua'
) '11011' @('SETTINGS_UI_BetterTradeScreen')
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_BTS_Text' @(
    'BTS/Text/BTS_Text_EN.xml',
    'BTS/Text/BTS_Text_Hans_CN.xml'
) '11012' @('SETTINGS_UI_BetterTradeScreen')
Add-ZylReplaceUIScript 'ZYL_HideMapPinListPanel' 'MapPinListPanel' 'RMP/UI/MapPinListPanel.lua' '1100' @('ZYL_NoMapPins')
Add-ZylAction 'InGameActions' 'ImportFiles' 'ZYL_HideMapPinListPanelFiles' @(
    'RMP/UI/MapPinListPanel.xml',
    'RMP/UI/MapPinListPanel.lua'
) '1110' @('ZYL_NoMapPins')
Add-ZylUserInterface 'ZYL_HideMapPinListButton' 'RMP/UI/Hide_MapPinListButton.xml' '1100' @('ZYL_NoMapPins')
Add-ZylAction 'InGameActions' 'UpdateText' 'ZYL_ForcedEndButtonText' 'FEB/ForcedEndButton_Text.xml' '1200'
Add-ZylUserInterface 'ZYL_ForcedEndButton' 'FEB/UI/ForcedEndButton.xml' '1200'
Add-ZylAction 'InGameActions' 'ImportFiles' 'ZYL_BDW_CompatibilityFiles' @(
    'Components/BetterDealWindow/DiplomacyDealView_ZYLPVP_Expansion2.lua',
    'Components/BetterDealWindow/ZYLPVP_BDW_MPH_Compatibility.lua'
) '50009'
Add-ZylReplaceUIScript 'ZYL_BDW_DiplomacyDealView_XP2' 'DiplomacyDealView' 'Components/BetterDealWindow/DiplomacyDealView_ZYLPVP_Expansion2.lua' '50010' @('Expansion2')
Add-ZylAction 'InGameActions' 'ImportFiles' 'ZYL_DiplomacyRibbonFiles_XP2' @(
	'ui/Replacements/DiplomacyRibbon.xml',
	'ui/Replacements/DiplomacyRibbon_ZYL.lua'
) '50009' @('Expansion2')
Add-ZylReplaceUIScript 'ZYL_DiplomacyRibbonIntel_XP2' 'DiplomacyRibbon' 'ui/Replacements/DiplomacyRibbon_ZYL.lua' '50010' @('Expansion2')
Add-ZylReplaceUIScript 'ZYL_DMT_MapPinManager' 'MapPinManager' 'Components/DetailedMapTacks/ui/mappinmanager_dmt.lua' '50020'
Add-ZylReplaceUIScript 'ZYL_DMT_MapPinPopup' 'MapPinPopup' 'Components/DetailedMapTacks/ui/mappinpopup_dmt.lua' '50020'

$filesNode = [System.Xml.XmlElement]$target.SelectSingleNode('/Mod/Files')
foreach ($newFile in @(
    'LeaderVariants/ZYL_CoastLeaderVariants_Gameplay.sql',
    'LeaderVariants/ZYL_CoastLeaderVariants_Config.sql',
    'LeaderVariants/ZYL_CoastLeaderVariants_Text.sql',
    'LeaderVariants/ZYL_CoastLeaderVariants_Icons.sql',
    'LeaderVariants/ZYL_CoastLeaderVariants_Colors.sql',
    'ArtDefs/ZYL_CoastLeaderVariants_Leaders.artdef',
    'ArtDefs/ZYL_CoastLeaderVariants_FallbackLeaders.artdef',
    'sql/ZYL_StartingSettler.sql',
    'sql/ZYL_ResourceHarvests.sql',
    'sql/ZYL_Pantheons.sql',
    'sql/ZYL_GeothermalMines.sql',
    'sql/ZYL_GameplayOverrides.sql',
	'sql/ZYL_EraLengthOptimization.sql',
    'sql/ZYL_GovernorOverrides.sql',
	'lang/ZYL_Pantheons_Text.xml',
	'lang/ZYL_GameplayOverrides_Text.xml',
	'lang/ZYL_BBG74_Chinese_Text.xml',
	'lang/ZYL_BBGExpanded_Chinese.sql',
	'configuration/ZYL_DisasterRange.sql',
	'configuration/ZYL_LobbyDefaults.xml',
    'icons/ZYL_Pantheon_Icons.xml',
	'Option/Options.xml',
	'NT/Notice.lua',
	'NT/Notice_Text.xml',
	'NHK/Config_NewUnitOperation.xml',
	'NHK/Config_NewUnitOperation_Text.xml',
	'NHK/UI/NewUnitOperation.lua',
	'NHK/UI/NewUnitOperation.xml',
	'BTS/Settings/BTS_Settings.sql',
	'BTS/Settings/BTS_SettingsPanel.lua',
	'BTS/Settings/BTS_SettingsPanel.xml',
	'BTS/Settings/BTS_SettingsSchema.sql',
	'BTS/Text/BTS_Text_EN.xml',
	'BTS/Text/BTS_Text_Hans_CN.xml',
	'BTS/UI/TradeOverview.lua',
	'BTS/UI/TradeOverview.xml',
	'BTS/UI/BTS_Serialize.lua',
	'BTS/UI/TradeSupport.lua',
	'BTS/UI/Choosers/TradeOriginChooser.lua',
	'BTS/UI/Choosers/TradeOriginChooser.xml',
	'BTS/UI/Choosers/TradeRouteChooser.lua',
	'BTS/UI/Choosers/TradeRouteChooser.xml',
	'ui/Replacements/DiplomacyRibbon_ZYL.lua',
	'ui/Replacements/DiplomacyRibbon.xml',
	'RMP/UI/Hide_MapPinListButton.lua',
	'RMP/UI/Hide_MapPinListButton.xml',
	'RMP/UI/MapPinListPanel.lua',
	'RMP/UI/MapPinListPanel.xml',
    'Components/TeamPVPSecretSocieties/Build_GildedShipyard.xml',
	'Components/BBG/sql/BBG_Expanded/Disable_new.sql',
	'Components/BBG/sql/BBG_Expanded/Disable_new_config.sql',
    'Components/TeamPVPSecretSocieties/Gameplay.sql',
    'Components/TeamPVPSecretSocieties/Text.xml',
    'Components/TeamPVPSecretSocieties/Icons.xml',
    'Components/TeamPVPSecretSocieties/TeamPVPSecretSocieties.dep',
    'Components/TeamPVPSecretSocieties/Buildings.artdef',
    'Components/TeamPVPSecretSocieties/Taoist/Taoist.dep',
    'Components/TeamPVPSecretSocieties/Taoist/Artdefs/Units.artdef',
    'Components/TeamPVPSecretSocieties/Taoist/Data/Taoist_icon.xml',
    'Components/TeamPVPSecretSocieties/Taoist/Data/Taoist_unit.sql',
    'Components/TeamPVPSecretSocieties/Taoist/Platforms/MacOS/BLPs/Taoist.blp',
    'Components/TeamPVPSecretSocieties/Taoist/Platforms/Windows/BLPs/Taoist.blp',
    'Components/TeamPVPSecretSocieties/Taoist/Scripts/Taoist_Gameplay.lua',
    'Components/TeamPVPSecretSocieties/Taoist/Text/Taoist_text.xml',
    'Components/TeamPVPSecretSocieties/Taoist/UI/Taoist_UI.lua',
    'Components/TeamPVPSecretSocieties/Taoist/UI/Taoist_UI.xml',
    'Components/BetterDealWindow/DiplomacyDealView.lua',
    'Components/BetterDealWindow/DiplomacyDealView.xml',
    'Components/BetterDealWindow/DiplomacyDealView_Expansion2.lua',
    'Components/BetterDealWindow/DiplomacyDealView_ZYLPVP_Expansion2.lua',
    'Components/BetterDealWindow/ZYLPVP_BDW_MPH_Compatibility.lua',
    'Components/DetailedMapTacks/ui/dmt_mappinsubjectmanager.lua',
    'Components/DetailedMapTacks/ui/dmt_modifiercalculator.lua',
    'Components/DetailedMapTacks/ui/dmt_modifierrequirementchecker.lua',
    'Components/DetailedMapTacks/ui/dmt_serialize.lua',
    'Components/DetailedMapTacks/ui/dmt_yieldcalculator.lua',
    'Components/DetailedMapTacks/ui/dmt_yieldcalculator.xml',
    'Components/DetailedMapTacks/ui/mappinmanager_dmt.lua',
    'Components/DetailedMapTacks/ui/mappinmanager.xml',
    'Components/DetailedMapTacks/ui/mappinpopup_dmt.lua',
    'Components/DetailedMapTacks/config/en_us/dmt_options_text.xml',
    'Components/DetailedMapTacks/config/dmt_options_translations_text.xml',
    'Components/DetailedMapTacks/text/en_us/dmt_text.xml',
    'Components/DetailedMapTacks/text/dmt_translations_text.xml',
    'Components/BetterDealWindow/Text/BDW_Text.xml',
    'Components/BetterDealWindow/Text/BDW_Text_CN.xml',
    'Components/BetterDealWindow/Text/BDW_Text_DE.xml',
    'Components/BetterDealWindow/Text/BDW_Text_ES.xml',
    'Components/BetterDealWindow/Text/BDW_Text_FR.xml',
    'Components/BetterDealWindow/Text/BDW_Text_IT.xml',
    'Components/BetterDealWindow/Text/BDW_Text_JP.xml',
    'Components/BetterDealWindow/Text/BDW_Text_KR.xml',
    'Components/BetterDealWindow/Text/BDW_Text_PL.xml',
    'Components/BetterDealWindow/Text/BDW_Text_PT.xml',
    'Components/BetterDealWindow/Text/BDW_Text_RU.xml',
    'FEB/ForcedEndButton_Text.xml',
    'FEB/UI/ForcedEndButton.lua',
    'FEB/UI/ForcedEndButton.xml',
    'Components/BBM/Configuration/ZYL_RichMainland_Config.xml',
    'Components/BBM/Lang/ZYL_RichMainland_Text.xml',
    'Components/BBM/Data/BBS Maps/zyl_team_rich_mainland.lua',
    'Components/BBM/Data/BBS Maps/zyl_ffa_rich_mainland.lua',
    'Components/BBM/Data/BBS Maps/zyl_rich_mainland_core.lua',
    'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureCommon.sql',
    'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureTeam.sql',
    'Components/BBM/Data/BBS Maps/ZYLRM/ConfigureFFA.sql',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_AssignStartingPlots.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_Balance.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_BBS_TerrainGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_CoastalLowlands.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_DW_TerrainGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_FeatureGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_MapUtilities.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_MountainsCliffs.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_ResourceGenerator.lua',
    'Components/BBM/Data/BBS Maps/Utility/ZYL_RVC_RiversLakes.lua',
    'CONFLICT_RESOLUTION.md',
    'SOURCES.md',
    'tools/assemble_modinfo.ps1',
    'tools/validate.ps1'
)) {
    $fileNode = $target.CreateElement('File')
    $fileNode.InnerText = $newFile
    [void]$filesNode.AppendChild($fileNode)
}

# Publish the complete BBG Expanded art package. Its .dep resolves paths
# relative to CIVITASResources, so the directory must remain intact.
$resourceAssetRoot = Join-Path $modRoot 'CIVITASResources'
foreach ($resourceAsset in @(Get-ChildItem -LiteralPath $resourceAssetRoot -Recurse -File | Sort-Object FullName)) {
    $resourceRelativePath = $resourceAsset.FullName.Substring($modRoot.Length + 1).Replace('\', '/')
    $fileNode = $target.CreateElement('File')
    $fileNode.InnerText = $resourceRelativePath
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
