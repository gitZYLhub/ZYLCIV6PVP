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

$upstreamBalanceChecksPath = Join-Path $PSScriptRoot 'validation\UpstreamBalanceChecks.ps1'
if (-not (Test-Path -LiteralPath $upstreamBalanceChecksPath -PathType Leaf)) {
    throw "Upstream balance validation helpers not found: $upstreamBalanceChecksPath"
}
. $upstreamBalanceChecksPath

$finalGameplayChecksPath = Join-Path $PSScriptRoot 'validation\FinalGameplayChecks.ps1'
if (-not (Test-Path -LiteralPath $finalGameplayChecksPath -PathType Leaf)) {
    throw "Final gameplay validation helpers not found: $finalGameplayChecksPath"
}
. $finalGameplayChecksPath

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

# Embedded BBG source adjustments, final override load order and their
# cross-file localization copies form one upstream balance contract.
$upstreamBalanceValidationParameters = @{
    ProjectRoot = $modRoot
    ActionIdMap = $actionIdMap
    ListedFileMap = $listedFileMap
}
$upstreamBalanceIssues = @(
    Get-ZylUpstreamBalanceContractIssues @upstreamBalanceValidationParameters
)
foreach ($issue in $upstreamBalanceIssues) {
    Add-ValidationError $issue
}

# Prove that Mansa Musa's preserved Golden Age route cannot disappear.
$bbgMaliPath = Join-Path $modRoot 'Components\BBG\sql\XP2\Mali.sql'
if (Test-Path -LiteralPath $bbgMaliPath -PathType Leaf) {
    $bbgMaliSource = Get-Content -LiteralPath $bbgMaliPath -Raw
    $bbgMaliDriftSource = $bbgMaliSource.Replace(
        'GOLDEN_AGE_TRADE_ROUTE',
        'GOLDEN_AGE_ROUTE_DRIFT'
    )
    $upstreamBalanceDriftIssues = @(
        Get-ZylUpstreamBalanceContractIssues @upstreamBalanceValidationParameters `
            -MaliSourceOverride $bbgMaliDriftSource
    )
    $expectedUpstreamBalanceDriftIssue =
        'Mansa Musa source does not document preservation of the original Golden Age Trade Route modifier.'
    if ($bbgMaliDriftSource -eq $bbgMaliSource -or
            $upstreamBalanceDriftIssues -notcontains $expectedUpstreamBalanceDriftIssue) {
        Add-ValidationError 'Upstream balance validation self-test did not reject a missing Golden Age route.'
    }
}

# ZYL's late Gameplay SQL owns the final database state after all embedded
# upstream sources have loaded.
$finalGameplayIssues = @(
    Get-ZylFinalGameplayContractIssues -ProjectRoot $modRoot
)
foreach ($issue in $finalGameplayIssues) {
    Add-ValidationError $issue
}

# Prove that a base Housing override cannot disappear from the final layer.
$gameplayOverridePath = Join-Path $modRoot 'sql\ZYL_GameplayOverrides.sql'
if (Test-Path -LiteralPath $gameplayOverridePath -PathType Leaf) {
    $finalGameplaySource = Get-Content -LiteralPath $gameplayOverridePath -Raw
    $finalGameplayDriftSource = $finalGameplaySource.Replace(
        'CITY_POPULATION_NO_WATER',
        'CITY_POPULATION_NO_WATER_DRIFT'
    )
    $finalGameplayDriftIssues = @(
        Get-ZylFinalGameplayContractIssues -ProjectRoot $modRoot `
            -GameplaySourceOverride $finalGameplayDriftSource
    )
    $expectedFinalGameplayDriftIssue = 'No-water city base Housing is not locked to 3.'
    if ($finalGameplayDriftSource -eq $finalGameplaySource -or
            $finalGameplayDriftIssues -notcontains $expectedFinalGameplayDriftIssue) {
        Add-ValidationError 'Final gameplay validation self-test did not reject a missing Housing override.'
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
