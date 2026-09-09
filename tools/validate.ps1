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

function Invoke-ZylPythonSelfTest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        Add-ValidationError "$Label is missing."
        return
    }
    $pythonCommand = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $pythonCommand) {
        $pythonCommand = Get-Command python3 -ErrorAction SilentlyContinue
    }
    if ($null -eq $pythonCommand) {
        Add-ValidationError "Python 3 is required to self-test $Label."
        return
    }
    $selfTestOutput = @(& $pythonCommand.Source $ScriptPath --self-test 2>&1)
    if ($LASTEXITCODE -ne 0) {
        Add-ValidationError "$Label self-test failed: $($selfTestOutput -join ' ')"
    }
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

$databaseWriteSetPath = Join-Path $PSScriptRoot 'validation\DatabaseWriteSet.ps1'
if (-not (Test-Path -LiteralPath $databaseWriteSetPath -PathType Leaf)) {
    throw "Database write-set helpers not found: $databaseWriteSetPath"
}
. $databaseWriteSetPath

$databaseSchemaChecksPath = Join-Path $PSScriptRoot 'validation\DatabaseSchemaChecks.ps1'
if (-not (Test-Path -LiteralPath $databaseSchemaChecksPath -PathType Leaf)) {
    throw "Database schema snapshot helpers not found: $databaseSchemaChecksPath"
}
. $databaseSchemaChecksPath

$databasePrimaryKeyPath = Join-Path $PSScriptRoot 'validation\DatabasePrimaryKeys.ps1'
if (-not (Test-Path -LiteralPath $databasePrimaryKeyPath -PathType Leaf)) {
    throw "Database primary-key helpers not found: $databasePrimaryKeyPath"
}
. $databasePrimaryKeyPath

$databaseInsertSelectPath = Join-Path $PSScriptRoot 'validation\DatabaseInsertSelects.ps1'
if (-not (Test-Path -LiteralPath $databaseInsertSelectPath -PathType Leaf)) {
    throw "Database INSERT SELECT helpers not found: $databaseInsertSelectPath"
}
. $databaseInsertSelectPath

$databaseFinalValueChecksPath = Join-Path $PSScriptRoot 'validation\DatabaseFinalValueChecks.ps1'
if (-not (Test-Path -LiteralPath $databaseFinalValueChecksPath -PathType Leaf)) {
    throw "Database final-value helpers not found: $databaseFinalValueChecksPath"
}
. $databaseFinalValueChecksPath

$databaseLogChecksPath = Join-Path $PSScriptRoot 'validation\DatabaseLogChecks.ps1'
if (-not (Test-Path -LiteralPath $databaseLogChecksPath -PathType Leaf)) {
    throw "Database.log helpers not found: $databaseLogChecksPath"
}
. $databaseLogChecksPath

$luaLogChecksPath = Join-Path $PSScriptRoot 'validation\LuaLogChecks.ps1'
if (-not (Test-Path -LiteralPath $luaLogChecksPath -PathType Leaf)) {
    throw "Lua.log helpers not found: $luaLogChecksPath"
}
. $luaLogChecksPath

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

$lobbyConfigurationChecksPath = Join-Path $PSScriptRoot 'validation\LobbyConfigurationChecks.ps1'
if (-not (Test-Path -LiteralPath $lobbyConfigurationChecksPath -PathType Leaf)) {
    throw "Lobby configuration validation helpers not found: $lobbyConfigurationChecksPath"
}
. $lobbyConfigurationChecksPath

$artIntegrationChecksPath = Join-Path $PSScriptRoot 'validation\ArtIntegrationChecks.ps1'
if (-not (Test-Path -LiteralPath $artIntegrationChecksPath -PathType Leaf)) {
    throw "Art integration validation helpers not found: $artIntegrationChecksPath"
}
. $artIntegrationChecksPath

$packageIdentityChecksPath = Join-Path $PSScriptRoot 'validation\PackageIdentityChecks.ps1'
if (-not (Test-Path -LiteralPath $packageIdentityChecksPath -PathType Leaf)) {
    throw "Package identity validation helpers not found: $packageIdentityChecksPath"
}
. $packageIdentityChecksPath

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
    -Source @'
local value = GameConfiguration.GetValue("OPTION")
local text = tostring(value)
'@ `
    -Label 'Fixture.lua')
$unsafeRuntimeTextFixture = @(Get-ZylRuntimeTextSafetyIssues -Source @'
loadstring("return 1")
local oldId = "3cd7857e-b720-4a1b-a61d-930f58d5237e"
local legacy = "NO_MORE_STACK"
local unsafeNumber = tonumber(GameConfiguration.GetValue("OPTION"))
local unsafeText = tostring(MapConfiguration.GetValue("OPTION"))
'@ -Label 'Fixture.lua')
if ($safeRuntimeTextFixture.Count -ne 0 -or $unsafeRuntimeTextFixture.Count -ne 5) {
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

$databaseSqlFixture = @'
-- INSERT INTO IgnoredComment VALUES (1);
CREATE TEMPORARY TABLE "Scratch" (Id INTEGER);
INSERT OR REPLACE INTO "Types" (Type) VALUES ('DELETE FROM IgnoredString; -- still text');
UPDATE OR IGNORE ModifierArguments SET Value = 'x' WHERE Name = 'Amount';
DELETE FROM [OldRows] WHERE Id = 1;
INSERT INTO Notes(Text) VALUES ('semi;colon');
DROP TABLE IF EXISTS Scratch;
'@
$databaseSqlFixtureOperations = @(Get-ZylSqlWriteOperations -Source $databaseSqlFixture)
$databaseSqlFixtureSummary = @($databaseSqlFixtureOperations | ForEach-Object {
    $_.operation + ':' + $_.table + ':' + [string]$_.conflictMode
}) -join '|'
$expectedDatabaseSqlFixtureSummary = @(
    'create-table:Scratch:',
    'insert:Types:replace',
    'update:ModifierArguments:ignore',
    'delete:OldRows:',
    'insert:Notes:',
    'drop-table:Scratch:'
) -join '|'
$databaseXmlFixture = [System.Xml.XmlDocument]::new()
$databaseXmlFixture.LoadXml(@'
<GameInfo>
  <Types><Row /><InsertOrIgnore /><Replace /><Update /><Delete /></Types>
</GameInfo>
'@)
$databaseXmlDriftFixture = [System.Xml.XmlDocument]::new()
$databaseXmlDriftFixture.LoadXml('<GameInfo><Types><Merge /></Types></GameInfo>')
$databaseSqlDriftOperations = @(Get-ZylSqlWriteOperations -Source 'UPDATE Broken;')
$databaseXmlFixtureOperations = @(Get-ZylXmlWriteOperations -Document $databaseXmlFixture)
$databaseXmlDriftOperations = @(Get-ZylXmlWriteOperations -Document $databaseXmlDriftFixture)
if ($databaseSqlFixtureSummary -ne $expectedDatabaseSqlFixtureSummary -or
        $databaseXmlFixtureOperations.Count -ne 5 -or
        @($databaseXmlFixtureOperations | Where-Object {
                $_.operation.StartsWith('unknown:', [System.StringComparison]::Ordinal)
            }).Count -ne 0 -or
        $databaseXmlDriftOperations.Count -ne 1 -or
        $databaseXmlDriftOperations[0].operation -ne 'unknown:Merge' -or
        $databaseSqlDriftOperations.Count -ne 1 -or
        $databaseSqlDriftOperations[0].operation -ne 'unknown:update') {
    Add-ValidationError 'Database write-set scanner failed its SQL/XML positive/negative self-test.'
}

$databasePrimaryKeySqlFixture = ConvertFrom-ZylSqlInsertStatement -Statement @'
INSERT OR REPLACE INTO Modifiers (ModifierId, ModifierType, RunOnce)
VALUES ('A,1', 'TYPE_A', 0), ('B', 'TYPE_B', COALESCE(1, 0))
'@
$databasePrimaryKeySelectFixture = ConvertFrom-ZylSqlInsertStatement -Statement @'
INSERT INTO TraitModifiers (TraitType, ModifierId)
SELECT TraitType, 'FIXTURE' FROM CivilizationTraits
'@
$databasePrimaryKeyLiteralFixture = ConvertFrom-ZylSqlLiteral -Text "'it''s stable'"
$databasePrimaryKeyExpressionFixture = ConvertFrom-ZylSqlLiteral -Text 'lower(Type)'
$databasePrimaryKeyCreateFixture = ConvertFrom-ZylSqlCreateTableStatement -Statement @'
CREATE TEMPORARY TABLE IF NOT EXISTS "Fixture" (
    "Id" TEXT PRIMARY KEY,
    Value TEXT,
    UNIQUE(Value),
    FOREIGN KEY(Value) REFERENCES Other(Value)
)
'@
$databasePrimaryKeyRowHashA = Get-ZylDatabaseRowSha256 -Table 'Fixture' -Fields @(
    [pscustomobject]@{ column = 'Id'; kind = 'text'; value = 'A' },
    [pscustomobject]@{ column = 'Value'; kind = 'number'; value = '1' }
)
$databasePrimaryKeyRowHashB = Get-ZylDatabaseRowSha256 -Table 'Fixture' -Fields @(
    [pscustomobject]@{ column = 'Value'; kind = 'number'; value = '1' },
    [pscustomobject]@{ column = 'Id'; kind = 'text'; value = 'A' }
)
$databasePrimaryKeyRowHashDrift = Get-ZylDatabaseRowSha256 -Table 'Fixture' -Fields @(
    [pscustomobject]@{ column = 'Id'; kind = 'text'; value = 'B' },
    [pscustomobject]@{ column = 'Value'; kind = 'number'; value = '1' }
)
if ($databasePrimaryKeySqlFixture.table -ne 'Modifiers' -or
        ($databasePrimaryKeySqlFixture.columns -join '|') -ne
            'ModifierId|ModifierType|RunOnce' -or
        $databasePrimaryKeySqlFixture.rows.Count -ne 2 -or
        $databasePrimaryKeySqlFixture.rows[0].values[0] -ne "'A,1'" -or
        $databasePrimaryKeySqlFixture.rows[1].values[2] -ne 'COALESCE(1, 0)' -or
        $null -ne $databasePrimaryKeySqlFixture.reason -or
        $databasePrimaryKeySelectFixture.reason -ne 'insert-select' -or
        -not $databasePrimaryKeyLiteralFixture.resolved -or
        $databasePrimaryKeyLiteralFixture.value -ne "it's stable" -or
        $databasePrimaryKeyExpressionFixture.resolved -or
        $databasePrimaryKeyCreateFixture.table -ne 'Fixture' -or
        -not $databasePrimaryKeyCreateFixture.temporary -or
        ($databasePrimaryKeyCreateFixture.columns -join '|') -ne 'Id|Value' -or
        ($databasePrimaryKeyCreateFixture.primaryKey -join '|') -ne 'Id' -or
        $null -ne $databasePrimaryKeyCreateFixture.reason -or
        $databasePrimaryKeyRowHashA -ne $databasePrimaryKeyRowHashB -or
        $databasePrimaryKeyRowHashA -eq $databasePrimaryKeyRowHashDrift) {
    Add-ValidationError 'Database primary-key parser failed its positive/negative self-test.'
}

$databaseInsertSelectShapeFixture = Get-ZylSqlInsertSelectShape `
    -TargetTable 'TargetRows' `
    -Statement @'
INSERT INTO TargetRows(Id, Value)
SELECT DISTINCT a.Id, 'FROM fake JOIN fake'
FROM "SourceA" a
LEFT JOIN [SourceB] b ON a.Id = b.Id
WHERE EXISTS (SELECT 1 FROM `SourceC` c WHERE c.Id = a.Id)
UNION SELECT Id, Value FROM TargetRows
'@
$databaseInsertSelectGuardFixture = Get-ZylSqlInsertSelectShape `
    -TargetTable 'TargetRows' `
    -Statement @'
INSERT INTO TargetRows(Id) SELECT 'A' WHERE EXISTS (SELECT 1 FROM ProviderRows)
'@
if ($databaseInsertSelectShapeFixture.shape -ne 'compound' -or
        ($databaseInsertSelectShapeFixture.sourceTables -join '|') -ne
            'SourceA|SourceB|SourceC|TargetRows' -or
        $databaseInsertSelectShapeFixture.selectCount -ne 3 -or
        -not $databaseInsertSelectShapeFixture.hasTopLevelFrom -or
        -not $databaseInsertSelectShapeFixture.hasJoin -or
        -not $databaseInsertSelectShapeFixture.hasWhere -or
        -not $databaseInsertSelectShapeFixture.hasCompound -or
        -not $databaseInsertSelectShapeFixture.hasDistinct -or
        -not $databaseInsertSelectShapeFixture.hasExists -or
        -not $databaseInsertSelectShapeFixture.hasNestedSelect -or
        -not $databaseInsertSelectShapeFixture.readsTargetTable -or
        $databaseInsertSelectGuardFixture.shape -ne 'nested' -or
        $databaseInsertSelectGuardFixture.hasTopLevelFrom -or
        -not $databaseInsertSelectGuardFixture.hasExists -or
        ($databaseInsertSelectGuardFixture.sourceTables -join '|') -ne 'ProviderRows') {
    Add-ValidationError 'Database INSERT SELECT classifier failed its lexical/shape self-test.'
}

$civ6SchemaSnapshotPath = Join-Path $modRoot ([string]$projectMetadata.civ6SchemaSnapshotFile)
if (-not (Test-Path -LiteralPath $civ6SchemaSnapshotPath -PathType Leaf)) {
    Add-ValidationError 'Civ VI schema-key snapshot is missing.'
}
else {
    try {
        $civ6SchemaSnapshotHash = (
            Get-FileHash -LiteralPath $civ6SchemaSnapshotPath -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        if ($civ6SchemaSnapshotHash -ne [string]$projectMetadata.civ6SchemaSnapshotSha256) {
            Add-ValidationError (
                'Civ VI schema-key snapshot hash drifted: ' +
                "$civ6SchemaSnapshotHash (expected $($projectMetadata.civ6SchemaSnapshotSha256))."
            )
        }
        $civ6SchemaSnapshot = Get-Content `
            -LiteralPath $civ6SchemaSnapshotPath `
            -Raw | ConvertFrom-Json
        if ([string]$civ6SchemaSnapshot.civ6BuildId -ne
                [string]$projectMetadata.civ6SchemaBuildId) {
            Add-ValidationError 'Civ VI schema-key snapshot build ID drifted from project metadata.'
        }
        foreach ($schemaSnapshotIssue in @(
                Get-ZylCiv6SchemaSnapshotIssues -Snapshot $civ6SchemaSnapshot
            )) {
            Add-ValidationError $schemaSnapshotIssue
        }
        $civ6SchemaDriftFixture = ConvertFrom-Json (
            $civ6SchemaSnapshot | ConvertTo-Json -Depth 100
        )
        $civ6SchemaDriftFixture.profiles.'gameplay-base'.Modifiers.primaryKey = @(
            '__missing_column__'
        )
        if (@(Get-ZylCiv6SchemaSnapshotIssues -Snapshot $civ6SchemaDriftFixture).Count -eq 0) {
            Add-ValidationError 'Civ VI schema-key snapshot self-test did not reject an invalid primary key.'
        }
    }
    catch {
        Add-ValidationError (
            'Civ VI schema-key snapshot could not be loaded: ' + $_.Exception.Message
        )
    }
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
$databaseWriteSetAnalysis = Get-ZylDatabaseWriteSetAnalysis `
    -ProjectRoot $modRoot `
    -ModInfo $modInfo
foreach ($databaseWriteSetIssue in @($databaseWriteSetAnalysis.issues)) {
    Add-ValidationError $databaseWriteSetIssue
}
if ($null -ne $civ6SchemaSnapshot) {
    $databaseSchemaCoverage = Get-ZylDatabaseSchemaCoverage `
        -Analysis $databaseWriteSetAnalysis `
        -Snapshot $civ6SchemaSnapshot
    $externalDatabaseTablesPath = Join-Path $modRoot 'manifest\external-database-tables.json'
    if (-not (Test-Path -LiteralPath $externalDatabaseTablesPath -PathType Leaf)) {
        Add-ValidationError 'External database-table contract is missing.'
    }
    else {
        try {
            $externalDatabaseTables = Get-Content `
                -LiteralPath $externalDatabaseTablesPath `
                -Raw | ConvertFrom-Json
            foreach ($externalDatabaseTableIssue in @(
                    Get-ZylExternalDatabaseTableIssues `
                        -Analysis $databaseWriteSetAnalysis `
                        -Coverage $databaseSchemaCoverage `
                        -Contract $externalDatabaseTables
                )) {
                Add-ValidationError $externalDatabaseTableIssue
            }
            $externalDatabaseDrift = ConvertFrom-Json (
                $externalDatabaseTables | ConvertTo-Json -Depth 20
            )
            $externalDatabaseDrift.tables[0].table = '__missing_external_table__'
            if (@(Get-ZylExternalDatabaseTableIssues `
                    -Analysis $databaseWriteSetAnalysis `
                    -Coverage $databaseSchemaCoverage `
                    -Contract $externalDatabaseDrift).Count -eq 0) {
                Add-ValidationError 'External database-table self-test did not reject a missing provider table.'
            }
        }
        catch {
            Add-ValidationError (
                'External database-table contract could not be loaded: ' + $_.Exception.Message
            )
        }
    }
    $databasePrimaryKeyAnalysis = Get-ZylDatabasePrimaryKeyAnalysis `
        -ProjectRoot $modRoot `
        -WriteSetAnalysis $databaseWriteSetAnalysis `
        -SchemaCoverage $databaseSchemaCoverage `
        -SchemaSnapshot $civ6SchemaSnapshot
    $databasePrimaryKeySemanticView = Get-ZylDatabasePrimaryKeySemanticView `
        -Analysis $databasePrimaryKeyAnalysis
    $databasePrimaryKeyAnalysisSha256 = Get-ZylSha256ForText -Text (
        ConvertTo-ZylCanonicalJson -InputObject $databasePrimaryKeySemanticView
    )
    $databasePrimaryKeyContractPath = Join-Path $modRoot (
        [string]$projectMetadata.databasePrimaryKeyContractFile
    )
    if (-not (Test-Path -LiteralPath $databasePrimaryKeyContractPath -PathType Leaf)) {
        Add-ValidationError 'Database primary-key contract is missing.'
    }
    else {
        try {
            $databasePrimaryKeyContract = Get-Content `
                -LiteralPath $databasePrimaryKeyContractPath `
                -Raw | ConvertFrom-Json
            foreach ($databasePrimaryKeyContractIssue in @(
                    Get-ZylDatabasePrimaryKeyContractIssues `
                        -Analysis $databasePrimaryKeyAnalysis `
                        -AnalysisSha256 $databasePrimaryKeyAnalysisSha256 `
                        -Contract $databasePrimaryKeyContract
                )) {
                Add-ValidationError $databasePrimaryKeyContractIssue
            }
            $databasePrimaryKeyDriftContract = ConvertFrom-Json (
                $databasePrimaryKeyContract | ConvertTo-Json -Depth 20
            )
            $databasePrimaryKeyDriftContract.expectedAnalysisSha256 = '0' * 64
            $databasePrimaryKeyDriftIssues = @(
                Get-ZylDatabasePrimaryKeyContractIssues `
                    -Analysis $databasePrimaryKeyAnalysis `
                    -AnalysisSha256 $databasePrimaryKeyAnalysisSha256 `
                    -Contract $databasePrimaryKeyDriftContract
            )
            if (@($databasePrimaryKeyDriftIssues | Where-Object {
                        $_ -like 'Database primary-key analysis drifted from expected fingerprint:*'
                    }).Count -ne 1) {
                Add-ValidationError 'Database primary-key self-test did not reject fingerprint drift.'
            }
        }
        catch {
            Add-ValidationError (
                'Database primary-key contract could not be loaded: ' + $_.Exception.Message
            )
        }
    }
    $databaseInsertSelectAnalysis = Get-ZylDatabaseInsertSelectAnalysis `
        -ProjectRoot $modRoot `
        -WriteSetAnalysis $databaseWriteSetAnalysis `
        -PrimaryKeyAnalysis $databasePrimaryKeyAnalysis
    $databaseInsertSelectSemanticView = Get-ZylDatabaseInsertSelectSemanticView `
        -Analysis $databaseInsertSelectAnalysis
    $databaseInsertSelectAnalysisSha256 = Get-ZylSha256ForText -Text (
        ConvertTo-ZylCanonicalJson -InputObject $databaseInsertSelectSemanticView
    )
    $databaseInsertSelectContractPath = Join-Path $modRoot (
        [string]$projectMetadata.databaseInsertSelectContractFile
    )
    if (-not (Test-Path -LiteralPath $databaseInsertSelectContractPath -PathType Leaf)) {
        Add-ValidationError 'Database INSERT SELECT contract is missing.'
    }
    else {
        try {
            $databaseInsertSelectContract = Get-Content `
                -LiteralPath $databaseInsertSelectContractPath `
                -Raw | ConvertFrom-Json
            foreach ($databaseInsertSelectContractIssue in @(
                    Get-ZylDatabaseInsertSelectContractIssues `
                        -Analysis $databaseInsertSelectAnalysis `
                        -AnalysisSha256 $databaseInsertSelectAnalysisSha256 `
                        -Contract $databaseInsertSelectContract
                )) {
                Add-ValidationError $databaseInsertSelectContractIssue
            }
            $databaseInsertSelectDriftContract = ConvertFrom-Json (
                $databaseInsertSelectContract | ConvertTo-Json -Depth 20
            )
            $databaseInsertSelectDriftContract.expectedCounts.statements++
            $databaseInsertSelectDriftIssues = @(
                Get-ZylDatabaseInsertSelectContractIssues `
                    -Analysis $databaseInsertSelectAnalysis `
                    -AnalysisSha256 $databaseInsertSelectAnalysisSha256 `
                    -Contract $databaseInsertSelectDriftContract
            )
            if (@($databaseInsertSelectDriftIssues | Where-Object {
                        $_ -like 'Database INSERT SELECT count drifted for statements:*'
                    }).Count -ne 1) {
                Add-ValidationError 'Database INSERT SELECT self-test did not reject count drift.'
            }
        }
        catch {
            Add-ValidationError (
                'Database INSERT SELECT contract could not be loaded: ' + $_.Exception.Message
            )
        }
    }
    $databaseDuplicateKeyAllowlist = $null
    $databaseDuplicateKeyAllowlistPath = Join-Path $modRoot (
        [string]$projectMetadata.databaseDuplicateKeyAllowlistFile
    )
    if (-not (Test-Path -LiteralPath $databaseDuplicateKeyAllowlistPath -PathType Leaf)) {
        Add-ValidationError 'Database duplicate-key allowlist is missing.'
    }
    else {
        try {
            $databaseDuplicateKeyAllowlist = Get-Content `
                -LiteralPath $databaseDuplicateKeyAllowlistPath `
                -Raw | ConvertFrom-Json
            foreach ($databaseDuplicateKeyAllowlistIssue in @(
                    Get-ZylDatabaseDuplicateKeyAllowlistIssues `
                        -PrimaryKeyAnalysis $databasePrimaryKeyAnalysis `
                        -WriteSetAnalysis $databaseWriteSetAnalysis `
                        -Contract $databaseDuplicateKeyAllowlist
                )) {
                Add-ValidationError $databaseDuplicateKeyAllowlistIssue
            }
            $databaseDuplicateKeyAllowlistDrift = ConvertFrom-Json (
                $databaseDuplicateKeyAllowlist | ConvertTo-Json -Depth 20
            )
            $databaseDuplicateKeyAllowlistDrift.groups[0].keySha256 = '0' * 64
            if (@(Get-ZylDatabaseDuplicateKeyAllowlistIssues `
                    -PrimaryKeyAnalysis $databasePrimaryKeyAnalysis `
                    -WriteSetAnalysis $databaseWriteSetAnalysis `
                    -Contract $databaseDuplicateKeyAllowlistDrift).Count -eq 0) {
                Add-ValidationError 'Database duplicate-key allowlist self-test did not reject key drift.'
            }
        }
        catch {
            Add-ValidationError (
                'Database duplicate-key allowlist could not be loaded: ' + $_.Exception.Message
            )
        }
    }
    $databaseFinalValueContractPath = Join-Path $modRoot (
        [string]$projectMetadata.databaseFinalValueContractFile
    )
    if (-not (Test-Path -LiteralPath $databaseFinalValueContractPath -PathType Leaf)) {
        Add-ValidationError 'Database final-value contract is missing.'
    }
    elseif ($null -eq $databaseDuplicateKeyAllowlist) {
        Add-ValidationError 'Database final-value contract cannot be checked without the duplicate-key allowlist.'
    }
    else {
        try {
            $databaseFinalValueContractHash = (
                Get-FileHash -LiteralPath $databaseFinalValueContractPath -Algorithm SHA256
            ).Hash.ToLowerInvariant()
            if ($databaseFinalValueContractHash -ne
                    [string]$projectMetadata.databaseFinalValueContractSha256) {
                Add-ValidationError (
                    'Database final-value contract hash drifted: ' +
                    "$databaseFinalValueContractHash (expected " +
                    "$($projectMetadata.databaseFinalValueContractSha256))."
                )
            }
            $databaseFinalValueContract = Get-Content `
                -LiteralPath $databaseFinalValueContractPath `
                -Raw | ConvertFrom-Json
            foreach ($databaseFinalValueContractIssue in @(
                    Get-ZylDatabaseFinalValueContractIssues `
                        -Contract $databaseFinalValueContract `
                        -ProjectMetadata $projectMetadata `
                        -DuplicateKeyAllowlist $databaseDuplicateKeyAllowlist
                )) {
                Add-ValidationError $databaseFinalValueContractIssue
            }
            $databaseFinalValueDrift = ConvertFrom-Json (
                $databaseFinalValueContract | ConvertTo-Json -Depth 100
            )
            $databaseFinalValueDrift.profiles[0].probes[0].duplicateKeySha256 = '0' * 64
            if (@(Get-ZylDatabaseFinalValueContractIssues `
                    -Contract $databaseFinalValueDrift `
                    -ProjectMetadata $projectMetadata `
                    -DuplicateKeyAllowlist $databaseDuplicateKeyAllowlist).Count -eq 0) {
                Add-ValidationError 'Database final-value contract self-test did not reject key coverage drift.'
            }
            $databaseFinalValueCapturePath = Join-Path `
                $PSScriptRoot 'database\capture_final_values.py'
            Invoke-ZylPythonSelfTest `
                -ScriptPath $databaseFinalValueCapturePath `
                -Label 'Database final-value capture tool'
        }
        catch {
            Add-ValidationError (
                'Database final-value contract could not be loaded: ' + $_.Exception.Message
            )
        }
    }
}
$databaseLogContractPath = Join-Path $modRoot (
    [string]$projectMetadata.databaseLogContractFile
)
if (-not (Test-Path -LiteralPath $databaseLogContractPath -PathType Leaf)) {
    Add-ValidationError 'Database.log contract is missing.'
}
else {
    try {
        $databaseLogContractHash = (
            Get-FileHash -LiteralPath $databaseLogContractPath -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        if ($databaseLogContractHash -ne [string]$projectMetadata.databaseLogContractSha256) {
            Add-ValidationError (
                'Database.log contract hash drifted: ' +
                "$databaseLogContractHash (expected $($projectMetadata.databaseLogContractSha256))."
            )
        }
        $databaseLogContract = Get-Content `
            -LiteralPath $databaseLogContractPath -Raw | ConvertFrom-Json
        foreach ($databaseLogContractIssue in @(
                Get-ZylDatabaseLogContractIssues `
                    -Contract $databaseLogContract `
                    -ProjectMetadata $projectMetadata
            )) {
            Add-ValidationError $databaseLogContractIssue
        }
        $databaseLogDrift = ConvertFrom-Json (
            $databaseLogContract | ConvertTo-Json -Depth 30
        )
        $databaseLogDrift.allowedErrorRules[0].scope = 'Gameplay'
        if (@(Get-ZylDatabaseLogContractIssues `
                -Contract $databaseLogDrift `
                -ProjectMetadata $projectMetadata).Count -eq 0) {
            Add-ValidationError 'Database.log contract self-test did not reject a Gameplay error allow rule.'
        }
        Invoke-ZylPythonSelfTest `
            -ScriptPath (Join-Path $PSScriptRoot 'logs\audit_database_log.py') `
            -Label 'Database.log audit tool'
    }
    catch {
        Add-ValidationError ('Database.log contract could not be loaded: ' + $_.Exception.Message)
    }
}
$luaLogContractPath = Join-Path $modRoot (
    [string]$projectMetadata.luaLogContractFile
)
if (-not (Test-Path -LiteralPath $luaLogContractPath -PathType Leaf)) {
    Add-ValidationError 'Lua.log contract is missing.'
}
else {
    try {
        $luaLogContractHash = (
            Get-FileHash -LiteralPath $luaLogContractPath -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        if ($luaLogContractHash -ne [string]$projectMetadata.luaLogContractSha256) {
            Add-ValidationError (
                'Lua.log contract hash drifted: ' +
                "$luaLogContractHash (expected $($projectMetadata.luaLogContractSha256))."
            )
        }
        $luaLogContract = Get-Content `
            -LiteralPath $luaLogContractPath -Raw | ConvertFrom-Json
        foreach ($luaLogContractIssue in @(
                Get-ZylLuaLogContractIssues `
                    -Contract $luaLogContract `
                    -ProjectMetadata $projectMetadata
            )) {
            Add-ValidationError $luaLogContractIssue
        }
        $luaLogDrift = ConvertFrom-Json (
            $luaLogContract | ConvertTo-Json -Depth 30
        )
        $luaLogDrift.fatalPatterns[0].regex = '['
        if (@(Get-ZylLuaLogContractIssues `
                -Contract $luaLogDrift `
                -ProjectMetadata $projectMetadata).Count -eq 0) {
            Add-ValidationError 'Lua.log contract self-test did not reject an invalid fatal regex.'
        }
        Invoke-ZylPythonSelfTest `
            -ScriptPath (Join-Path $PSScriptRoot 'logs\audit_lua_log.py') `
            -Label 'Lua.log audit tool'
    }
    catch {
        Add-ValidationError ('Lua.log contract could not be loaded: ' + $_.Exception.Message)
    }
}
$databaseWriteSetContractPath = Join-Path $modRoot 'manifest\database-write-set-contract.json'
if (-not (Test-Path -LiteralPath $databaseWriteSetContractPath -PathType Leaf)) {
    Add-ValidationError 'Database write-set contract is missing.'
}
else {
    try {
        $databaseWriteSetContract = Get-Content `
            -LiteralPath $databaseWriteSetContractPath `
            -Raw | ConvertFrom-Json
        $databaseSemanticView = Get-ZylDatabaseWriteSetSemanticView `
            -Analysis $databaseWriteSetAnalysis
        $databaseAnalysisSha256 = Get-ZylSha256ForText -Text (
            ConvertTo-ZylCanonicalJson -InputObject $databaseSemanticView
        )
        foreach ($databaseWriteSetContractIssue in @(
                Get-ZylDatabaseWriteSetContractIssues `
                    -Analysis $databaseWriteSetAnalysis `
                    -AnalysisSha256 $databaseAnalysisSha256 `
                    -Contract $databaseWriteSetContract
            )) {
            Add-ValidationError $databaseWriteSetContractIssue
        }
        $databaseWriteSetDriftContract = ConvertFrom-Json (
            $databaseWriteSetContract | ConvertTo-Json -Depth 20
        )
        $databaseWriteSetDriftContract.expectedCurrentAnalysisSha256 = '0' * 64
        $databaseWriteSetDriftIssues = @(
            Get-ZylDatabaseWriteSetContractIssues `
                -Analysis $databaseWriteSetAnalysis `
                -AnalysisSha256 $databaseAnalysisSha256 `
                -Contract $databaseWriteSetDriftContract
        )
        if (@($databaseWriteSetDriftIssues | Where-Object {
                    $_ -like 'Database write-set drifted from expected current fingerprint:*'
                }).Count -ne 1) {
            Add-ValidationError 'Database write-set contract self-test did not reject fingerprint drift.'
        }
    }
    catch {
        Add-ValidationError (
            'Database write-set contract could not be loaded: ' + $_.Exception.Message
        )
    }
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
$packageIdentityValidationParameters = @{
    ProjectRoot = $modRoot
    ModInfo = $modInfo
    ExpectedModId = $expectedModId
    ExpectedPackageName = $expectedPackageName
    ExpectedSemanticVersion = $expectedSemanticVersion
    ExpectedModInfoVersion = $expectedModInfoVersion
}
$packageIdentityIssues = @(
    Get-ZylPackageIdentityContractIssues @packageIdentityValidationParameters
)
foreach ($issue in $packageIdentityIssues) {
    Add-ValidationError $issue
}

# Prove that the multiplayer handshake cannot drift from project metadata.
$multiplayerHelperPath = Join-Path $modRoot 'data\MP_helper.lua'
if (Test-Path -LiteralPath $multiplayerHelperPath -PathType Leaf) {
    $multiplayerHelperSource = Get-Content -LiteralPath $multiplayerHelperPath -Raw
    $expectedHandshake = "local g_version = `"$expectedPackageName v$expectedSemanticVersion`""
    $multiplayerHelperDrift = $multiplayerHelperSource.Replace(
        $expectedHandshake,
        'local g_version = "ZYLPVPMOD vDRIFT"'
    )
    $packageIdentityDriftIssues = @(
        Get-ZylPackageIdentityContractIssues @packageIdentityValidationParameters `
            -MultiplayerHelperSourceOverride $multiplayerHelperDrift
    )
    $expectedHandshakeDriftIssue =
        "The multiplayer version handshake must identify " +
        "$expectedPackageName v$expectedSemanticVersion."
    if ($multiplayerHelperDrift -eq $multiplayerHelperSource -or
            $packageIdentityDriftIssues -notcontains $expectedHandshakeDriftIssue) {
        Add-ValidationError 'Package identity self-test did not reject a handshake drift.'
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
$zylConfig = $null
if (Test-Path -LiteralPath $zylConfigPath -PathType Leaf) {
    $zylConfig = Load-XmlDocument $zylConfigPath
}

$lobbyConfigurationValidationParameters = @{
    ProjectRoot = $modRoot
    ModInfo = $modInfo
    ActionIdMap = $actionIdMap
    ZylConfig = $zylConfig
}
$lobbyConfigurationIssues = @(
    Get-ZylLobbyConfigurationContractIssues @lobbyConfigurationValidationParameters
)
foreach ($issue in $lobbyConfigurationIssues) {
    Add-ValidationError $issue
}

# Prove that a final lobby default cannot silently drift.
$lobbyDefaultsPath = Join-Path $modRoot 'configuration\ZYL_LobbyDefaults.xml'
if (Test-Path -LiteralPath $lobbyDefaultsPath -PathType Leaf) {
    $lobbyDefaultsDrift = Load-XmlDocument $lobbyDefaultsPath
    $smartTimerDefaultNode = $lobbyDefaultsDrift.SelectSingleNode(
        '/GameInfo/Parameters/Update[Where/@ParameterId="CPL_SMARTTIMER"]/Set'
    )
    if ($null -eq $smartTimerDefaultNode) {
        Add-ValidationError 'Lobby configuration self-test fixture is missing CPL_SMARTTIMER.'
    }
    else {
        $smartTimerDefaultNode.SetAttribute('DefaultValue', '8')
        $lobbyDefaultDriftIssues = @(
            Get-ZylLobbyConfigurationContractIssues @lobbyConfigurationValidationParameters `
                -LobbyDefaultsOverride $lobbyDefaultsDrift
        )
        if ($lobbyDefaultDriftIssues -notcontains
                'Final lobby default CPL_SMARTTIMER must be 9.') {
            Add-ValidationError 'Lobby configuration self-test did not reject a default drift.'
        }
    }
}

# Keep the turn-processing limit helper covered through the extracted contract.
$turnProcessingPath = Join-Path $modRoot 'ui\Additions\TurnProcessing.lua'
if (Test-Path -LiteralPath $turnProcessingPath -PathType Leaf) {
    $turnProcessingSource = Get-Content -Raw -LiteralPath $turnProcessingPath
    $turnProcessingDriftSource = $turnProcessingSource.Replace(
        'if g_timeCommandUses >= MAX_TIME_EXTENSIONS_PER_TURN then return end',
        'if false then return end'
    )
    $turnProcessingDriftIssues = @(
        Get-ZylLobbyConfigurationContractIssues @lobbyConfigurationValidationParameters `
            -TurnProcessingSourceOverride $turnProcessingDriftSource
    )
    $expectedTurnProcessingDriftIssue =
        'P++ per-turn limit logic is missing: ' +
        'if g_timeCommandUses >= MAX_TIME_EXTENSIONS_PER_TURN then return end'
    if ($turnProcessingDriftSource -eq $turnProcessingSource -or
            $turnProcessingDriftIssues -notcontains $expectedTurnProcessingDriftIssue) {
        Add-ValidationError 'Lobby configuration self-test did not reject a timer-limit drift.'
    }
}

if ($null -ne $zylConfig) {
    foreach ($identityIssue in @(Get-ZylIdentityContractIssues `
            -ProjectRoot $modRoot `
            -ConfigurationXml $zylConfig `
            -ListedFileMap $listedFileMap `
            -ActionIdMap $actionIdMap)) {
        Add-ValidationError $identityIssue
    }
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
    $startingBonusNoValueDriftSource = $startingBonusScriptSource.Replace(
        'tonumber(selectedBonusValue)',
        'tonumber(GameConfiguration.GetValue(BONUS_OPTION))'
    )
    $startingBonusNoValueDriftIssues = @(
        Get-ZylStartingBonusContractIssues @startingBonusValidationParameters `
            -StartingBonusScriptOverride $startingBonusNoValueDriftSource
    )
    $expectedStartingBonusNoValueIssue =
        'Starting-player bonus options must be captured before tonumber; ' +
        'an unset Civ VI option can return no values and cause a zero-argument call.'
    if ($startingBonusNoValueDriftSource -eq $startingBonusScriptSource -or
            $startingBonusNoValueDriftIssues -notcontains $expectedStartingBonusNoValueIssue) {
        Add-ValidationError 'Starting bonus validation self-test did not reject an unsafe option conversion.'
    }
}

foreach ($multiplayerUiIssue in @(Get-ZylMultiplayerUiRuntimeContractIssues `
        -ProjectRoot $modRoot)) {
    Add-ValidationError $multiplayerUiIssue
}
foreach ($multiplayerUiSelfTestIssue in @(
        Get-ZylMultiplayerUiRuntimeSelfTestIssues -ProjectRoot $modRoot
    )) {
    Add-ValidationError $multiplayerUiSelfTestIssue
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

# BBM's root dependency, ArtDefs, platform packages and removed upstream
# references form one art-loading compatibility boundary.
$artIntegrationValidationParameters = @{
    ProjectRoot = $modRoot
    ActionNodes = @($actionNodes)
    ListedFileMap = $listedFileMap
    ActionReferenceMap = $actionReferenceMap
}
$artIntegrationIssues = @(
    Get-ZylArtIntegrationContractIssues @artIntegrationValidationParameters
)
foreach ($issue in $artIntegrationIssues) {
    Add-ValidationError $issue
}

# Prove that a dependency descriptor cannot point at a missing ArtDef.
$bbmDependencyPath = Join-Path $modRoot 'NaturalWondersMod.dep'
if (Test-Path -LiteralPath $bbmDependencyPath -PathType Leaf) {
    $bbmDependencyDrift = Load-XmlDocument $bbmDependencyPath
    $bbmArtDefDriftNode = $bbmDependencyDrift.SelectSingleNode(
        '//*[local-name()="ArtDefPath" or ' +
        'local-name()="ArtDefDependencyPaths"]//Element[@text][1]'
    )
    if ($null -eq $bbmArtDefDriftNode) {
        Add-ValidationError 'Art integration self-test fixture has no ArtDef dependency.'
    }
    else {
        $bbmArtDefDriftNode.SetAttribute('text', '__selftest_missing__.artdef')
        $artIntegrationDriftIssues = @(
            Get-ZylArtIntegrationContractIssues @artIntegrationValidationParameters `
                -DependencyOverride $bbmDependencyDrift
        )
        if ($artIntegrationDriftIssues -notcontains
                'BBM art definition dependency missing: ArtDefs\__selftest_missing__.artdef') {
            Add-ValidationError 'Art integration self-test did not reject a missing ArtDef.'
        }
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

if ($validationErrors.Count -gt 0) {
    foreach ($validationError in $validationErrors) { Write-Error $validationError }
    Write-Host "FAILED: $($validationErrors.Count) validation error(s)." -ForegroundColor Red
    exit 1
}

Write-Host ("PASS: {0} XML artifacts, {1} criteria, {2} actions, {3} listed files, {4} active references, {5} intentionally dormant files and {6} source-only files validated." -f `
    $xmlFiles.Count, $criteriaMap.Count, $actionNodes.Count, $listedFiles.Count, $actionReferenceMap.Count, $intentionallyUnlistedFiles.Count, $sourceOnlyFileCount) -ForegroundColor Green
exit 0
