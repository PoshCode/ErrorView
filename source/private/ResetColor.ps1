function ResetColor {
    $script:resetColor = ''
    $script:errorColor = ''
    $script:accentColor = ''

    if ($Host.UI.SupportsVirtualTerminal -and ([string]::IsNullOrEmpty($env:__SuppressAnsiEscapeSequences))) {
        $script:resetColor = "$([char]27)[0m"
        $script:errorColor = if ($null -ne $PSStyle.Formatting.Error) { $PSStyle.Formatting.Error } else { "`e[1;31m" }
        $script:accentColor = if ($null -ne $PSStyle.Formatting.ErrorAccent) { $PSStyle.Formatting.ErrorAccent } else { "`e[1;36m" }
    }
}