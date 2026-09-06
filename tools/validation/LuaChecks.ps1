function Get-ZylLuaEventLifecycleIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $registrationCounts = @{}
    foreach ($registration in [regex]::Matches(
        $Source,
        '(?m)(Events|LuaEvents)\.([A-Za-z0-9_]+)\.Add\(\s*([A-Za-z0-9_]+)\s*\)'
    )) {
        $key = "$($registration.Groups[1].Value).$($registration.Groups[2].Value)|$($registration.Groups[3].Value)"
        $registrationCounts[$key] = 1 + [int]$registrationCounts[$key]
    }

    $removalCounts = @{}
    foreach ($removal in [regex]::Matches(
        $Source,
        '(?m)(Events|LuaEvents)\.([A-Za-z0-9_]+)\.Remove\(\s*([A-Za-z0-9_]+)\s*\)'
    )) {
        $key = "$($removal.Groups[1].Value).$($removal.Groups[2].Value)|$($removal.Groups[3].Value)"
        $removalCounts[$key] = 1 + [int]$removalCounts[$key]
    }

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($registrationKey in $registrationCounts.Keys) {
        if ([int]$removalCounts[$registrationKey] -lt [int]$registrationCounts[$registrationKey]) {
            $issues.Add(
                "$Label global event registration has no matching removal: $registrationKey " +
                "(Add $($registrationCounts[$registrationKey]), Remove $([int]$removalCounts[$registrationKey]))."
            )
        }
    }
    return @($issues)
}

function Test-ZylLuaEventLifecycle {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    foreach ($issue in @(Get-ZylLuaEventLifecycleIssues -Source $Source -Label $Label)) {
        Add-ValidationError $issue
    }
}

function Test-ZylLuaHasNoUnguardedPrint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if ([regex]::Matches($Source, '(?m)^\s*print\(').Count -ne 0) {
        Add-ValidationError "$Label contains an unguarded runtime print."
    }
}
