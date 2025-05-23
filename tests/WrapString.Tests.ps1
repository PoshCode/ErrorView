#requires -Module Pansies
Describe WrapString {
    BeforeAll {
        $CommandUnderTest = & (Get-Module ErrorView) { Get-Command WrapString }
        $newline = [Environment]::Newline
    }

    It "Word-wraps text to keep it under a specified width" {
        "The quick brown fox jumped over the lazy dog and then ran away with the unicorn." |
            & $CommandUnderTest -Width 20 <# -Verbose #> |
            Should -Be "The quick brown fox${newline}jumped over the lazy${newline}dog and then ran${newline}away with the${newline}unicorn."
    }
    It "Does not count ANSI escape sequences as characters" {
        "${bg:Gray20}The quick brown ${fg:red}fox${fg:clear} jumped over the lazy ${fg:green}dog and then ran away with the unicorn.${fg:clear}${bg:Clear}" |
            & $CommandUnderTest -Width 20 <# -Verbose #> |
            Should -Be "${bg:Gray20}The quick brown ${fg:red}fox${fg:clear}${newline}jumped over the lazy${newline}${fg:green}dog and then ran${newline}away with the${newline}unicorn.${fg:clear}${bg:Clear}"
    }
}
