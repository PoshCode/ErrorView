filter GetErrorTitle {
    [CmdletBinding()]
    [OUtputType([string])]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )

    if ($InputObject.Exception -and $InputObject.Exception.WasThrownFromThrowStatement) {
        'Exception'
        # MyCommand can be the script block, so we don't want to show that so check if it's an actual command
    } elseif ($InputObject.InvocationInfo.MyCommand -and $InputObject.InvocationInfo.MyCommand.Name -and (Get-Command -Name $InputObject.InvocationInfo.MyCommand -ErrorAction Ignore)) {
        $InputObject.InvocationInfo.MyCommand
    } elseif ($InputObject.CategoryInfo.Activity) {
        # If it's a scriptblock, better to show the command in the scriptblock that had the error
        $InputObject.CategoryInfo.Activity
    } elseif ($InputObject.InvocationInfo.MyCommand) {
        $InputObject.InvocationInfo.MyCommand
    } elseif ($InputObject.InvocationInfo.InvocationName) {
        $InputObject.InvocationInfo.InvocationName
    } elseif ($InputObject.CategoryInfo.Category) {
        $InputObject.CategoryInfo.Category
    } elseif ($InputObject.CategoryInfo.Reason) {
        $InputObject.CategoryInfo.Reason
    } else {
        'Error'
    }
}