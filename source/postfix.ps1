if ($script:ErrorView) {
    Set-ErrorView $ErrorView
} elseif ($Env:GITHUB_ACTIONS -or $Env:TF_BUILD) {
    Set-ErrorView "DetailedErrorView"
} else {
    Set-ErrorView "ConciseView"
}