filter ConvertTo-FullErrorView {
    <#
        .SYNOPSIS
            Converts an ErrorRecord to a full error view
        .DESCRIPTION
            A simple, verbose error view that just shows everything, recursing forever.
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
    #$accentColor = ''

    if ($Host.UI.SupportsVirtualTerminal -and ([string]::IsNullOrEmpty($env:__SuppressAnsiEscapeSequences))) {
        # For Format-List to use color when piped to Out-String, OutputRendering needs to be Ansi
        $PSStyle.OutputRendering, $Rendering = "Ansi", $PSStyle.OutputRendering

        $resetColor = "$([char]0x1b)[0m"
        $errorColor = if ($PSStyle.Formatting.Error) { $PSStyle.Formatting.Error } else { "`e[1;31m" }
    }

    $Detail = $InputObject | Format-List * -Force | Out-String -Width 120

    # NOTE: ErrorViewRecurse is normally false, and only set temporarily by Format-Error -Recurse
    if ($ErrorViewRecurse) {
        $Count = 1
        $Exception = $InputObject.Exception
        while ($Exception = $Exception.InnerException) {
            $Detail += $errorColor + "`nINNER EXCEPTION $($Count): $resetColor$($Exception.GetType().FullName)`n`n"
            $Detail += $Exception | Format-List * -Force | Out-String -Width 120
            $Count++
        }
    }
    if ($resetColor) {
        $PSStyle.OutputRendering = $Rendering
    }
    $Detail
}