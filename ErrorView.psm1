param(
    $global:ErrorView = "Simple"
)

# We need to overwrite the ErrorView
# So -PrependPath, instead of FormatsToProcess
Update-FormatData -PrependPath $PSScriptRoot\ErrorView.ps1xml

function Get-Error {
    <#
        .SYNOPSIS
            Allows retrieving errors from the global:Error collection based on which command from history triggered them
        .EXAMPLE
            Get-Error

            Returns all of the errors triggered by the most recent command with an error
    #>
    [Alias("ge")]
    [OutputType([System.Management.Automation.ErrorRecord])]
    [CmdletBinding(DefaultParameterSetName="Count")]
    param(
        # The number of recent commands to show errors for
        [Parameter(Position = 0, ParameterSetName = "HistoryCount")]
        [Alias("CommandCount")]
        [int]$Count = 1,

        [Parameter(Mandatory, ParameterSetName = "ErrorCount")]
        [int]$ErrorCount,

        # The history index of the commands you want to see errors for (defaults to the most recent $Count errors)
        [Parameter(Position = 0, ParameterSetName = "HistoryId")]
        [Alias("Id")]
        [int[]]$HistoryId = $(($MyInvocation.HistoryId - 1)..($MyInvocation.HistoryId - [Math]::Min($Count, $MyInvocation.HistoryId)))
    )
    if ($global:Error.Count -eq 0) {
        Write-Warning "The global `$Error collection is empty"
    } elseif ($ErrorCount) {
        $e = $global:Error[0..$ErrorCount]
    } else {
        $e = $global:Error.Where({ $_.InvocationInfo.HistoryId -in $HistoryId -or $_.ErrorRecord.InvocationInfo.HistoryId -in $HistoryId})

        # if we didn't find any errors matching the HistoryId, what's the most recent command with an error?
        if ($e.Count -eq 0) {

            if($global:Error[0].InvocationInfo.HistoryId -gt 0) {
                $FoundErrorIndex = $global:Error[0].InvocationInfo.HistoryId
            } elseif ($global:Error[0].ErrorRecord.InvocationInfo.HistoryId -gt 0) {
                $FoundErrorIndex = $global:Error[0].ErrorRecord.InvocationInfo.HistoryId
            } else {
                $FoundErrorIndex = -1
            }

            if ($FoundErrorIndex -lt $HistoryId[0]) {
                Write-Warning "No error from the command with HistoryId $($HistoryId -join ',').`n         Showing errors from most recent command with errors $FoundErrorIndex"
                $e = $global:Error.Where( { $_.InvocationInfo.HistoryId -in $FoundErrorIndex -or $_.ErrorRecord.InvocationInfo.HistoryId -in $FoundErrorIndex })
                # If there were no errors from history, but there are errors, let's show them all
                if ($e.Count -eq 0) {
                    Write-Warning "No errors have HistoryId... Showing all errors."
                    $e = $global:Error
                }
            } else {
                Write-Warning "No error from the command with HistoryId $($HistoryId -join ',').`n         Most recent command with detectable errors was $FoundErrorIndex"
            }

        }
    }
    # Return only ErrorRecords -- no exceptions
    @($e).ForEach{ if ($_ -is [System.Management.Automation.ErrorRecord]) { $_ } else { $_.ErrorRecord } }

}

function Format-Error {
    <#
        .SYNOPSIS
            Formats an error for the screen using a custom error view
        .DESCRIPTION
            Temporarily switches the error view and outputs the errors
        .EXAMPLE
            Format-Error

            Shows the Normal error view for the most recent error
        .EXAMPLE
            $error[0..4] | Format-Error Full

            Shows the full error view (like using | Format-List * -Force) for the most recent 5 errors
        .EXAMPLE
            $error[3] | Format-Error Full -Recurse

            Shows the full error view of the specific error, recursing into the inner exceptions (if that's supported by the view)
    #>
    [CmdletBinding()]
    [Alias("fe")]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        # The name of the ErrorView you want to use (there must a matching ConvertTo-${View}ErrorView function)
        [Parameter(Position=0, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            [System.Management.Automation.CompletionResult[]]((
                Get-Command ConvertTo-*ErrorView -ListImported -ParameterName InputObject -ParameterType [System.Management.Automation.ErrorRecord]
            ).Name -replace "ConvertTo-(.*)ErrorView",'$1' -like "*$($wordToComplete)*")
        })]
        $View = "Normal",

        # The history index of the commands you want to see errors for (defaults to the most recent $Count errors)
        [Parameter(Position = 0, ParameterSetName = "HistoryId")]
        [Alias("Id")]
        [int[]]$HistoryId = $(($MyInvocation.HistoryId - 1)..($MyInvocation.HistoryId - [Math]::Min(2, $MyInvocation.HistoryId))),

        # Error records (e.g. from $Error).
        # Defaults to Get-Error with the HistoryId
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("ErrorRecord")]
        [System.Management.Automation.ErrorRecord[]]$InputObject = $(Get-Error -HistoryId $HistoryId),

        # Allows ErrorView functions to recurse to InnerException
        [switch]$Recurse
    )
    begin {
        $ErrorActionPreference = "Continue"
        $View, $global:ErrorView = $ErrorView, $View
        [bool]$Recurse, [bool]$global:ErrorViewRecurse = [bool]$global:ErrorViewRecurse, $Recurse
    }
    process {
        $InputObject
    }
    end {
        [bool]$global:ErrorViewRecurse = $Recurse
        $global:ErrorView = $View
    }
}

function Set-ErrorView {
    <#
        .SYNOPSIS
            A helper function to provide tab-completion for error view names
    #>
    [CmdletBinding()]
    [Alias("sev")]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        # The name of the ErrorView you want to use (there must a matching ConvertTo-${View}ErrorView function)
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter( {
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
                [System.Management.Automation.CompletionResult[]]((
                        Get-Command ConvertTo-*ErrorView -ListImported -ParameterName InputObject -ParameterType [System.Management.Automation.ErrorRecord]
                    ).Name -replace "ConvertTo-(.*)ErrorView", '$1' -like "*$($wordToComplete)*")
            })]
        $View = "Normal"
    )
    $global:ErrorView = $View
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

        $Coloring = $(
            if (!$InputObject.ErrorDetails -or !$InputObject.ErrorDetails.Message) {
                $InputObject.Exception.Message + $posmsg + "`n "
            } else {
                $InputObject.ErrorDetails.Message + $posmsg
            }
        )
        $Lines = [regex]::Matches($Coloring, "\n").Count + 2
        $Colors = Get-Gradient "DarkRed" "Goldenrod1" -ColorSpace HSB -Flatten -Length $Lines | Get-Complement -Passthru -ForceContrast
        $Host.PrivateData.ErrorBackgroundColor = "DarkRed"
        $Host.PrivateData.ErrorForegroundColor = "White"

        $script:Index = 0

        $SetColor = {
            -join @(
                $args[0].Value
                $Colors[$Index].ToVtEscapeSequence($true)
                $Colors[$Index+1].ToVtEscapeSequence($false)
            )
            $script:Index += 2
        }
        "$(. $SetColor)$([regex]::Replace($Coloring, "\n", $SetColor))$bg:Clear$fg:Clear"
    }
}

function ConvertTo-FullErrorView {
    [CmdletBinding()]
    param(
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

    $Detail = $InputObject | Format-List * -Force | Out-String

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


function ConvertTo-FireErrorView {
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

        if ( & { Set-StrictMode -Version 1; $InputObject.PSMessageDetails } ) {
            $posmsg = " : " + $InputObject.PSMessageDetails + $posmsg
        }

        $indent = 4
        $width = $host.UI.RawUI.BufferSize.Width - $indent - 2

        $errorCategoryMsg = & { Set-StrictMode -Version 1; $InputObject.ErrorCategory_Message }
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

        $originInfo = & { Set-StrictMode -Version 1; $InputObject.OriginInfo }
        if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName)) {
            $indentString = "+ PSComputerName          : " + $originInfo.PSComputerName
            $posmsg += "`n"
            foreach ($line in @($indentString -split "(.{$width})")) {
                if ($line) {
                    $posmsg += (" " * $indent + $line)
                }
            }
        }

        $Coloring = $(
            if (!$InputObject.ErrorDetails -or !$InputObject.ErrorDetails.Message) {
                $InputObject.Exception.Message + $posmsg + "`n "
            } else {
                $InputObject.ErrorDetails.Message + $posmsg
            }
        )
        $Lines = [regex]::Matches($Coloring, "\n").Count + 2
        $Colors = Get-Gradient "DarkRed" "Goldenrod1" -ColorSpace HSB -Flatten -Length $Lines | Get-Complement -Passthru -ForceContrast
        $Host.PrivateData.ErrorBackgroundColor = "DarkRed"
        $Host.PrivateData.ErrorForegroundColor = "White"

        $script:Index = 0

        $SetColor = {
            -join @(
                $args[0].Value
                $Colors[$Index].ToVtEscapeSequence($true)
                $Colors[$Index + 1].ToVtEscapeSequence($false)
            )
            $script:Index += 2
        }
        "$(. $SetColor)$([regex]::Replace($Coloring, "\n", $SetColor))$bg:Clear$fg:Clear"
    }
}