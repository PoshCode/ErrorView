param(
    [ArgumentCompleter({ (Get-Command ConvertTo-Error* -ListImported).Name -replace "ConvertTo-Error(?:View)?(.*)(?:View)",'$1' })]
    $ErrorView
)

# We need to overwrite the ErrorView
# So -PrependPath, instead of FormatsToProcess
Update-FormatData -PrependPath $PSScriptRoot\ErrorView.ps1xml

function Write-NativeCommandError {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $CurrentError
    )

    if ($CurrentError.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") { return }

    $myinv = $CurrentError.InvocationInfo
    if ($myinv -and $myinv.MyCommand) {
        switch -regex ( $myinv.MyCommand.CommandType ) {
            ([System.Management.Automation.CommandTypes]::ExternalScript) {
                if ($myinv.MyCommand.Path) {
                    $myinv.MyCommand.Path + " : "
                }
                break
            }
            ([System.Management.Automation.CommandTypes]::Script) {
                if ($myinv.MyCommand.ScriptBlock) {
                    $myinv.MyCommand.ScriptBlock.ToString() + " : "
                }
                break
            }
            default {
                if ($myinv.InvocationName -match '^[&amp;\.]?$') {
                    if ($myinv.MyCommand.Name) {
                        $myinv.MyCommand.Name + " : "
                    }
                } else {
                    $myinv.InvocationName + " : "
                }
                break
            }
        }
    } elseif ($myinv -and $myinv.InvocationName) {
        $myinv.InvocationName + " : "
    }
}
function ConvertTo-ErrorCategoryView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $CurrentError
    )

    $CurrentError.CategoryInfo.GetMessage()
}

function ConvertTo-ErrorSimpleView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $CurrentError
    )

    if ($CurrentError.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
        $CurrentError.Exception.Message
    } else {
        $myinv = $CurrentError.InvocationInfo
        if ($myinv -and ($myinv.MyCommand -or ($CurrentError.CategoryInfo.Category -ne 'ParserError'))) {
            $posmsg = $myinv.PositionMessage
        } else {
            $posmsg = ""
        }

        if ($posmsg -ne "") {
            $posmsg = "`n" + $posmsg
        }

        if ( & { Set-StrictMode -Version 1; $CurrentError.PSMessageDetails } ) {
            $posmsg = " : " + $CurrentError.PSMessageDetails + $posmsg
        }

        $indent = 4
        $width = $host.UI.RawUI.BufferSize.Width - $indent - 2

        $originInfo = & { Set-StrictMode -Version 1; $CurrentError.OriginInfo }
        if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName)) {
            $indentString = "+ PSComputerName        : " + $originInfo.PSComputerName
            $posmsg += "`n"
            foreach ($line in @($indentString -split "(.{$width})")) {
                if ($line) {
                    $posmsg += (" " * $indent + $line)
                }
            }
        }

        if (!$CurrentError.ErrorDetails -or !$CurrentError.ErrorDetails.Message) {
            $CurrentError.Exception.Message + $posmsg + "`n "
        } else {
            $CurrentError.ErrorDetails.Message + $posmsg
        }
    }
}
function ConvertTo-ErrorNormalView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $CurrentError
    )

    if ($CurrentError.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
        $CurrentError.Exception.Message
    } else {
        $myinv = $CurrentError.InvocationInfo
        if ($myinv -and ($myinv.MyCommand -or ($CurrentError.CategoryInfo.Category -ne 'ParserError'))) {
            $posmsg = $myinv.PositionMessage
        } else {
            $posmsg = ""
        }

        if ($posmsg -ne "") {
            $posmsg = "`n" + $posmsg
        }

        if ( &{ Set-StrictMode -Version 1; $CurrentError.PSMessageDetails } ) {
            $posmsg = " : " +  $CurrentError.PSMessageDetails + $posmsg
        }

        $indent = 4
        $width = $host.UI.RawUI.BufferSize.Width - $indent - 2

        $errorCategoryMsg = &{ Set-StrictMode -Version 1; $CurrentError.ErrorCategory_Message }
        if ($null -ne $errorCategoryMsg) {
            $indentString = "+ CategoryInfo            : " + $CurrentError.ErrorCategory_Message
        } else {
            $indentString = "+ CategoryInfo            : " + $CurrentError.CategoryInfo
        }
        $posmsg += "`n"
        foreach ($line in @($indentString -split "(.{$width})")) {
            if ($line) {
                $posmsg += (" " * $indent + $line)
            }
        }

        $indentString = "+ FullyQualifiedErrorId   : " + $CurrentError.FullyQualifiedErrorId
        $posmsg += "`n"
        foreach ($line in @($indentString -split "(.{$width})")) {
            if ($line) {
                $posmsg += (" " * $indent + $line)
            }
        }

        $originInfo = &{ Set-StrictMode -Version 1; $CurrentError.OriginInfo }
        if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName)) {
            $indentString = "+ PSComputerName          : " + $originInfo.PSComputerName
            $posmsg += "`n"
            foreach ($line in @($indentString -split "(.{$width})")) {
                if ($line) {
                    $posmsg += (" " * $indent + $line)
                }
            }
        }

        if (!$CurrentError.ErrorDetails -or !$CurrentError.ErrorDetails.Message) {
            $CurrentError.Exception.Message + $posmsg + "`n "
        } else {
            $CurrentError.ErrorDetails.Message + $posmsg
        }
    }
}