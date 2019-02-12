param(
    $global:ErrorView = "Simple"
)

# We need to overwrite the ErrorView
# So -PrependPath, instead of FormatsToProcess
Update-FormatData -PrependPath $PSScriptRoot\ErrorView.ps1xml

function Format-Error {
    [CmdletBinding()]
    [Alias("fe")]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        [Parameter(Position=0, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            [System.Management.Automation.CompletionResult[]]((
                Get-Command ConvertTo-*ErrorView -ListImported -ParameterName InputObject -ParameterType [System.Management.Automation.ErrorRecord]
            ).Name -replace "ConvertTo-(.*)ErrorView",'$1' -like "*$($wordToComplete)*")
        })]
        $View = $ErrorView,

        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [System.Management.Automation.ErrorRecord]$InputObject

    )
    begin {
        $View, $global:ErrorView = $ErrorView, $View
    }
    process {
        $InputObject
    }
    end {
        $global:ErrorView = $View
    }
}

function Write-NativeCommandError {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

    if ($InputObject.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") { return }

    $myinv = $InputObject.InvocationInfo
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

function ConvertTo-CategoryErrorView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

    $InputObject.CategoryInfo.GetMessage()
}

function ConvertTo-SimpleErrorView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

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
            $InputObject.Exception.Message + $posmsg + "`n "
        } else {
            $InputObject.ErrorDetails.Message + $posmsg
        }
    }
}

function ConvertTo-NormalErrorView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

    if ($InputObject.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
        $InputObject.Exception.Message
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
            $InputObject.Exception.Message + $posmsg + "`n "
        } else {
            $InputObject.ErrorDetails.Message + $posmsg
        }
    }
}
