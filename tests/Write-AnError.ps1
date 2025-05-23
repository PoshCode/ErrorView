[CmdletBinding()]
param (
    [Parameter()]
    [string]$Message = "We faked an error."
)

function Write-AnError {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$Message = "We faked an error."
    )

    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.Exception]::new($Message),
            "AnError",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
    )
}

Write-AnError @PSBoundParameters
