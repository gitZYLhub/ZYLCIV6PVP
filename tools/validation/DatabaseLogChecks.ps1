function Test-ZylValidRegex {
    param([AllowEmptyString()][string]$Pattern)

    if ([string]::IsNullOrWhiteSpace($Pattern)) {
        return $false
    }
    try {
        [void][regex]::new($Pattern)
        return $true
    }
    catch {
        return $false
    }
}

function Get-ZylDatabaseLogContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Contract,

        [Parameter(Mandatory = $true)]
        [object]$ProjectMetadata
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Contract.schemaVersion -ne 1) {
        $issues.Add('Database.log contract schemaVersion must be 1.')
        return @($issues)
    }
    if ([string]$Contract.packageName -ne [string]$ProjectMetadata.packageName -or
            [string]$Contract.semanticVersion -ne [string]$ProjectMetadata.semanticVersion -or
            [string]$Contract.modId -ne [string]$ProjectMetadata.modId -or
            [string]$Contract.civ6BuildId -ne [string]$ProjectMetadata.civ6SchemaBuildId) {
        $issues.Add('Database.log contract identity drifted from project metadata.')
    }
    if ([int]$Contract.contextRadius -lt 1 -or [int]$Contract.contextRadius -gt 20) {
        $issues.Add('Database.log contract context radius must be from 1 through 20.')
    }

    $markers = @($Contract.requiredMarkers)
    $markerIds = [System.Collections.Generic.List[string]]::new()
    foreach ($marker in $markers) {
        $markerId = [string]$marker.id
        if ([string]::IsNullOrWhiteSpace($markerId) -or $markerIds.Contains($markerId) -or
                [int]$marker.minimumOccurrences -lt 1 -or
                [string]::IsNullOrWhiteSpace([string]$marker.rationale) -or
                -not (Test-ZylValidRegex -Pattern ([string]$marker.regex))) {
            $issues.Add("Database.log contract has an invalid required marker: $markerId")
        }
        else {
            $markerIds.Add($markerId)
        }
    }

    $rules = @($Contract.allowedErrorRules)
    $ruleIds = [System.Collections.Generic.List[string]]::new()
    foreach ($rule in $rules) {
        $ruleId = [string]$rule.id
        $messageRegex = [string]$rule.messageRegex
        $contextFileRegex = [string]$rule.contextFileRegex
        $contextRegexes = @($rule.contextRegexes)
        if ([string]::IsNullOrWhiteSpace($ruleId) -or $ruleIds.Contains($ruleId) -or
                [string]::IsNullOrWhiteSpace([string]$rule.rationale) -or
                [string]$rule.scope -in @('Gameplay', 'Configuration') -or
                $messageRegex -notmatch '^\^.*\$$' -or
                $contextFileRegex -notmatch '^\^.*\$$' -or
                -not [bool]$rule.requireContextFile -or
                $contextRegexes.Count -lt 2 -or
                -not (Test-ZylValidRegex -Pattern $messageRegex) -or
                -not (Test-ZylValidRegex -Pattern $contextFileRegex) -or
                @($contextRegexes | Where-Object {
                        -not (Test-ZylValidRegex -Pattern ([string]$_))
                    }).Count -gt 0) {
            $issues.Add("Database.log contract has an unsafe allowed-error rule: $ruleId")
        }
        else {
            $ruleIds.Add($ruleId)
        }
    }
    if ($markers.Count -eq 0 -or
            [int]$Contract.coverage.requiredMarkers -ne $markers.Count -or
            [int]$Contract.coverage.allowedErrorRules -ne $rules.Count) {
        $issues.Add('Database.log contract coverage metadata drifted.')
    }
    return @($issues)
}
