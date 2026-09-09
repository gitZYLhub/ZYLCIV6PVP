function Get-ZylLuaLogContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Contract,

        [Parameter(Mandatory = $true)]
        [object]$ProjectMetadata
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Contract.schemaVersion -ne 1) {
        $issues.Add('Lua.log contract schemaVersion must be 1.')
        return @($issues)
    }
    if ([string]$Contract.packageName -ne [string]$ProjectMetadata.packageName -or
            [string]$Contract.semanticVersion -ne [string]$ProjectMetadata.semanticVersion -or
            [string]$Contract.modId -ne [string]$ProjectMetadata.modId -or
            [string]$Contract.civ6BuildId -ne [string]$ProjectMetadata.civ6SchemaBuildId) {
        $issues.Add('Lua.log contract identity drifted from project metadata.')
    }
    if ([string]$Contract.expectedFileName -ne 'Lua.log') {
        $issues.Add('Lua.log contract must require the exact Lua.log file name.')
    }
    if ([int]$Contract.minimumLineCount -lt 1) {
        $issues.Add('Lua.log contract minimum line count must be positive.')
    }
    if ([int]$Contract.contextRadius -lt 1 -or [int]$Contract.contextRadius -gt 20) {
        $issues.Add('Lua.log contract context radius must be from 1 through 20.')
    }

    $patterns = @($Contract.fatalPatterns)
    $patternIds = [System.Collections.Generic.List[string]]::new()
    foreach ($pattern in $patterns) {
        $patternId = [string]$pattern.id
        $regex = [string]$pattern.regex
        if ([string]::IsNullOrWhiteSpace($patternId) -or
                $patternIds.Contains($patternId) -or
                [string]::IsNullOrWhiteSpace([string]$pattern.rationale) -or
                $regex -notmatch '^\^.*\$$' -or
                -not (Test-ZylValidRegex -Pattern $regex)) {
            $issues.Add("Lua.log contract has an invalid fatal pattern: $patternId")
        }
        else {
            $patternIds.Add($patternId)
        }
    }
    if ($patterns.Count -eq 0 -or
            [int]$Contract.coverage.fatalPatterns -ne $patterns.Count) {
        $issues.Add('Lua.log contract coverage metadata drifted.')
    }
    return @($issues)
}
