function Normalize-RelativePath {
    param([string]$Path)

    return $Path.Trim().Replace('/', '\').ToLowerInvariant()
}

function Test-IsSourceOnlyFile {
    param([string]$NormalizedPath)

    if ($NormalizedPath.StartsWith('docs\') -or
            $NormalizedPath.StartsWith('.github\') -or
            $NormalizedPath.StartsWith('tools\') -or
            $NormalizedPath.StartsWith('manifest\')) {
        return $true
    }
    return $NormalizedPath -in @(
        '.gitattributes',
        '.gitignore',
        'changelog.md',
        'zylpvpmod1.3.0修改大全.md'
    )
}

function Test-IsGeneratedProjectPath {
    param([string]$NormalizedPath)

    return $NormalizedPath.StartsWith('.git\') -or
        $NormalizedPath.StartsWith('artifacts\') -or
        $NormalizedPath.StartsWith('build\') -or
        $NormalizedPath.StartsWith('dist\')
}

function Load-XmlDocument {
    param([string]$Path)

    $document = [System.Xml.XmlDocument]::new()
    $document.PreserveWhitespace = $false
    $document.Load($Path)
    return $document
}

function Get-ZylProjectFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return @(Get-ChildItem -LiteralPath $ProjectRoot -Recurse -Force -File | Where-Object {
        $relativePath = $_.FullName.Substring($ProjectRoot.Length + 1)
        -not (Test-IsGeneratedProjectPath (Normalize-RelativePath $relativePath))
    })
}

function Get-ZylWorkshopCacheReferenceIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $forbiddenPattern = '(?i)steamapps[\\/]+workshop(?:[\\/]|$)'
    $lineNumber = 0
    foreach ($line in [regex]::Split($Source, '\r?\n')) {
        $lineNumber++
        if ($line -match $forbiddenPattern) {
            $issues.Add("Forbidden Steam Workshop content path in maintenance script ${Label}:$lineNumber")
        }
    }
    return @($issues)
}

function Get-ZylProjectBoundaryIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ProjectFiles,

        [Parameter(Mandatory = $true)]
        [string]$ValidatorPath,

        [Parameter(Mandatory = $true)]
        [string]$AssemblerPath,

        [Parameter(Mandatory = $true)]
        [string]$ReleaseBuilderPath
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $maintenanceScripts = @($ProjectFiles | Where-Object {
        $_.Extension -in @('.ps1', '.psm1', '.py', '.bat', '.cmd', '.sh', '.lua') -and
            $_.FullName -ne $ValidatorPath
    })
    foreach ($maintenanceScript in $maintenanceScripts) {
        $relativeScriptPath = $maintenanceScript.FullName.Substring($ProjectRoot.Length + 1)
        $source = Get-Content -LiteralPath $maintenanceScript.FullName -Raw
        foreach ($issue in @(Get-ZylWorkshopCacheReferenceIssues `
                -Source $source `
                -Label $relativeScriptPath)) {
            $issues.Add($issue)
        }
    }

    if (-not (Test-Path -LiteralPath $AssemblerPath -PathType Leaf)) {
        $issues.Add('The local-only ModInfo assembler is missing.')
        return @($issues)
    }
    $assemblerSource = Get-Content -LiteralPath $AssemblerPath -Raw
    foreach ($requiredBoundaryToken in @(
        '$projectMetadataPath = Join-Path $PSScriptRoot ''project.json''',
        '$manifestSourcesPath = Join-Path $PSScriptRoot ''manifest\ManifestSources.ps1''',
        '$modInfoPath = Join-Path $modRoot ([string]$projectMetadata.modInfoFile)',
        'function Resolve-ProjectFile',
        'Sync-ActionCriteria $modInfo',
        "-SectionName 'FrontEndActions'",
        "-SectionName 'InGameActions'",
        'Sync-FilesSection $modInfo',
        '$fullPath.StartsWith($modRootPrefix',
        'Manifest path escapes the project root'
    )) {
        if (-not $assemblerSource.Contains($requiredBoundaryToken)) {
            $issues.Add("The ModInfo assembler is missing its project-local input boundary: $requiredBoundaryToken")
        }
    }

    if (-not (Test-Path -LiteralPath $ReleaseBuilderPath -PathType Leaf)) {
        $issues.Add('The deterministic release builder is missing.')
        return @($issues)
    }
    $releaseBuilderSource = Get-Content -LiteralPath $ReleaseBuilderPath -Raw
    foreach ($requiredReleaseToken in @(
        'function Test-ZylReleaseTextPath',
        'function ConvertTo-ZylReleaseTextBytes',
        '[System.Text.UTF8Encoding]::new($false, $true)',
        '$normalizedText = $text.Replace("`r`n", "`n")',
        '[System.IO.File]::WriteAllBytes($targetPath, $normalizedBytes)',
        'NormalizeText = Test-ZylReleaseTextPath $relativePath',
        '$releaseRelativePaths.Sort([System.StringComparer]::Ordinal)',
        'ConvertTo-Json -Depth 5 -Compress',
        "textNormalization = 'utf8-lf'",
        'Release text-normalization helper accepted invalid UTF-8.'
    )) {
        if (-not $releaseBuilderSource.Contains($requiredReleaseToken)) {
            $issues.Add(
                "The release builder is missing deterministic text normalization: $requiredReleaseToken"
            )
        }
    }
    return @($issues)
}

function Get-ZylXmlArtifactIssues {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$XmlFiles
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($xmlFile in $XmlFiles) {
        try {
            [void](Load-XmlDocument $xmlFile.FullName)
        }
        catch {
            $issues.Add("Invalid XML: $($xmlFile.FullName) :: $($_.Exception.Message)")
        }
    }
    return @($issues)
}
