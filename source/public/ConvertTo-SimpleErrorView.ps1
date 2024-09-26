function ConvertTo-SimpleErrorView {
    [CmdletBinding()]
    param(
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
        $InputObject.Exception.Message
    } else {
        $myinv = $InputObject.InvocationInfo
        if ($myinv -and ($myinv.MyCommand -or ($InputObject.CategoryInfo.Category -ne 'ParserError'))) {
            # rip off lines that say "At line:1 char:1" (hopefully, in a language agnostic way)
            $posmsg  = $myinv.PositionMessage -replace "^At line:1 .*[\r\n]+"
            # rip off the underline and instead, put >>>markers<<< around the important bit
            # we could, instead, set the background to a highlight color?
            $pattern = $posmsg -split "[\r\n]+" -match "\+( +~+)\s*" -replace '(~+)', '($1)' -replace '( +)','($1)' -replace '~| ','.'
            $posmsg  = $posmsg -replace '[\r\n]+\+ +~+'
            if ($pattern) {
                $posmsg  = $posmsg -replace "\+$pattern", '+ $1>>>$2<<<'
            }
        } else {
            $posmsg = ""
        }

        if ($posmsg -ne "") {
            $posmsg = "`n" + $posmsg
        }

        if ( & { Set-StrictMode -Version 1; $InputObject.PSMessageDetails } ) {
            $posmsg = " : " + $InputObject.PSMessageDetails + $posmsg
        }

        $indent = 4
        $width = $host.UI.RawUI.BufferSize.Width - $indent - 2

        $originInfo = & { Set-StrictMode -Version 1; $InputObject.OriginInfo }
        if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName)) {
            $indentString = "+ PSComputerName        : " + $originInfo.PSComputerName
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