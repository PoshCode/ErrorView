function ConvertTo-DetailedErrorView {
    <#
        .SYNOPSIS
            Converts an ErrorRecord to a detailed error string
        .DESCRIPTION
            The default PowerShell "DetailedView" ErrorView
            Copied from the PowerShellCore.format.ps1xml
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

    begin {
        Write-Information "ENTER ConvertTo-DetailedErrorView BEGIN " -Tags 'Trace', 'Enter', 'ConvertTo-DetailedErrorView'

        Write-Information "EXIT ConvertTo-DetailedErrorView BEGIN" -Tags 'Trace', 'Enter', 'ConvertTo-DetailedErrorView'
    }
    process {
        Write-Information "ENTER ConvertTo-DetailedErrorView PROCESS $($InputObject.GetType().FullName)" -Tags 'Trace', 'Enter', 'ConvertTo-DetailedErrorView'
        GetListRecursive $InputObject
        Write-Information "EXIT ConvertTo-DetailedErrorView PROCESS $($InputObject.GetType().FullName)" -Tags 'Trace', 'Enter', 'ConvertTo-DetailedErrorView'
    }
}
