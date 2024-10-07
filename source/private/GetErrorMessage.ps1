filter GetErrorTitle {
    [CmdletBinding()]
    [OUtputType([string])]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )
    if ($InputObject.ErrorDetails -and $InputObject.ErrorDetails.Message) {
        $InputObject.ErrorDetails.Message
    } else {
        if ($InputObject.CategoryInfo.Category -eq 'ParserError' -and $InputObject.Exception.Message.Contains("~$newline")) {
            # need to parse out the relevant part of the pre-rendered positionmessage
            $InputObject.Exception.Message.split("~$newline")[1].split("${newline}${newline}")[0]
        } elseif ($InputObject.Exception) {
            $InputObject.Exception.Message
        } elseif ($InputObject.Message) {
            $InputObject.Message
        } else {
            $InputObject.ToString()
        }
    }
}