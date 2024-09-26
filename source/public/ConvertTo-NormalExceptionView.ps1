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
    $resetColor = ''
    $errorColor = ''
    #$accentColor = ''

    if ($Host.UI.SupportsVirtualTerminal -and ([string]::IsNullOrEmpty($env:__SuppressAnsiEscapeSequences))) {
        $resetColor = "$([char]0x1b)[0m"
        $errorColor = if ($PSStyle.Formatting.Error) { $PSStyle.Formatting.Error } else { "`e[1;31m" }
        #$accentColor = if ($PSStyle.Formatting.ErrorAccent) { $PSStyle.Formatting.ErrorAccent } else { "`e[1;36m" }
    }

    $errorColor + $InputObject.Message + $resetColor

}