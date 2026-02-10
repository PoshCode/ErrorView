
# https://github.com/sindresorhus/string-width

# import stripAnsi from 'strip-ansi';
# import {eastAsianWidth} from 'get-east-asian-width';
# import emojiRegex from 'emoji-regex';

# const segmenter = new Intl.Segmenter();

# const defaultIgnorableCodePointRegex = /^\p{Default_Ignorable_Code_Point}$/u;

filter Measure-String {
    <#
        .SYNOPSIS
            Measures the length of a string with support for escape sequences and wide characters
        .DESCRIPTION
            By default, ignores ANSI escape sequences when measuring the length
            Optionally can count ambiguous characters as wide
            Optionally can count emoji characters as single characters (defaults to double because that's how they are typically displayed in terminals)
        .LINK
            Measure-String
    #>
    param(
        [ValidateNotNull()]
        [Parameter(ValueFromPipeline)]
        [string]$string,

        # Set AmbiguousAsWide to count ambiguous width characters as 2 characters wide.
        # By default, they are counted as a single character.
        [switch]$AmbiguousAsWide,

        # Set EmojiAsSingle to count emoji as a single character.
        # By default, we count emoji as wide (2 characters) because that's how they are typically displayed in terminals.
        [switch]$EmojiAsSingle,

        # Set CountAnsiEscapeCodes to include ANSI escape codes in the width count. By default, they are ignored.
        [switch]$CountAnsiEscapeCodes
    )
    if ($string.length -eq 0) {
        return 0;
    }

    if (!$CountAnsiEscapeCodes) {
        $string = $string -replace $AnsiRegex
    }

    if ($string.length -eq 0) {
        return 0;
    }

    # PowerShell 5 (.NET 4) isn't UAX 29 compliant, so this would not work correctly for grapheme clusters.
    # That is, in .NET Framework, GetTextElementEnumerator will split up "👩‍💻" into [👩, ZWJ, 💻] and count it as 3 instead of 1
    #requires -Version 7.5

    $width = 0;
    foreach ($element in [System.Globalization.StringInfo]::GetTextElementEnumerator($string)) {
        $codepoint = [char]::ConvertToUtf32($element, 0)
        # If the whole element is ignorable, skip it.
        if ($element -match "^[\p{IsCombiningDiacriticalMarks}\p{IsCombiningMarksforSymbols}\p{IsVariationSelectors}\p{M}]+$") {
            Write-Debug "Ignoring ignorable element: U+$('{0:x4}' -f $codepoint)"
            continue
        }

        if ($element -match $EmojiRegex) {
            if ($EmojiAsSingle) {
                Write-Debug "Treating emoji as single width: U+$('{0:x4}' -f $codepoint)"
                $width += 1 # Treat emojis as single width
            } else {
                Write-Debug "Treating emoji as double width: U+$('{0:x4}' -f $codepoint)"
                $width += 2 # Treat emojis as double width
            }
            continue
        }

        # If it starts with something that takes up no space, trim that to find the real codepoint to measure.
        if (!($element = $element -replace "^[\p{IsCombiningDiacriticalMarks}\p{IsCombiningMarksforSymbols}\p{IsVariationSelectors}\p{Cf}\p{M}]+")) {
            Write-Debug "Element started with ignorable characters: U+$('{0:x4}' -f $codepoint)"
            continue
        }
        # $codepoint = [char]::IsSurrogatePair($element, 0) ? [char]::ConvertToUtf32($element, 0) : [char]$element[0]
        $codepoint = [char]::ConvertToUtf32($element, 0)

        # Ignore control characters [\u0000-\u001F\u007F-\u009F]
        if ($codepoint -le 0x1F -or ($codepoint -ge 0x7F -and $codepoint -le 0x9F)) {
            Write-Debug "Ignoring control character: U+$('{0:x4}' -f $codepoint)"
            continue
        }

        # Ignore zero-width characters [\u200B-\u200D\uFEFF]
        if (($codepoint -ge 0x200B -and $codepoint -le 0x200F) -or # Zero-width space, non-joiner, joiner, left-to-right mark, right-to-left mark
            $codepoint -eq 0xFEFF ) {
            Write-Debug "Ignoring zero-width character: U+$('{0:x4}' -f $codepoint)"
            continue
        }

        # Ignore variation selectors [\uFE00-\uFE0F]
        if ($codepoint -ge 0xFE00 -and $codepoint -le 0xFE0F) {
            Write-Debug "Ignoring variation selector character: U+$('{0:x4}' -f $codepoint)"
            continue
        }

        $width += Measure-EastAsianWidth $codepoint -AmbiguousAsWide:$AmbiguousAsWide
        Write-Debug "After U+$('{0:x4}' -f $codepoint), width: $($width)"
    }

    return $width;
}