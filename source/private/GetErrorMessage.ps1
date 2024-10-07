filter GetErrorTitle {
    [CmdletBinding()]
    [OUtputType([string])]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )
    if (! $err.ErrorDetails -or ! $err.ErrorDetails.Message) {
        if ($err.CategoryInfo.Category -eq 'ParserError' -and $err.Exception.Message.Contains("~$newline")) {
            # need to parse out the relevant part of the pre-rendered positionmessage
            $err.Exception.Message.split("~$newline")[1].split("${newline}${newline}")[0]
        } elseif ($err.Exception) {
            $err.Exception.Message
        } elseif ($err.Message) {
            $err.Message
        } else {
            $err.ToString()
        }
    } else {
        $err.ErrorDetails.Message
    }
}