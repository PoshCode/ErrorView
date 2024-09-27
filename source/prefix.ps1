[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'ErrorView is all about the ErrorView global variable')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Seriously. Stop complaining about ErrorView')]
param(
    $global:ErrorView = "Simple"
)

# We need to _overwrite_ the ErrorView
# So -PrependPath, instead of using FormatsToProcess
Update-FormatData -PrependPath $PSScriptRoot\ErrorView.format.ps1xml

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
trap { 'Error found in error view definition: ' + $_.Exception.Message }

# Borrowed this one from https://github.com/chalk/ansi-regex
$script:AnsiEscapes = [Regex]::new("([\u001b\u009b][[\]()#;?]*(?:(?:(?:(?:;[-a-zA-Z\d\/#&.:=?%@~_]+)*|[a-zA-Z\d]+(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?(?:\u001b\u005c|\u0007))|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-nq-uy=><~])))", "Compiled");

# starting with an escape character and then...
# ESC ] <anything> <ST> - where ST is either 1B 5C or 7 (BEL, aka `a)
# ESC [ non-letters letter (or ~, =, @, >)
# ESC ( <any character>
# ESC O P
# ESC O Q
# ESC O R
# ESC O S
# $script:AnsiEscapes = [Regex]::new("\x1b[\(\)%`"&\.\/*+.-][@-Z]|\x1b\].*?(?:\u001b\u005c|\u0007|^)|\x1b\[\P{L}*[@-_A-Za-z^`\{\|\}~]|\x1b#\d|\x1b[!-~]", [System.Text.RegularExpressions.RegexOptions]::Compiled);

$script:ellipsis = [char]0x2026
$script:newline = [Environment]::Newline
$script:LineColors = @(
    "`e[38;2;255;255;255m"
    "`e[38;2;179;179;179m"
)
