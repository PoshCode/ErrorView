filter ConvertTo-NormalErrorView {
    <#
        .SYNOPSIS
            Converts an ErrorRecord to a NormalView message string
        .DESCRIPTION
            The original default PowerShell ErrorView
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
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

    if ($InputObject.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
        $errorColor + $InputObject.Exception.Message + $resetColor
    } else {
        $myinv = $InputObject.InvocationInfo
        if ($myinv -and ($myinv.MyCommand -or ($InputObject.CategoryInfo.Category -ne 'ParserError'))) {
            $posmsg = $myinv.PositionMessage
        } else {
            $posmsg = ""
        }

        if ($posmsg -ne "") {
            $posmsg = "`n" + $posmsg
        }

        if ( &{ Set-StrictMode -Version 1; $InputObject.PSMessageDetails } ) {
            $posmsg = " : " +  $InputObject.PSMessageDetails + $posmsg
        }

        $indent = 4
        $width = $host.UI.RawUI.BufferSize.Width - $indent - 2

        $errorCategoryMsg = &{ Set-StrictMode -Version 1; $InputObject.ErrorCategory_Message }
        if ($null -ne $errorCategoryMsg) {
            $indentString = "+ CategoryInfo            : " + $InputObject.ErrorCategory_Message
        } else {
            $indentString = "+ CategoryInfo            : " + $InputObject.CategoryInfo
        }
        $posmsg += "`n"
        foreach ($line in @($indentString -split "(.{$width})")) {
            if ($line) {
                $posmsg += (" " * $indent + $line)
            }
        }

        $indentString = "+ FullyQualifiedErrorId   : " + $InputObject.FullyQualifiedErrorId
        $posmsg += "`n"
        foreach ($line in @($indentString -split "(.{$width})")) {
            if ($line) {
                $posmsg += (" " * $indent + $line)
            }
        }

        $originInfo = &{ Set-StrictMode -Version 1; $InputObject.OriginInfo }
        if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName)) {
            $indentString = "+ PSComputerName          : " + $originInfo.PSComputerName
            $posmsg += "`n"
            foreach ($line in @($indentString -split "(.{$width})")) {
                if ($line) {
                    $posmsg += (" " * $indent + $line)
                }
            }
        }

        if (!$InputObject.ErrorDetails -or !$InputObject.ErrorDetails.Message) {
            $errorColor + $InputObject.Exception.Message + $posmsg + $resetColor + "`n "
        } else {
            $errorColor + $InputObject.ErrorDetails.Message + $posmsg + $resetColor
        }
    }
}