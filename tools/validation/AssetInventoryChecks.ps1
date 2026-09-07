function Get-ZylDuplicateNormalizedPaths {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    $seen = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $duplicates = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $Paths) {
        $normalizedPath = Normalize-RelativePath $path
        if (-not $seen.Add($normalizedPath)) {
            $duplicates.Add($path)
        }
    }
    return @($duplicates)
}

function Get-ZylAssetInventory {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$ModInfo,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo[]]$ProjectFiles,

        [Parameter(Mandatory = $true)]
        [string]$ModInfoPath,

        [Parameter(Mandatory = $true)]
        [string]$DormantFileListPath
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $listedFiles = [System.Collections.Generic.List[string]]::new()
    $listedFileMap = @{}
    foreach ($fileNode in @($ModInfo.SelectNodes('/Mod/Files/File'))) {
        $relativePath = $fileNode.InnerText.Trim().Replace('/', '\')
        $key = Normalize-RelativePath $relativePath
        if ($listedFileMap.ContainsKey($key)) {
            $issues.Add("Duplicate <Files> entry (case-insensitive): $relativePath")
        }
        else {
            $listedFileMap[$key] = $relativePath
            $listedFiles.Add($relativePath)
        }
    }
    foreach ($relativePath in $listedFiles) {
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativePath))) {
            $issues.Add("Listed file missing on disk: $relativePath")
        }
    }

    $intentionallyUnlistedFiles = [System.Collections.Generic.List[string]]::new()
    $intentionallyUnlistedMap = @{}
    if (-not (Test-Path -LiteralPath $DormantFileListPath -PathType Leaf)) {
        $issues.Add("Dormant-file allowlist is missing: $DormantFileListPath")
    }
    else {
        foreach ($line in Get-Content -LiteralPath $DormantFileListPath) {
            $relativePath = $line.Trim()
            if ([string]::IsNullOrWhiteSpace($relativePath) -or $relativePath.StartsWith('#')) {
                continue
            }
            $key = Normalize-RelativePath $relativePath
            if ($intentionallyUnlistedMap.ContainsKey($key)) {
                $issues.Add("Duplicate dormant-file allowlist entry: $relativePath")
                continue
            }
            $intentionallyUnlistedMap[$key] = $relativePath
            $intentionallyUnlistedFiles.Add($relativePath)
        }
    }

    $sourceOnlyFileCount = 0
    foreach ($diskFile in $ProjectFiles) {
        if ($diskFile.FullName -eq $ModInfoPath) {
            continue
        }
        $relativePath = $diskFile.FullName.Substring($ProjectRoot.Length + 1)
        $key = Normalize-RelativePath $relativePath
        if (Test-IsSourceOnlyFile $key) {
            $sourceOnlyFileCount++
            continue
        }
        if (-not $listedFileMap.ContainsKey($key) -and
                -not $intentionallyUnlistedMap.ContainsKey($key)) {
            $issues.Add(
                "File exists on disk but is absent from <Files> and the dormant allowlist: $relativePath"
            )
        }
    }
    foreach ($key in $intentionallyUnlistedMap.Keys) {
        $relativePath = $intentionallyUnlistedMap[$key]
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativePath))) {
            $issues.Add("Dormant-file allowlist entry no longer exists; remove or update it: $relativePath")
        }
        if ($listedFileMap.ContainsKey($key)) {
            $issues.Add("A deliberately dormant/conflicting file was added to <Files>: $relativePath")
        }
    }

    $actionNodes = @(
        $ModInfo.SelectNodes('/Mod/FrontEndActions/*') |
            Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
        $ModInfo.SelectNodes('/Mod/InGameActions/*') |
            Where-Object { $_.NodeType -eq [System.Xml.XmlNodeType]::Element }
    )
    $actionIdMap = @{}
    foreach ($actionNode in $actionNodes) {
        $actionId = $actionNode.GetAttribute('id')
        if ([string]::IsNullOrWhiteSpace($actionId)) {
            $issues.Add("Action without id: $($actionNode.OuterXml)")
            continue
        }
        $actionKey = $actionId.ToLowerInvariant()
        if ($actionIdMap.ContainsKey($actionKey)) {
            $issues.Add("Duplicate action id: $actionId")
        }
        else {
            $actionIdMap[$actionKey] = $actionNode
        }
    }

    foreach ($updateArtAction in @($actionNodes | Where-Object { $_.LocalName -eq 'UpdateArt' })) {
        foreach ($fileNode in @($updateArtAction.SelectNodes('.//File'))) {
            if ([System.IO.Path]::GetExtension($fileNode.InnerText.Trim()) -ieq '.artdef') {
                $issues.Add(
                    "UpdateArt action $($updateArtAction.GetAttribute('id')) directly loads an ArtDef " +
                    "instead of a .dep manifest: $($fileNode.InnerText.Trim())"
                )
            }
        }
    }

    $criteriaMap = @{}
    foreach ($criteriaNode in @($ModInfo.SelectNodes('/Mod/ActionCriteria/Criteria'))) {
        $criteriaId = $criteriaNode.GetAttribute('id')
        if ([string]::IsNullOrWhiteSpace($criteriaId)) {
            $issues.Add("Criteria without id: $($criteriaNode.OuterXml)")
            continue
        }
        $criteriaKey = $criteriaId.ToLowerInvariant()
        if ($criteriaMap.ContainsKey($criteriaKey)) {
            $issues.Add("Duplicate criteria id: $criteriaId")
        }
        else {
            $criteriaMap[$criteriaKey] = $criteriaNode
        }
    }
    foreach ($actionNode in $actionNodes) {
        $criteriaReferences = [System.Collections.Generic.List[string]]::new()
        foreach ($criteriaNode in @($actionNode.SelectNodes('./Criteria'))) {
            $criteriaReferences.Add($criteriaNode.InnerText.Trim())
        }
        foreach ($attributeName in @('criteria', 'Criteria')) {
            if ($actionNode.HasAttribute($attributeName)) {
                $criteriaReferences.Add($actionNode.GetAttribute($attributeName).Trim())
            }
        }
        foreach ($criteriaReference in $criteriaReferences) {
            if (-not $criteriaMap.ContainsKey($criteriaReference.ToLowerInvariant())) {
                $issues.Add(
                    "Unknown criteria '$criteriaReference' in action '$($actionNode.GetAttribute('id'))'."
                )
            }
        }
    }

    $actionReferenceMap = @{}
    foreach ($actionNode in $actionNodes) {
        foreach ($referenceNode in @(
                $actionNode.SelectNodes('.//File') + $actionNode.SelectNodes('.//LuaReplace')
            )) {
            $relativePath = $referenceNode.InnerText.Trim().Replace('/', '\')
            $actionReferenceMap[(Normalize-RelativePath $relativePath)] = $relativePath
        }
    }
    # AddUserInterfaces loads a same-named Lua file beside its XML when present.
    foreach ($actionNode in @($actionNodes | Where-Object { $_.LocalName -eq 'AddUserInterfaces' })) {
        foreach ($fileNode in @($actionNode.SelectNodes('.//File'))) {
            if ($fileNode.InnerText -notlike '*.xml') {
                continue
            }
            $pairedLua = [System.IO.Path]::ChangeExtension(
                $fileNode.InnerText.Trim(),
                '.lua'
            ).Replace('/', '\')
            if (Test-Path -LiteralPath (Join-Path $ProjectRoot $pairedLua)) {
                $actionReferenceMap[(Normalize-RelativePath $pairedLua)] = $pairedLua
            }
        }
    }
    foreach ($key in @($actionReferenceMap.Keys | Sort-Object)) {
        $relativePath = $actionReferenceMap[$key]
        if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativePath))) {
            $issues.Add("Action reference missing on disk: $relativePath")
        }
        if (-not $listedFileMap.ContainsKey($key)) {
            $issues.Add("Action reference absent from <Files>: $relativePath")
        }
    }

    return [pscustomobject]@{
        Issues = @($issues)
        ListedFiles = @($listedFiles)
        ListedFileMap = $listedFileMap
        IntentionallyUnlistedFiles = @($intentionallyUnlistedFiles)
        IntentionallyUnlistedMap = $intentionallyUnlistedMap
        SourceOnlyFileCount = $sourceOnlyFileCount
        ActionNodes = @($actionNodes)
        ActionIdMap = $actionIdMap
        CriteriaMap = $criteriaMap
        ActionReferenceMap = $actionReferenceMap
    }
}
