@{
    ModuleManifest           = "./source/ErrorView.psd1"
    CopyPaths                = 'ErrorView.format.ps1xml'
    Prefix                   = 'prefix.ps1'
    # The rest of the paths are relative to the manifest
    OutputDirectory          = ".."
    VersionedOutputDirectory = $true
}