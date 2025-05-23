#requires -Module Pansies
Describe "Format-Error produces the same results for scriptblocks" {
    BeforeAll {
        # $Session = New-PSSession -EnableNetworkAccess
        # Invoke-Command -Session $Session { $ErrorView = 'ConciseView' }
        $ModuleVer = $GitVersion.$PSModuleName.MajorMinorPatch
        $PSModuleManifestPath = Get-ChildItem $PSModuleOutputPath/$ModuleVer -Filter "$PSModuleName.psd1" -Recurse -ErrorAction Ignore

        $NewConciseView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'ConciseView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )

        $OldConciseView = [ScriptBlock]::Create(
            "`$ErrorView = 'ConciseView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )

        $NewNormalView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'NormalView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )

        $OldNormalView = [ScriptBlock]::Create(
            "`$ErrorView = 'NormalView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )

        $NewCategoryView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'CategoryView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )

        $OldCategoryView = [ScriptBlock]::Create(
            "`$ErrorView = 'CategoryView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )
        $NewDetailedView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'DetailedView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )

        $OldDetailedView = [ScriptBlock]::Create(
            "`$ErrorView = 'DetailedView'`n" +
            '.{ Invoke-Expression ''$R = "$([char]27)]8;;{0}`a{0}$([char]27)]8;;`a" -f $pwd,'' } 2>&1 | Out-String'
        )
    }

    It 'As the default CategoryView' {
        $expectCV = pwsh -noprofile -c $OldConciseView
        $actualCV = pwsh -noprofile -c $NewConciseView
        $actualCV | Should -Be $expectCV
    }
    It 'As the default NormalView' {
        $expectNV = pwsh -noprofile -c $OldNormalView
        $actualNV = pwsh -noprofile -c $NewNormalView
        $actualNV | Should -Be $expectNV
    }
    It 'As the default CategoryView' {
        $expectCV = pwsh -noprofile -c $OldCategoryView
        $actualCV = pwsh -noprofile -c $NewCategoryView
        $actualCV | Should -Be $expectCV
    }
    It 'As the default DetailedView' {
        $expectDV = pwsh -noprofile -c $OldDetailedView
        $actualDV = pwsh -noprofile -c $NewDetailedView

        <# My DetailedView has the same information as the default, but without showing the ErrorRecord twice, so they aren't the same #>
        $expectDV = @($expectDV -split "\W+" | Sort-Object -uniq) -notmatch "^Type|ErrorRecord|ParentContainsErrorRecordException"
        # Also, I show the HResult in hex
        $actualDV = @($actualDV -split "\W+" | Sort-Object -uniq) -notmatch "0x80131501"
        # This test has failed once or twice, so I added this to help debug
        if ($expectDV -ne $actualDV) {
            $actualDV | Compare-Object $expectDV | Out-Host
        }
        $actualDV | Should -Be $expectDV
    }

}

Describe "Format-Error produces the same results for scriptblocks" {
    BeforeAll {
        # $Session = New-PSSession -EnableNetworkAccess
        # Invoke-Command -Session $Session { $ErrorView = 'ConciseView' }
        $ModuleVer = $GitVersion.$PSModuleName.MajorMinorPatch
        $PSModuleManifestPath = Get-ChildItem $PSModuleOutputPath/$ModuleVer -Filter "$PSModuleName.psd1" -Recurse -ErrorAction Ignore

        $NewConciseView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'ConciseView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )

        $OldConciseView = [ScriptBlock]::Create(
            "`$ErrorView = 'ConciseView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )

        $NewNormalView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'NormalView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )

        $OldNormalView = [ScriptBlock]::Create(
            "`$ErrorView = 'NormalView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )

        $NewCategoryView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'CategoryView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )

        $OldCategoryView = [ScriptBlock]::Create(
            "`$ErrorView = 'CategoryView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )
        $NewDetailedView = [ScriptBlock]::Create(
            "Import-Module -Name $PSModuleManifestPath -ArgumentList 'DetailedView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )

        $OldDetailedView = [ScriptBlock]::Create(
            "`$ErrorView = 'DetailedView'`n" +
            "$BuildRoot\tests\Write-AnError.ps1 2>&1 | Out-String"
        )
    }

    It 'As the default CategoryView' {
        $expectCV = pwsh -noprofile -c $OldConciseView
        $actualCV = pwsh -noprofile -c $NewConciseView
        $actualCV | Should -Be $expectCV
    }
    It 'As the default NormalView' {
        $expectNV = pwsh -noprofile -c $OldNormalView
        $actualNV = pwsh -noprofile -c $NewNormalView
        $actualNV | Should -Be $expectNV
    }
    It 'As the default CategoryView' {
        $expectCV = pwsh -noprofile -c $OldCategoryView
        $actualCV = pwsh -noprofile -c $NewCategoryView
        $actualCV | Should -Be $expectCV
    }
    It 'As the default DetailedView' {
        $global:expectDV = pwsh -noprofile -c $OldDetailedView
        $global:actualDV = pwsh -noprofile -c $NewDetailedView

        <# My DetailedView has the same information as the default, but without showing the ErrorRecord twice, so they aren't the same #>
        $expectDV = @($expectDV -split "\W+" | Sort-Object -uniq) -notmatch "^Type"
        # Also, I show the HResult in hex
        $actualDV = @($actualDV -split "\W+" | Sort-Object -uniq) -notmatch "0x80131500"
        # This test has failed once or twice, so I added this to help debug
        if ($expectDV -ne $actualDV) {
            $actualDV | Compare-Object $expectDV | Out-Host
        }
        $actualDV | Should -Be $expectDV
    }

}