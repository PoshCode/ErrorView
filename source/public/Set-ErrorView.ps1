filter Set-ErrorView {
    <#
        .SYNOPSIS
            A helper function to provide tab-completion for error view names
    #>
    [CmdletBinding()]
    [Alias("sev")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification='The ArgumentCompleter parameters are the required method signature')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'ErrorView is all about the ErrorView global variable')]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        # The name of the ErrorView you want to use (there must a matching ConvertTo-${View}ErrorView function)
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
                [System.Management.Automation.CompletionResult[]]((
                        Get-Command ConvertTo-*ErrorView -ListImported -ParameterName InputObject -ParameterType [System.Management.Automation.ErrorRecord]
                    ).Name -replace "ConvertTo-(.*)ErrorView", '$1' -like "*$($wordToComplete)*")
            })]
        $View = "Normal"
    )
    # Update the enum every time, because how often do you change the error view?
    $Names = [System.Management.Automation.ErrorView].GetEnumNames() + @(
        Get-Command ConvertTo-*ErrorView -ListImported -ParameterName InputObject -ParameterType [System.Management.Automation.ErrorRecord]
    ).Name -replace "ConvertTo-(\w+)ErrorView", '$1View' | Select-Object -Unique

    $ofs = ';'
    [ScriptBlock]::Create("enum ErrorView { $Names }").Invoke()

    [ErrorView]$global:ErrorView = $View
}
