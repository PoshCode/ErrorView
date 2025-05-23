filter TruncateString {
    [CmdletBinding()]
    param(
        # The input string will be wrapped to a certain length, with optional padding on the front
        [Parameter(ValueFromPipeline)]
        [string]$InputObject,

        [Parameter(Position = 0)]
        [Alias('Length')]
        [int]$Width = ($Host.UI.RawUI.BufferSize.Width)
    )
    # $wrappableChars = [char[]]" ,.?!:;-`n`r`t"
    # $maxLength = $width - $IndentPadding.Length -1
    $wrapper = [Regex]::new("((?:$AnsiPattern)*[^-=,.?!:;\s\r\n\t\\\/\|]+(?:$AnsiPattern)*)", "Compiled")

    if ($InputObject.Length -le $Width) {
        return $InputObject
    }

    ($InputObject.Substring(0,$length) -split $wrapper,-2)[0]
}

function TrimAnsi($string) {
    $words = $string -split ' '
    $last = $words.length;

    while ($last > 0) {
        if ((Measure-String $words[$last - 1]) -gt 0) {
            break
        }

        $last--
    }

    if ($last -ne $words.length) {
        return $string
    }

    ($words[0..$last] -join ' ') + ($words[$last..$words.length] -join '')
}