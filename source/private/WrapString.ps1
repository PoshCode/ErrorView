$script:AnsiPattern = "[\u001b\u009b][[\]()#;?]*(?:(?:(?:(?:;[-a-zA-Z\d\/#&.:=?%@~_]+)*|[a-zA-Z\d]+(?:;[-a-zA-Z\d\/#&.:=?%@~_]*)*)?(?:\u001b\u005c|\u0007))|(?:(?:\d{1,4}(?:;\d{0,4})*)?[\dA-PR-TZcf-nq-uy=><~]))"
$script:AnsiRegex = [Regex]::new($AnsiPattern, "Compiled");
function MeasureString {
    [CmdletBinding()]
    param(
        [string]$InputObject
    )
    $AnsiRegex.Replace($InputObject, '').Length
}


filter WrapString {
    [CmdletBinding()]
    param(
        # The input string will be wrapped to a certain length, with optional padding on the front
        [Parameter(ValueFromPipeline)]
        [string]$InputObject,

        # The maximum length of a line. Defaults to [Console]::BufferWidth - 1
        [Parameter(Position=0)]
        [int]$Width = ($Host.UI.RawUI.BufferSize.Width),

        # The padding to add to the front of each line to cause indenting. Defaults to empty string.
        [Parameter(Position=1)]
        [string]$IndentPadding = ([string]::Empty),

        # If set, colors to use for alternating lines
        [string[]]$Colors = @(''),

        # If set, will output empty lines for each original new line
        [switch]$EmphasizeOriginalNewlines
    )
    begin {
        $color = 0;
        Write-Debug "Colors: $($Colors -replace "`e(.+)", "`e`$1``e`$1")"
        # $wrappableChars = [char[]]" ,.?!:;-`n`r`t"
        # $maxLength = $width - $IndentPadding.Length -1
        $wrapper = [Regex]::new("((?:$AnsiPattern)*[^-=,.?!:;\s\r\n\t\\\/\|]+(?:$AnsiPattern)*)", "Compiled")
        $output = [System.Text.StringBuilder]::new()
        $buffer = [System.Text.StringBuilder]::new($Colors[$color])
        $lineLength = 0
        if ($Width -lt $IndentPadding.Length) {
            Write-Warning "Width $Width is less than IndentPadding length $($IndentPadding.Length). Setting Width to BufferWidth ($($Host.UI.RawUI.BufferSize.Width))"
        }
    }
    process {
        foreach($line in $InputObject -split "(\r?\n)") {
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
                    $color = ($color + 1) % $Colors.Length
                    #$null = $output.Append($buffer.ToString())
                    $null = $buffer.Append($newline).Append($slice.Text)
                    $lineLength = $IndentPadding.Length + $slice.Length
                }
            }
            $null = $output.Append($buffer.ToString())
            $null = $buffer.Clear().Append($newline).Append($Colors[$color]).Append($IndentPadding)
            $lineLength = $IndentPadding.Length
        }
        $output.ToString()
    }
}