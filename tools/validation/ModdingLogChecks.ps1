function Get-ZylModdingLogContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Contract,

        [Parameter(Mandatory = $true)]
        [object]$ProjectMetadata
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Contract.schemaVersion -ne 1) {
        $issues.Add('Modding.log contract schemaVersion must be 1.')
        return @($issues)
    }
    if ([string]$Contract.packageName -ne [string]$ProjectMetadata.packageName -or
            [string]$Contract.semanticVersion -ne [string]$ProjectMetadata.semanticVersion -or
            [string]$Contract.modId -ne [string]$ProjectMetadata.modId -or
            [string]$Contract.civ6BuildId -ne [string]$ProjectMetadata.civ6SchemaBuildId) {
        $issues.Add('Modding.log contract identity drifted from project metadata.')
    }
    if ([string]$Contract.expectedFileName -ne 'Modding.log') {
        $issues.Add('Modding.log contract must require the exact Modding.log file name.')
    }
    if ([int]$Contract.minimumLineCount -lt 1 -or
            [int]$Contract.minimumProjectTargetComponents -lt 1 -or
            [int]$Contract.minimumProjectAppliedComponents -lt 1) {
        $issues.Add('Modding.log contract minimum coverage values must be positive.')
    }

    $markers = @($Contract.requiredMarkers)
    $markerIds = [System.Collections.Generic.List[string]]::new()
    foreach ($marker in $markers) {
        $markerId = [string]$marker.id
        $regex = [string]$marker.regex
        if ([string]::IsNullOrWhiteSpace($markerId) -or
                $markerIds.Contains($markerId) -or
                [int]$marker.minimumOccurrences -lt 1 -or
                [string]::IsNullOrWhiteSpace([string]$marker.rationale) -or
                $regex -notmatch '^\^.*\$$' -or
                -not (Test-ZylValidRegex -Pattern $regex)) {
            $issues.Add("Modding.log contract has an invalid required marker: $markerId")
        }
        else {
            $markerIds.Add($markerId)
        }
    }

    $externalRules = @($Contract.externalWarningRules)
    $externalRuleIds = [System.Collections.Generic.List[string]]::new()
    foreach ($rule in $externalRules) {
        $ruleId = [string]$rule.id
        $kind = [string]$rule.kind
        $messageRegex = [string]$rule.messageRegex
        $valid = -not [string]::IsNullOrWhiteSpace($ruleId) -and
            -not $externalRuleIds.Contains($ruleId) -and
            $kind -in @('single', 'paired-path') -and
            -not [string]::IsNullOrWhiteSpace([string]$rule.rationale) -and
            $messageRegex -match '^\^.*\$$' -and
            (Test-ZylValidRegex -Pattern $messageRegex)
        if ($valid -and $kind -eq 'paired-path') {
            $companionRegex = [string]$rule.companionRegex
            $pathRegex = [string]$rule.pathRegex
            $valid = $companionRegex -match '^\^.*\$$' -and
                $pathRegex -match '^\^.*\$$' -and
                $pathRegex -match 'DLC' -and
                (Test-ZylValidRegex -Pattern $companionRegex) -and
                (Test-ZylValidRegex -Pattern $pathRegex)
        }
        if (-not $valid) {
            $issues.Add("Modding.log contract has an unsafe external warning rule: $ruleId")
        }
        else {
            $externalRuleIds.Add($ruleId)
        }
    }

    $componentRules = @($Contract.allowedComponentWarningRules)
    $componentRuleIds = [System.Collections.Generic.List[string]]::new()
    foreach ($rule in $componentRules) {
        $ruleId = [string]$rule.id
        $loadPathRegex = [string]$rule.loadPathRegex
        $messageRegex = [string]$rule.messageRegex
        if ([string]::IsNullOrWhiteSpace($ruleId) -or
                $componentRuleIds.Contains($ruleId) -or
                [string]$rule.ownerModId -eq [string]$ProjectMetadata.modId -or
                [string]::IsNullOrWhiteSpace([string]$rule.ownerModId) -or
                [string]::IsNullOrWhiteSpace([string]$rule.componentId) -or
                [string]::IsNullOrWhiteSpace([string]$rule.operation) -or
                [string]::IsNullOrWhiteSpace([string]$rule.rationale) -or
                $loadPathRegex -notmatch '^\^.*\$$' -or
                $messageRegex -notmatch '^\^.*\$$' -or
                -not (Test-ZylValidRegex -Pattern $loadPathRegex) -or
                -not (Test-ZylValidRegex -Pattern $messageRegex)) {
            $issues.Add("Modding.log contract has an unsafe component warning rule: $ruleId")
        }
        else {
            $componentRuleIds.Add($ruleId)
        }
    }

    if ($markers.Count -eq 0 -or
            [int]$Contract.coverage.requiredMarkers -ne $markers.Count -or
            [int]$Contract.coverage.externalWarningRules -ne $externalRules.Count -or
            [int]$Contract.coverage.allowedComponentWarningRules -ne $componentRules.Count) {
        $issues.Add('Modding.log contract coverage metadata drifted.')
    }
    return @($issues)
}
