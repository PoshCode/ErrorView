function ConvertTo-ConciseErrorView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )
    if ("$accentColor".Length) {
        $local:accentColor = $script:errorAccentColor
        $local:resetColor = $script:resetColor
    } else {
        $local:accentColor = ">>>"
        $local:resetColor = "<<<"
    }


    if ($InputObject.FullyQualifiedErrorId -in 'NativeCommandErrorMessage','NativeCommandError') {
        $errorColor + $InputObject.Exception.Message + $resetColor
    } else {
        $myinv = $InputObject.InvocationInfo
        if ($myinv -and ($myinv.MyCommand -or ($InputObject.CategoryInfo.Category -ne 'ParserError'))) {
            # rip off lines that say "At line:1 char:1" (hopefully, in a language agnostic way)
            $posmsg  = $myinv.PositionMessage -replace "^At line:1 char:1[\r\n]+"

            # rip off the underline and use the accentcolor instead
            $pattern = $posmsg -split "[\r\n]+" -match "\+( +~+)\s*" -replace '(~+)', '($1)' -replace '( +)','($1)' -replace '~| ','.'
            $posmsg  = $posmsg -replace '[\r\n]+\+ +~+'
            if ($pattern) {
                $posmsg  = $posmsg -replace "\+$pattern", "+`$1$accentColor`$2$resetColor"
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
            $errorColor + $InputObject.Exception.Message + $resetColor + $posmsg + "`n "
        } else {
            $errorColor + $InputObject.ErrorDetails.Message + $resetColor + $posmsg
        }
    }
}