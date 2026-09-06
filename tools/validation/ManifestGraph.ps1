function ConvertTo-ZylCanonicalXmlNode {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlElement]$Node
    )

    $attributes = @(
        foreach ($attribute in @($Node.Attributes) | Sort-Object Name) {
            [ordered]@{
                name = $attribute.Name
                value = $attribute.Value
            }
        }
    )
    $elementChildren = @($Node.ChildNodes | Where-Object NodeType -eq Element)
    $record = [ordered]@{
        name = $Node.LocalName
    }
    if ($attributes.Count -gt 0) {
        $record.attributes = $attributes
    }
    if ($elementChildren.Count -gt 0) {
        $record.children = @(
            foreach ($child in $elementChildren) {
                ConvertTo-ZylCanonicalXmlNode -Node ([System.Xml.XmlElement]$child)
            }
        )
    }
    else {
        $record.value = $Node.InnerText
    }
    return [pscustomobject]$record
}

function Get-ZylModInfoActionGraphFromDocument {
    param(
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]$Document
    )

    $sectionNames = @('ActionCriteria', 'FrontEndActions', 'InGameActions', 'Files')
    $sections = @(
        foreach ($sectionName in $sectionNames) {
            $section = [System.Xml.XmlElement]$Document.SelectSingleNode("/Mod/$sectionName")
            if ($null -eq $section) {
                throw "ModInfo is missing semantic graph section: $sectionName"
            }
            ConvertTo-ZylCanonicalXmlNode -Node $section
        }
    )

    return [pscustomobject][ordered]@{
        schemaVersion = 1
        sections = $sections
    }
}

function Get-ZylModInfoActionGraph {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $document = [System.Xml.XmlDocument]::new()
    $document.PreserveWhitespace = $false
    $document.Load($Path)
    return Get-ZylModInfoActionGraphFromDocument -Document $document
}

function ConvertTo-ZylCanonicalJson {
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject
    )

    process {
        return $InputObject | ConvertTo-Json -Depth 100 -Compress
    }
}

function Get-ZylSha256ForText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.UTF8Encoding]::new($false).GetBytes($Text)
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-ZylModInfoActionGraphFingerprint {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $graph = Get-ZylModInfoActionGraph -Path $Path
    $json = ConvertTo-ZylCanonicalJson -InputObject $graph
    return Get-ZylSha256ForText -Text $json
}
