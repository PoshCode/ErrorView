
filter Format-String {
    <#
        .SYNOPSIS
            Formats a string to fit within a certain width, with optional indentation and alternating colors
        .DESCRIPTION
            Wraps a string on word breaks to fit within a certain width.
            Preserves virtual terminal escape sequences, and supports indenting,
            including different indents for the first line and others.

            Ignores ANSI escape sequences when measuring the length,
            and handles wide characters (including treating emoji as 2 characters wide).
        .LINK
            Measure-String
    #>
    [Alias("WrapString")]
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
        [Alias("HangingIndent")]
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
        $output = [System.Text.StringBuilder]::new()
        $buffer = [System.Text.StringBuilder]::new()
        $lineLength = 0
        if ($Width -lt $IndentPadding.Length) {
            Write-Warning "Width $Width is less than IndentPadding length $($IndentPadding.Length). Setting Width to BufferWidth ($($Host.UI.RawUI.BufferSize.Width))"
        }
    }
    process {
        $output = [System.Text.StringBuilder]::new()
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

            $slices = $line -split $WordBoundaryRegex | Where-Object { $_.Length } | ForEach-Object { @{ Text = $_; Length = Measure-String $_ -EmojiAsWide } }
            Write-Debug "$($line.Length) characters in line in $($slices.Count) words. $($AnsiRegex.Replace($line, ''))"
            $lineLength = $IndentPadding.Length
            foreach($slice in $slices) {
                $lineLength = $lineLength + $slice.Length
                Write-Verbose "+ $($slice.Length) = $lineLength <= $Width '$($slice.Text -replace "`e","``e")'"
                if ($lineLength -le $Width) {
                    if ($lineLength -eq $slice.Length -and [string]::IsNullOrWhitespace($slice.Text)) {
                        Write-Debug "Skip whitespace '$($slice.Text)'"
                        $lineLength = $lineLength - $slice.Length
                        continue
                    }
                    $null = $buffer.Append($slice.Text)
                } elseif ($slice.Length -gt $Width) {
                    Write-Debug "Slice too long $($slice.Length) > $Width"
                    $needLength = $Width - ($lineLength - $slice.Length)

                    $remains = $slice
                    # If the slice is too long for a line, it's going to wrap anyway, so do it ourselves
                    while($remains.Length -gt $needLength) {
                        $next, $remains = $remains.Text -split "((?:(?:$AnsiPattern)*.(?:$AnsiPattern)*){1,$needLength})", 2 | Where-Object { $_.Length } | ForEach-Object { @{ Text = $_; Length = Measure-String $_ -EmojiAsWide } }
                        $null = $buffer.Append($next.Text).Append($newline).Append($WrappedIndent)
                        $lineLength = $WrappedIndent.Length
                        $needLength = $Width - $lineLength
                    }

                    # Don't start a line with whitespace
                    if (![string]::IsNullOrWhitespace($remains.Text)) {
                        Write-Debug "Output $($lineLength) not whitespace '$($remains.Text)'"
                        $null = $buffer.Append($remains.Text)
                        $lineLength = $lineLength + $remains.Length
                    }

                } else {
                    Write-Verbose "Output $($lineLength - $slice.Length)"
                    $null = $buffer.Append($newline).Append($WrappedIndent)
                    $lineLength = $WrappedIndent.Length
                    # Don't start a line with whitespace
                    if (![string]::IsNullOrWhitespace($slice.Text)) {
                        Write-Debug "Output $($lineLength) not whitespace '$($slice.Text)'"
                        $null = $buffer.Append($slice.Text)
                        $lineLength = $WrappedIndent.Length + $slice.Length
                    }
                }
            }
            if (!$FirstLine) {
                $null = $output.Append($newline)
            }
            if ($PSBoundParameters.ContainsKey("IndentPadding")) {
                $null = $output.Append($Colors[$color] + $IndentPadding + (<# TrimAnsi #> $buffer.ToString().TrimStart()))
            } else {
                $null = $output.Append($Colors[$color] + (<# TrimAnsi #> $buffer.ToString()))
            }
            $color = ($color + 1) % $Colors.Length
            $null = $buffer.Clear() #.Append($Colors[$color]).Append($IndentPadding)
            $lineLength = $IndentPadding.Length
            $FirstLine = $false
            $IndentPadding = $FirstLineIndent
        }
        $output.ToString() -replace "\s(?=$newline)" # trim trailing whitespace from each line
    }
}