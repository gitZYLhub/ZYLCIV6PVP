function Test-ZylManifestSectionsMatch {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlElement]$Expected,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlElement]$Actual
    )

    $expectedJson = ConvertTo-ZylCanonicalJson -InputObject (
        ConvertTo-ZylCanonicalXmlNode -Node $Expected
    )
    $actualJson = ConvertTo-ZylCanonicalJson -InputObject (
        ConvertTo-ZylCanonicalXmlNode -Node $Actual
    )
    return $expectedJson -eq $actualJson
}

function Get-ZylManifestBaselineIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModInfoPath,

        [Parameter(Mandatory = $true)]
        [string]$BaselinePath
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $BaselinePath -PathType Leaf)) {
        $issues.Add('The frozen 1.3.0 ModInfo action-graph fingerprint is missing.')
        return @($issues)
    }

    try {
        $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json
        $actualFingerprint = Get-ZylModInfoActionGraphFingerprint -Path $ModInfoPath
        $document = [System.Xml.XmlDocument]::new()
        $document.PreserveWhitespace = $false
        $document.Load($ModInfoPath)
        $actualCounts = [ordered]@{
            criteria = @($document.SelectNodes('/Mod/ActionCriteria/Criteria')).Count
            frontEndActions = @($document.SelectNodes('/Mod/FrontEndActions/*')).Count
            inGameActions = @($document.SelectNodes('/Mod/InGameActions/*')).Count
            files = @($document.SelectNodes('/Mod/Files/File')).Count
        }
        if ($baseline.schemaVersion -ne 1 -or
                [string]::IsNullOrWhiteSpace([string]$baseline.actionGraphSha256) -or
                $null -eq $baseline.counts) {
            $issues.Add('The frozen ModInfo action-graph fingerprint has an invalid schema.')
            return @($issues)
        }
        if ($actualFingerprint -ne [string]$baseline.actionGraphSha256) {
            $issues.Add(
                "ModInfo action graph differs from the frozen 1.3.0 semantic baseline: " +
                "expected $($baseline.actionGraphSha256), found $actualFingerprint."
            )
        }
        foreach ($countName in $actualCounts.Keys) {
            if ([int]$baseline.counts.$countName -ne $actualCounts[$countName]) {
                $issues.Add(
                    "Frozen ModInfo action-graph count is stale for ${countName}: " +
                    "expected $($baseline.counts.$countName), found $($actualCounts[$countName])."
                )
            }
        }
    }
    catch {
        $issues.Add("Unable to validate the frozen ModInfo action graph: $($_.Exception.Message)")
    }
    return @($issues)
}

function Get-ZylGeneratedManifestSourceIssues {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [Parameter(Mandatory = $true)]
        [string]$CriteriaSourceDirectory,

        [Parameter(Mandatory = $true)]
        [string]$FrontEndActionsSourceDirectory,

        [Parameter(Mandatory = $true)]
        [string]$InGameActionsSourceDirectory,

        [Parameter(Mandatory = $true)]
        [string]$FilesSourceDirectory
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    try {
        $expectedCriteria = New-ZylActionCriteriaSection `
            -OwnerDocument $ModInfo `
            -SourceDirectory $CriteriaSourceDirectory
        $actualCriteria = [System.Xml.XmlElement]$ModInfo.SelectSingleNode('/Mod/ActionCriteria')
        if ($null -eq $actualCriteria) {
            $issues.Add('ModInfo is missing the generated ActionCriteria section.')
        }
        elseif (-not (Test-ZylManifestSectionsMatch -Expected $expectedCriteria -Actual $actualCriteria)) {
            $issues.Add(
                'ModInfo ActionCriteria differs from the domain source fragments; ' +
                'run tools/assemble_modinfo.ps1.'
            )
        }
    }
    catch {
        $issues.Add("Invalid ModInfo Criteria source fragments: $($_.Exception.Message)")
    }

    $actionSources = @(
        [pscustomobject]@{
            SectionName = 'FrontEndActions'
            SourceDirectory = $FrontEndActionsSourceDirectory
        },
        [pscustomobject]@{
            SectionName = 'InGameActions'
            SourceDirectory = $InGameActionsSourceDirectory
        }
    )
    foreach ($actionSource in $actionSources) {
        try {
            $expectedActions = New-ZylActionsSection `
                -OwnerDocument $ModInfo `
                -SectionName $actionSource.SectionName `
                -SourceDirectory $actionSource.SourceDirectory
            $actualActions = [System.Xml.XmlElement]$ModInfo.SelectSingleNode(
                "/Mod/$($actionSource.SectionName)"
            )
            if ($null -eq $actualActions) {
                $issues.Add("ModInfo is missing the generated $($actionSource.SectionName) section.")
            }
            elseif (-not (Test-ZylManifestSectionsMatch -Expected $expectedActions -Actual $actualActions)) {
                $issues.Add(
                    "ModInfo $($actionSource.SectionName) differs from the domain " +
                    'source fragments; run tools/assemble_modinfo.ps1.'
                )
            }
        }
        catch {
            $issues.Add(
                "Invalid ModInfo $($actionSource.SectionName) source fragments: " +
                $_.Exception.Message
            )
        }
    }

    try {
        $expectedFiles = New-ZylFilesSection `
            -OwnerDocument $ModInfo `
            -SourceDirectory $FilesSourceDirectory
        $actualFiles = [System.Xml.XmlElement]$ModInfo.SelectSingleNode('/Mod/Files')
        if ($null -eq $actualFiles) {
            $issues.Add('ModInfo is missing the generated Files section.')
        }
        elseif (-not (Test-ZylManifestSectionsMatch -Expected $expectedFiles -Actual $actualFiles)) {
            $issues.Add(
                'ModInfo Files differs from the domain source fragments; ' +
                'run tools/assemble_modinfo.ps1.'
            )
        }
    }
    catch {
        $issues.Add("Invalid ModInfo Files source fragments: $($_.Exception.Message)")
    }
    return @($issues)
}
