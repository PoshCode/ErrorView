filter ConvertTo-FullErrorView {
    <#
        .SYNOPSIS
            Converts an ErrorRecord to a full error view
        .DESCRIPTION
            The most verbose error view I've got, it shows everything, recursing forever.
    #>
    [CmdletBinding()]
    param(
        # The ErrorRecord to display
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )
    $PSStyle.OutputRendering, $Rendering = "Ansi", $PSStyle.OutputRendering
    $Detail = $InputObject | Format-List * -Force | Out-String
    $PSStyle.OutputRendering = $Rendering

    # NOTE: ErrorViewRecurse is normally false, and only set temporarily by Format-Error -Recurse
    if ($ErrorViewRecurse) {
        $Count = 1
        $Exception = $InputObject.Exception
        while ($Exception = $Exception.InnerException) {
            $Detail += "`nINNER EXCEPTION $($Count): $($Exception.GetType().FullName)`n`n"
            $Detail += $Exception | Format-List * -Force | Out-String
            $Count++
        }
    }
    $Detail
}