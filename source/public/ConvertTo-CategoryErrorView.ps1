filter ConvertTo-CategoryErrorView {
    <#
        .SYNOPSIS
            Converts an ErrorRecord to a CategoryInfo message string
        .DESCRIPTION
            The default PowerShell "CategoryView" ErrorView
            Copied directly from the PowerShellCore.format.ps1xml
        .LINK
            https://github.com/PowerShell/PowerShell/blob/c444645b0941d73dc769f0bba6ab70d317bd51a9/src/System.Management.Automation/FormatAndOutput/DefaultFormatters/PowerShellCore_format_ps1xml.cs#L1302
    #>
    [CmdletBinding()]
    param(
        # The ErrorRecord to display
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )
    $resetColor = ''
    $errorColor = ''

    if ($Host.UI.SupportsVirtualTerminal -and ([string]::IsNullOrEmpty($env:__SuppressAnsiEscapeSequences))) {
        $resetColor = "$([char]0x1b)[0m"
        $errorColor = if ($PSStyle.Formatting.Error) { $PSStyle.Formatting.Error } else { "`e[1;31m" }
    }
    $errorColor + $InputObject.CategoryInfo.GetMessage() + $resetColor
}