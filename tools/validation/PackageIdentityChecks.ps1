function Get-ZylPackageIdentityContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedModId,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedPackageName,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedSemanticVersion,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedModInfoVersion,

        [AllowEmptyString()]
        [string]$MultiplayerHelperSourceOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $modElement = $ModInfo.DocumentElement
    if ($null -eq $modElement -or
            $modElement.GetAttribute('id') -ne $ExpectedModId) {
        $actualModId = if ($null -eq $modElement) {
            '<missing>'
        }
        else {
            $modElement.GetAttribute('id')
        }
        $issues.Add("Unexpected Mod ID: $actualModId")
    }

    $propertyVersionNode = $ModInfo.SelectSingleNode('/Mod/Properties/Version')
    $toolboxVersionNode = $ModInfo.SelectSingleNode('/Mod/Properties/ToolboxVersion')
    if ($null -eq $modElement -or
            $modElement.GetAttribute('version') -ne $ExpectedModInfoVersion -or
            $null -eq $propertyVersionNode -or
            $propertyVersionNode.InnerText -ne $ExpectedModInfoVersion -or
            $null -eq $toolboxVersionNode -or
            $toolboxVersionNode.InnerText -ne $ExpectedSemanticVersion) {
        $issues.Add(
            'Package version metadata must match tools/project.json ' +
            "($ExpectedSemanticVersion / ModInfo $ExpectedModInfoVersion)."
        )
    }

    $nameNode = $ModInfo.SelectSingleNode('/Mod/Properties/Name')
    if ($null -eq $nameNode -or $nameNode.InnerText -ne 'LOC_ZYLPVPMOD_TITLE') {
        $issues.Add('The ModInfo title is not the ZYLPVPMOD localization key.')
    }

    $titleEnglish = $ModInfo.SelectSingleNode(
        "/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_TITLE']/en_US"
    )
    $titleChinese = $ModInfo.SelectSingleNode(
        "/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_TITLE']/zh_Hans_CN"
    )
    $expectedPackageTitle = "$ExpectedPackageName $ExpectedSemanticVersion"
    if ($null -eq $titleEnglish -or
            $titleEnglish.InnerText -ne $expectedPackageTitle -or
            $null -eq $titleChinese -or
            $titleChinese.InnerText -ne $expectedPackageTitle) {
        $issues.Add("The localized ModInfo title must be $expectedPackageTitle.")
    }

    $descriptionChinese = $ModInfo.SelectSingleNode(
        "/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_DESCRIPTION']/zh_Hans_CN"
    )
    $knownDescriptionTypo = ([string][char]0x4FDD) + [char]0x6559
    if ($null -eq $descriptionChinese -or
            $descriptionChinese.InnerText.Contains($knownDescriptionTypo)) {
        $issues.Add(
            'The generated Simplified Chinese ModInfo description is missing ' +
            'or contains the known typo.'
        )
    }

    $multiplayerHelperPath = Join-Path $ProjectRoot 'data\MP_helper.lua'
    $multiplayerHelperSource = if ($PSBoundParameters.ContainsKey(
            'MultiplayerHelperSourceOverride'
        )) {
        $MultiplayerHelperSourceOverride
    }
    elseif (Test-Path -LiteralPath $multiplayerHelperPath -PathType Leaf) {
        Get-Content -LiteralPath $multiplayerHelperPath -Raw
    }
    else {
        $null
    }
    $expectedHandshake = "local g_version = `"$ExpectedPackageName v$ExpectedSemanticVersion`""
    if ($null -eq $multiplayerHelperSource -or
            -not $multiplayerHelperSource.Contains($expectedHandshake)) {
        $issues.Add(
            "The multiplayer version handshake must identify " +
            "$ExpectedPackageName v$ExpectedSemanticVersion."
        )
    }
    if ($null -ne $multiplayerHelperSource) {
        foreach ($requiredFragment in @(
                'if Drop_Data[playerID] ~= nil then',
                'local savedMovesByUnitID = {}',
                'UnitManager.ChangeMovesRemaining(unit, savedMoves - currentMoves)',
                'local function DebugLog(...)'
            )) {
            if (-not $multiplayerHelperSource.Contains($requiredFragment)) {
                $issues.Add(
                    'The multiplayer helper is missing its deterministic ' +
                    "drop/reconnect guard: $requiredFragment"
                )
            }
        }
        foreach ($forbiddenFragment in @(
                'Game.GetRandNum',
                'GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted)',
                'UnitManager.ChangeMovesRemaining(unit, -99)',
                'function Tablelength(',
                'function FindTableIndex('
            )) {
            if ($multiplayerHelperSource.Contains($forbiddenFragment)) {
                $issues.Add(
                    'The multiplayer helper restored a random-stream, ' +
                    "non-idempotent or dead-code path: $forbiddenFragment"
                )
            }
        }
    }

    return @($issues)
}
