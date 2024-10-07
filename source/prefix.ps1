param(
    $ErrorView
)

# We need to _overwrite_ the ErrorView, so we must use -PrependPath
Update-FormatData -PrependPath $PSScriptRoot\ErrorView.format.ps1xml

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'
trap { 'Error found in error view definition: ' + $_.Exception.Message }

$script:ellipsis = [char]0x2026
$script:newline = [Environment]::Newline
$script:LineColors = @(
    "`e[38;2;255;255;255m"
    "`e[38;2;179;179;179m"
)