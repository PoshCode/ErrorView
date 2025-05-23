filter GetConciseMessage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject
    )
    $posmsg = ''
    $headerWhitespace = ''
    $message = ''
    $prefix = ''

    # Handle case where there is a TargetObject from a Pester `Should` assertion failure and we can show the error at the target rather than the script source
    # Note that in some versions, this is a Dictionary&lt;,&gt; and in others it's a hashtable. So we explicitly cast to a shared interface in the method invocation
    # to force using `IDictionary.Contains`. Hashtable does have it's own `ContainKeys` as well, but if they ever opt to use a custom `IDictionary`, that may not.
    $useTargetObject = $null -ne $InputObject.TargetObject -and
    $InputObject.TargetObject -is [System.Collections.IDictionary] -and
        ([System.Collections.IDictionary]$InputObject.TargetObject).Contains('Line') -and
        ([System.Collections.IDictionary]$InputObject.TargetObject).Contains('LineText')

    # The checks here determine if we show line detailed error information:
    # - check if `ParserError` and comes from PowerShell which eventually results in a ParseException, but during this execution it's an ErrorRecord
    $isParseError = $InputObject.CategoryInfo.Category -eq 'ParserError' -and
    $InputObject.Exception -is [System.Management.Automation.ParentContainsErrorRecordException]

    # - check if invocation is a script or multiple lines in the console
    $Invocation = $InputObject.InvocationInfo
    $isMultiLineOrExternal = $Invocation.ScriptName -or $Invocation.ScriptLineNumber -gt 1

    # - check that it's not a script module as expectation is that users don't want to see the line of error within a module
    $shouldShowLineDetail = ($isParseError -or $isMultiLineOrExternal) -and
    $Invocation.ScriptName -notmatch '\.psm1$'

    if ($useTargetObject -or $shouldShowLineDetail) {

        if ($useTargetObject) {
            $posmsg = "${resetcolor}$($InputObject.TargetObject.File)${newline}"
        } elseif ($Invocation.ScriptName) {
            if ($env:TERM_PROGRAM -eq 'vscode') {
                # If we are running in vscode, we know the file:line:col links are clickable so we use this format
                $posmsg = "${resetcolor}$($Invocation.ScriptName):$($Invocation.ScriptLineNumber):$($Invocation.OffsetInLine)${newline}"
            } else {
                $posmsg = "${resetcolor}$($Invocation.ScriptName):$($Invocation.ScriptLineNumber)${newline}"
            }
        } else {
            $posmsg = "${newline}"
        }

        if ($useTargetObject) {
            $scriptLineNumber = $InputObject.TargetObject.Line
            $scriptLineNumberLength = $InputObject.TargetObject.Line.ToString().Length
        } else {
            $scriptLineNumber = $Invocation.ScriptLineNumber
            $scriptLineNumberLength = $Invocation.ScriptLineNumber.ToString().Length
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
        } else {
            $positionMessage = $Invocation.PositionMessage.Split($newline)
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
        $prefix = "${accentColor}${headerWhitespace}     ${verticalBar} ${errorColor}"
        if ($highlightLine -ne '') {
            $posMsg += "${prefix}${highlightLine}${newline}"
        }
        $message = "${prefix}"
    }

    if (! $InputObject.ErrorDetails -or ! $InputObject.ErrorDetails.Message) {
        if ($InputObject.CategoryInfo.Category -eq 'ParserError' -and $InputObject.Exception.Message.Contains("~$newline")) {
            # need to parse out the relevant part of the pre-rendered positionmessage
            $message += $InputObject.Exception.Message.split("~$newline")[1].split("${newline}${newline}")[0]
        } elseif ($InputObject.Exception) {
            $message += $InputObject.Exception.Message
        } elseif ($InputObject.Message) {
            $message += $InputObject.Message
        } else {
            $message += $InputObject.ToString()
        }
    } else {
        $message += $InputObject.ErrorDetails.Message
    }

    # if rendering line information, break up the message if it's wider than the console
    if ($Invocation -and $Invocation.ScriptName -or $InputObject.CategoryInfo.Category -eq 'ParserError') {
        $prefixLength = [System.Management.Automation.Internal.StringDecorated]::new($prefix).ContentLength
        $prefixVtLength = $prefix.Length - $prefixLength

        # replace newlines in message so it lines up correct
        $message = $message.Replace($newline, ' ').Replace("`n", ' ').Replace("`t", ' ')

        $windowWidth = 120
        if ($null -ne $Host.UI.RawUI) {
            $windowWidth = $Host.UI.RawUI.WindowSize.Width
        }

        if ($windowWidth -gt 0 -and ($message.Length - $prefixVTLength) -gt $windowWidth) {
            $sb = [Text.StringBuilder]::new()
            $substring = TruncateString -InputObject $message -length ($windowWidth + $prefixVTLength)
            $null = $sb.Append($substring)
            $remainingMessage = $message.Substring($substring.Length).Trim()
            $null = $sb.Append($newline)
            while (($remainingMessage.Length + $prefixLength) -gt $windowWidth) {
                $subMessage = $prefix + $remainingMessage
                $substring = TruncateString -InputObject $subMessage -length ($windowWidth + $prefixVtLength)

                if ($substring.Length - $prefix.Length -gt 0) {
                    $null = $sb.Append($substring)
                    $null = $sb.Append($newline)
                    $remainingMessage = $remainingMessage.Substring($substring.Length - $prefix.Length).Trim()
                } else {
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
    if ($InputObject.Exception -and $InputObject.Exception.WasThrownFromThrowStatement) {
        $reason = 'Exception'
        # MyCommand can be the script block, so we don't want to show that so check if it's an actual command
    } elseif ($Invocation.MyCommand -and $Invocation.MyCommand.Name -and (Get-Command -Name $Invocation.MyCommand -ErrorAction Ignore)) {
        $reason = $Invocation.MyCommand
    } elseif ($InputObject.CategoryInfo.Activity) {
        # If it's a scriptblock, better to show the command in the scriptblock that had the error
        $reason = $InputObject.CategoryInfo.Activity
    } elseif ($Invocation.MyCommand) {
        $reason = $Invocation.MyCommand
    } elseif ($Invocation.InvocationName) {
        $reason = $Invocation.InvocationName
    } elseif ($InputObject.CategoryInfo.Category) {
        $reason = $InputObject.CategoryInfo.Category
    } elseif ($InputObject.CategoryInfo.Reason) {
        $reason = $InputObject.CategoryInfo.Reason
    }

    "${errorColor}${reason}: ${posmsg}${resetcolor}"
}
