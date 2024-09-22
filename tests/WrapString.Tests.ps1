#requires -Module Pansies
Describe WrapString {
    BeforeAll {
        $CommandUnderTest = & (Get-Module ErrorView) { Get-Command WrapString }
    }

    It "Word-wraps text to keep it under a specified width" {
        "The quick brown fox jumped over the lazy dog and then ran away with the unicorn." |
            & $CommandUnderTest -Width 20 <# -Verbose #> |
            Should -Be "The quick brown fox", "jumped over the lazy", "dog and then ran", "away with the", "unicorn."
    }
    It "Does not count ANSI escape sequences as characters" {
        "The quick brown ${fg:red}fox${fg:clear} jumped over the lazy ${fg:green}dog and then ran away with the unicorn.${fg:clear}" |
            & $CommandUnderTest -Width 20 <# -Verbose #> |
            Should -Be "The quick brown ${fg:red}fox${fg:clear}", "jumped over the lazy", "${fg:green}dog and then ran", "away with the", "unicorn.${fg:clear}"
    }
}
