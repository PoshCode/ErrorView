if ($ErrorViewArgument) {
    Set-ErrorView $ErrorViewArgument
} elseif ($Env:GITHUB_ACTIONS -or $Env:TF_BUILD) {
    Set-ErrorView "DetailedErrorView"
} else {
    Set-ErrorView "ConciseView"
}