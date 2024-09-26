function Format-Error {
    <#
        .SYNOPSIS
            Formats an error for the screen using a specified error view
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
    [CmdletBinding(DefaultParameterSetName="Count")]
    [Alias("fe", "Get-Error")]
    [OutputType([System.Management.Automation.ErrorRecord])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'The ArgumentCompleter parameters are the required method signature')]

    param(
        # The name of the ErrorView you want to use (there must a matching ConvertTo-${View}ErrorView function)
        [Parameter(Position=0, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            [System.Management.Automation.CompletionResult[]]((
                Get-Command ConvertTo-*ErrorView -ListImported -ParameterName InputObject -ParameterType [System.Management.Automation.ErrorRecord]
            ).Name -replace "ConvertTo-(.*)ErrorView",'$1' -like "*$($wordToComplete)*")
        })]
        $View = "Detailed",

        [Parameter(ParameterSetName="Count")]
        [int]$Newest = 1,

        # Error records (e.g. from $Error). Defaults to the most recent error: $Error[0]
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName="InputObject", Mandatory)]
        [Alias("ErrorRecord")]
        [PSObject]$InputObject = $(
            if ($global:Error.Count -eq 0) {
                Write-Warning "The global `$Error collection is empty"
            } else {
                $global:Error[0..($Newest-1)]
            }
        ),

        # Allows ErrorView functions to recurse to InnerException
        [switch]$Recurse
    )
    begin {
        $ErrorActionPreference = "Continue"
        $ErrorView, $View = $View, $ErrorView
        [bool]$Recurse, [bool]$ErrorViewRecurse = [bool]$ErrorViewRecurse, $Recurse
    }
    process {
        $InputObject
    }
    end {
        [bool]$ErrorViewRecurse = $Recurse
        $ErrorView = $View
    }
}
