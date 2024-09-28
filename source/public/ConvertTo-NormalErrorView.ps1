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
    begin { ResetColor }
    process {
        if ($InputObject.FullyQualifiedErrorId -in 'NativeCommandErrorMessage','NativeCommandError') {
            "${errorColor}$($InputObject.Exception.Message)${resetColor}"
        } else {
            $myinv = $InputObject.InvocationInfo
            $posmsg = ''
            if ($myinv -and ($myinv.MyCommand -or ($InputObject.CategoryInfo.Category -ne 'ParserError')) -and $myinv.PositionMessage) {
                $posmsg = $newline + $myinv.PositionMessage
            }

            if ($err.PSMessageDetails) {
                $posmsg = ' : ' + $err.PSMessageDetails + $posmsg
            }

            $Wrap = @{
                Width = $host.UI.RawUI.BufferSize.Width - 2
                IndentPadding = "                         "
            }

            $errorCategoryMsg = $InputObject.ErrorCategory_Message
            [string]$line = if ($null -ne $errorCategoryMsg) {
                $accentColor + "+ CategoryInfo         : " + $errorColor + $InputObject.ErrorCategory_Message | WrapString @Wrap
            } else {
                $accentColor + "+ CategoryInfo         : " + $errorColor + $InputObject.CategoryInfo | WrapString @Wrap
            }
            $posmsg += $newline + $line

            $line = $accentColor + "+ FullyQualifiedErrorId: " + $errorColor + $InputObject.FullyQualifiedErrorId | WrapString @Wrap
            $posmsg += $newline + $line

            $originInfo = $InputObject.OriginInfo
            if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName)) {
                $line = $accentColor + "+ PSComputerName       : " + $errorColor + $originInfo.PSComputerName | WrapString @Wrap
                $posmsg += $newline + $line
            }

            if (!$InputObject.ErrorDetails -or !$InputObject.ErrorDetails.Message) {
                $errorColor + $InputObject.Exception.Message + $posmsg + $resetColor
            } else {
                $errorColor + $InputObject.ErrorDetails.Message + $posmsg + $resetColor
            }
        }
    }
}