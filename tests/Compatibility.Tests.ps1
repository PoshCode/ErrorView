#requires -Module Pansies
Describe "Format-Error produces the same results" {
    BeforeAll {
        $_cacheErrorView = $global:ErrorView
        try {
            Invoke-Expression '$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd, Split-Path -Leaf $pwd'
        } catch { }
        $TestError = $Error[0]

        # Try to clear our ErrorView format data
        Remove-Item "$PSScriptRoot/../output/ErrorView/ErrorView.backup" -ErrorAction Ignore
        Rename-Item "$PSScriptRoot/../output/ErrorView/ErrorView.format.ps1xml" "ErrorView.backup"
        Set-Content "$PSScriptRoot/../output/ErrorView/ErrorView.format.ps1xml" (
            '<?xml version="1.0" encoding="utf-8" ?>' + "`n" +
            '<Configuration><ViewDefinitions></ViewDefinitions></Configuration>')
        Remove-Module ErrorView -ErrorAction SilentlyContinue
        Update-FormatData


        [System.Management.Automation.ErrorView]$global:ErrorView = 'ConciseView'
        $ExpectedConciseView = $TestError | Out-String
        Write-Host "$($PSStyle.Foreground.Red)ExpectedConciseView: " $PSStyle.Reset $ExpectedConciseView

        [System.Management.Automation.ErrorView]$global:ErrorView = 'NormalView'
        $ExpectedNormalView = $TestError | Out-String
        Write-Host "$($PSStyle.Foreground.Red)ExpectedNormalView: " $PSStyle.Reset $ExpectedNormalView

        [System.Management.Automation.ErrorView]$global:ErrorView = 'CategoryView'
        $ExpectedCategoryView = $TestError | Out-String
        Write-Host "$($PSStyle.Foreground.Red)ExpectedCategoryView: " $PSStyle.Reset $ExpectedCategoryView

        [System.Management.Automation.ErrorView]$global:ErrorView = 'DetailedView'
        $ExpectedDetailedView = $TestError | Out-String
        # Write-Host "$($PSStyle.Foreground.Red)ExpectedDetailedView: " $PSStyle.Reset $ExpectedDetailedView

        Remove-Item "$PSScriptRoot/../output/ErrorView/ErrorView.format.ps1xml" -ErrorAction Ignore
        Rename-Item "$PSScriptRoot/../output/ErrorView/ErrorView.backup" "ErrorView.format.ps1xml"
        Import-Module $PSScriptRoot/../output/ErrorView/ErrorView.psd1 -Force

    }
    AfterAll {
        $global:ErrorView = $_cacheErrorView
    }

    It 'As the default CategoryView' {
        $actual = $TestError | Format-Error -View CategoryView | Out-String
        $actual | Should -Be $ExpectedCategoryView
    }
    It 'As the default ConciseView' {
        $actual = $TestError | Format-Error -View ConciseView | Out-String
        $actual | Should -Be $ExpectedConciseView
    }
    It 'As the default NormalView' {
        $actual = $TestError | Format-Error -View NormalView | Out-String
        $actual | Should -Be $ExpectedNormalView
    }
    It 'As the default DetailedView' {
        $actual = $TestError | Format-Error -View DetailedView | Out-String
        $actual | Should -Be $ExpectedDetailedView
    }

}