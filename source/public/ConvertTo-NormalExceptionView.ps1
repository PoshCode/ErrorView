filter ConvertTo-NormalExceptionView {
    <#
        .SYNOPSIS
            Converts an Exception to a NormalView message string
        .DESCRIPTION
            The original default PowerShell ErrorView, updated for VT100
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Exception]
        $InputObject
    )
    begin { ResetColor }
    process {
        $errorColor + $InputObject.Message + $resetColor
    }
}