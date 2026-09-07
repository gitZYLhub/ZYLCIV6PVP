function Get-ZylPlatformAssetDescriptor {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $normalizedPath = $RelativePath.Trim().Replace('\', '/')
    $platformMatches = [regex]::Matches(
        $normalizedPath,
        '(?<Prefix>(?:^|/)Platforms/)(?<Platform>MacOS|Windows)(?=/|$)',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
    if ($platformMatches.Count -eq 0) {
        return $null
    }
    if ($platformMatches.Count -ne 1) {
        return [pscustomobject]@{
            RelativePath = $normalizedPath
            Platform = $null
            LogicalKey = $null
            MatchCount = $platformMatches.Count
        }
    }

    $platformMatch = $platformMatches[0]
    $platform = if ($platformMatch.Groups['Platform'].Value.Equals(
            'Windows',
            [System.StringComparison]::OrdinalIgnoreCase
        )) { 'windows' } else { 'macos' }
    $logicalKey = (
        $normalizedPath.Substring(0, $platformMatch.Index) +
        $platformMatch.Groups['Prefix'].Value +
        '{PLATFORM}' +
        $normalizedPath.Substring($platformMatch.Index + $platformMatch.Length)
    ).ToLowerInvariant()

    return [pscustomobject]@{
        RelativePath = $normalizedPath
        Platform = $platform
        LogicalKey = $logicalKey
        MatchCount = 1
    }
}

function Test-ZylReleasePathIncluded {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('universal', 'windows', 'macos')]
        [string]$Profile
    )

    $platformAsset = Get-ZylPlatformAssetDescriptor -RelativePath $RelativePath
    if ($null -eq $platformAsset) {
        return $true
    }
    if ($platformAsset.MatchCount -ne 1) {
        return $false
    }
    return $Profile -eq 'universal' -or $platformAsset.Platform -eq $Profile
}

function Get-ZylPlatformAssetPairIssues {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $platformPairs = [System.Collections.Generic.Dictionary[string, object]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($fileNode in @($ModInfo.SelectNodes('/Mod/Files/File'))) {
        $relativePath = $fileNode.InnerText.Trim().Replace('\', '/')
        $platformAsset = Get-ZylPlatformAssetDescriptor -RelativePath $relativePath
        if ($null -eq $platformAsset) {
            continue
        }
        if ($platformAsset.MatchCount -ne 1) {
            $issues.Add("Platform asset path contains more than one platform segment: $relativePath")
            continue
        }

        if (-not $platformPairs.ContainsKey($platformAsset.LogicalKey)) {
            $platformPairs[$platformAsset.LogicalKey] = `
                [System.Collections.Generic.HashSet[string]]::new(
                    [System.StringComparer]::OrdinalIgnoreCase
                )
        }
        if (-not $platformPairs[$platformAsset.LogicalKey].Add($platformAsset.Platform)) {
            $issues.Add("Duplicate $($platformAsset.Platform) platform asset pair member: $relativePath")
        }
    }

    foreach ($pair in $platformPairs.GetEnumerator()) {
        foreach ($requiredPlatform in @('windows', 'macos')) {
            if (-not $pair.Value.Contains($requiredPlatform)) {
                $issues.Add("Platform asset pair is missing $requiredPlatform member: $($pair.Key)")
            }
        }
    }

    foreach ($actionFileNode in @($ModInfo.SelectNodes(
                '/Mod/FrontEndActions/*/File | /Mod/InGameActions/*/File'
            ))) {
        $actionPath = $actionFileNode.InnerText.Trim().Replace('\', '/')
        if ($null -ne (Get-ZylPlatformAssetDescriptor -RelativePath $actionPath)) {
            $issues.Add("ModInfo action directly references a platform-specific asset: $actionPath")
        }
    }

    return @($issues)
}

function Get-ZylPlatformLiteralReferenceIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $lineNumber = 0
    foreach ($line in [regex]::Split($Source, '\r?\n')) {
        $lineNumber++
        if ($line -match '(?i)(?:^|[\\/])Platforms[\\/](?:MacOS|Windows)(?:[\\/]|$)') {
            $issues.Add("Platform-specific literal reference in asset definition ${Label}:$lineNumber")
        }
    }
    return @($issues)
}

function Get-ZylPlatformAssetDefinitionIssues {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ProjectFiles,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $assetDefinitionExtensions = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@('.dep', '.artdef', '.xlp', '.tex', '.mtl', '.anm', '.geo'),
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
    foreach ($assetFile in @($ProjectFiles | Where-Object {
                $assetDefinitionExtensions.Contains($_.Extension)
            })) {
        $relativePath = $assetFile.FullName.Substring($ProjectRoot.Length + 1)
        try {
            $source = $strictUtf8.GetString(
                [System.IO.File]::ReadAllBytes($assetFile.FullName)
            )
        }
        catch {
            $issues.Add("Asset definition cannot be audited as strict UTF-8: $relativePath")
            continue
        }
        foreach ($issue in @(Get-ZylPlatformLiteralReferenceIssues `
                -Source $source `
                -Label $relativePath)) {
            $issues.Add($issue)
        }
    }
    return @($issues)
}

function Get-ZylReleaseBuilderIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredReleaseToken in @(
            "[ValidateSet('universal', 'windows', 'macos')]",
            '. $releaseChecksPath',
            'Test-ZylReleasePathIncluded',
            'function Test-ZylReleaseTextPath',
            'function ConvertTo-ZylReleaseTextBytes',
            '[System.Text.UTF8Encoding]::new($false, $true)',
            '$normalizedText = $text.Replace("`r`n", "`n")',
            '[System.IO.File]::WriteAllBytes($targetPath, $normalizedBytes)',
            'NormalizeText = Test-ZylReleaseTextPath $relativePath',
            '$releaseRelativePaths.Sort([System.StringComparer]::Ordinal)',
            'ConvertTo-Json -Depth 5 -Compress',
            'textNormalization = ''utf8-lf''',
            'profile = $Profile',
            'Release text-normalization helper accepted invalid UTF-8.'
        )) {
        if (-not $Source.Contains($requiredReleaseToken)) {
            $issues.Add("The release builder is missing a required deterministic/profile boundary: $requiredReleaseToken")
        }
    }
    return @($issues)
}
