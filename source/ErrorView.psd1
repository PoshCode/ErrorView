@{
    Description          = 'Enhances formatting of Errors, and provides compatibility for older versions of PowerShell'
    GUID                 = '5857f85c-8a0a-44e1-8da5-c8ff352167e0'
    Author               = 'Joel Bennett'
    CompanyName          = 'PoshCode'

    ModuleToProcess      = 'ErrorView.psm1'
    ModuleVersion        = '0.0.3'

    Copyright            = '(c) Joel Bennett. All rights reserved.'

    FunctionsToExport    = 'Format-Error', 'Set-ErrorView', 'Write-NativeCommandError', 'ConvertTo-CategoryErrorView', 'ConvertTo-NormalErrorView', 'ConvertTo-SimpleErrorView', 'ConvertTo-FullErrorView'

    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @("fe")

    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @("ErrorView")

            # A URL to the license for this module.
            LicenseUri = "http://opensource.org/licenses/MIT"

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/poshcode/errorview'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'I wrote this module to enhance ErrorViews for PowerShell (without waiting for PS7+)'

        } # End of PSData hashtable

    } # End of PrivateData hashtable

}

