[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modRoot = Split-Path -Parent $PSScriptRoot
$projectMetadataPath = Join-Path $PSScriptRoot 'project.json'
if (-not (Test-Path -LiteralPath $projectMetadataPath -PathType Leaf)) {
    throw "Project metadata not found: $projectMetadataPath"
}
$projectMetadata = Get-Content -LiteralPath $projectMetadataPath -Raw | ConvertFrom-Json
$modInfoPath = Join-Path $modRoot ([string]$projectMetadata.modInfoFile)
$expectedModId = [string]$projectMetadata.modId
$expectedPackageName = [string]$projectMetadata.packageName
$expectedSemanticVersion = [string]$projectMetadata.semanticVersion
$expectedModInfoVersion = ([int]$projectMetadata.modInfoVersion).ToString(
    [System.Globalization.CultureInfo]::InvariantCulture
)
$validationErrors = [System.Collections.Generic.List[string]]::new()

function Add-ValidationError {
    param([string]$Message)
    $validationErrors.Add($Message)
}

$luaChecksPath = Join-Path $PSScriptRoot 'validation\LuaChecks.ps1'
if (-not (Test-Path -LiteralPath $luaChecksPath -PathType Leaf)) {
    throw "Lua validation helpers not found: $luaChecksPath"
}
. $luaChecksPath

$manifestGraphHelpersPath = Join-Path $PSScriptRoot 'validation\ManifestGraph.ps1'
if (-not (Test-Path -LiteralPath $manifestGraphHelpersPath -PathType Leaf)) {
    throw "Manifest graph validation helpers not found: $manifestGraphHelpersPath"
}
. $manifestGraphHelpersPath

$manifestSourcesHelpersPath = Join-Path $PSScriptRoot 'manifest\ManifestSources.ps1'
if (-not (Test-Path -LiteralPath $manifestSourcesHelpersPath -PathType Leaf)) {
    throw "Manifest source helpers not found: $manifestSourcesHelpersPath"
}
. $manifestSourcesHelpersPath

$manifestChecksPath = Join-Path $PSScriptRoot 'validation\ManifestChecks.ps1'
if (-not (Test-Path -LiteralPath $manifestChecksPath -PathType Leaf)) {
    throw "Manifest validation helpers not found: $manifestChecksPath"
}
. $manifestChecksPath

$projectChecksPath = Join-Path $PSScriptRoot 'validation\ProjectChecks.ps1'
if (-not (Test-Path -LiteralPath $projectChecksPath -PathType Leaf)) {
    throw "Project validation helpers not found: $projectChecksPath"
}
. $projectChecksPath

$assetInventoryChecksPath = Join-Path $PSScriptRoot 'validation\AssetInventoryChecks.ps1'
if (-not (Test-Path -LiteralPath $assetInventoryChecksPath -PathType Leaf)) {
    throw "Asset inventory validation helpers not found: $assetInventoryChecksPath"
}
. $assetInventoryChecksPath

$runtimeSafetyChecksPath = Join-Path $PSScriptRoot 'validation\RuntimeSafetyChecks.ps1'
if (-not (Test-Path -LiteralPath $runtimeSafetyChecksPath -PathType Leaf)) {
    throw "Runtime safety validation helpers not found: $runtimeSafetyChecksPath"
}
. $runtimeSafetyChecksPath

$databaseContractChecksPath = Join-Path $PSScriptRoot 'validation\DatabaseContractChecks.ps1'
if (-not (Test-Path -LiteralPath $databaseContractChecksPath -PathType Leaf)) {
    throw "Database contract validation helpers not found: $databaseContractChecksPath"
}
. $databaseContractChecksPath

$teamPvpSocietyChecksPath = Join-Path $PSScriptRoot 'validation\TeamPvpSocietyChecks.ps1'
if (-not (Test-Path -LiteralPath $teamPvpSocietyChecksPath -PathType Leaf)) {
    throw "Team PVP Secret Societies validation helpers not found: $teamPvpSocietyChecksPath"
}
. $teamPvpSocietyChecksPath

$expandedResourceChecksPath = Join-Path $PSScriptRoot 'validation\ExpandedResourceChecks.ps1'
if (-not (Test-Path -LiteralPath $expandedResourceChecksPath -PathType Leaf)) {
    throw "BBG Expanded resource validation helpers not found: $expandedResourceChecksPath"
}
. $expandedResourceChecksPath

$pantheonChecksPath = Join-Path $PSScriptRoot 'validation\PantheonChecks.ps1'
if (-not (Test-Path -LiteralPath $pantheonChecksPath -PathType Leaf)) {
    throw "Pantheon validation helpers not found: $pantheonChecksPath"
}
. $pantheonChecksPath

$startingBonusChecksPath = Join-Path $PSScriptRoot 'validation\StartingBonusChecks.ps1'
if (-not (Test-Path -LiteralPath $startingBonusChecksPath -PathType Leaf)) {
    throw "Starting bonus validation helpers not found: $startingBonusChecksPath"
}
. $startingBonusChecksPath

$leaderVariantChecksPath = Join-Path $PSScriptRoot 'validation\LeaderVariantChecks.ps1'
if (-not (Test-Path -LiteralPath $leaderVariantChecksPath -PathType Leaf)) {
    throw "Leader variant validation helpers not found: $leaderVariantChecksPath"
}
. $leaderVariantChecksPath

$monopoliesChecksPath = Join-Path $PSScriptRoot 'validation\MonopoliesChecks.ps1'
if (-not (Test-Path -LiteralPath $monopoliesChecksPath -PathType Leaf)) {
    throw "Industries/Corporations validation helpers not found: $monopoliesChecksPath"
}
. $monopoliesChecksPath

$bbgLocalizationChecksPath = Join-Path $PSScriptRoot 'validation\BbgLocalizationChecks.ps1'
if (-not (Test-Path -LiteralPath $bbgLocalizationChecksPath -PathType Leaf)) {
    throw "BBG localization validation helpers not found: $bbgLocalizationChecksPath"
}
. $bbgLocalizationChecksPath

$bbgIconChecksPath = Join-Path $PSScriptRoot 'validation\BbgIconChecks.ps1'
if (-not (Test-Path -LiteralPath $bbgIconChecksPath -PathType Leaf)) {
    throw "BBG icon validation helpers not found: $bbgIconChecksPath"
}
. $bbgIconChecksPath

$gameplayLocalizationChecksPath = Join-Path $PSScriptRoot 'validation\GameplayLocalizationChecks.ps1'
if (-not (Test-Path -LiteralPath $gameplayLocalizationChecksPath -PathType Leaf)) {
    throw "Gameplay localization validation helpers not found: $gameplayLocalizationChecksPath"
}
. $gameplayLocalizationChecksPath

$bbgTooltipChecksPath = Join-Path $PSScriptRoot 'validation\BbgTooltipChecks.ps1'
if (-not (Test-Path -LiteralPath $bbgTooltipChecksPath -PathType Leaf)) {
    throw "BBG tooltip validation helpers not found: $bbgTooltipChecksPath"
}
. $bbgTooltipChecksPath

$releaseChecksPath = Join-Path $PSScriptRoot 'validation\ReleaseChecks.ps1'
if (-not (Test-Path -LiteralPath $releaseChecksPath -PathType Leaf)) {
    throw "Release validation helpers not found: $releaseChecksPath"
}
. $releaseChecksPath

$multiplayerChecksPath = Join-Path $PSScriptRoot 'validation\MultiplayerChecks.ps1'
if (-not (Test-Path -LiteralPath $multiplayerChecksPath -PathType Leaf)) {
    throw "Multiplayer validation helpers not found: $multiplayerChecksPath"
}
. $multiplayerChecksPath

$mapChecksPath = Join-Path $PSScriptRoot 'validation\MapChecks.ps1'
if (-not (Test-Path -LiteralPath $mapChecksPath -PathType Leaf)) {
    throw "Map validation helpers not found: $mapChecksPath"
}
. $mapChecksPath

$uiChecksPath = Join-Path $PSScriptRoot 'validation\UiChecks.ps1'
if (-not (Test-Path -LiteralPath $uiChecksPath -PathType Leaf)) {
    throw "UI validation helpers not found: $uiChecksPath"
}
. $uiChecksPath

$identityChecksPath = Join-Path $PSScriptRoot 'validation\IdentityChecks.ps1'
if (-not (Test-Path -LiteralPath $identityChecksPath -PathType Leaf)) {
    throw "Identity validation helpers not found: $identityChecksPath"
}
. $identityChecksPath

$missingRemovalFixture = @(Get-ZylLuaEventLifecycleIssues -Source 'Events.Example.Add(OnExample)' -Label 'Fixture')
$balancedLifecycleFixture = @(Get-ZylLuaEventLifecycleIssues -Source @'
Events.Example.Add(OnExample)
Events.Example.Remove(OnExample)
'@ -Label 'Fixture')
$duplicateRegistrationFixture = @(Get-ZylLuaEventLifecycleIssues -Source @'
Events.Example.Add(OnExample)
Events.Example.Add(OnExample)
Events.Example.Remove(OnExample)
'@ -Label 'Fixture')
if ($missingRemovalFixture.Count -ne 1 -or
        $balancedLifecycleFixture.Count -ne 0 -or
        $duplicateRegistrationFixture.Count -ne 1) {
    Add-ValidationError 'Lua event-lifecycle helper failed its positive/negative self-test.'
}

$canonicalXmlFixtureA = [System.Xml.XmlDocument]::new()
$canonicalXmlFixtureA.LoadXml('<Root b="2" a="1"><Child>x</Child></Root>')
$canonicalXmlFixtureB = [System.Xml.XmlDocument]::new()
$canonicalXmlFixtureB.LoadXml('<Root a="1" b="2"><Child>x</Child></Root>')
$canonicalFixtureJsonA = ConvertTo-ZylCanonicalJson -InputObject (
    ConvertTo-ZylCanonicalXmlNode -Node $canonicalXmlFixtureA.DocumentElement
)
$canonicalFixtureJsonB = ConvertTo-ZylCanonicalJson -InputObject (
    ConvertTo-ZylCanonicalXmlNode -Node $canonicalXmlFixtureB.DocumentElement
)
if ($canonicalFixtureJsonA -ne $canonicalFixtureJsonB) {
    Add-ValidationError 'Manifest canonicalization helper is sensitive to XML attribute order.'
}

$matchingManifestFixture = [System.Xml.XmlDocument]::new()
$matchingManifestFixture.LoadXml('<Files><File b="2" a="1">a.xml</File></Files>')
$reorderedManifestFixture = [System.Xml.XmlDocument]::new()
$reorderedManifestFixture.LoadXml('<Files><File a="1" b="2">a.xml</File></Files>')
$driftedManifestFixture = [System.Xml.XmlDocument]::new()
$driftedManifestFixture.LoadXml('<Files><File a="1" b="2">b.xml</File></Files>')
if (-not (Test-ZylManifestSectionsMatch `
        -Expected $matchingManifestFixture.DocumentElement `
        -Actual $reorderedManifestFixture.DocumentElement) -or
        (Test-ZylManifestSectionsMatch `
            -Expected $matchingManifestFixture.DocumentElement `
            -Actual $driftedManifestFixture.DocumentElement)) {
    Add-ValidationError 'Manifest section matcher failed its positive/negative self-test.'
}

$safeWorkshopFixture = @(Get-ZylWorkshopCacheReferenceIssues `
    -Source 'Join-Path $modRoot manifest' `
    -Label 'Fixture')
$unsafeWorkshopFixture = @(Get-ZylWorkshopCacheReferenceIssues `
    -Source 'C:\Steam\steamapps\workshop\content\289070' `
    -Label 'Fixture')
if ($safeWorkshopFixture.Count -ne 0 -or
        $unsafeWorkshopFixture.Count -ne 1 -or
        -not (Test-IsSourceOnlyFile 'docs\architecture.md') -or
        (Test-IsSourceOnlyFile 'ui\stagingroom.lua') -or
        -not (Test-IsGeneratedProjectPath 'artifacts\workshop\file.xml') -or
        (Test-IsGeneratedProjectPath 'components\bbg\file.xml')) {
    Add-ValidationError 'Project boundary helpers failed their positive/negative self-test.'
}

$uniquePathFixture = @(Get-ZylDuplicateNormalizedPaths -Paths @('a/file.xml', 'b/file.xml'))
$duplicatePathFixture = @(Get-ZylDuplicateNormalizedPaths -Paths @('A/file.xml', 'a\FILE.xml'))
if ($uniquePathFixture.Count -ne 0 -or $duplicatePathFixture.Count -ne 1) {
    Add-ValidationError 'Asset path identity helper failed its positive/negative self-test.'
}

$safeRuntimeTextFixture = @(Get-ZylRuntimeTextSafetyIssues `
    -Source 'local value = 1' `
    -Label 'Fixture.lua')
$unsafeRuntimeTextFixture = @(Get-ZylRuntimeTextSafetyIssues -Source @'
loadstring("return 1")
local oldId = "3cd7857e-b720-4a1b-a61d-930f58d5237e"
local legacy = "NO_MORE_STACK"
'@ -Label 'Fixture.lua')
if ($safeRuntimeTextFixture.Count -ne 0 -or $unsafeRuntimeTextFixture.Count -ne 3) {
    Add-ValidationError 'Active runtime safety helper failed its positive/negative self-test.'
}

$validEraDurationFixture = @(
    'GameEraMinimumTurns',
    'GameEraMaximumTurns'
)
foreach ($eraDurationFixture in @(
        @('ERA_ANCIENT', 50),
        @('ERA_CLASSICAL', 46),
        @('ERA_MEDIEVAL', 46),
        @('ERA_RENAISSANCE', 42),
        @('ERA_INDUSTRIAL', 42),
        @('ERA_MODERN', 40),
        @('ERA_ATOMIC', 40),
        @('ERA_INFORMATION', 40)
    )) {
    $validEraDurationFixture += "WHEN '$($eraDurationFixture[0])' THEN $($eraDurationFixture[1])"
    $validEraDurationFixture += "WHEN '$($eraDurationFixture[0])' THEN $($eraDurationFixture[1])"
}
$validEraDurationFixture = $validEraDurationFixture -join "`n"
$invalidEraDurationFixture = $validEraDurationFixture.Replace(
    "WHEN 'ERA_ANCIENT' THEN 50",
    "WHEN 'ERA_ANCIENT' THEN 51"
)
if (@(Get-ZylEraDurationSqlIssues -Source $validEraDurationFixture).Count -ne 0 -or
        @(Get-ZylEraDurationSqlIssues -Source $invalidEraDurationFixture).Count -ne 1) {
    Add-ValidationError 'Era-duration database contract helper failed its positive/negative self-test.'
}

$pairedPlatformFixture = [System.Xml.XmlDocument]::new()
$pairedPlatformFixture.LoadXml(@'
<Mod>
  <FrontEndActions />
  <InGameActions />
  <Files>
    <File>Assets/Platforms/MacOS/example.blp</File>
    <File>Assets/Platforms/Windows/example.blp</File>
  </Files>
</Mod>
'@)
$missingPlatformFixture = [System.Xml.XmlDocument]$pairedPlatformFixture.Clone()
[void]$missingPlatformFixture.SelectSingleNode(
    '/Mod/Files/File[contains(., "Windows")]'
).ParentNode.RemoveChild(
    $missingPlatformFixture.SelectSingleNode('/Mod/Files/File[contains(., "Windows")]')
)
$directPlatformActionFixture = [System.Xml.XmlDocument]$pairedPlatformFixture.Clone()
$directPlatformActionFixture.SelectSingleNode('/Mod/InGameActions').InnerXml = @'
<ImportFiles id="Fixture"><File>Assets/Platforms/Windows/example.blp</File></ImportFiles>
'@
if (@(Get-ZylPlatformAssetPairIssues -ModInfo $pairedPlatformFixture).Count -ne 0 -or
        @(Get-ZylPlatformAssetPairIssues -ModInfo $missingPlatformFixture).Count -ne 1 -or
        @(Get-ZylPlatformAssetPairIssues -ModInfo $directPlatformActionFixture).Count -ne 1 -or
        @(Get-ZylPlatformLiteralReferenceIssues `
            -Source 'Asset/Platforms/{PLATFORM}/example.blp' `
            -Label 'Fixture').Count -ne 0 -or
        @(Get-ZylPlatformLiteralReferenceIssues `
            -Source 'Asset/Platforms/Windows/example.blp' `
            -Label 'Fixture').Count -ne 1 -or
        -not (Test-ZylReleasePathIncluded -RelativePath 'common/file.xml' -Profile 'windows') -or
        -not (Test-ZylReleasePathIncluded -RelativePath 'Platforms/Windows/a.blp' -Profile 'windows') -or
        (Test-ZylReleasePathIncluded -RelativePath 'Platforms/MacOS/a.blp' -Profile 'windows') -or
        -not (Test-ZylReleasePathIncluded -RelativePath 'Nested/Platforms/MacOS/a.blp' -Profile 'macos') -or
        -not (Test-ZylReleasePathIncluded -RelativePath 'Platforms/MacOS/a.blp' -Profile 'universal')) {
    Add-ValidationError 'Release platform helper failed its positive/negative self-test.'
}

$duplicateContentFixture = Get-ZylDuplicateContentSummary -Entries @(
    [pscustomobject]@{ path = 'b.dds'; bytes = 10; sha256 = 'same' },
    [pscustomobject]@{ path = 'a.dds'; bytes = 10; sha256 = 'same' },
    [pscustomobject]@{ path = 'c.dds'; bytes = 20; sha256 = 'unique' }
)
$uniqueContentFixture = Get-ZylDuplicateContentSummary -Entries @(
    [pscustomobject]@{ path = 'a.dds'; bytes = 10; sha256 = 'a' },
    [pscustomobject]@{ path = 'b.dds'; bytes = 10; sha256 = 'b' }
)
if ($duplicateContentFixture.groupCount -ne 1 -or
        $duplicateContentFixture.fileCount -ne 2 -or
        $duplicateContentFixture.extraCopyCount -ne 1 -or
        $duplicateContentFixture.theoreticalReclaimableBytes -ne 10 -or
        ($duplicateContentFixture.groups[0].paths -join '|') -ne 'a.dds|b.dds' -or
        $uniqueContentFixture.groupCount -ne 0) {
    Add-ValidationError 'Release duplicate-content helper failed its positive/negative self-test.'
}
if (-not (Test-ZylReleaseSizeWithinBudget -TotalBytes 10 -BudgetBytes 10) -or
        (Test-ZylReleaseSizeWithinBudget -TotalBytes 11 -BudgetBytes 10) -or
        (Test-ZylReleaseSizeWithinBudget -TotalBytes 0 -BudgetBytes 0)) {
    Add-ValidationError 'Release size-budget helper failed its boundary self-test.'
}

if (-not (Test-Path -LiteralPath $modInfoPath)) {
    throw "ModInfo not found: $modInfoPath"
}

$actionGraphBaselinePath = Join-Path $modRoot 'manifest\baseline-1.3.0-action-graph.json'
foreach ($manifestIssue in @(Get-ZylManifestBaselineIssues `
        -ModInfoPath $modInfoPath `
        -BaselinePath $actionGraphBaselinePath)) {
    Add-ValidationError $manifestIssue
}

$projectFiles = @(Get-ZylProjectFiles -ProjectRoot $modRoot)
foreach ($platformDefinitionIssue in @(Get-ZylPlatformAssetDefinitionIssues `
        -ProjectFiles $projectFiles `
        -ProjectRoot $modRoot)) {
    Add-ValidationError $platformDefinitionIssue
}

# Build and maintenance scripts must never consume Steam Workshop caches.
# Upstream content is copied into this repository deliberately; once embedded,
# the repository and its ModInfo are the only allowed build inputs.
$assemblerPath = Join-Path $modRoot 'tools\assemble_modinfo.ps1'
$releaseBuilderPath = Join-Path $modRoot 'tools\build_workshop_release.ps1'
foreach ($projectBoundaryIssue in @(Get-ZylProjectBoundaryIssues `
        -ProjectRoot $modRoot `
        -ProjectFiles $projectFiles `
        -ValidatorPath $PSCommandPath `
        -AssemblerPath $assemblerPath)) {
    Add-ValidationError $projectBoundaryIssue
}
if (-not (Test-Path -LiteralPath $releaseBuilderPath -PathType Leaf)) {
    Add-ValidationError 'The deterministic release builder is missing.'
}
else {
    $releaseBuilderSource = Get-Content -LiteralPath $releaseBuilderPath -Raw
    foreach ($releaseBuilderIssue in @(Get-ZylReleaseBuilderIssues `
            -Source $releaseBuilderSource)) {
        Add-ValidationError $releaseBuilderIssue
    }
}

# Validate every runtime XML-bearing artifact, including the BBM art
# dependency. Reference snapshots live outside the mod root.
$xmlFiles = @($projectFiles | Where-Object {
	$_.Extension -in @('.xml', '.modinfo', '.dep')
})
foreach ($xmlIssue in @(Get-ZylXmlArtifactIssues -XmlFiles $xmlFiles)) {
    Add-ValidationError $xmlIssue
}

$modInfo = Load-XmlDocument $modInfoPath
foreach ($platformAssetIssue in @(Get-ZylPlatformAssetPairIssues -ModInfo $modInfo)) {
    Add-ValidationError $platformAssetIssue
}
$criteriaSourceDirectory = Join-Path $modRoot 'manifest\criteria'
$frontEndActionsSourceDirectory = Join-Path $modRoot 'manifest\actions\frontend'
$inGameActionsSourceDirectory = Join-Path $modRoot 'manifest\actions\ingame'
$filesSourceDirectory = Join-Path $modRoot 'manifest\files'
foreach ($manifestIssue in @(Get-ZylGeneratedManifestSourceIssues `
        -ModInfo $modInfo `
        -CriteriaSourceDirectory $criteriaSourceDirectory `
        -FrontEndActionsSourceDirectory $frontEndActionsSourceDirectory `
        -InGameActionsSourceDirectory $inGameActionsSourceDirectory `
        -FilesSourceDirectory $filesSourceDirectory)) {
    Add-ValidationError $manifestIssue
}
if ($modInfo.DocumentElement.GetAttribute('id') -ne $expectedModId) {
    Add-ValidationError "Unexpected Mod ID: $($modInfo.DocumentElement.GetAttribute('id'))"
}
if ($modInfo.DocumentElement.GetAttribute('version') -ne $expectedModInfoVersion -or
		$modInfo.SelectSingleNode('/Mod/Properties/Version').InnerText -ne $expectedModInfoVersion -or
		$modInfo.SelectSingleNode('/Mod/Properties/ToolboxVersion').InnerText -ne $expectedSemanticVersion) {
	Add-ValidationError "Package version metadata must match tools/project.json ($expectedSemanticVersion / ModInfo $expectedModInfoVersion)."
}
if ($modInfo.SelectSingleNode('/Mod/Properties/Name').InnerText -ne 'LOC_ZYLPVPMOD_TITLE') {
    Add-ValidationError 'The ModInfo title is not the ZYLPVPMOD localization key.'
}
$workshopTitleEnglish = $modInfo.SelectSingleNode("/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_TITLE']/en_US")
$workshopTitleChinese = $modInfo.SelectSingleNode("/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_TITLE']/zh_Hans_CN")
$expectedPackageTitle = "$expectedPackageName $expectedSemanticVersion"
if ($null -eq $workshopTitleEnglish -or $workshopTitleEnglish.InnerText -ne $expectedPackageTitle -or
		$null -eq $workshopTitleChinese -or $workshopTitleChinese.InnerText -ne $expectedPackageTitle) {
	Add-ValidationError "The localized ModInfo title must be $expectedPackageTitle."
}
$multiplayerHelperPath = Join-Path $modRoot 'data\MP_helper.lua'
if (-not (Test-Path -LiteralPath $multiplayerHelperPath) -or
		-not (Get-Content -LiteralPath $multiplayerHelperPath -Raw).Contains("local g_version = `"$expectedPackageName v$expectedSemanticVersion`"")) {
	Add-ValidationError "The multiplayer version handshake must identify $expectedPackageName v$expectedSemanticVersion."
}
else {
	$multiplayerHelperSource = Get-Content -LiteralPath $multiplayerHelperPath -Raw
	foreach ($requiredHelperFragment in @(
		'if Drop_Data[playerID] ~= nil then',
		'local savedMovesByUnitID = {}',
		'UnitManager.ChangeMovesRemaining(unit, savedMoves - currentMoves)',
		'local function DebugLog(...)'
	)) {
		if (-not $multiplayerHelperSource.Contains($requiredHelperFragment)) {
			Add-ValidationError "The multiplayer helper is missing its deterministic drop/reconnect guard: $requiredHelperFragment"
		}
	}
	foreach ($forbiddenHelperFragment in @(
		'Game.GetRandNum',
		'GameEvents.OnGameTurnStarted.Add(OnGameTurnStarted)',
		'UnitManager.ChangeMovesRemaining(unit, -99)',
		'function Tablelength(',
		'function FindTableIndex('
	)) {
		if ($multiplayerHelperSource.Contains($forbiddenHelperFragment)) {
			Add-ValidationError "The multiplayer helper restored a random-stream, non-idempotent or dead-code path: $forbiddenHelperFragment"
		}
	}
}

# The Industries/Corporations balance values, mode-gated load order and final
# Simplified Chinese text form one vertical contract.
$monopoliesValidationParameters = @{
    ProjectRoot = $modRoot
    ModInfo = $modInfo
}
$monopoliesIssues = @(
    Get-ZylMonopoliesContractIssues @monopoliesValidationParameters
)
foreach ($issue in $monopoliesIssues) {
    Add-ValidationError $issue
}

# Prove that a high-risk Industry percentage drift is detected in memory.
$monopoliesBalancePath = Join-Path $modRoot 'sql\ZYL_MonopoliesBalance.sql'
if (Test-Path -LiteralPath $monopoliesBalancePath -PathType Leaf) {
    $monopoliesBalanceSource = Get-Content -LiteralPath $monopoliesBalancePath -Raw
    $monopoliesBalanceDriftSource = $monopoliesBalanceSource.Replace(
        "SET Value = '10' WHERE ModifierId = 'INDUSTRY_CITY_GROWTH'",
        "SET Value = '11' WHERE ModifierId = 'INDUSTRY_CITY_GROWTH'"
    )
    $monopoliesDriftIssues = @(
        Get-ZylMonopoliesContractIssues @monopoliesValidationParameters `
            -BalanceSourceOverride $monopoliesBalanceDriftSource
    )
    $expectedMonopoliesDriftIssue =
        'Industries/Corporations balance value is wrong for INDUSTRY_CITY_GROWTH: expected 10, found 11'
    if ($monopoliesBalanceDriftSource -eq $monopoliesBalanceSource -or
            $monopoliesDriftIssues -notcontains $expectedMonopoliesDriftIssue) {
        Add-ValidationError 'Industries/Corporations validation self-test did not reject a balance drift.'
    }
}

# BBG 7.4.6 localization synchronization and package-wide English-to-Chinese
# coverage are owned by one read-only localization contract.
$bbgLocalizationValidationParameters = @{
    ProjectRoot = $modRoot
    XmlFiles = $xmlFiles
}
$bbgLocalizationIssues = @(
    Get-ZylBbgLocalizationContractIssues @bbgLocalizationValidationParameters
)
foreach ($issue in $bbgLocalizationIssues) {
    Add-ValidationError $issue
}

# Prove that a critical translated gameplay fragment cannot silently regress.
$bbgChineseOverlayPath = Join-Path $modRoot 'lang\ZYL_BBG74_Chinese_Text.xml'
if (Test-Path -LiteralPath $bbgChineseOverlayPath -PathType Leaf) {
    $bbgChineseOverlayDrift = Load-XmlDocument $bbgChineseOverlayPath
    $bbgChineseOverlayDriftNode = $bbgChineseOverlayDrift.SelectSingleNode(
        "/GameData/LocalizedText/*[@Tag='LOC_ABILITY_BYZANTIUM_COMBAT_UNITS_DESCRIPTION' and @Language='zh_Hans_CN']/Text"
    )
    if ($null -eq $bbgChineseOverlayDriftNode) {
        Add-ValidationError 'BBG localization validation self-test fixture is missing its critical row.'
    }
    else {
        $bbgChineseOverlayOriginalText = $bbgChineseOverlayDriftNode.InnerText
        $bbgChineseOverlayDriftNode.InnerText =
            $bbgChineseOverlayOriginalText.Replace('宗教压力', '宗教影响_DRIFT')
        $bbgLocalizationDriftIssues = @(
            Get-ZylBbgLocalizationContractIssues @bbgLocalizationValidationParameters `
                -ChineseOverlayOverride $bbgChineseOverlayDrift
        )
        $expectedBbgLocalizationDriftIssue =
            'Critical BBG Chinese correction LOC_ABILITY_BYZANTIUM_COMBAT_UNITS_DESCRIPTION is missing: 宗教压力'
        if ($bbgChineseOverlayDriftNode.InnerText -eq $bbgChineseOverlayOriginalText -or
                $bbgLocalizationDriftIssues -notcontains $expectedBbgLocalizationDriftIssue) {
            Add-ValidationError 'BBG localization validation self-test did not reject a critical translation drift.'
        }
    }
}

# Build a case-insensitive runtime inventory for Windows/macOS portability and
# reverse-audit every repository file against published, dormant or source-only
# ownership. Action and Criteria identity/reference maps are shared below.
$dormantFileListPath = Join-Path $modRoot 'manifest\dormant-files.txt'
$assetInventory = Get-ZylAssetInventory `
    -ModInfo $modInfo `
    -ProjectRoot $modRoot `
    -ProjectFiles $projectFiles `
    -ModInfoPath $modInfoPath `
    -DormantFileListPath $dormantFileListPath
foreach ($assetIssue in @($assetInventory.Issues)) {
    Add-ValidationError $assetIssue
}
$listedFiles = @($assetInventory.ListedFiles)
$listedFileMap = $assetInventory.ListedFileMap
$intentionallyUnlistedFiles = @($assetInventory.IntentionallyUnlistedFiles)
$sourceOnlyFileCount = $assetInventory.SourceOnlyFileCount
$actionNodes = @($assetInventory.ActionNodes)
$actionIdMap = $assetInventory.ActionIdMap
$criteriaMap = $assetInventory.CriteriaMap
$actionReferenceMap = $assetInventory.ActionReferenceMap

# ZYLPVPMOD's final gameplay override layer must remain later than every
# embedded BBG/BBM action; otherwise an upstream update can silently restore
# the values this integration intentionally replaces.
$requiredOverrideActions = @{
    'zyl_gameplayoverrides' = '260000000'
    'zyl_governoroverrides' = '260000010'
    'zyl_gameplayoverridestext' = '260000020'
    'zyl_gameplayoverridesfrontendtext' = '260000020'
}
foreach ($entry in $requiredOverrideActions.GetEnumerator()) {
    if (-not $actionIdMap.ContainsKey($entry.Key)) {
        Add-ValidationError "Required gameplay override action is missing: $($entry.Key)"
        continue
    }
    $loadOrderNode = $actionIdMap[$entry.Key].SelectSingleNode('./Properties/LoadOrder')
    if ($null -eq $loadOrderNode -or $loadOrderNode.InnerText.Trim() -ne $entry.Value) {
        Add-ValidationError "Gameplay override action $($entry.Key) must load at $($entry.Value)."
    }
}

$requiredBbgChineseActions = @{
    'zyl_bbg74_chinesetextfrontend' = @('FrontEndActions', 'lang/ZYL_BBG74_Chinese_Text.xml')
    'zyl_bbg74_chinesetext' = @('InGameActions', 'lang/ZYL_BBG74_Chinese_Text.xml')
}
foreach ($entry in $requiredBbgChineseActions.GetEnumerator()) {
    $action = $actionIdMap[$entry.Key]
    if ($null -eq $action -or
            $action.ParentNode.LocalName -ne $entry.Value[0] -or
            $action.LocalName -ne 'UpdateText' -or
            $null -eq $action.SelectSingleNode("./File[.='$($entry.Value[1])']") -or
            $action.SelectSingleNode('./Properties/LoadOrder').InnerText.Trim() -ne '259999990') {
        Add-ValidationError "BBG 7.4.6 Simplified Chinese overlay action is missing or malformed: $($entry.Key)"
    }
}
if (-not $listedFileMap.ContainsKey((Normalize-RelativePath 'lang/ZYL_BBG74_Chinese_Text.xml'))) {
    Add-ValidationError 'BBG 7.4.6 Simplified Chinese overlay is absent from the ModInfo <Files> manifest.'
}

$disasterRangeAction = $actionIdMap['zyl_disablenaturaldisastersoption']
if ($null -eq $disasterRangeAction -or
        $disasterRangeAction.LocalName -ne 'UpdateDatabase' -or
        $null -eq $disasterRangeAction.SelectSingleNode("./File[.='configuration/ZYL_DisasterRange.sql']")) {
    Add-ValidationError 'The TPT no-natural-disasters lobby option is not loaded.'
}
$disasterRangePath = Join-Path $modRoot 'configuration\ZYL_DisasterRange.sql'
if (Test-Path -LiteralPath $disasterRangePath) {
    $disasterRangeSql = Get-Content -LiteralPath $disasterRangePath -Raw
    if (-not $disasterRangeSql.Contains("WHERE Domain = 'RealismRange'") -or
            -not $disasterRangeSql.Contains('MinimumValue = -1')) {
        Add-ValidationError 'The disaster-intensity range no longer exposes the -1/disabled value.'
    }
}

$bbgBasePath = Join-Path $modRoot 'Components\BBG\sql\Base\base.sql'
if (Test-Path -LiteralPath $bbgBasePath) {
    $activeBbgTechMultiplier = @(Get-Content -LiteralPath $bbgBasePath | Where-Object {
        $_ -notmatch '^\s*--' -and $_ -match 'Cost\s*=\s*Cost\s*\*\s*1\.05'
    })
    if ($activeBbgTechMultiplier.Count -gt 0) {
        Add-ValidationError 'BBG Medieval-and-later technology +5% base-cost multiplier is active.'
    }
}

# Improvement Housing is displayed as Housing / TilesRequired.  BBG's source
# comment calls the Colossal Head value +1, but the shipped SQL deliberately
# leaves the final database at 1 / 2, so the effective tooltip value is +0.5.
$bbgCityStatesPath = Join-Path $modRoot 'Components\BBG\sql\Base\CityStates.sql'
if (-not (Test-Path -LiteralPath $bbgCityStatesPath)) {
    Add-ValidationError 'BBG city-state gameplay SQL is missing.'
}
else {
    $bbgCityStatesSql = Get-Content -LiteralPath $bbgCityStatesPath -Raw
    if ($bbgCityStatesSql -notmatch "(?s)UPDATE\s+Improvements\s+SET\s+Housing\s*=\s*1\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_COLOSSAL_HEAD'.*?UPDATE\s+Improvements\s+SET\s+TilesRequired\s*=\s*2\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_COLOSSAL_HEAD'") {
        Add-ValidationError 'Colossal Head Housing must remain 1 / 2 (+0.5 per improvement) to match the final Chinese text.'
    }
}

$bbgMaliPath = Join-Path $modRoot 'Components\BBG\sql\XP2\Mali.sql'
if (-not (Test-Path -LiteralPath $bbgMaliPath)) {
	Add-ValidationError 'BBG Mali gameplay SQL is missing.'
}
else {
	$bbgMaliSql = Get-Content -LiteralPath $bbgMaliPath -Raw
	foreach ($removedMaliToken in @(
		'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION',
		'BBG_MALI_FAITH_NEXT_DESERT',
		'BBG_MALI_FAITH_NEXT_DESERT_HILLS',
		'BBG_MALI_FAITH_NEXT_CAPITAL',
		'TRAIT_BBG_MANSA_FREE_TRADER_BANKS',
		'ZYL_MALI_FAITH_DESERT',
		'ZYL_MALI_FAITH_DESERT_HILLS',
		'BBG_MALI_GOLD_DESERT_MINES',
		'BBG_MALI_GOLD_DESERT_HILLS_MINES',
		'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION',
		'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION_BUILDING'
	)) {
		if ($bbgMaliSql.Contains($removedMaliToken)) {
			Add-ValidationError "Mali source still defines a removed modifier: $removedMaliToken"
		}
	}
	if ($bbgMaliSql -match "(?is)DELETE\s+FROM\s+(?:TraitModifiers|Modifiers|ModifierArguments)\b[^;]*GOLDEN_AGE_TRADE_ROUTE[^;]*;") {
		Add-ValidationError 'Mansa Musa source still deletes the original Golden Age Trade Route modifier.'
	}
	if (-not $bbgMaliSql.Contains('GOLDEN_AGE_TRADE_ROUTE')) {
		Add-ValidationError 'Mansa Musa source does not document preservation of the original Golden Age Trade Route modifier.'
	}
	foreach ($maliYieldBinding in @(
		@('ZYL_MALI_PRODUCTION_DESERT', 'YIELD_PRODUCTION', 'BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET'),
		@('ZYL_MALI_PRODUCTION_DESERT_HILLS', 'YIELD_PRODUCTION', 'BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET')
	)) {
		$modifierId = [regex]::Escape($maliYieldBinding[0])
		$yieldType = [regex]::Escape($maliYieldBinding[1])
		$requirementSetId = [regex]::Escape($maliYieldBinding[2])
		if ($bbgMaliSql -notmatch "(?s)\('$modifierId'\s*,\s*'MODIFIER_PLAYER_ADJUST_PLOT_YIELD'\s*,\s*'$requirementSetId'\).*?\('$modifierId'\s*,\s*'YieldType'\s*,\s*'$yieldType'\).*?\('$modifierId'\s*,\s*'Amount'\s*,\s*1\)") {
			Add-ValidationError "Mali featureless Desert yield modifier is incomplete: $($maliYieldBinding[0])"
		}
		if ($bbgMaliSql -notmatch "\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'$modifierId'\)") {
			Add-ValidationError "Mali featureless Desert yield modifier is not attached to the civilization trait: $($maliYieldBinding[0])"
		}
	}
	if ($bbgMaliSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s+IN\s*\(\s*'SUGUBA_CHEAPER_BUILDING_PURCHASE'\s*,\s*'SUGUBA_CHEAPER_DISTRICT_PURCHASE'\s*\)") {
		Add-ValidationError 'Suguba building/district purchase discount is not locked to 10%.'
	}
	if ($bbgMaliSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s*=\s*'SUGUBA_CHEAPER_UNIT_PURCHASE'") {
		Add-ValidationError 'Suguba unit purchase discount is not locked to 10%.'
	}
}

$bbgKhmerPath = Join-Path $modRoot 'Components\BBG\sql\DLC_Indonesia_Khmer\Khmer.sql'
if (-not (Test-Path -LiteralPath $bbgKhmerPath)) {
	Add-ValidationError 'BBG Khmer gameplay SQL is missing.'
}
else {
	$bbgKhmerSql = Get-Content -LiteralPath $bbgKhmerPath -Raw
	if ($bbgKhmerSql -notmatch "(?s)DELETE\s+from\s+TraitModifiers\s+where\s+TraitType\s*=\s*'TRAIT_LEADER_MONASTERIES_KING'\s+and\s+ModifierId\s*=\s*'TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY'") {
		Add-ValidationError "Khmer source does not remove the old Jayavarman-only river Holy Site Faith modifier."
	}
	if ($bbgKhmerSql -notmatch "(?s)\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'Amount'\s*,\s*1\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_HOLY_SITE'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'YieldType'\s*,\s*'YIELD_FAITH'\).*?\('TRAIT_CIVILIZATION_KHMER_BARAYS'\s*,\s*'ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\)") {
		Add-ValidationError 'Khmer source does not attach the standard +1 river Holy Site Faith bonus to the civilization trait.'
	}
	if ($bbgKhmerSql -match "INSERT\s+(?:OR\s+IGNORE\s+)?INTO\s+TraitModifiers[^;]*TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY") {
		Add-ValidationError 'Khmer source still grants the river Holy Site Faith modifier to Jayavarman.'
	}
}

$bbgCreePath = Join-Path $modRoot 'Components\BBG\sql\XP1\Cree.sql'
if (-not (Test-Path -LiteralPath $bbgCreePath)) {
	Add-ValidationError 'BBG Cree gameplay SQL is missing.'
}
else {
	$bbgCreeSql = Get-Content -LiteralPath $bbgCreePath -Raw
	if ($bbgCreeSql -notmatch "(?s)UPDATE\s+ModifierArguments\s+SET\s+Value\s*=\s*1\s+WHERE\s+ModifierId\s+IN\s*\(\s*'TRAIT_TRADE_FOOD_FROM_CAMPS'\s*,\s*'TRAIT_TRADE_FOOD_FROM_PASTURES'\s*\)\s+AND\s+Name\s*=\s*'Amount'") {
		Add-ValidationError 'Cree source does not restore outgoing Camp/Pasture Trade Route Food to +1.'
	}
	if ($bbgCreeSql -match "(?s)UPDATE\s+Modifiers\s+SET(?:(?!;).)*SubjectStackLimit(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_CAMPS'(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_PASTURES'(?:(?!;).)*;") {
		Add-ValidationError 'Cree source incorrectly uses a modifier stack limit as an improvement-count cap.'
	}
}

$bbgGranColombiaPath = Join-Path $modRoot 'Components\BBG\sql\NFP\GranColombia.sql'
if (-not (Test-Path -LiteralPath $bbgGranColombiaPath)) {
	Add-ValidationError 'BBG Gran Colombia gameplay SQL is missing.'
}
else {
	$bbgGranColombiaSql = Get-Content -LiteralPath $bbgGranColombiaPath -Raw
	if ($bbgGranColombiaSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s+AND\s+ModifierId\s*=\s*'BBG_COLUMBIA_MOVEMENT_BONUS'.*?INSERT\s+OR\s+IGNORE\s+INTO\s+TraitModifiers\s*\(\s*TraitType\s*,\s*ModifierId\s*\)\s+VALUES\s*\(\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s*,\s*'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT'\s*\)") {
		Add-ValidationError 'Gran Colombia source does not restore the original all-unit movement trait attachment.'
	}
	if ($bbgGranColombiaSql -match "BBG_UTILS_PLAYER_HAS_CIVIC_POLITICAL_PHILOSOPHY_REQSET|BBG_REQUIREMENT_UNIT_IS_NAVAL_OR_LAND|BBG_COLUMBIA_MOVEMENT_BONUS_MODIFIER") {
		Add-ValidationError 'Gran Colombia source still defines the Political Philosophy military-only movement replacement.'
	}
	if ($bbgGranColombiaSql -notmatch "(?s)UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_PROMOTE_NO_FINISH_MOVES'") {
		Add-ValidationError 'Gran Colombia no longer preserves the Cavalry/Air/Spy promote-and-move restriction.'
	}
}

$bbgGaulPath = Join-Path $modRoot 'Components\BBG\sql\NFP\Gaul.sql'
if (-not (Test-Path -LiteralPath $bbgGaulPath)) {
	Add-ValidationError 'BBG Gaul gameplay SQL is missing.'
}
else {
	$bbgGaulSql = Get-Content -LiteralPath $bbgGaulPath -Raw
	if ($bbgGaulSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SUK_GALLIC_WAR'.*?ModifierId\s*=\s*'GAUL_MINE_CULTURE'.*?INSERT\s+OR\s+IGNORE\s+INTO\s+TraitModifiers\s*\(\s*TraitType\s*,\s*ModifierId\s*\)\s+VALUES\s*\(\s*'TRAIT_CIVILIZATION_GAUL'\s*,\s*'GAUL_MINE_CULTURE'\s*\).*?UPDATE\s+Modifiers\s+SET\s+OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING'\s*,\s*SubjectRequirementSetId\s*=\s*'PLOT_HAS_MINE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'GAUL_MINE_CULTURE'") {
		Add-ValidationError 'Gaul source does not move GAUL_MINE_CULTURE to the civilization trait with the Bronze Working/Mine requirements.'
	}
	if ($bbgGaulSql -match "ZYL_GAUL_MINE_CULTURE_CRAFTSMANSHIP|BBG_UTILS_PLAYER_HAS_CIVIC_CRAFTSMANSHIP_REQSET") {
		Add-ValidationError 'Gaul source still contains the superseded standalone Craftsmanship Mine Culture modifier.'
	}
}

$bbgVercingetorixPath = Join-Path $modRoot 'Components\BBG\sql\BBG_Expanded\Vercingetorix.sql'
if (-not (Test-Path -LiteralPath $bbgVercingetorixPath)) {
	Add-ValidationError 'BBG Vercingetorix gameplay SQL is missing.'
}
else {
	$bbgVercingetorixSql = Get-Content -LiteralPath $bbgVercingetorixPath -Raw
	if ($bbgVercingetorixSql -match "INSERT\s+INTO\s+TraitModifiers[^;]*GAUL_MINE_CULTURE|OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING'[^;]*GAUL_MINE_CULTURE") {
		Add-ValidationError 'Vercingetorix source still grants GAUL_MINE_CULTURE as a separate leader ability.'
	}
}

$bbgRomePath = Join-Path $modRoot 'Components\BBG\sql\Base\Rome.sql'
if (-not (Test-Path -LiteralPath $bbgRomePath)) {
	Add-ValidationError 'BBG Rome gameplay SQL is missing.'
}
else {
	$bbgRomeSql = Get-Content -LiteralPath $bbgRomePath -Raw
	if ($bbgRomeSql -notmatch "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING'\s*;") {
		Add-ValidationError 'Trajan free City Center building is not unlocked by Foreign Trade in the Rome source SQL.'
	}
	if ($bbgRomeSql -match "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET'") {
		Add-ValidationError "Rome source SQL still unlocks Trajan's free building at Early Empire."
	}
}

foreach ($gaulTextSpec in @(
	@('Components\BBG\lang\english.xml', 'en_US', 'Bronze Working', '+1 [ICON_CULTURE] Culture'),
	@('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '铸铜术', '+1 [ICON_CULTURE] 文化'),
	@('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '铸铜术', '+1 [ICON_CULTURE] 文化'),
	@('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', 'Bronze Working', '+1 [ICON_CULTURE] Culture'),
	@('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '铸铜术', '+1 [ICON_CULTURE] 文化')
)) {
	$gaulTextPath = Join-Path $modRoot $gaulTextSpec[0]
	if (-not (Test-Path -LiteralPath $gaulTextPath)) {
		Add-ValidationError "Gaul localization file is missing: $($gaulTextSpec[0])"
		continue
	}
	$gaulTextXml = Load-XmlDocument $gaulTextPath
	$gaulTextNode = $gaulTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_CIVILIZATION_GAUL_DESCRIPTION' and @Language='$($gaulTextSpec[1])']/Text")
	if ($null -eq $gaulTextNode -or
		-not $gaulTextNode.InnerText.Contains($gaulTextSpec[2]) -or
		-not $gaulTextNode.InnerText.Contains($gaulTextSpec[3])) {
		Add-ValidationError "Gaul $($gaulTextSpec[1]) text does not describe the Bronze Working Mine +1 Culture bonus: $($gaulTextSpec[0])"
	}
}

foreach ($vercingetorixTextSpec in @(
	@('Components\BBG\lang\english.xml', 'en_US', 'Workshops grant'),
	@('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '工作坊'),
	@('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '工作坊'),
	@('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '工作坊'),
	@('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', 'Workshops grant')
)) {
	$vercingetorixTextPath = Join-Path $modRoot $vercingetorixTextSpec[0]
	if (-not (Test-Path -LiteralPath $vercingetorixTextPath)) {
		Add-ValidationError "Vercingetorix localization file is missing: $($vercingetorixTextSpec[0])"
		continue
	}
	$vercingetorixTextXml = Load-XmlDocument $vercingetorixTextPath
	foreach ($vercingetorixTag in @(
		'LOC_TRAIT_LEADER_SUK_GALLIC_WAR_DESCRIPTION',
		'LOC_TRAIT_LEADER_SUK_GALLIC_WAR_DESCRIPTION_DLC'
	)) {
		$vercingetorixTextNode = $vercingetorixTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$vercingetorixTag' and @Language='$($vercingetorixTextSpec[1])']/Text")
		if ($null -eq $vercingetorixTextNode -or -not $vercingetorixTextNode.InnerText.Contains($vercingetorixTextSpec[2])) {
			Add-ValidationError "Vercingetorix $($vercingetorixTextSpec[1]) text does not retain the Workshop Influence ability: $vercingetorixTag"
			continue
		}
		foreach ($removedFragment in @('Bronze Working', '铸铜术', 'mines', '矿山', '[ICON_CULTURE]')) {
			if ($vercingetorixTextNode.InnerText.Contains($removedFragment)) {
				Add-ValidationError "Vercingetorix $($vercingetorixTextSpec[1]) text still claims the transferred Mine Culture ability: $vercingetorixTag"
				break
			}
		}
	}
}

foreach ($trajanTextSpec in @(
	@('Components\BBG\lang\english.xml', 'en_US', 'Foreign Trade', 'Early Empire'),
	@('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '对外贸易', '帝国初期'),
	@('lang\ZYL_BBG74_Chinese_Text.xml', 'zh_Hans_CN', '对外贸易', '帝国初期'),
	@('lang\ZYL_GameplayOverrides_Text.xml', 'en_US', 'Foreign Trade', 'Early Empire'),
	@('lang\ZYL_GameplayOverrides_Text.xml', 'zh_Hans_CN', '对外贸易', '帝国初期')
)) {
	$trajanTextPath = Join-Path $modRoot $trajanTextSpec[0]
	if (-not (Test-Path -LiteralPath $trajanTextPath)) {
		Add-ValidationError "Trajan localization file is missing: $($trajanTextSpec[0])"
		continue
	}
	$trajanTextXml = Load-XmlDocument $trajanTextPath
	$trajanTextNode = $trajanTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='LOC_TRAIT_LEADER_TRAJANS_COLUMN_DESCRIPTION' and @Language='$($trajanTextSpec[1])']/Text")
	if ($null -eq $trajanTextNode -or -not $trajanTextNode.InnerText.Contains($trajanTextSpec[2])) {
		Add-ValidationError "Trajan $($trajanTextSpec[1]) text does not mention Foreign Trade: $($trajanTextSpec[0])"
		continue
	}
	if ($trajanTextNode.InnerText.Contains($trajanTextSpec[3])) {
		Add-ValidationError "Trajan $($trajanTextSpec[1]) text still claims Early Empire: $($trajanTextSpec[0])"
	}
}

foreach ($granColombiaTextSpec in @(
	@('Components\BBG\lang\english.xml', 'en_US', 'all units', 'military units', 'Political Philosophy'),
	@('Components\BBG\lang\chinese.xml', 'zh_Hans_CN', '所有单位+1', '所有军事单位', '政治哲学')
)) {
	$granColombiaTextPath = Join-Path $modRoot $granColombiaTextSpec[0]
	if (-not (Test-Path -LiteralPath $granColombiaTextPath)) {
		Add-ValidationError "Gran Colombia localization file is missing: $($granColombiaTextSpec[0])"
		continue
	}
	$granColombiaTextXml = Load-XmlDocument $granColombiaTextPath
	foreach ($granColombiaTag in @(
		'LOC_TRAIT_CIVILIZATION_EJERCITO_PATRIOTA_DESCRIPTION',
		'LOC_ABILITY_EJERCITO_PATRIOTA_EXTRA_MOVEMENT_DESCRIPTION'
	)) {
		$granColombiaTextNode = $granColombiaTextXml.SelectSingleNode("/GameData/LocalizedText/*[@Tag='$granColombiaTag' and @Language='$($granColombiaTextSpec[1])']/Text")
		if ($null -eq $granColombiaTextNode -or -not $granColombiaTextNode.InnerText.Contains($granColombiaTextSpec[2])) {
			Add-ValidationError "Gran Colombia $($granColombiaTextSpec[1]) text does not say all units receive the movement bonus: $granColombiaTag"
			continue
		}
		foreach ($removedFragment in @($granColombiaTextSpec[3], $granColombiaTextSpec[4])) {
			if ($granColombiaTextNode.InnerText.Contains($removedFragment)) {
				Add-ValidationError "Gran Colombia $($granColombiaTextSpec[1]) text still claims the removed military/Political Philosophy restriction: $granColombiaTag"
			}
		}
	}
}

$gameplayOverridePath = Join-Path $modRoot 'sql\ZYL_GameplayOverrides.sql'
$governorOverridePath = Join-Path $modRoot 'sql\ZYL_GovernorOverrides.sql'

$bbgMaoriPath = Join-Path $modRoot 'Components\BBG\sql\XP2\Maori.sql'
if (-not (Test-Path -LiteralPath $bbgMaoriPath)) {
	Add-ValidationError 'BBG Maori gameplay SQL is missing.'
}
else {
	$bbgMaoriSql = Get-Content -LiteralPath $bbgMaoriPath -Raw
	if ($bbgMaoriSql -notmatch "(?s)UPDATE\s+Leaders_XP2\s+SET\s+OceanStart\s*=\s*0\s+WHERE\s+LeaderType\s*=\s*'LEADER_KUPE'") {
		Add-ValidationError 'Kupe is no longer locked to BBG land-based starting behavior.'
	}
	if ($bbgMaoriSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasTerrains.*?'CIVILIZATION_MAORI'\s*,\s*'TERRAIN_COAST'\s*,\s*'1'") {
		Add-ValidationError 'Maori no longer have the T1 Coast bias required by Rich Mainland shore placement.'
	}
	foreach ($maoriFeature in @('FEATURE_FOREST', 'FEATURE_JUNGLE')) {
		if ($bbgMaoriSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasFeatures.*?'CIVILIZATION_MAORI'\s*,\s*'$maoriFeature'\s*,\s*4") {
			Add-ValidationError "Maori are missing their T4 $maoriFeature start bias."
		}
	}
}

$bbgGermanyPath = Join-Path $modRoot 'Components\BBG\sql\Base\Germany.sql'
if (-not (Test-Path -LiteralPath $bbgGermanyPath)) {
	Add-ValidationError 'BBG Germany gameplay SQL is missing.'
}
else {
	$bbgGermanySql = Get-Content -LiteralPath $bbgGermanyPath -Raw
	if ($bbgGermanySql -notmatch "(?s)UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_EXTRA_DISTRICT_EACH_CITY'") {
		Add-ValidationError 'Germany extra district capacity is not unlocked at Early Empire.'
	}
}

if (-not (Test-Path -LiteralPath $gameplayOverridePath)) {
    Add-ValidationError 'ZYL gameplay override SQL is missing.'
}
else {
    $gameplayOverrideSql = Get-Content -LiteralPath $gameplayOverridePath -Raw
    foreach ($requiredToken in @(
        'CITY_POPULATION_NO_WATER',
        'CITY_POPULATION_COAST',
        'BBG_MAYA_CAPITAL_HOUSING',
        'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING',
        'TECH_COST_PERCENT_CHANGE_BEFORE_GAME_ERA',
        "('TECH_CELESTIAL_NAVIGATION', 'TECH_SAILING')",
		'TRAIT_MAORI_EMBARKED_ABILITY',
		'BBG_PLOT_HAS_FOREST_EARLY_EMPIRE',
		'BBG_PLOT_HAS_JUNGLE_EARLY_EMPIRE',
		'TRAIT_MAORI_PREVENT_HARVEST',
        "WHERE TechnologyType = 'TECH_ARCHERY'",
        "WHERE TechnologyType = 'TECH_BRONZE_WORKING'",
        "WHERE TechnologyType = 'TECH_MILITARY_TACTICS'",
        "WHERE CivicType = 'CIVIC_GAMES_RECREATION'",
        "WHERE CivicType = 'CIVIC_RECORDED_HISTORY'",
        "WHERE CivicType = 'CIVIC_HUMANISM'",
        "WHERE CivicType = 'CIVIC_NAVAL_TRADITION'",
        "WHERE CivicType = 'CIVIC_FEUDALISM'",
        'ZYL_COMMERCIAL_HUB_LUXURY_GOLD',
		'BBG_MALI_FAITH_NEXT_DESERT',
		'BBG_MALI_FAITH_NEXT_DESERT_HILLS',
		'BBG_MALI_FAITH_NEXT_CAPITAL',
		'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION',
		'TRAIT_BBG_MANSA_FREE_TRADER_BANKS',
		'ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS',
		'ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS',
		'ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER',
		'ZYL_MALI_DESERT_CITY_CENTER_FAITH',
		'ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH',
		'TRAIT_MALI_MINES_PRODUCTION',
		'TRAIT_MALI_MINES_GOLD',
		'TRAIT_DESERT_CITY_CENTER_FAITH',
		'TRAIT_DESERT_HILLS_CITY_CENTER_FAITH',
		'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION',
		'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION_BUILDING',
		'BBG_COLUMBIA_MOVEMENT_BONUS',
		'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT',
		'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING',
		'BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET',
		'GAUL_MINE_CULTURE',
		'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING',
		'PLOT_HAS_MINE_REQUIREMENTS',
		'SUGUBA_CHEAPER_BUILDING_PURCHASE',
		'SUGUBA_CHEAPER_DISTRICT_PURCHASE',
		'SUGUBA_CHEAPER_UNIT_PURCHASE',
		'FEATURE_OASIS',
		'Feature_YieldChanges',
		'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER',
		'MISSION_NEWCONTINENT_FAITH',
		'MISSION_NEWCONTINENT_FOOD',
		'MISSION_NEWCONTINENT_PRODUCTION',
		'ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA',
		'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE',
		'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA',
		'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA',
		'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA',
		'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA',
		'BBG_SULEIMAN_COMBAT_BUFF',
		'OPPONENT_IS_IN_GOLDEN_AGE_REQUIREMENTS',
        'BBG_APPEAL_WYWH',
		'BBG_AUTOMATON_GDR_PROD',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX',
		'TRAIT_INCREASED_TUNDRA_HILLS_FAITH'
    )) {
        if (-not $gameplayOverrideSql.Contains($requiredToken)) {
            Add-ValidationError "Gameplay override SQL is missing invariant: $requiredToken"
        }
    }

    if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*'3'\s+WHERE\s+Name\s*=\s*'CITY_POPULATION_NO_WATER'") {
        Add-ValidationError 'No-water city base Housing is not locked to 3.'
    }
    if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*'4'\s+WHERE\s+Name\s*=\s*'CITY_POPULATION_COAST'") {
        Add-ValidationError 'Coast-only city base Housing is not locked to 4.'
    }
    if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TechnologyPrereqs\s+WHERE\s+Technology\s*=\s*'TECH_CELESTIAL_NAVIGATION'") {
        Add-ValidationError 'Celestial Navigation prerequisite cleanup is missing.'
    }
    if ($gameplayOverrideSql -notmatch "(?s)INSERT\s+OR\s+IGNORE\s+INTO\s+TechnologyPrereqs\s*\(\s*Technology\s*,\s*PrereqTech\s*\)\s*VALUES\s*\(\s*'TECH_CELESTIAL_NAVIGATION'\s*,\s*'TECH_SAILING'\s*\)") {
        Add-ValidationError 'Celestial Navigation is not directly unlocked by Sailing.'
    }
    if ($gameplayOverrideSql -match "(?s)\(\s*'TECH_CELESTIAL_NAVIGATION'\s*,\s*'TECH_ASTROLOGY'\s*\)") {
        Add-ValidationError 'Celestial Navigation still has an Astrology prerequisite.'
    }
    if ($gameplayOverrideSql -notmatch "(?s)SET\s+ModifierType\s*=\s*'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING'\s+WHERE\s+ModifierId\s*=\s*'BBG_MAYA_CAPITAL_HOUSING'") {
        Add-ValidationError 'Maya Housing modifier is not scoped to all cities.'
    }
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_SAILING'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_MAORI_EMBARKED_ABILITY'") {
		Add-ValidationError 'Final Maori embarked-unit +2 Movement bonus is not unlocked at Sailing.'
	}
	$maoriProductionBindings = @(
		@('BBG_PLOT_HAS_FOREST_EARLY_EMPIRE', 'TRAIT_MAORI_PRODUCTION_WOODS'),
		@('BBG_PLOT_HAS_JUNGLE_EARLY_EMPIRE', 'TRAIT_MAORI_PRODUCTION_RAINFOREST')
	)
	foreach ($binding in $maoriProductionBindings) {
		$requirementSetId = [regex]::Escape($binding[0])
		$modifierId = [regex]::Escape($binding[1])
		if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'$requirementSetId'\s+WHERE\s+ModifierId\s*=\s*'$modifierId'") {
			Add-ValidationError "Maori +1 Production modifier is not unlocked at Early Empire: $($binding[1])"
		}
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_MAORI_MANA'\s+AND\s+ModifierId\s*=\s*'TRAIT_MAORI_PREVENT_HARVEST'") {
		Add-ValidationError 'Final Maori override does not remove the resource-harvesting restriction.'
	}
    if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_MALI_GOLD_DESERT'.*?'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION'.*?'BBG_MALI_FAITH_NEXT_DESERT'.*?'BBG_MALI_FAITH_NEXT_DESERT_HILLS'.*?'BBG_MALI_FAITH_NEXT_CAPITAL'") {
		Add-ValidationError 'Final Mali override does not remove the Production penalty and Foreign Trade city Faith package.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SAHEL_MERCHANTS'.*?ModifierId\s*=\s*'TRAIT_BBG_MANSA_FREE_TRADER_BANKS'") {
		Add-ValidationError 'Final Mansa Musa override does not remove the Banking Trade Route modifier.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_MALI_GOLD_DESERT'.*?'ZYL_MALI_FAITH_DESERT'.*?'ZYL_MALI_FAITH_DESERT_HILLS'.*?'BBG_MALI_GOLD_DESERT_MINES'.*?'BBG_MALI_GOLD_DESERT_HILLS_MINES'") {
		Add-ValidationError 'Final Mali override does not detach the superseded Desert Faith and Desert-only Mine modifiers.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SAHEL_MERCHANTS'.*?'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION'.*?'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION_BUILDING'") {
		Add-ValidationError 'Final Mansa Musa override does not remove both Holy Site Production modifiers.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s+AND\s+ModifierId\s*=\s*'BBG_COLUMBIA_MOVEMENT_BONUS'.*?INSERT\s+OR\s+IGNORE\s+INTO\s+TraitModifiers\s*\(\s*TraitType\s*,\s*ModifierId\s*\)\s+VALUES\s*\(\s*'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'\s*,\s*'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT'\s*\)") {
		Add-ValidationError 'Final Gran Colombia override does not restore the original all-unit movement trait attachment.'
	}
	if ($gameplayOverrideSql -notmatch "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING'\s*;") {
		Add-ValidationError 'Final Trajan override does not unlock the free City Center building at Foreign Trade.'
	}
	if ($gameplayOverrideSql -match "(?m)^\s*UPDATE\s+Modifiers\s+SET\s+SubjectRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_CIVIC_EARLY_EMPIRE_REQSET'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING'") {
		Add-ValidationError 'Final Trajan override still unlocks the free City Center building at Early Empire.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_SUK_GALLIC_WAR'\s+AND\s+ModifierId\s*=\s*'GAUL_MINE_CULTURE'") {
		Add-ValidationError 'Final Gaul override does not detach GAUL_MINE_CULTURE from Vercingetorix.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)UPDATE\s+Modifiers\s+SET\s+ModifierType\s*=\s*'MODIFIER_PLAYER_ADJUST_PLOT_YIELD'\s*,\s*OwnerRequirementSetId\s*=\s*'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING'\s*,\s*SubjectRequirementSetId\s*=\s*'PLOT_HAS_MINE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'GAUL_MINE_CULTURE'") {
		Add-ValidationError 'Final Gaul override does not lock GAUL_MINE_CULTURE to Bronze Working and Mine plots.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)\('GAUL_MINE_CULTURE'\s*,\s*'YieldType'\s*,\s*'YIELD_CULTURE'\).*?\('GAUL_MINE_CULTURE'\s*,\s*'Amount'\s*,\s*1\).*?\('TRAIT_CIVILIZATION_GAUL'\s*,\s*'GAUL_MINE_CULTURE'\)") {
		Add-ValidationError 'Final Gaul override does not lock the +1 Culture argument and civilization-trait attachment.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+TraitModifiers\s+WHERE\s+TraitType\s*=\s*'TRAIT_LEADER_MONASTERIES_KING'.*?ModifierId\s*=\s*'TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY'.*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'Amount'\s*,\s*1\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_HOLY_SITE'\).*?\('ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\s*,\s*'YieldType'\s*,\s*'YIELD_FAITH'\).*?\('TRAIT_CIVILIZATION_KHMER_BARAYS'\s*,\s*'ZYL_KHMER_HOLY_SITE_RIVER_FAITH'\)") {
		Add-ValidationError 'Final Khmer override does not provide the standard +1 river Holy Site Faith bonus on the civilization trait.'
	}
	if ($gameplayOverrideSql -match "(?s)\('TRAIT_LEADER_MONASTERIES_KING'\s*,\s*'TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY'\)") {
		Add-ValidationError 'Final Khmer override still attaches the old river Holy Site Faith modifier to Jayavarman.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)UPDATE\s+ModifierArguments\s+SET\s+Value\s*=\s*1\s+WHERE\s+ModifierId\s+IN\s*\(\s*'TRAIT_TRADE_FOOD_FROM_CAMPS'\s*,\s*'TRAIT_TRADE_FOOD_FROM_PASTURES'\s*\)\s+AND\s+Name\s*=\s*'Amount'") {
		Add-ValidationError 'Final Cree override does not restore outgoing Camp/Pasture Trade Route Food to +1.'
	}
	if ($gameplayOverrideSql -match "(?s)UPDATE\s+Modifiers\s+SET(?:(?!;).)*SubjectStackLimit(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_CAMPS'(?:(?!;).)*'TRAIT_TRADE_FOOD_FROM_PASTURES'(?:(?!;).)*;") {
		Add-ValidationError 'Final Cree override incorrectly uses a modifier stack limit as an improvement-count cap.'
	}
	foreach ($maliCityFaithBinding in @(
		@('ZYL_MALI_DESERT_CITY_CENTER_FAITH', 'ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS', 'REQUIRES_PLOT_HAS_DESERT'),
		@('ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH', 'ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS', 'REQUIRES_PLOT_HAS_DESERT_HILLS')
	)) {
		$modifierId = [regex]::Escape($maliCityFaithBinding[0])
		$requirementSetId = [regex]::Escape($maliCityFaithBinding[1])
		$terrainRequirementId = [regex]::Escape($maliCityFaithBinding[2])
		if ($gameplayOverrideSql -notmatch "(?s)\('ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER'\s*,\s*'REQUIREMENT_PLOT_DISTRICT_TYPE_MATCHES'\).*?\('ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_CITY_CENTER'\).*?\('$requirementSetId'\s*,\s*'$terrainRequirementId'\).*?\('$requirementSetId'\s*,\s*'ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER'\).*?\('$modifierId'\s*,\s*'MODIFIER_PLAYER_ADJUST_PLOT_YIELD'\s*,\s*'$requirementSetId'\).*?\('$modifierId'\s*,\s*'YieldType'\s*,\s*'YIELD_FAITH'\).*?\('$modifierId'\s*,\s*'Amount'\s*,\s*2\).*?\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'$modifierId'\)") {
			Add-ValidationError "Mali Desert City Center +2 Faith binding is incomplete: $($maliCityFaithBinding[0])"
		}
	}
	if ($gameplayOverrideSql -notmatch "(?s)\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'TRAIT_MALI_MINES_PRODUCTION'\).*?\('TRAIT_CIVILIZATION_MALI_GOLD_DESERT'\s*,\s*'TRAIT_MALI_MINES_GOLD'\).*?SET\s+SubjectRequirementSetId\s*=\s*'PLOT_HAS_MINE_REQUIREMENTS'.*?WHERE\s+ModifierId\s+IN\s*\(\s*'TRAIT_MALI_MINES_PRODUCTION'\s*,\s*'TRAIT_MALI_MINES_GOLD'\s*\)") {
		Add-ValidationError 'Mali original Mine modifiers are not attached with an all-Mines scope.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)ModifierArguments\s*\(\s*ModifierId\s*,\s*Name\s*,\s*Value\s*\).*?'TRAIT_MALI_MINES_PRODUCTION'\s*,\s*'YieldType'\s*,\s*'YIELD_PRODUCTION'.*?'TRAIT_MALI_MINES_PRODUCTION'\s*,\s*'Amount'\s*,\s*-1.*?'TRAIT_MALI_MINES_GOLD'\s*,\s*'YieldType'\s*,\s*'YIELD_GOLD'.*?'TRAIT_MALI_MINES_GOLD'\s*,\s*'Amount'\s*,\s*4") {
		Add-ValidationError 'Mali Mine yields are not locked to -1 Production / +4 Gold.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+Value\s*=\s*10\s+WHERE\s+ModifierId\s+IN\s*\(.*?'SUGUBA_CHEAPER_BUILDING_PURCHASE'.*?'SUGUBA_CHEAPER_DISTRICT_PURCHASE'.*?'SUGUBA_CHEAPER_UNIT_PURCHASE'.*?\)\s+AND\s+Name\s*=\s*'Amount'") {
		Add-ValidationError 'Final Suguba purchase discount override is not locked to 10%.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)Feature_YieldChanges\s*\(\s*FeatureType\s*,\s*YieldType\s*,\s*YieldChange\s*\).*?'FEATURE_OASIS'\s*,\s*'YIELD_FOOD'\s*,\s*4.*?'FEATURE_OASIS'\s*,\s*'YIELD_GOLD'\s*,\s*1") {
		Add-ValidationError 'Global Oasis feature yields do not seed the required 4 Food / 1 Gold values.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+YieldChange\s*=\s*4\s+WHERE\s+FeatureType\s*=\s*'FEATURE_OASIS'\s+AND\s+YieldType\s*=\s*'YIELD_FOOD'.*?SET\s+YieldChange\s*=\s*1\s+WHERE\s+FeatureType\s*=\s*'FEATURE_OASIS'\s+AND\s+YieldType\s*=\s*'YIELD_GOLD'") {
		Add-ValidationError 'Global Oasis feature yields are not forced to exactly 4 Food / 1 Gold.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE'\s*,\s*'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA'\s*,\s*'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_HOLY_SITE'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA'\s*,\s*'DistrictType'\s*,\s*'DISTRICT_LAVRA'") {
		Add-ValidationError 'Russia Tundra Faith adjacency must accept both Holy Sites and Lavras.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA'.*?'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA'.*?'REQUIRES_PLOT_HAS_TUNDRA'.*?'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA'.*?'REQUIRES_PLOT_HAS_TUNDRA_HILLS'") {
		Add-ValidationError 'Russia Tundra Faith terrain requirement sets are not limited to adjacent Tundra/Tundra Hills.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_INCREASED_TUNDRA_FAITH'.*?SET\s+SubjectRequirementSetId\s*=\s*'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA'\s+WHERE\s+ModifierId\s*=\s*'TRAIT_INCREASED_TUNDRA_HILLS_FAITH'") {
		Add-ValidationError 'Russia Tundra Faith modifiers are not bound to the adjacency-aware terrain sets.'
	}
	if ($gameplayOverrideSql.Contains('ZYL_RUSSIA_CITY_HAS_HOLY_SITE')) {
		Add-ValidationError 'Russia Tundra Faith still contains the obsolete city-wide Holy Site requirement.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+StartBiasResources\s+WHERE\s+CivilizationType\s*=\s*'CIVILIZATION_FRANCE'.*?ResourceClassType\s*=\s*'RESOURCECLASS_LUXURY'") {
		Add-ValidationError 'France does not clear its existing Luxury resource biases before rebuilding them.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)INSERT\s+INTO\s+StartBiasResources\s*\(\s*CivilizationType\s*,\s*ResourceType\s*,\s*Tier\s*\)\s*SELECT\s*'CIVILIZATION_FRANCE'\s*,\s*ResourceType\s*,\s*4\s+FROM\s+Resources\s+WHERE\s+ResourceClassType\s*=\s*'RESOURCECLASS_LUXURY'") {
		Add-ValidationError 'France does not receive a civilization-wide T4 bias for every active Luxury resource.'
	}
	$magnificenceRequirements = @(
		@('ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP', 'BBG_REQUIRES_PLOT_HAS_IMPROVED_LUXURY'),
		@('ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP', 'BBG_UTILS_PLAYER_HAS_CIVIC_CRAFTSMANSHIP_REQUIREMENT'),
		@('ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM', 'BBG_REQUIRES_PLOT_HAS_IMPROVED_BONUS'),
		@('ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM', 'BBG_UTILS_PLAYER_HAS_CIVIC_FEUDALISM_REQUIREMENT'),
		@('ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES', 'REQUIRES_PLOT_HAS_IMPROVED_STRATEGIC'),
		@('ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES', 'BBG_UTILS_PLAYER_HAS_TECH_CASTLES_REQUIREMENT')
	)
	foreach ($binding in $magnificenceRequirements) {
		$requirementSetId = [regex]::Escape($binding[0])
		$requirementId = [regex]::Escape($binding[1])
		if ($gameplayOverrideSql -notmatch "\('$requirementSetId'\s*,\s*'$requirementId'\)") {
			Add-ValidationError "Magnificence resource Culture requirement is missing: $($binding[0]) -> $($binding[1])"
		}
	}
	$magnificenceModifiers = @(
		@('BBG_MAGNIFICENCE_CULTURE_ON_LUX', 'ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP'),
		@('BBG_MAGNIFICENCE_CULTURE_ON_BONUS', 'ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM'),
		@('BBG_MAGNIFICENCE_CULTURE_ON_STRAT', 'ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES')
	)
	foreach ($binding in $magnificenceModifiers) {
		$modifierId = [regex]::Escape($binding[0])
		$requirementSetId = [regex]::Escape($binding[1])
		if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'$requirementSetId'\s+WHERE\s+ModifierId\s*=\s*'$modifierId'") {
			Add-ValidationError "Magnificence resource Culture modifier has the wrong unlock: $($binding[0])"
		}
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s*=\s*'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER'.*?DELETE\s+FROM\s+Modifiers\s+WHERE\s+ModifierId\s*=\s*'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER'") {
		Add-ValidationError 'Malformed Scythia medieval ability giver is not removed.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ImprovementModifiers\s+WHERE\s+ImprovementType\s*=\s*'IMPROVEMENT_MISSION'.*?'MISSION_NEWCONTINENT_FAITH'.*?'MISSION_NEWCONTINENT_FOOD'.*?'MISSION_NEWCONTINENT_PRODUCTION'") {
		Add-ValidationError 'Spain Mission orphan modifier links are not removed.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+SubjectRequirementSetId\s*=\s*'OPPONENT_IS_IN_GOLDEN_AGE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'BBG_SULEIMAN_COMBAT_BUFF'") {
		Add-ValidationError 'Suleiman BBG combat bonus is not limited to opponents in Golden/Heroic Ages.'
	}
	if ($gameplayOverrideSql -match "(?s)SET\s+SubjectRequirementSetId\s*=\s*'OPPONENT_IS_NOT_IN_GOLDEN_AGE_REQUIREMENTS'\s+WHERE\s+ModifierId\s*=\s*'BBG_SULEIMAN_COMBAT_BUFF'") {
		Add-ValidationError 'Suleiman +2 and +4 combat modifiers would overlap against Normal/Dark-Age opponents.'
	}
	if ($gameplayOverrideSql -notmatch "(?s)SET\s+OwnerRequirementSetId\s*=\s*'PLAYER_HAS_GOLDEN_AGE'\s+WHERE\s+ModifierId\s+IN\s*\(\s*'BBG_APPEAL_WYWH'\s*,\s*'BBG_AUTOMATON_GDR_PROD'\s*\)") {
		Add-ValidationError 'Wish You Were Here Appeal and Automaton GDR production are not limited to Golden/Heroic Ages.'
	}
	$johannesburgOuterModifiers = @(
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX_BALLISTICS',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS_BALLISTICS',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT_BALLISTICS',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX_INDUS',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS_INDUS',
		'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT_INDUS'
	)
	$johannesburgInnerModifiers = @(
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_BALLISTICS',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_BALLISTICS',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_BALLISTICS',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_INDUS',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_INDUS',
		'BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_INDUS'
	)
	foreach ($modifierId in $johannesburgOuterModifiers) {
		$escapedModifierId = [regex]::Escape($modifierId)
		if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s+IN\s*\(.*?'$escapedModifierId'.*?\)\s+AND\s+Name\s+IN\s*\(\s*'Amount'\s*,\s*'YieldType'\s*\)") {
			Add-ValidationError "Johannesburg attach modifier still risks consuming city-yield arguments: $modifierId"
		}
	}
	foreach ($modifierId in $johannesburgInnerModifiers) {
		$escapedModifierId = [regex]::Escape($modifierId)
		if ($gameplayOverrideSql -notmatch "\('$escapedModifierId'\s*,\s*'Amount'\s*,\s*'1'\)" -or
				$gameplayOverrideSql -notmatch "\('$escapedModifierId'\s*,\s*'YieldType'\s*,\s*'YIELD_PRODUCTION'\)") {
			Add-ValidationError "Johannesburg city-yield modifier is missing Amount=1 or YieldType=YIELD_PRODUCTION: $modifierId"
		}
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s*=\s*'UNIQUE_LEADER_SPIES_START_PROMOTED'\s+AND\s+Name\s*=\s*'Amount'") {
		Add-ValidationError "France's attach modifier still carries the child experience argument."
	}
	if ($gameplayOverrideSql -notmatch "(?s)DELETE\s+FROM\s+ModifierArguments\s+WHERE\s+ModifierId\s+IN\s*\(\s*'CHICHEN_ITZA_JUNGLE_CULTURE'\s*,\s*'CHICHEN_ITZA_JUNGLE_PRODUCTION'\s*\)\s+AND\s+Name\s*=\s*'ModifierId'") {
		Add-ValidationError 'Chichen Itza direct plot-yield modifiers still carry obsolete child-modifier links.'
	}
}

$bbgGovernorPath = Join-Path $modRoot 'Components\BBG\sql\XP1\Governors_XP1_or_XP2.sql'
if (-not (Test-Path -LiteralPath $bbgGovernorPath)) {
	Add-ValidationError 'BBG governor gameplay SQL is missing.'
}
else {
	$bbgGovernorSql = Get-Content -LiteralPath $bbgGovernorPath -Raw
	if ($bbgGovernorSql.Contains('BBG_MOKSHA_GREATPROPHET_POINT_FOR_HS')) {
		Add-ValidationError 'Moksha still contains the unbound duplicate Great Prophet point attach chain.'
	}
	if ($bbgGovernorSql -notmatch "\(\s*'BBG_MOKSHA_PROPHET_POINTS'\s*,\s*'Amount'\s*,\s*2\s*\)" -or
		$bbgGovernorSql -notmatch "\(\s*'GOVERNOR_PROMOTION_CARDINAL_CITADEL_OF_GOD'\s*,\s*'BBG_MOKSHA_PROPHET_POINTS'\s*\)") {
		Add-ValidationError 'Moksha Citadel of God must keep its effective local +2 Great Prophet point modifier.'
	}
}

# BBG-created policy and Secret Society promotion icons are one UI asset
# contract backed by the embedded SQL policy inventory.
$bbgIconValidationParameters = @{
    ProjectRoot = $modRoot
    ModInfo = $modInfo
}
$bbgIconIssues = @(
    Get-ZylBbgIconContractIssues @bbgIconValidationParameters
)
foreach ($issue in $bbgIconIssues) {
    Add-ValidationError $issue
}

# Prove that a missing stock-icon alias is detected without changing the XML.
$bbgIconPath = Join-Path $modRoot 'Components\BBG\data\new_bbg_icons.xml'
if (Test-Path -LiteralPath $bbgIconPath -PathType Leaf) {
    $bbgIconDriftDocument = Load-XmlDocument $bbgIconPath
    $bbgIconDriftNode = $bbgIconDriftDocument.SelectSingleNode(
        "/GameInfo/IconAliases/Row[@Name='ICON_POLICY_EMPIRICAL_METHOD']"
    )
    if ($null -eq $bbgIconDriftNode) {
        Add-ValidationError 'BBG icon validation self-test fixture is missing its policy alias.'
    }
    else {
        [void]$bbgIconDriftNode.ParentNode.RemoveChild($bbgIconDriftNode)
        $bbgIconDriftIssues = @(
            Get-ZylBbgIconContractIssues @bbgIconValidationParameters `
                -IconDocumentOverride $bbgIconDriftDocument
        )
        $expectedBbgIconDriftIssue =
            'BBG icon alias is missing or targets the wrong stock icon: ICON_POLICY_EMPIRICAL_METHOD -> ICON_POLICY_ECONOMIC'
        if ($bbgIconDriftIssues -notcontains $expectedBbgIconDriftIssue) {
            Add-ValidationError 'BBG icon validation self-test did not reject a missing policy alias.'
        }
    }
}

# The final gameplay override localization mirrors ZYL's late database layer
# across embedded upstream copies and supported languages.
$gameplayLocalizationIssues = @(
    Get-ZylGameplayLocalizationContractIssues -ProjectRoot $modRoot
)
foreach ($issue in $gameplayLocalizationIssues) {
    Add-ValidationError $issue
}

# Prove that a visible Mali balance value cannot silently drift from gameplay.
$gameplayOverrideTextPath = Join-Path $modRoot 'lang\ZYL_GameplayOverrides_Text.xml'
if (Test-Path -LiteralPath $gameplayOverrideTextPath -PathType Leaf) {
    $gameplayOverrideTextSource = [System.IO.File]::ReadAllText(
        $gameplayOverrideTextPath,
        [System.Text.Encoding]::UTF8
    )
    $gameplayOverrideTextDriftSource = $gameplayOverrideTextSource.Replace(
        '建立在沙漠或沙漠丘陵上的市中心+2 [ICON_FAITH]',
        '建立在沙漠或沙漠丘陵上的市中心+3 [ICON_FAITH]'
    )
    $gameplayLocalizationDriftIssues = @(
        Get-ZylGameplayLocalizationContractIssues -ProjectRoot $modRoot `
            -GameplayTextSourceOverride $gameplayOverrideTextDriftSource
    )
    $expectedGameplayLocalizationDriftIssue =
        'Mali Chinese text is missing: 市中心+2 [ICON_FAITH]'
    if ($gameplayOverrideTextDriftSource -eq $gameplayOverrideTextSource -or
            $gameplayLocalizationDriftIssues -notcontains $expectedGameplayLocalizationDriftIssue) {
        Add-ValidationError 'Gameplay localization validation self-test did not reject a Mali text drift.'
    }
}

# Embedded BBG leader/unit/Great Person tooltips must match their final
# gameplay bindings and values.
$bbgTooltipIssues = @(
    Get-ZylBbgTooltipContractIssues -ProjectRoot $modRoot
)
foreach ($issue in $bbgTooltipIssues) {
    Add-ValidationError $issue
}

# Prove that Saladin's combat radius cannot regress to the stale tooltip.
$bbgEnglishPath = Join-Path $modRoot 'Components\BBG\lang\english.xml'
if (Test-Path -LiteralPath $bbgEnglishPath -PathType Leaf) {
    $bbgTooltipDriftDocument = Load-XmlDocument $bbgEnglishPath
    $bbgTooltipDriftNode = $bbgTooltipDriftDocument.SelectSingleNode(
        "/GameData/LocalizedText/*[@Tag='LOC_BBG_SULTAN_COMBAT_ADJACENT_APOSTLE_ABILITY_DESC' and @Language='en_US']/Text"
    )
    if ($null -eq $bbgTooltipDriftNode) {
        Add-ValidationError 'BBG tooltip validation self-test fixture is missing the Sultan row.'
    }
    else {
        $bbgTooltipOriginalText = $bbgTooltipDriftNode.InnerText
        $bbgTooltipDriftNode.InnerText =
            $bbgTooltipOriginalText.Replace('within 2 tiles', 'within 1 tile')
        $bbgTooltipDriftIssues = @(
            Get-ZylBbgTooltipContractIssues -ProjectRoot $modRoot `
                -EnglishDocumentOverride $bbgTooltipDriftDocument
        )
        $expectedBbgTooltipDriftIssue =
            'Saladin (Sultan) English combat tooltip must target military units within 2 tiles of an Apostle.'
        if ($bbgTooltipDriftNode.InnerText -eq $bbgTooltipOriginalText -or
                $bbgTooltipDriftIssues -notcontains $expectedBbgTooltipDriftIssue) {
            Add-ValidationError 'BBG tooltip validation self-test did not reject a stale combat radius.'
        }
    }
}

# Late repairs for malformed BBG ModifierArguments and final governor values
# remain part of the database contract module.
$finalDatabaseRepairIssues = @(
    Get-ZylFinalDatabaseRepairIssues -ProjectRoot $modRoot
)
foreach ($issue in $finalDatabaseRepairIssues) {
    Add-ValidationError $issue
}

# Prove that a removed tourism repair is rejected in memory.
$gameplayOverridePath = Join-Path $modRoot 'sql\ZYL_GameplayOverrides.sql'
if (Test-Path -LiteralPath $gameplayOverridePath -PathType Leaf) {
    $finalRepairGameplaySource = Get-Content -LiteralPath $gameplayOverridePath -Raw
    $finalRepairGameplayDriftSource = $finalRepairGameplaySource.Replace(
        "WHERE ModifierId = 'FERRIS_WHEEL_TOURISM'",
        "WHERE ModifierId = 'FERRIS_WHEEL_TOURISM_DRIFT'"
    )
    $finalDatabaseRepairDriftIssues = @(
        Get-ZylFinalDatabaseRepairIssues -ProjectRoot $modRoot `
            -GameplaySourceOverride $finalRepairGameplayDriftSource
    )
    $expectedFinalDatabaseRepairDriftIssue =
        "Malformed BBG ModifierArguments repair is missing invariant: WHERE ModifierId = 'FERRIS_WHEEL_TOURISM'"
    if ($finalRepairGameplayDriftSource -eq $finalRepairGameplaySource -or
            $finalDatabaseRepairDriftIssues -notcontains $expectedFinalDatabaseRepairDriftIssue) {
        Add-ValidationError 'Final database repair self-test did not reject a missing tourism repair.'
    }
}

# Rich Mainland publishes two map variants and protects their map-generation
# fallbacks, deterministic retry path, canvas geometry and ModInfo graph.
foreach ($richMainlandIssue in @(Get-ZylRichMainlandContractIssues `
        -ProjectRoot $modRoot `
        -ListedFileMap $listedFileMap `
        -CriteriaMap $criteriaMap `
        -ActionIdMap $actionIdMap `
        -ModInfo $modInfo)) {
    Add-ValidationError $richMainlandIssue
}
$richMainlandAssignPath = Join-Path $modRoot 'Components\BBM\Data\BBS Maps\Utility\ZYL_RVC_AssignStartingPlots.lua'
if (Test-Path -LiteralPath $richMainlandAssignPath -PathType Leaf) {
    $richMainlandAssignSource = Get-Content -LiteralPath $richMainlandAssignPath -Raw
    $richMainlandAssignIssues = @(Get-ZylRichMainlandAssignStartingPlotsIssues `
        -Source $richMainlandAssignSource)
    $richMainlandAssignDriftSource = $richMainlandAssignSource.Replace(
        '__PlaceMissingMinorCivsRelaxed',
        '__PlaceMissingMinorCivsLegacy'
    )
    if ($richMainlandAssignIssues.Count -ne 0 -or
            $richMainlandAssignDriftSource -eq $richMainlandAssignSource -or
            @(Get-ZylRichMainlandAssignStartingPlotsIssues `
                -Source $richMainlandAssignDriftSource).Count -eq 0) {
        Add-ValidationError 'Rich Mainland map helper failed its positive/negative self-test.'
    }
}

# TPT UI/QoL features must remain wired to the intended contexts, criteria
# and safe runtime implementations.
foreach ($tptUiIssue in @(Get-ZylTptUiContractIssues `
        -ProjectRoot $modRoot `
        -ListedFileMap $listedFileMap `
        -CriteriaMap $criteriaMap `
        -ActionIdMap $actionIdMap)) {
    Add-ValidationError $tptUiIssue
}
$forcedEndLuaPath = Join-Path $modRoot 'FEB\UI\ForcedEndButton.lua'
if (Test-Path -LiteralPath $forcedEndLuaPath -PathType Leaf) {
    $forcedEndSource = Get-Content -LiteralPath $forcedEndLuaPath -Raw
    $forcedEndIssues = @(Get-ZylForcedEndButtonIssues -Source $forcedEndSource)
    $forcedEndDriftSource = $forcedEndSource.Replace(
        'ActionTypes.ACTION_ENDTURN',
        'ActionTypes.ACTION_UNREADYTURN'
    )
    if ($forcedEndIssues.Count -ne 0 -or
            $forcedEndDriftSource -eq $forcedEndSource -or
            @(Get-ZylForcedEndButtonIssues -Source $forcedEndDriftSource).Count -eq 0) {
        Add-ValidationError 'TPT UI helper failed its positive/negative self-test.'
    }
}

$zylConfigPath = Join-Path $modRoot 'configuration\Config_ZYL.xml'
if (Test-Path -LiteralPath $zylConfigPath) {
    $zylConfig = Load-XmlDocument $zylConfigPath
    $warningNode = $zylConfig.SelectSingleNode('/GameInfo/Parameters/Row[@ParameterId="TOOLS_15_TIME"]')
    if ($null -eq $warningNode -or $warningNode.GetAttribute('DefaultValue') -ne '1') {
        Add-ValidationError 'The 15-second warning must default to enabled.'
    }
    $zylConfigRows = @($zylConfig.SelectNodes('/GameInfo/Parameters/Row'))
    foreach ($parameterId in @('TOOLS_COMMAND', 'TOOLS_15_TIME')) {
        if ($null -eq ($zylConfigRows | Where-Object { $_.GetAttribute('ParameterId') -eq $parameterId })) {
            Add-ValidationError "Config_ZYL.xml is missing $parameterId."
        }
    }
	$ribbonModeOptions = @($zylConfig.SelectNodes('/GameInfo/Parameters/Row[@ParameterId="ZYL_DIPLOMACY_RIBBON_MODE"]'))
	if ($ribbonModeOptions.Count -ne 1 -or
		$ribbonModeOptions[0].GetAttribute('Key2') -ne 'RULESET_EXPANSION_2' -or
		$ribbonModeOptions[0].GetAttribute('Domain') -ne 'ZylDiplomacyRibbonModes' -or
		$ribbonModeOptions[0].GetAttribute('DefaultValue') -ne '0') {
		Add-ValidationError 'The diplomacy-ribbon mode must be an Expansion 2 lobby option using ZylDiplomacyRibbonModes and defaulting to FFA (0).'
	}
	$ribbonModeValues = @($zylConfig.SelectNodes('/GameInfo/DomainValues/Row[@Domain="ZylDiplomacyRibbonModes"]'))
	if ($ribbonModeValues.Count -ne 2 -or
		$null -eq ($ribbonModeValues | Where-Object { $_.GetAttribute('Value') -eq '0' }) -or
		$null -eq ($ribbonModeValues | Where-Object { $_.GetAttribute('Value') -eq '1' })) {
		Add-ValidationError 'The diplomacy-ribbon domain must contain exactly FFA (0) and Team (1).'
	}

}

foreach ($identityIssue in @(Get-ZylIdentityContractIssues `
        -ProjectRoot $modRoot `
        -ConfigurationXml $zylConfig `
        -ListedFileMap $listedFileMap `
        -ActionIdMap $actionIdMap)) {
    Add-ValidationError $identityIssue
}
$identityPanelLuaPath = Join-Path $modRoot 'ui\Additions\IdentityRolePanel.lua'
if (Test-Path -LiteralPath $identityPanelLuaPath -PathType Leaf) {
    $identityPanelSource = Get-Content -LiteralPath $identityPanelLuaPath -Raw
    $identityPanelIssues = @(Get-ZylIdentityRolePanelSourceIssues `
        -Source $identityPanelSource)
    $identityPanelDriftSource = $identityPanelSource.Replace(
        'Game.GetLocalPlayer()',
        'Game:SetProperty('
    )
    if ($identityPanelIssues.Count -ne 0 -or
            $identityPanelDriftSource -eq $identityPanelSource -or
            @(Get-ZylIdentityRolePanelSourceIssues `
                -Source $identityPanelDriftSource).Count -eq 0) {
        Add-ValidationError 'Identity contract helper failed its positive/negative self-test.'
    }
}

$startingBonusValidationParameters = @{
    ProjectRoot = $modRoot
    ActionIdMap = $actionIdMap
    ListedFileMap = $listedFileMap
}
$startingBonusIssues = @(
    Get-ZylStartingBonusContractIssues @startingBonusValidationParameters
)
foreach ($issue in $startingBonusIssues) {
    Add-ValidationError $issue
}

# Prove that the synchronized grant keeps its persisted idempotency write.
$startingBonusScriptPath = Join-Path $modRoot 'scripts\ZYL_StartingPlayerBonus.lua'
if (Test-Path -LiteralPath $startingBonusScriptPath -PathType Leaf) {
    $startingBonusScriptSource = Get-Content -LiteralPath $startingBonusScriptPath -Raw
    $startingBonusScriptDriftSource = $startingBonusScriptSource.Replace(
        'player:SetProperty(APPLIED_PROPERTY, selectedBonus)',
        'player:SetProperty(APPLIED_PROPERTY_DRIFT, selectedBonus)'
    )
    $startingBonusDriftIssues = @(
        Get-ZylStartingBonusContractIssues @startingBonusValidationParameters `
            -StartingBonusScriptOverride $startingBonusScriptDriftSource
    )
    $expectedStartingBonusDriftIssue =
        'Starting-player bonus script is missing: player:SetProperty(APPLIED_PROPERTY, selectedBonus)'
    if ($startingBonusScriptDriftSource -eq $startingBonusScriptSource -or
            $startingBonusDriftIssues -notcontains $expectedStartingBonusDriftIssue) {
        Add-ValidationError 'Starting bonus validation self-test did not reject a broken idempotency write.'
    }
}

$stagingRoomPath = Join-Path $modRoot 'ui\stagingroom.lua'
if (-not (Test-Path -LiteralPath $stagingRoomPath)) {
Add-ValidationError 'The staging-room replacement is missing.'
}
else {
$stagingRoomSource = Get-Content -LiteralPath $stagingRoomPath -Raw
$stagingRoomIssues = @(Get-ZylStagingRoomContractIssues -Source $stagingRoomSource)
$shuffleDriftSource = $stagingRoomSource.Replace(
'local swapIndex = math.random(index)',
'local swapIndex = 1 + math.random(index)'
)
$transitionDriftSource = $stagingRoomSource.Replace(
'if isConnected and player.Status ~= previousStatus',
'if isConnected'
)
if ($stagingRoomIssues.Count -ne 0 -or
$shuffleDriftSource -eq $stagingRoomSource -or
$transitionDriftSource -eq $stagingRoomSource -or
@(Get-ZylStagingRoomContractIssues -Source $shuffleDriftSource).Count -eq 0 -or
@(Get-ZylStagingRoomContractIssues -Source $transitionDriftSource).Count -eq 0) {
Add-ValidationError 'Staging-room contract module failed its positive/negative self-test.'
}
foreach ($stagingRoomIssue in $stagingRoomIssues) {
Add-ValidationError $stagingRoomIssue
}
}

$multiplayerControllerSpecs = @(
    [pscustomobject]@{
        RelativePath = 'ui\Additions\VotePanel.lua'
        MissingMessage = 'The remap/vote panel is missing.'
        CheckFunction = 'Get-ZylVotePanelContractIssues'
        DriftFrom = 'local b_remap_armed = false'
        DriftTo = 'local b_RemapArmed = false'
        Label = 'Vote panel'
    },
    [pscustomobject]@{
        RelativePath = 'ui\Additions\DropControl.lua'
        MissingMessage = 'The multiplayer drop controller is missing.'
        CheckFunction = 'Get-ZylDropControlContractIssues'
        DriftFrom = 'not UpdateData(playerID, true)'
        DriftTo = 'UpdateData(playerID, true)'
        Label = 'Drop controller'
    },
    [pscustomobject]@{
        RelativePath = 'ui\Additions\MPHOptions.lua'
        MissingMessage = 'The multiplayer options/resync controller is missing.'
        CheckFunction = 'Get-ZylResyncControllerContractIssues'
        DriftFrom = 'if m_lastResyncTickSecond == now then'
        DriftTo = 'if false then'
        Label = 'Multiplayer resync controller'
    },
    [pscustomobject]@{
        RelativePath = 'ui\Additions\SuddenDeathPanel.lua'
        MissingMessage = 'The sudden-death panel is missing.'
        CheckFunction = 'Get-ZylSuddenDeathContractIssues'
        DriftFrom = 'if m_lastBroadcastTurn == currentTurn then'
        DriftTo = 'if false then'
        Label = 'Sudden-death controller'
    }
)
foreach ($controllerSpec in $multiplayerControllerSpecs) {
    $controllerPath = Join-Path $modRoot $controllerSpec.RelativePath
    if (-not (Test-Path -LiteralPath $controllerPath -PathType Leaf)) {
        Add-ValidationError $controllerSpec.MissingMessage
        continue
    }

    $controllerSource = Get-Content -LiteralPath $controllerPath -Raw
    $checkFunction = $controllerSpec.CheckFunction
    $controllerIssues = @(& $checkFunction -Source $controllerSource)
    $driftSource = $controllerSource.Replace($controllerSpec.DriftFrom, $controllerSpec.DriftTo)
    if ($controllerIssues.Count -ne 0 -or
            $driftSource -eq $controllerSource -or
            @(& $checkFunction -Source $driftSource).Count -eq 0) {
        Add-ValidationError "$($controllerSpec.Label) contract helper failed its positive/negative self-test."
    }
    foreach ($controllerIssue in $controllerIssues) {
        Add-ValidationError $controllerIssue
    }
}

$mainMenuPath = Join-Path $modRoot 'ui\mainmenu.lua'
if (-not (Test-Path -LiteralPath $mainMenuPath -PathType Leaf)) {
Add-ValidationError 'The main-menu replacement is missing.'
}
else {
$mainMenuSource = Get-Content -LiteralPath $mainMenuPath -Raw
foreach ($requiredMainMenuLifecycleFragment in @(
'local b_debug = false',
'ContextPtr:SetShutdown( OnShutdown );',
'LuaEvents.EnterCrossPlayLobby.Remove(OnEnterCrossPlayLobby);',
'Events.SystemUpdateUI.Remove(OnUpdateUI);'
)) {
if (-not $mainMenuSource.Contains($requiredMainMenuLifecycleFragment)) {
Add-ValidationError "Main-menu lifecycle guard is missing: $requiredMainMenuLifecycleFragment"
}
}
Test-ZylLuaEventLifecycle -Source $mainMenuSource -Label 'Main menu'
Test-ZylLuaHasNoUnguardedPrint -Source $mainMenuSource -Label 'Main menu'
}

# The two custom Casual timers remain distinct options. Casual (Relaxed) is
# the default and uses the requested turn + 70 + 4C + 2U + delta formula.
$cplConfigPath = Join-Path $modRoot 'configuration\Config.xml'
$turnProcessingPath = Join-Path $modRoot 'ui\Additions\TurnProcessing.lua'
if (Test-Path -LiteralPath $cplConfigPath) {
    $cplConfig = Load-XmlDocument $cplConfigPath
	$smartTimerParameter = $cplConfig.SelectSingleNode('/GameInfo/Parameters/Row[@ParameterId="CPL_SMARTTIMER"]')
	if ($null -eq $smartTimerParameter -or $smartTimerParameter.GetAttribute('DefaultValue') -ne '9') {
		Add-ValidationError 'The base smart-timer lobby parameter must default to Casual (Relaxed), value 9.'
	}
    $balancedTimerOption = $cplConfig.SelectSingleNode('/GameInfo/DomainValues/Row[@Domain="TimerLimits" and @Value="8"]')
    if ($null -eq $balancedTimerOption -or
        $balancedTimerOption.GetAttribute('Name') -ne 'TIMER_CASUAL_BALANCED_NAME' -or
        $balancedTimerOption.GetAttribute('Description') -ne 'TIMER_CASUAL_BALANCED_DESC') {
        Add-ValidationError 'The balanced Casual timer option (TimerLimits value 8) is missing or malformed.'
    }
	$relaxedTimerOption = $cplConfig.SelectSingleNode('/GameInfo/DomainValues/Row[@Domain="TimerLimits" and @Value="9"]')
	if ($null -eq $relaxedTimerOption -or
		$relaxedTimerOption.GetAttribute('Name') -ne 'TIMER_CASUAL_RELAXED_NAME' -or
		$relaxedTimerOption.GetAttribute('Description') -ne 'TIMER_CASUAL_RELAXED_DESC') {
		Add-ValidationError 'The relaxed Casual timer option (TimerLimits value 9) is missing or malformed.'
	}
}
if (-not (Test-Path -LiteralPath $turnProcessingPath -PathType Leaf)) {
    Add-ValidationError 'The turn-processing controller is missing.'
}
else {
    $turnProcessingSource = Get-Content -Raw -LiteralPath $turnProcessingPath
    $turnProcessingIssues = @(Get-ZylTurnProcessingContractIssues -Source $turnProcessingSource)
    $turnProcessingDriftSource = $turnProcessingSource.Replace(
        'if g_timeCommandUses >= MAX_TIME_EXTENSIONS_PER_TURN then return end',
        'if false then return end'
    )
    if ($turnProcessingIssues.Count -ne 0 -or
            $turnProcessingDriftSource -eq $turnProcessingSource -or
            @(Get-ZylTurnProcessingContractIssues -Source $turnProcessingDriftSource).Count -eq 0) {
        Add-ValidationError 'Turn-processing contract helper failed its positive/negative self-test.'
    }
    foreach ($turnProcessingIssue in $turnProcessingIssues) {
        Add-ValidationError $turnProcessingIssue
    }
}

foreach ($eraContractIssue in @(Get-ZylEraConfigurationContractIssues `
        -ProjectRoot $modRoot `
        -ModInfo $modInfo `
        -ZylConfig $zylConfig)) {
    Add-ValidationError $eraContractIssue
}

# The final lobby defaults are deliberately a separate, late-loading action.
# Config_ZYL.xml also owns the two TPT rows, but its old mixed Update block ran
# before MPH/BBG had created their Parameters and therefore matched zero rows.
$lobbyDefaultsPath = Join-Path $modRoot 'configuration\ZYL_LobbyDefaults.xml'
if (-not (Test-Path -LiteralPath $lobbyDefaultsPath)) {
    Add-ValidationError 'The final lobby-default configuration is missing.'
}
else {
    $lobbyDefaults = Load-XmlDocument $lobbyDefaultsPath
    $expectedLobbyDefaults = @{
        'TOOLS_COMMAND' = '1'
        'TOOLS_15_TIME' = '1'
        'CPL_SMARTTIMER' = '9'
        'ZYL_ERA_LENGTH_OPTIMIZATION' = '1'
		'ZYL_DIPLOMACY_RIBBON_MODE' = '0'
		'ZYL_STARTING_BONUS_PLAYER' = '0'
		'ZYL_STARTING_BONUS_TYPE' = '0'
        'BBCC_SETTING' = '0'
        'BBCC_SETTING_YIELD' = '2'
		'SettlersConfig' = '0'
        'BarbariansSetting' = '-1'
        'NoBarbarians' = '1'
        'GameMode_Monopolies' = '1'
        'GameMode_SecretSocieties' = '1'
        'ZYLRM_TEAM_RouteLevel' = '1'
        'ZYLRM_FFA_RouteLevel' = '1'
    }
    foreach ($entry in $expectedLobbyDefaults.GetEnumerator()) {
        $node = $lobbyDefaults.SelectSingleNode("/GameInfo/Parameters/Update[Where/@ParameterId='$($entry.Key)']/Set")
        if ($null -eq $node -or $node.GetAttribute('DefaultValue') -ne $entry.Value) {
            Add-ValidationError "Final lobby default $($entry.Key) must be $($entry.Value)."
        }
    }
    $lobbyAction = $actionIdMap['zyl_lobbydefaults']
    if ($null -eq $lobbyAction) {
        Add-ValidationError 'Final lobby-default ModInfo action is missing.'
    }
    else {
        if ($lobbyAction.ParentNode.LocalName -ne 'FrontEndActions' -or $lobbyAction.LocalName -ne 'UpdateDatabase') {
            Add-ValidationError 'Final lobby-default action must be a FrontEndActions UpdateDatabase action.'
        }
        $loadOrderNode = $lobbyAction.SelectSingleNode('./Properties/LoadOrder')
        if ($null -eq $loadOrderNode -or [int64]$loadOrderNode.InnerText.Trim() -lt 300000000) {
            Add-ValidationError 'Final lobby-default action must load at or after 300000000.'
        }
        $cplAction = $actionIdMap['cpl_settings']
        if ($null -ne $cplAction) {
            $cplLoadOrderNode = $cplAction.SelectSingleNode('./Properties/LoadOrder')
            if ($null -ne $cplLoadOrderNode -and [int64]$loadOrderNode.InnerText.Trim() -le [int64]$cplLoadOrderNode.InnerText.Trim()) {
                Add-ValidationError 'Final lobby-default action must load after CPL_SETTINGS.'
            }
        }
        $lobbyActionFile = @($lobbyAction.SelectNodes('./File') | ForEach-Object { Normalize-RelativePath $_.InnerText })
        if ((Normalize-RelativePath 'configuration/ZYL_LobbyDefaults.xml') -notin $lobbyActionFile) {
            Add-ValidationError 'Final lobby-default action does not reference ZYL_LobbyDefaults.xml.'
        }
    }
}

$hostGamePath = Join-Path $modRoot 'ui\hostgame.lua'
if (Test-Path -LiteralPath $hostGamePath) {
    $kickVotingCalls = @(Select-String -LiteralPath $hostGamePath -SimpleMatch 'GameConfiguration.SetKickVoting(true);')
    if ($kickVotingCalls.Count -lt 2) {
        Add-ValidationError 'Kick voting must be enabled in fresh-host and restore-default flows.'
    }
    $hostGameLua = Get-Content -LiteralPath $hostGamePath -Raw
    $applyDefaultCalls = @([regex]::Matches($hostGameLua, 'ApplyZYLLobbyDefaults\s*\(\s*\)'))
    if ($applyDefaultCalls.Count -lt 4) {
        Add-ValidationError 'Host game must apply ZYLPVPMOD defaults for fresh rooms, Restore Defaults and MPH preset None.'
    }
	foreach ($requiredDefault in @(
		'{ "CPL_SMARTTIMER", 9 }',
		'{ "ZYL_ERA_LENGTH_OPTIMIZATION", 1 }',
		'{ "ZYL_DIPLOMACY_RIBBON_MODE", 0 }',
		'{ "ZYL_STARTING_BONUS_PLAYER", 0 }',
		'{ "ZYL_STARTING_BONUS_TYPE", 0 }',
		'{ "SettlersConfig", 0 }'
	)) {
		if (-not $hostGameLua.Contains($requiredDefault)) {
			Add-ValidationError "Host game is missing the requested lobby default: $requiredDefault"
		}
	}
	foreach ($requiredHostLifecycleFragment in @(
		'local b_debug = false;',
		'function OnFinishedGameplayContentConfigure(result)',
		'Events.FinishedGameplayContentConfigure.Add(OnFinishedGameplayContentConfigure);',
		'Events.FinishedGameplayContentConfigure.Remove(OnFinishedGameplayContentConfigure);',
		'hostID == nil or localID == nil or hostID < 0 or localID ~= hostID'
	)) {
		if (-not $hostGameLua.Contains($requiredHostLifecycleFragment)) {
			Add-ValidationError "Host-game lifecycle or authority guard is missing: $requiredHostLifecycleFragment"
		}
	}
	foreach ($forbiddenHostFragment in @(
		'Events.FinishedGameplayContentConfigure.Add(function',
		'Network.BroadcastPlayerInfo()',
		'SpawnRecalculation',
		'OnUpdateUI()'
	)) {
		if ($hostGameLua.Contains($forbiddenHostFragment)) {
			Add-ValidationError "Host game restored a dead path or unrelated broadcast: $forbiddenHostFragment"
		}
	}
	Test-ZylLuaEventLifecycle -Source $hostGameLua -Label 'Host game'
	Test-ZylLuaHasNoUnguardedPrint -Source $hostGameLua -Label 'Host game'
}

$bbgConfigPath = Join-Path $modRoot 'Components\BBG\config\config.xml'
if (Test-Path -LiteralPath $bbgConfigPath) {
    $bbgConfig = Load-XmlDocument $bbgConfigPath
    $settlersParameter = $bbgConfig.SelectSingleNode('/GameInfo/Parameters/Row[@ParameterId="SettlersConfig"]')
    if ($null -eq $settlersParameter -or $settlersParameter.GetAttribute('DefaultValue') -ne '0') {
        Add-ValidationError 'BBG captured-settler option must default to Send Home (0).'
    }
}
else {
    Add-ValidationError 'BBG front-end configuration is missing.'
}

# All sixteen Secret Society promotions refund one Governor Title through the
# correctly gated BBG database action.
$secretSocietiesPath = Join-Path $modRoot 'Components\BBG\sql\Secret_Societies.sql'
if (-not (Test-Path -LiteralPath $secretSocietiesPath -PathType Leaf)) {
    Add-ValidationError 'BBG Secret Societies SQL is missing.'
}
else {
    $secretSocietiesSource = Get-Content -LiteralPath $secretSocietiesPath -Raw
    $secretSocietyRefundIssues = @(Get-ZylSecretSocietyRefundContractIssues `
        -Source $secretSocietiesSource `
        -ModInfo $modInfo)
    $secretSocietyRefundDriftSource = $secretSocietiesSource.Replace(
        'CIVIC_GRANT_PLAYER_GOVERNOR_POINTS',
        'CIVIC_LEGACY_GOVERNOR_POINTS'
    )
    if ($secretSocietyRefundIssues.Count -ne 0 -or
            $secretSocietyRefundDriftSource -eq $secretSocietiesSource -or
            @(Get-ZylSecretSocietyRefundContractIssues `
                -Source $secretSocietyRefundDriftSource `
                -ModInfo $modInfo).Count -eq 0) {
        Add-ValidationError 'Secret Society refund helper failed its positive/negative self-test.'
    }
    foreach ($secretSocietyRefundIssue in $secretSocietyRefundIssues) {
        Add-ValidationError $secretSocietyRefundIssue
    }
}

# Team PVP Secret Societies is a self-contained, mode-gated vertical
# integration. Keep its payload, localization, art, ModInfo action graph and
# LightweightBalance harvesting hand-off under one validation contract.
$teamPvpSocietyValidationParameters = @{
    ProjectRoot = $modRoot
    ModInfo = $modInfo
    CriteriaMap = $criteriaMap
    ActionIdMap = $actionIdMap
    ListedFileMap = $listedFileMap
}
$teamPvpSocietyIssues = @(
    Get-ZylTeamPvpSecretSocietyContractIssues @teamPvpSocietyValidationParameters
)
foreach ($issue in $teamPvpSocietyIssues) {
    Add-ValidationError $issue
}

# Prove that the extracted contract rejects a high-risk balance drift without
# copying or mutating the project tree.
$teamPvpSocietyGameplayPath = Join-Path $modRoot 'Components\TeamPVPSecretSocieties\Gameplay.sql'
if (Test-Path -LiteralPath $teamPvpSocietyGameplayPath -PathType Leaf) {
    $teamPvpSocietyGameplaySource = Get-Content -LiteralPath $teamPvpSocietyGameplayPath -Raw
    $teamPvpSocietyDriftSource = $teamPvpSocietyGameplaySource.Replace(
        'DiscoverAtCityStateBaseChance = 100000',
        'DiscoverAtCityStateBaseChance = 1'
    )
    $teamPvpSocietyDriftIssues = @(
        Get-ZylTeamPvpSecretSocietyContractIssues @teamPvpSocietyValidationParameters `
            -GameplaySourceOverride $teamPvpSocietyDriftSource
    )
    $expectedTeamPvpSocietyDriftIssue =
        'Team PVP Secret Societies SQL is missing required behavior: DiscoverAtCityStateBaseChance = 100000'
    if ($teamPvpSocietyDriftSource -eq $teamPvpSocietyGameplaySource -or
            $teamPvpSocietyDriftIssues -notcontains $expectedTeamPvpSocietyDriftIssue) {
        Add-ValidationError 'Team PVP Secret Societies validation self-test did not reject a gameplay balance drift.'
    }
}

# BBG Expanded's six resources, art payload, Monopolies extension and
# external-package hand-off form one vertical integration contract.
$expandedResourceValidationParameters = @{
    ProjectRoot = $modRoot
    ModInfo = $modInfo
    CriteriaMap = $criteriaMap
    ActionIdMap = $actionIdMap
    ListedFileMap = $listedFileMap
}
$expandedResourceIssues = @(
    Get-ZylExpandedResourceContractIssues @expandedResourceValidationParameters
)
foreach ($issue in $expandedResourceIssues) {
    Add-ValidationError $issue
}

# Prove that the extracted balance contract rejects a resource-placement drift.
$expandedResourceBalancePath = Join-Path $modRoot 'Components\BBG\sql\BBG_Expanded\Resources.sql'
if (Test-Path -LiteralPath $expandedResourceBalancePath -PathType Leaf) {
    $expandedResourceBalanceSource = Get-Content -LiteralPath $expandedResourceBalancePath -Raw
    $expandedResourceDriftSource = $expandedResourceBalanceSource.Replace(
        "('RESOURCE_P0K_PENGUINS', 'TERRAIN_COAST')",
        "('RESOURCE_P0K_PENGUINS', 'TERRAIN_OCEAN')"
    )
    $expandedResourceDriftIssues = @(
        Get-ZylExpandedResourceContractIssues @expandedResourceValidationParameters `
            -BalanceSourceOverride $expandedResourceDriftSource
    )
    $expectedExpandedResourceDriftIssue =
        "BBG Expanded resource balance is missing required behavior: ('RESOURCE_P0K_PENGUINS', 'TERRAIN_COAST')"
    if ($expandedResourceDriftSource -eq $expandedResourceBalanceSource -or
            $expandedResourceDriftIssues -notcontains $expectedExpandedResourceDriftIssue) {
        Add-ValidationError 'BBG Expanded resource validation self-test did not reject a placement drift.'
    }
}


# The selected Lightweight Balance pantheons, ZYL Druid and the
# Gathering Storm geothermal Mine form one gameplay/text/icon contract.
$pantheonValidationParameters = @{
    ProjectRoot = $modRoot
    ModInfo = $modInfo
    CriteriaMap = $criteriaMap
    ActionIdMap = $actionIdMap
    ListedFileMap = $listedFileMap
}
$pantheonIssues = @(
    Get-ZylPantheonContractIssues @pantheonValidationParameters
)
foreach ($issue in $pantheonIssues) {
    Add-ValidationError $issue
}

# Prove that the selected-belief allowlist rejects a missing Druid definition.
$selectedPantheonPath = Join-Path $modRoot 'sql\ZYL_Pantheons.sql'
if (Test-Path -LiteralPath $selectedPantheonPath -PathType Leaf) {
    $selectedPantheonSource = Get-Content -LiteralPath $selectedPantheonPath -Raw
    $selectedPantheonDriftSource = $selectedPantheonSource.Replace(
        "('BELIEF_ZYL_DRUID', 'KIND_BELIEF')",
        "('BELIEF_ZYL_DRUID', 'KIND_BELIEF_DRIFT')"
    )
    $selectedPantheonDriftIssues = @(
        Get-ZylPantheonContractIssues @pantheonValidationParameters `
            -PantheonSourceOverride $selectedPantheonDriftSource
    )
    $expectedPantheonDriftIssue = 'Selected pantheon is not registered: BELIEF_ZYL_DRUID'
    if ($selectedPantheonDriftSource -eq $selectedPantheonSource -or
            $selectedPantheonDriftIssues -notcontains $expectedPantheonDriftIssue) {
        Add-ValidationError 'Pantheon validation self-test did not reject a missing selected belief.'
    }
}


# Coastal/inland leader variants are exact data aliases whose only runtime
# difference is owned by the map-placement scripts.
$leaderVariantValidationParameters = @{
    ProjectRoot = $modRoot
    ActionIdMap = $actionIdMap
}
$leaderVariantIssues = @(
    Get-ZylLeaderVariantContractIssues @leaderVariantValidationParameters
)
foreach ($issue in $leaderVariantIssues) {
    Add-ValidationError $issue
}

# Prove that an incomplete trait clone is rejected without touching the SQL.
$leaderVariantGameplayPath = Join-Path $modRoot 'LeaderVariants\ZYL_CoastLeaderVariants_Gameplay.sql'
if (Test-Path -LiteralPath $leaderVariantGameplayPath -PathType Leaf) {
    $leaderVariantGameplaySource = Get-Content -LiteralPath $leaderVariantGameplayPath -Raw
    $leaderVariantGameplayDriftSource = $leaderVariantGameplaySource.Replace(
        "SELECT 'LEADER_HOJO_INLAND', TraitType",
        "SELECT 'LEADER_HOJO_INLAND_DRIFT', TraitType"
    )
    $leaderVariantDriftIssues = @(
        Get-ZylLeaderVariantContractIssues @leaderVariantValidationParameters `
            -GameplaySourceOverride $leaderVariantGameplayDriftSource
    )
    $expectedLeaderVariantDriftIssue =
        'LEADER_HOJO_INLAND no longer clones the final traits of LEADER_HOJO.'
    if ($leaderVariantGameplayDriftSource -eq $leaderVariantGameplaySource -or
            $leaderVariantDriftIssues -notcontains $expectedLeaderVariantDriftIssue) {
        Add-ValidationError 'Leader variant validation self-test did not reject an incomplete trait clone.'
    }
}

# UI replacement contexts have one cross-component owner; EndGame combines
# MPH's complete layout with BBG's Lua extension.
$uiContextOwnerIssues = @(Get-ZylUiContextOwnerIssues -ActionNodes @($actionNodes))
$uiContextOwnerFixture = [System.Xml.XmlDocument]::new()
$uiContextOwnerFixture.LoadXml(@'
<Actions>
  <ReplaceUIScript id="fixture-bbg"><Properties><LuaContext>Fixture</LuaContext><LuaReplace>Components/BBG/ui/fixture.lua</LuaReplace></Properties></ReplaceUIScript>
  <ReplaceUIScript id="fixture-toolbox"><Properties><LuaContext>Fixture</LuaContext><LuaReplace>ui/fixture.lua</LuaReplace></Properties></ReplaceUIScript>
</Actions>
'@)
$uiContextOwnerDriftIssues = @(Get-ZylUiContextOwnerIssues `
    -ActionNodes @($uiContextOwnerFixture.DocumentElement.ChildNodes))
if ($uiContextOwnerIssues.Count -ne 0 -or $uiContextOwnerDriftIssues.Count -ne 1) {
    Add-ValidationError 'UI context-owner helper failed its positive/negative self-test.'
}
foreach ($uiContextOwnerIssue in $uiContextOwnerIssues) {
    Add-ValidationError $uiContextOwnerIssue
}
foreach ($endGameUiIssue in @(Get-ZylEndGameUiOwnershipIssues `
        -ListedFileMap $listedFileMap `
        -ActionReferenceMap $actionReferenceMap)) {
    Add-ValidationError $endGameUiIssue
}

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

# Better Deal Window, Detailed Map Tacks and the diplomacy ribbon share one
# explicitly owned, compatibility-checked UI integration chain.
foreach ($integratedUiIssue in @(Get-ZylIntegratedDealMapUiContractIssues `
        -ProjectRoot $modRoot `
        -ActionNodes @($actionNodes) `
        -ListedFileMap $listedFileMap `
        -ActionReferenceMap $actionReferenceMap `
        -ModInfo $modInfo)) {
    Add-ValidationError $integratedUiIssue
}
$bdwEntryPath = Join-Path $modRoot 'Components\BetterDealWindow\DiplomacyDealView_ZYLPVP_Expansion2.lua'
if (Test-Path -LiteralPath $bdwEntryPath -PathType Leaf) {
    $bdwEntrySource = Get-Content -LiteralPath $bdwEntryPath -Raw
    $bdwEntryIssues = @(Get-ZylBetterDealWindowEntryIssues -Source $bdwEntrySource)
    $bdwEntryDriftSource = $bdwEntrySource.Replace(
        'include("ZYLPVP_BDW_MPH_Compatibility")',
        'include("Legacy_BDW_MPH_Compatibility")'
    )
    if ($bdwEntryIssues.Count -ne 0 -or
            $bdwEntryDriftSource -eq $bdwEntrySource -or
            @(Get-ZylBetterDealWindowEntryIssues `
                -Source $bdwEntryDriftSource).Count -eq 0) {
        Add-ValidationError 'Integrated deal/map UI helper failed its positive/negative self-test.'
    }
}

# Better Trade Screen Lite owns one complete, criteria-gated trade UI chain.
foreach ($betterTradeIssue in @(Get-ZylBetterTradeScreenContractIssues `
        -ProjectRoot $modRoot `
        -ListedFileMap $listedFileMap `
        -ActionReferenceMap $actionReferenceMap `
        -CriteriaMap $criteriaMap `
        -ActionIdMap $actionIdMap)) {
    Add-ValidationError $betterTradeIssue
}
$betterTradeSupportPath = Join-Path $modRoot 'BTS\UI\TradeSupport.lua'
if (Test-Path -LiteralPath $betterTradeSupportPath -PathType Leaf) {
    $betterTradeSupportSource = Get-Content -LiteralPath $betterTradeSupportPath -Raw
    $betterTradeSupportIssues = @(Get-ZylBetterTradeSupportIssues `
        -Source $betterTradeSupportSource)
    $betterTradeSupportDriftSource = $betterTradeSupportSource.Replace(
        'GetBBGAmaniTradeRouteYieldBonus',
        'GetLegacyAmaniTradeRouteYieldBonus'
    )
    if ($betterTradeSupportIssues.Count -ne 0 -or
            $betterTradeSupportDriftSource -eq $betterTradeSupportSource -or
            @(Get-ZylBetterTradeSupportIssues `
                -Source $betterTradeSupportDriftSource).Count -eq 0) {
        Add-ValidationError 'Better Trade Screen helper failed its positive/negative self-test.'
    }
}

foreach ($remainingUiIssue in @(Get-ZylRemainingUiContractIssues `
        -ProjectRoot $modRoot)) {
    Add-ValidationError $remainingUiIssue
}
$pantheonChooserPath = Join-Path $modRoot 'BPC\UI\PantheonChooser_TPT.lua'
if (Test-Path -LiteralPath $pantheonChooserPath -PathType Leaf) {
    $pantheonChooserSource = Get-Content -LiteralPath $pantheonChooserPath -Raw
    $pantheonChooserIssues = @(Get-ZylPantheonChooserIssues `
        -Source $pantheonChooserSource)
    $pantheonChooserDriftSource = $pantheonChooserSource.Replace(
        'InstanceButton[row.Index]',
        'InstanceButton[row]'
    )
    if ($pantheonChooserIssues.Count -ne 0 -or
            $pantheonChooserDriftSource -eq $pantheonChooserSource -or
            @(Get-ZylPantheonChooserIssues `
                -Source $pantheonChooserDriftSource).Count -eq 0) {
        Add-ValidationError 'Remaining UI helper failed its positive/negative self-test.'
    }
}

# Scan only active runtime text files for dangerous or disabled behavior.
foreach ($runtimeSafetyIssue in @(Get-ZylActiveRuntimeSafetyIssues `
        -ProjectRoot $modRoot `
        -ActionReferenceMap $actionReferenceMap)) {
    Add-ValidationError $runtimeSafetyIssue
}

$descriptionZhNode = $modInfo.SelectSingleNode("/Mod/LocalizedText/Text[@id='LOC_ZYLPVPMOD_DESCRIPTION']/zh_Hans_CN")
if ($null -eq $descriptionZhNode -or $descriptionZhNode.InnerText.Contains('保教')) {
    Add-ValidationError 'The generated Chinese ModInfo description still contains the 保教/保留 typo.'
}

if ($validationErrors.Count -gt 0) {
    foreach ($validationError in $validationErrors) { Write-Error $validationError }
    Write-Host "FAILED: $($validationErrors.Count) validation error(s)." -ForegroundColor Red
    exit 1
}

Write-Host ("PASS: {0} XML artifacts, {1} criteria, {2} actions, {3} listed files, {4} active references, {5} intentionally dormant files and {6} source-only files validated." -f `
    $xmlFiles.Count, $criteriaMap.Count, $actionNodes.Count, $listedFiles.Count, $actionReferenceMap.Count, $intentionallyUnlistedFiles.Count, $sourceOnlyFileCount) -ForegroundColor Green
exit 0
