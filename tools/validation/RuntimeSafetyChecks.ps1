function Get-ZylRuntimeTextSafetyIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $dangerPatterns = @(
        @{ Name = 'dynamic loadstring'; Pattern = 'loadstring\s*\(' },
        @{ Name = 'Workshop auto-update'; Pattern = 'Modding\.UpdateSubscription\s*\(' },
        @{
            Name = 'zero-argument strict configuration conversion'
            Pattern = '(?:tonumber|tostring)\s*\(\s*(?:GameConfiguration|MapConfiguration|UserConfiguration)\.GetValue\s*\('
        },
        @{
            Name = 'unguarded configuration numeric use'
            Pattern = '(?:(?:GameConfiguration|MapConfiguration|UserConfiguration)\.GetValue\s*\([^)]*\)\s*(?:\+|-(?!-)|\*|/|%|[<>]=?)|(?:\+|(?<!-)-(?!-)|\*|/|%|[<>]=?)\s*(?:GameConfiguration|MapConfiguration|UserConfiguration)\.GetValue\s*\(|(?:GetRandom|math\.randomseed)\s*\([^\r\n]*(?:GameConfiguration|MapConfiguration|UserConfiguration)\.GetValue\s*\()'
        },
        @{ Name = 'science/culture anti-stacking'; Pattern = 'NoMoreStack|NO_MORE_STACK' }
    )
    $oldRuntimeIds = @(
        '3cd7857e-b720-4a1b-a61d-930f58d5237e',
        'cb84075d-5007-4207-b662-c35a5f7be260',
        'cb84075d-5007-4207-b662-c35a5f7be250',
        'cb84075d-5007-4207-b662-c35a5f7be254',
        'c88cba8b-8311-4d35-90c3-51a4a5d66542',
        'c88cba8b-8311-4d35-90c3-51a4a5d66550',
        '619ac86e-d99d-4bf3-b8f0-8c5b8c402567',
        '00000000-0165-224C-A3AA-154BB4B9C1C5'
    )
    $lineNumber = 0
    foreach ($line in [regex]::Split($Source, '\r?\n')) {
        $lineNumber++
        foreach ($dangerPattern in $dangerPatterns) {
            if ($line -match $dangerPattern.Pattern) {
                $issues.Add("$($dangerPattern.Name) in active file ${Label}:$lineNumber")
            }
        }
        foreach ($oldId in $oldRuntimeIds) {
            if ($line.Contains($oldId)) {
                $issues.Add("Old component Mod ID in active runtime file ${Label}:${lineNumber}: $oldId")
            }
        }
    }
    return @($issues)
}

function Get-ZylActiveRuntimeSafetyIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [hashtable]$ActionReferenceMap
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($key in @($ActionReferenceMap.Keys | Sort-Object)) {
        $relativePath = $ActionReferenceMap[$key]
        if ([System.IO.Path]::GetExtension($relativePath) -notin @('.lua', '.sql', '.xml')) {
            continue
        }
        $fullPath = Join-Path $ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }
        $source = Get-Content -LiteralPath $fullPath -Raw
        foreach ($issue in @(Get-ZylRuntimeTextSafetyIssues `
                -Source $source `
                -Label $relativePath)) {
            $issues.Add($issue)
        }
    }
    return @($issues)
}
