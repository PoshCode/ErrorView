filter GetGoogleWorkflowPositionMessage {
    [CmdletBinding()]
    [OUtputType([string])]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )
    $InvocationInfo = $InputObject.InvocationInfo
    # Handle case where there is a TargetObject from a Pester `Should` assertion failure and we can show the error at the target rather than the script source
    # Note that in some versions, this is a Dictionary<,> and in others it's a hashtable. So we explicitly cast to a shared interface in the method invocation
    # to force using `IDictionary.Contains`. Hashtable does have it's own `ContainKeys` as well, but if they ever opt to use a custom `IDictionary`, that may not.
    $useTargetObject = $null -ne $InputObject.TargetObject -and
                    $InputObject.TargetObject -is [System.Collections.IDictionary] -and
                    ([System.Collections.IDictionary]$InputObject.TargetObject).Contains('Line') -and
                    ([System.Collections.IDictionary]$InputObject.TargetObject).Contains('LineText')

    $file = if ($useTargetObject) {
        "$($InputObject.TargetObject.File)"
    } elseif (.ScriptName) {
        "$($InvocationInfo.ScriptName)"
    }

    $line = if ($useTargetObject) {
        $InputObject.TargetObject.Line
    } else {
        $InvocationInfo.ScriptLineNumber
    }

    if ($useTargetObject) {
        "file=$file,line=$line"
    } else {
        $column = $InvocationInfo.OffsetInLine

        $Length = $InvocationInfo.PositionMessage.Split($newline)[-1].Substring(1).Trim().Length
        $endColumn = $column + $Length
        "file=$file,line=$line,col=$column,endColumn=$endColumn"
    }
}
