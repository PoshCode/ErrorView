function Write-NativeCommandError {
    [CmdletBinding()]
    param(
        $InputObject
    )
    $resetColor = ''
    $errorColor = ''
    $accentColor = ''

    if ($Host.UI.SupportsVirtualTerminal -and ([string]::IsNullOrEmpty($env:__SuppressAnsiEscapeSequences))) {
        $resetColor = "$([char]0x1b)[0m"
        $errorColor = if ($PSStyle.Formatting.Error) { $PSStyle.Formatting.Error } else { "`e[1;31m" }
        $accentColor = $PSStyle.Formatting.ErrorAccent
    }

    if ($InputObject.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") { return }

    $invoc = $InputObject.InvocationInfo
    if ($invoc -and $invoc.MyCommand) {
        switch -regex ( $invoc.MyCommand.CommandType ) {
            ([System.Management.Automation.CommandTypes]::ExternalScript) {
                if ($invoc.MyCommand.Path) {
                    $accentColor + $invoc.MyCommand.Path + " : " + $resetColor
                }
                break
            }
            ([System.Management.Automation.CommandTypes]::Script) {
                if ($invoc.MyCommand.ScriptBlock) {
                    $accentColor + $invoc.MyCommand.ScriptBlock.ToString() + " : " + $resetColor
                }
                break
            }
            default {
                if ($invoc.InvocationName -match '^[&amp;\.]?$') {
                    if ($invoc.MyCommand.Name) {
                        $accentColor + $invoc.MyCommand.Name + " : " + $resetColor
                    }
                } else {
                    $accentColor + $invoc.InvocationName + " : " + $resetColor
                }
                break
            }
        }
    } elseif ($invoc -and $invoc.InvocationName) {
        $accentColor + $invoc.InvocationName + " : " + $resetColor
    }
}