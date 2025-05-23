
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
            Optionally can treat ambiguous characters as wide
            Optionally can treat emoji characters wide
        .LINK
            Measure-String
    #>
    param(
        [ValidateNotNull()]
        [Parameter(ValueFromPipeline)]
        [string]$string,

        [switch]$AmbiguousAsWide,

        [switch]$EmojiAsWide,

        [switch]$countAnsiEscapeCodes
    )
    if ($string.length -eq 0) {
        return 0;
    }

    if (!$countAnsiEscapeCodes) {
        $string = $string -replace $AnsiRegex
    }

    if ($string.length -eq 0) {
        return 0;
    }

    # PowerShell 5 (.NET 4) isn't UAX 29 compliant
    $width = 0;
    foreach ($character in $string.GetEnumerator()) {
        $codePoint = [int]$character;

        # Ignore control characters
        if ($codePoint -le 0x1F -or ($codePoint -ge 0x7F -and $codePoint -le 0x9F)) {
            continue
        }

        # Ignore zero-width characters
        if (($codePoint -ge 0x200B -and $codePoint -le 0x200F) -or # Zero-width space, non-joiner, joiner, left-to-right mark, right-to-left mark
            $codePoint -eq 0xFEFF ) {
            # Zero-width no-break space# Zero-width no-break space
            continue
        }

        # Ignore combining characters
        if (($codePoint -ge 0x300 -and $codePoint -le 0x36F) -or # Combining diacritical marks
            ($codePoint -ge 0x1AB0 -and $codePoint -le 0x1AFF) -or # Combining diacritical marks extended
            ($codePoint -ge 0x1DC0 -and $codePoint -le 0x1DFF) -or # Combining diacritical marks supplement
            ($codePoint -ge 0x20D0 -and $codePoint -le 0x20FF) -or # Combining diacritical marks for symbols
            ($codePoint -ge 0xFE20 -and $codePoint -le 0xFE2F)) {
            # Combining half marks
            continue
        }

        # Ignore surrogate pairs
        if ($codePoint -ge 0xD800 -and $codePoint -le 0xDFFF) {
            continue
        }

        # Ignore variation selectors
        if ($codePoint -ge 0xFE00 -and $codePoint -le 0xFE0F) {
            continue
        }

        # This covers some of the above cases, but we still keep them for performance reasons.
        if ([Char]::GetUnicodeCategory($character) -in 'NonSpacingMark', 'SpacingCombiningMark', 'EnclosingMark', 'Format') {
            continue
        }

        if ($character -match $EmojiRegex) {
            if ($EmojiAsWide) {
                $width += 2 # Treat emojis as double width
            } else {
                $width += 1 # Treat emojis as single width
            }
            continue
        }

        $width += Measure-EastAsianWidth $codePoint -AmbiguousAsWide:$AmbiguousAsWide
    }

    return $width;
}