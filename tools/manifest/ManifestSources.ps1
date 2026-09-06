function Get-ZylOrderedManifestElements {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,

        [Parameter(Mandatory = $true)]
        [string]$FragmentRootName,

        [Parameter(Mandatory = $true)]
        [string]$ElementName
    )

    if (-not (Test-Path -LiteralPath $SourceDirectory -PathType Container)) {
        throw "Manifest source directory not found: $SourceDirectory"
    }

    $records = [System.Collections.Generic.List[object]]::new()
    $orders = [System.Collections.Generic.HashSet[int]]::new()
    $identifiers = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $fragmentFiles = @(Get-ChildItem -LiteralPath $SourceDirectory -Filter '*.xml' -File | Sort-Object Name)
    if ($fragmentFiles.Count -eq 0) {
        throw "Manifest source directory contains no XML fragments: $SourceDirectory"
    }

    foreach ($fragmentFile in $fragmentFiles) {
        $document = [System.Xml.XmlDocument]::new()
        $document.PreserveWhitespace = $false
        $document.Load($fragmentFile.FullName)
        $root = [System.Xml.XmlElement]$document.DocumentElement
        if ($root.LocalName -ne $FragmentRootName -or $root.GetAttribute('schemaVersion') -ne '1') {
            throw "Invalid manifest fragment root/schema: $($fragmentFile.FullName)"
        }
        $domain = $root.GetAttribute('domain')
        if ([string]::IsNullOrWhiteSpace($domain)) {
            throw "Manifest fragment has no domain: $($fragmentFile.FullName)"
        }

        foreach ($element in @($root.ChildNodes | Where-Object NodeType -eq Element)) {
            if ($element.LocalName -ne $ElementName) {
                throw "Unexpected element $($element.LocalName) in $($fragmentFile.FullName); expected $ElementName."
            }
            $orderText = $element.GetAttribute('manifestOrder')
            $order = 0
            if (-not [int]::TryParse($orderText, [ref]$order) -or $order -lt 1) {
                throw "Invalid manifestOrder '$orderText' in $($fragmentFile.FullName)."
            }
            if (-not $orders.Add($order)) {
                throw "Duplicate manifestOrder $order in $SourceDirectory."
            }
            $identifier = $element.GetAttribute('id')
            if ([string]::IsNullOrWhiteSpace($identifier) -or -not $identifiers.Add($identifier)) {
                throw "Missing or duplicate $ElementName id '$identifier' in $SourceDirectory."
            }
            $records.Add([pscustomobject][ordered]@{
                Order = $order
                Domain = $domain
                Source = $fragmentFile.FullName
                Element = $element
            })
        }
    }

    $orderedRecords = @($records | Sort-Object Order)
    for ($index = 0; $index -lt $orderedRecords.Count; $index++) {
        $expectedOrder = $index + 1
        if ($orderedRecords[$index].Order -ne $expectedOrder) {
            throw "Manifest order is not contiguous in ${SourceDirectory}: expected $expectedOrder, found $($orderedRecords[$index].Order)."
        }
    }
    return $orderedRecords
}

function New-ZylActionCriteriaSection {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$OwnerDocument,

        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory
    )

    $section = $OwnerDocument.CreateElement('ActionCriteria')
    $records = @(Get-ZylOrderedManifestElements `
        -SourceDirectory $SourceDirectory `
        -FragmentRootName 'CriteriaFragment' `
        -ElementName 'Criteria')
    foreach ($record in $records) {
        $element = [System.Xml.XmlElement]$OwnerDocument.ImportNode($record.Element, $true)
        $element.RemoveAttribute('manifestOrder')
        [void]$section.AppendChild($element)
    }
    return ,$section
}
