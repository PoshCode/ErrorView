<#
if (@('NativeCommandErrorMessage','NativeCommandError') -notcontains $_.FullyQualifiedErrorId -and @('CategoryView','ConciseView','DetailedView') -notcontains $ErrorView)
{
    $myinv = $_.InvocationInfo
    if ($myinv -and $myinv.MyCommand)
    {
        switch -regex ( $myinv.MyCommand.CommandType )
        {
            ([System.Management.Automation.CommandTypes]::ExternalScript)
            {
                if ($myinv.MyCommand.Path)
                {
                    $myinv.MyCommand.Path + ' : '
                }

                break
            }

            ([System.Management.Automation.CommandTypes]::Script)
            {
                if ($myinv.MyCommand.ScriptBlock)
                {
                    $myinv.MyCommand.ScriptBlock.ToString() + ' : '
                }

                break
            }
            default
            {
                if ($myinv.InvocationName -match '^[&\.]?$')
                {
                    if ($myinv.MyCommand.Name)
                    {
                        $myinv.MyCommand.Name + ' : '
                    }
                }
                else
                {
                    $myinv.InvocationName + ' : '
                }

                break
            }
        }
    }
    elseif ($myinv -and $myinv.InvocationName)
    {
        $myinv.InvocationName + ' : '
    }
}


Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
trap { 'Error found in error view definition: ' + $_.Exception.Message }
$newline = [Environment]::Newline

$resetColor = ''
$errorColor = ''
$accentColor = ''

if ($Host.UI.SupportsVirtualTerminal -and ([string]::IsNullOrEmpty($env:__SuppressAnsiEscapeSequences))) {
    $resetColor = $PSStyle.Reset
    $errorColor = $PSStyle.Formatting.Error
    $accentColor = $PSStyle.Formatting.ErrorAccent
}
function Get-ConciseViewPositionMessage {

    # returns a string cut to last whitespace
    function Get-TruncatedString($string, [int]$length) {

        if ($string.Length -le $length) {
            return $string
        }

        return ($string.Substring(0,$length) -split '\s',-2)[0]
    }

    $posmsg = ''
    $headerWhitespace = ''
    $offsetWhitespace = ''
    $message = ''
    $prefix = ''

    # The checks here determine if we show line detailed error information:
    # - check if `ParserError` and comes from PowerShell which eventually results in a ParseException, but during this execution it's an ErrorRecord
    # - check if invocation is a script or multiple lines in the console
    # - check that it's not a script module as expectation is that users don't want to see the line of error within a module
    if ((($err.CategoryInfo.Category -eq 'ParserError' -and $err.Exception -is 'System.Management.Automation.ParentContainsErrorRecordException') -or $myinv.ScriptName -or $myinv.ScriptLineNumber -gt 1) -and $myinv.ScriptName -notmatch '\.psm1$') {
        $useTargetObject = $false

        # Handle case where there is a TargetObject and we can show the error at the target rather than the script source
        if ($_.TargetObject.Line -and $_.TargetObject.LineText) {
            $posmsg = "${resetcolor}$($_.TargetObject.File)${newline}"
            $useTargetObject = $true
        }
        elseif ($myinv.ScriptName) {
            if ($env:TERM_PROGRAM -eq 'vscode') {
                # If we are running in vscode, we know the file:line:col links are clickable so we use this format
                $posmsg = "${resetcolor}$($myinv.ScriptName):$($myinv.ScriptLineNumber):$($myinv.OffsetInLine)${newline}"
            }
            else {
                $posmsg = "${resetcolor}$($myinv.ScriptName):$($myinv.ScriptLineNumber)${newline}"
            }
        }
        else {
            $posmsg = "${newline}"
        }

        if ($useTargetObject) {
            $scriptLineNumber = $_.TargetObject.Line
            $scriptLineNumberLength = $_.TargetObject.Line.ToString().Length
        }
        else {
            $scriptLineNumber = $myinv.ScriptLineNumber
            $scriptLineNumberLength = $myinv.ScriptLineNumber.ToString().Length
        }

        if ($scriptLineNumberLength -gt 4) {
            $headerWhitespace = ' ' * ($scriptLineNumberLength - 4)
        }

        $lineWhitespace = ''
        if ($scriptLineNumberLength -lt 4) {
            $lineWhitespace = ' ' * (4 - $scriptLineNumberLength)
        }

        $verticalBar = '|'
        $posmsg += "${accentColor}${headerWhitespace}Line ${verticalBar}${newline}"

        $highlightLine = ''
        if ($useTargetObject) {
            $line = $_.TargetObject.LineText.Trim()
            $offsetLength = 0
            $offsetInLine = 0
        }
        else {
            $positionMessage = $myinv.PositionMessage.Split($newline)
            $line = $positionMessage[1].Substring(1) # skip the '+' at the start
            $highlightLine = $positionMessage[$positionMessage.Count - 1].Substring(1)
            $offsetLength = $highlightLine.Trim().Length
            $offsetInLine = $highlightLine.IndexOf('~')
        }

        if (-not $line.EndsWith($newline)) {
            $line += $newline
        }

        # don't color the whole line
        if ($offsetLength -lt $line.Length - 1) {
            $line = $line.Insert($offsetInLine + $offsetLength, $resetColor).Insert($offsetInLine, $accentColor)
        }

        $posmsg += "${accentColor}${lineWhitespace}${ScriptLineNumber} ${verticalBar} ${resetcolor}${line}"
        $offsetWhitespace = ' ' * $offsetInLine
        $prefix = "${accentColor}${headerWhitespace}     ${verticalBar} ${errorColor}"
        if ($highlightLine -ne '') {
            $posMsg += "${prefix}${highlightLine}${newline}"
        }
        $message = "${prefix}"
    }

    if (! $err.ErrorDetails -or ! $err.ErrorDetails.Message) {
        if ($err.CategoryInfo.Category -eq 'ParserError' -and $err.Exception.Message.Contains("~$newline")) {
            # need to parse out the relevant part of the pre-rendered positionmessage
            $message += $err.Exception.Message.split("~$newline")[1].split("${newline}${newline}")[0]
        }
        elseif ($err.Exception) {
            $message += $err.Exception.Message
        }
        elseif ($err.Message) {
            $message += $err.Message
        }
        else {
            $message += $err.ToString()
        }
    }
    else {
        $message += $err.ErrorDetails.Message
    }

    # if rendering line information, break up the message if it's wider than the console
    if ($myinv -and $myinv.ScriptName -or $err.CategoryInfo.Category -eq 'ParserError') {
        $prefixLength = "$([char]27)]8;;{0}`a{1}$([char]27)]8;;`a" -f $pwd, $pwd::new($prefix).ContentLength
        $prefixVtLength = $prefix.Length - $prefixLength

        # replace newlines in message so it lines up correct
        $message = $message.Replace($newline, ' ').Replace("`n", ' ').Replace("`t", ' ')

        $windowWidth = 120
        if ($Host.UI.RawUI -ne $null) {
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
        }

        if ($windowWidth -gt 0 -and ($message.Length - $prefixVTLength) -gt $windowWidth) {
            $sb = [Text.StringBuilder]::new()
            $substring = Get-TruncatedString -string $message -length ($windowWidth + $prefixVTLength)
            $null = $sb.Append($substring)
            $remainingMessage = $message.Substring($substring.Length).Trim()
            $null = $sb.Append($newline)
            while (($remainingMessage.Length + $prefixLength) -gt $windowWidth) {
                $subMessage = $prefix + $remainingMessage
                $substring = Get-TruncatedString -string $subMessage -length ($windowWidth + $prefixVtLength)

                if ($substring.Length - $prefix.Length -gt 0)
                {
                    $null = $sb.Append($substring)
                    $null = $sb.Append($newline)
                    $remainingMessage = $remainingMessage.Substring($substring.Length - $prefix.Length).Trim()
                }
                else
                {
                    break
                }
            }
            $null = $sb.Append($prefix + $remainingMessage.Trim())
            $message = $sb.ToString()
        }

        $message += $newline
    }

    $posmsg += "${errorColor}" + $message

    $reason = 'Error'
    if ($err.Exception -and $err.Exception.WasThrownFromThrowStatement) {
        $reason = 'Exception'
    }
    # MyCommand can be the script block, so we don't want to show that so check if it's an actual command
    elseif ($myinv.MyCommand -and $myinv.MyCommand.Name -and (Get-Command -Name $myinv.MyCommand -ErrorAction Ignore))
    {
        $reason = $myinv.MyCommand
    }
    # If it's a scriptblock, better to show the command in the scriptblock that had the error
    elseif ($_.CategoryInfo.Activity) {
        $reason = $_.CategoryInfo.Activity
    }
    elseif ($myinv.MyCommand) {
        $reason = $myinv.MyCommand
    }
    elseif ($myinv.InvocationName) {
        $reason = $myinv.InvocationName
    }
    elseif ($err.CategoryInfo.Category) {
        $reason = $err.CategoryInfo.Category
    }
    elseif ($err.CategoryInfo.Reason) {
        $reason = $err.CategoryInfo.Reason
    }

    $errorMsg = 'Error'

    "${errorColor}${reason}: ${posmsg}${resetcolor}"
}

$myinv = $_.InvocationInfo
$err = $_
if (!$myinv -and $_.ErrorRecord -and $_.ErrorRecord.InvocationInfo) {
    $err = $_.ErrorRecord
    $myinv = $err.InvocationInfo
}

if ($err.FullyQualifiedErrorId -eq 'NativeCommandErrorMessage' -or $err.FullyQualifiedErrorId -eq 'NativeCommandError') {
    return "${errorColor}$($err.Exception.Message)${resetcolor}"
}

$myinv = $err.InvocationInfo
if ($ErrorView -eq 'DetailedView') {
    $message = Get-Error
    return "${errorColor}${message}${resetcolor}"
}

if ($ErrorView -eq 'CategoryView') {
    $message = $err.CategoryInfo.GetMessage()
    return "${errorColor}${message}${resetcolor}"
}

$posmsg = ''
if ($ErrorView -eq 'ConciseView') {
    $posmsg = Get-ConciseViewPositionMessage
}
elseif ($myinv -and ($myinv.MyCommand -or ($err.CategoryInfo.Category -ne 'ParserError'))) {
    $posmsg = $myinv.PositionMessage
}

if ($posmsg -ne '') {
    $posmsg = $newline + $posmsg
}

if ($err.PSMessageDetails) {
    $posmsg = ' : ' +  $err.PSMessageDetails + $posmsg
}

if ($ErrorView -eq 'ConciseView') {
    if ($err.PSMessageDetails) {
        $posmsg = "${errorColor}${posmsg}"
    }
    return $posmsg
}

$indent = 4

$errorCategoryMsg = $err.ErrorCategory_Message

if ($null -ne $errorCategoryMsg)
{
    $indentString = '+ CategoryInfo          : ' + $err.ErrorCategory_Message
}
else
{
    $indentString = '+ CategoryInfo          : ' + $err.CategoryInfo
}

$posmsg += $newline + $indentString

$indentString = "+ FullyQualifiedErrorId : " + $err.FullyQualifiedErrorId
$posmsg += $newline + $indentString

$originInfo = $err.OriginInfo

if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName))
{
    $indentString = "+ PSComputerName        : " + $originInfo.PSComputerName
    $posmsg += $newline + $indentString
}

$finalMsg = if ($err.ErrorDetails.Message) {
    $err.ErrorDetails.Message + $posmsg
} else {
    $err.Exception.Message + $posmsg
}

"${errorColor}${finalMsg}${resetcolor}"

#>