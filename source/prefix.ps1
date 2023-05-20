[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'ErrorView is all about the ErrorView global variable')]
param(
    $global:ErrorView = "Simple"
)

# We need to _overwrite_ the ErrorView
# So -PrependPath, instead of FormatsToProcess
Update-FormatData -PrependPath $PSScriptRoot\ErrorView.format.ps1xml