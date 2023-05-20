<#
.SYNOPSIS
    ./project.build.ps1
.EXAMPLE
    Invoke-Build
.NOTES
    0.5.0 - Parameterize
    Add parameters to this script to control the build
#>
[CmdletBinding()]
param(
    # dotnet build configuration parameter (Debug or Release)
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    # Add the clean task before the default build
    [switch]$Clean,

    # Collect code coverage when tests are run
    [switch]$CollectCoverage
)
$InformationPreference = "Continue"

$BuildTasks = "BuildTasks", "../BuildTasks", "../../BuildTasks" | Convert-Path -ErrorAction Ignore | Select-Object -First 1

## Self-contained build script - can be invoked directly or via Invoke-Build
if ($MyInvocation.ScriptName -notlike '*Invoke-Build.ps1') {
    & "$BuildTasks/_Bootstrap.ps1"

    Invoke-Build -File $MyInvocation.MyCommand.Path @PSBoundParameters -Result Result

    if ($Result.Error) {
        $Error[-1].ScriptStackTrace | Out-String
        exit 1
    }
    exit 0
}

## The first task defined is the default task
if ($Clean) {
    Add-BuildTask . Clean, Test
} else {
    Add-BuildTask . Test
}

## Initialize the build variables, and import shared tasks, including DotNet tasks
. "$BuildTasks/_Initialize.ps1" -PSModuleTasks