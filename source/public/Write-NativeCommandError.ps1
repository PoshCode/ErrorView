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
    if ($InputObject -is [System.Exception]) {
        $errorColor + $InputObject.GetType().FullName + " : " + $resetColor
    }

    # @('NativeCommandErrorMessage', 'NativeCommandError') -notcontains $_.FullyQualifiedErrorId -and @('CategoryView', 'ConciseView', 'DetailedView') -notcontains $ErrorView
    if (@('NativeCommandErrorMessage', 'NativeCommandError') -notcontains $_.FullyQualifiedErrorId -and @('CategoryView', 'ConciseView', 'DetailedView') -notcontains $ErrorView) {
        $invoc = $InputObject.InvocationInfo
        if ($invoc -and $invoc.MyCommand) {
            switch -regex ( $invoc.MyCommand.CommandType ) {
                ([System.Management.Automation.CommandTypes]::ExternalScript) {
                    if ($invoc.MyCommand.Path) {
                        $errorColor + $invoc.MyCommand.Path + " : " + $resetColor
                    }
                    break
                }
                ([System.Management.Automation.CommandTypes]::Script) {
                    if ($invoc.MyCommand.ScriptBlock) {
                        $errorColor + $invoc.MyCommand.ScriptBlock.ToString() + " : " + $resetColor
                    }
                    break
                }
                default {
                    if ($invoc.InvocationName -match '^[&amp;\.]?$') {
                        if ($invoc.MyCommand.Name) {
                            $errorColor + $invoc.MyCommand.Name + " : " + $resetColor
                        }
                    } else {
                        $errorColor + $invoc.InvocationName + " : " + $resetColor
                    }
                    break
                }
            }
        } elseif ($invoc -and $invoc.InvocationName) {
            $errorColor + $invoc.InvocationName + " : " + $resetColor
        }
    }
}