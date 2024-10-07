function ConvertTo-ConciseErrorView {
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
            if (!"$accentColor".Length) {
                $local:accentColor = ">>>"
                $local:resetColor = "<<<"
            }

            $message = GetConciseMessage -InputObject $InputObject

            if ($InputObject.PSMessageDetails) {
                $message = $errorColor + ' : ' + $InputObject.PSMessageDetails + $message
            }

            $recommendedAction = $InputObject.ErrorDetails.RecommendedAction
            if (-not [String]::IsNullOrWhiteSpace($recommendedAction)) {
                $message = $message + $newline + ${errorColor} + '  Recommendation: ' + $recommendedAction + ${resetcolor}
            }

            $message
        }
    }
}