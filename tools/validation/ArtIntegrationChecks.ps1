function Get-ZylArtIntegrationContractIssues {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [object[]]$ActionNodes,

        [Parameter(Mandatory = $true)]
        [object]$ListedFileMap,

        [Parameter(Mandatory = $true)]
        [object]$ActionReferenceMap,

        [AllowNull()]
        [System.Xml.XmlDocument]$DependencyOverride
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    $artActions = @($ActionNodes | Where-Object {
            if ($_.LocalName -ne 'UpdateArt') {
                return $false
            }
            $fileNode = $_.SelectSingleNode('.//File')
            return $null -ne $fileNode -and
                $fileNode.InnerText -ieq 'NaturalWondersMod.dep'
        })
    if ($artActions.Count -ne 1) {
        $issues.Add(
            'Expected exactly one root NaturalWondersMod.dep UpdateArt action; ' +
            "found $($artActions.Count)."
        )
    }

    $dependencyPath = Join-Path $ProjectRoot 'NaturalWondersMod.dep'
    $dependency = if ($PSBoundParameters.ContainsKey('DependencyOverride')) {
        $DependencyOverride
    }
    elseif (Test-Path -LiteralPath $dependencyPath -PathType Leaf) {
        Load-XmlDocument $dependencyPath
    }
    else {
        $null
    }
    if ($null -eq $dependency) {
        $issues.Add('BBM art dependency descriptor is missing: NaturalWondersMod.dep')
    }
    else {
        $artDefNames = @($dependency.SelectNodes(
                '//*[local-name()="ArtDefPath" or ' +
                'local-name()="ArtDefDependencyPaths"]//Element'
            ) | ForEach-Object {
                $_.GetAttribute('text')
            } | Where-Object {
                $_ -like '*.artdef'
            } | Sort-Object -Unique)
        foreach ($artDefName in $artDefNames) {
            $artDefPath = Join-Path $ProjectRoot (Join-Path 'ArtDefs' $artDefName)
            if (-not (Test-Path -LiteralPath $artDefPath -PathType Leaf)) {
                $issues.Add("BBM art definition dependency missing: ArtDefs\$artDefName")
            }
        }

        $packageNames = @($dependency.SelectNodes(
                '//*[local-name()="PackageDependencies"]/Element'
            ) | ForEach-Object {
                $_.GetAttribute('text')
            } | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } | Sort-Object -Unique)
        foreach ($platform in @('Windows', 'MacOS')) {
            foreach ($packageName in $packageNames) {
                $platformPackageName = $packageName.Replace('/', '\')
                $packagePath = Join-Path $ProjectRoot (
                    "Platforms\$platform\BLPs\$platformPackageName"
                )
                if (-not (Test-Path -LiteralPath $packagePath -PathType Leaf)) {
                    $issues.Add("BBM art package dependency missing: $packagePath")
                }
            }
        }
    }

    foreach ($removedReference in @(
            'Components\BBG\sql\DLC_Indonesia_Khmer\_dlc_indo_khmer_utils.sql',
            'Components\BBG\sql\DLC_Indonesia_Khmer\Other.sql',
            'Components\BBG\sql\LP\lp_arabia_saladin_sultan.sql',
            'Components\BBM\Data\BBS_D.lua',
            'Components\BBM\Data\BBS Maps\Utility\BBS_Balance.lua'
        )) {
        $key = Normalize-RelativePath $removedReference
        if ($ListedFileMap.ContainsKey($key) -or
                $ActionReferenceMap.ContainsKey($key)) {
            $issues.Add("Removed upstream reference returned: $removedReference")
        }
    }

    return @($issues)
}
