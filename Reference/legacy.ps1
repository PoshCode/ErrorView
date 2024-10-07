if ($_.FullyQualifiedErrorId -eq "NativeCommandErrorMessage") {
    $_.Exception.Message
}
else
{
    $myinv = $_.InvocationInfo
    if ($myinv -and ($myinv.MyCommand -or ($_.CategoryInfo.Category -ne 'ParserError'))) {
        $posmsg = $myinv.PositionMessage
    } else {
        $posmsg = ""
    }

    if ($posmsg -ne "")
    {
        $posmsg = "`n" + $posmsg
    }

    if ( & { Set-StrictMode -Version 1; $_.PSMessageDetails } ) {
        $posmsg = " : " +  $_.PSMessageDetails + $posmsg
    }

    $indent = 4
    $width = $host.UI.RawUI.BufferSize.Width - $indent - 2

    $errorCategoryMsg = &amp; { Set-StrictMode -Version 1; $_.ErrorCategory_Message }
    if ($errorCategoryMsg -ne $null)
    {
        $indentString = "+ CategoryInfo          : " + $_.ErrorCategory_Message
    }
    else
    {
        $indentString = "+ CategoryInfo          : " + $_.CategoryInfo
    }
    $posmsg += "`n"
    foreach($line in @($indentString -split "(.{$width})")) { if($line) { $posmsg += (" " * $indent + $line) } }

    $indentString = "+ FullyQualifiedErrorId : " + $_.FullyQualifiedErrorId
    $posmsg += "`n"
    foreach($line in @($indentString -split "(.{$width})")) { if($line) { $posmsg += (" " * $indent + $line) } }

    $originInfo = &amp; { Set-StrictMode -Version 1; $_.OriginInfo }
    if (($originInfo -ne $null) -and ($originInfo.PSComputerName -ne $null))
    {
        $indentString = "+ PSComputerName        : " + $originInfo.PSComputerName
        $posmsg += "`n"
        foreach($line in @($indentString -split "(.{$width})")) { if($line) { $posmsg += (" " * $indent + $line) } }
    }

    if ($ErrorView -eq "CategoryView") {
        $_.CategoryInfo.GetMessage()
    }
    elseif (! $_.ErrorDetails -or ! $_.ErrorDetails.Message) {
        $_.Exception.Message + $posmsg + "`n "
    } else {
        $_.ErrorDetails.Message + $posmsg
    }
}