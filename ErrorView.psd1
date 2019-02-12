@{
    Description          = 'Enhances formatting ability for Errors'
    GUID                 = '5857f85c-8a0a-44e1-8da5-c8ff352167e0'
    Author               = 'Joel Bennett'
    CompanyName          = 'PoshCode'

    RootModule           = 'ErrorView.psm1'
    ModuleVersion        = '0.0.1'
    CompatiblePSEditions = @("Core", "Desktop")

    Copyright            = '(c) Joel Bennett. All rights reserved.'

    FunctionsToExport    = 'Format-Error', 'Write-NativeCommandError', 'ConvertTo-CategoryErrorView', 'ConvertTo-NormalErrorView', 'ConvertTo-SimpleErrorView'

    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @("fe")

PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfoURI = ''
}

