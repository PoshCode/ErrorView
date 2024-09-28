filter ConvertTo-DetailedErrorView {
    <#
        .SYNOPSIS
            Converts an ErrorRecord to a detailed error string
        .DESCRIPTION
            An "improved" version of the PowerShell "DetailedView" ErrorView
            Originally copied from the PowerShellCore.format.ps1xml
        .LINK
            https://github.com/PowerShell/PowerShell/blob/c444645b0941d73dc769f0bba6ab70d317bd51a9/src/System.Management.Automation/FormatAndOutput/DefaultFormatters/PowerShellCore_format_ps1xml.cs#L903
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'maxDepth')]
    [CmdletBinding()]
    param(
        # The ErrorRecord to display
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject,

        # The maximum depth to recurse into the object
        [int]$maxDepth = 10
    )
    begin { ResetColor }
    process {
        $newline + (GetListRecursive $InputObject) + $newline
    }
}
