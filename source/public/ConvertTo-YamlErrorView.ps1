function ConvertTo-YamlErrorView {
    <#
        .SYNOPSIS
            Creates a description of an ErrorRecord that looks like valid Yaml
        .DESCRIPTION
            This produces valid Yaml output from ErrorRecord you pass to it, recursively.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'maxDepth')]
    [CmdletBinding()]
    param(
        # The object that you want to convert to YAML
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject,

        # The maximum depth to recurse into the object
        [int]$maxDepth = 10,

        # If set, include empty and null properties in the output
        [switch]$IncludeEmpty
    )
    begin { ResetColor }
    process {
        GetYamlRecursive -InputObject $InputObject -IncludeEmpty:$IncludeEmpty
    }
}