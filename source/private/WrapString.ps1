
filter WrapString {
    [CmdletBinding()]
    param(
        # The input string will be wrapped to a certain length, with optional padding on the front
        [Parameter(ValueFromPipeline)]
        [string]$InputObject,

        # The maximum length of a line. Defaults to [Console]::BufferWidth - 1
        [Parameter(Position=0)]
        [int]$Width = ($Host.UI.RawUI.BufferSize.Width),

        # The padding for each line defaults to an empty string.
        # If set, whitespace on the front of each line is replaced with this string.
        [string]$IndentPadding = ([string]::Empty),

        # If set, this will be used only for the first line (defaults to IndentPadding)
        [string]$FirstLineIndent = $IndentPadding,

        # If set, wrapped lines use this instead of IndentPadding to create a hanging indent
        [string]$WrappedIndent  = $IndentPadding,


        # If set, colors to use for alternating lines
        [string[]]$Colors = @(''),

        # If set, will output empty lines for each original new line
        [switch]$EmphasizeOriginalNewlines
    )
    begin {
        $FirstLine = $true
        $color = 0;
        Write-Debug "Colors: $($Colors -replace "`e(.+)", "`e`$1``e`$1")"
        # $wrappableChars = [char[]]" ,.?!:;-`n`r`t"
        # $maxLength = $width - $IndentPadding.Length -1
        $wrapper = [Regex]::new("((?:$AnsiPattern)*[^-=,.?!:;\s\r\n\t\\\/\|]+(?:$AnsiPattern)*)", "Compiled")
        $output = [System.Text.StringBuilder]::new()
        $buffer = [System.Text.StringBuilder]::new()
        $lineLength = 0
        if ($Width -lt $IndentPadding.Length) {
            Write-Warning "Width $Width is less than IndentPadding length $($IndentPadding.Length). Setting Width to BufferWidth ($($Host.UI.RawUI.BufferSize.Width))"
        }
    }
    process {
        foreach($line in $InputObject -split "(\r?\n)") {
            if ($FirstLine -and $PSBoundParameters.ContainsKey('FirstLineIndent')) {
                $IndentPadding, $FirstLineIndent = $FirstLineIndent, $IndentPadding
            }
            # Don't bother trying to split empty lines
            if ([String]::IsNullOrWhiteSpace($AnsiRegex.Replace($line, ''))) {
                Write-Debug "Empty String ($($line.Length))"
                if ($EmphasizeOriginalNewlines) {
                    $null = $output.Append($newline)
                }
                continue
            }

            $slices = $line -split $wrapper | ForEach-Object { @{ Text = $_; Length = MeasureString $_ } }
            Write-Debug "$($line.Length) words in line. $($AnsiRegex.Replace($line, ''))"
            foreach($slice in $slices) {
                $lineLength += $slice.Length
                if ($lineLength -le $Width) {
                    Write-Verbose "+ $($slice.Length) = $lineLength < $Width"
                    $null = $buffer.Append($slice.Text)
                } else {
                    Write-Verbose "Output $($lineLength - $slice.Length)"
                    Write-Verbose "+ $($slice.Length) = $($slice.Length)"
                    #$null = $output.Append($buffer.ToString())
                    $null = $buffer.Append($newline).Append($WrappedIndent).Append($slice.Text)
                    $lineLength = $IndentPadding.Length + $slice.Length
                }
            }
            if (!$FirstLine) {
                $null = $output.Append($newline)
            }
            if ($PSBoundParameters.ContainsKey("IndentPadding")) {
                $null = $output.Append($Colors[$color] + $IndentPadding + $buffer.ToString().TrimStart())
            } else {
                $null = $output.Append($Colors[$color] + $buffer.ToString())
            }
            $color = ($color + 1) % $Colors.Length
            $null = $buffer.Clear() #.Append($Colors[$color]).Append($IndentPadding)
            $lineLength = $IndentPadding.Length
            $FirstLine = $false
            $IndentPadding = $FirstLineIndent
        }
        $output.ToString()
    }
}