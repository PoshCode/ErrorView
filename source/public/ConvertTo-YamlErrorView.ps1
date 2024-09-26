function ConvertTo-YamlErrorView {
    <#
        .SYNOPSIS
            Creates a description of an ErrorRecord that looks like valid Yaml
        .DESCRIPTION
            This produces valid Yaml output from ErrorRecord you pass to it, recursively.
    #>
    [CmdletBinding()]
    param(
        # The object that you want to convert to YAML
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject,

        # Optionally, a limit on the depth to recurse properties (defaults to 16)
        [parameter()]
        [int]$depth = 16,

        # If set, include empty and null properties in the output
        [switch]$IncludeEmpty,

        # Recursive use only. Handles indentation for formatting
        [parameter(DontShow)]
        [int]$NestingLevel = 0,

        # use OuterXml instead of treating XmlDocuments like objects
        [parameter(DontShow)]
        [switch]$XmlAsXml
    )
    process {
        GetYamlRecursive $InputObject
    }
}