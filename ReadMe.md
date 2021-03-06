# PowerShell ErrorView

## A module to help customize your view of Errors in PowerShell

This is a _very_ simple module. It exports one important command: `Format-Error` and a handful of formatting commands:

* `ConvertTo-CategoryErrorView`
* `ConvertTo-NormalErrorView`
* `ConvertTo-SimpleErrorView`
* `ConvertTo-FullErrorView`

### Install it from PSGallery

```powershell
Install-Module ErrorView
```

_When it's imported_, it sets PowerShell's global `$ErrorView` variable to "Simple" and provides an implementation as `ConvertTo-SimpleErrorView`.  **More importantly**, it allows you to write your own ErrorView! For example you could write a function or script `ConvertTo-SingleLineErrorView` and then set the preference variable `$ErrorView = "SingleLine"`, or even set it as you import the ErrorView module:

```powershell
Import-Module ErrorView -Args SingleLine
```

NOTE: by default, there is no "SingleLine" view in the ErrorView module. The default after importing the module is the "Simple" error view, which is currently a 2-line view.

![Some Examples of Formatted Errors](Resources/screenshot.png "Make sure you try Format-Error!")

### Format-Error

The `Format-Error` command lets you change the view temporarily to look at more details of errors, and even has a -Recurse switch to let error views show details of inner exceptions. If you have set your view to Simple (which is the default after importing the module), you can see the Normal view for the previous error by just running `Format-Error`. To see more than one error, you can look at the previous 5 errors like: `$error[0..4] | Format-Error`

### Custom Error Views

As stated above, the ErrorView module allows you to write your own formats. Here's an example, and a few pointers:

```powershell
function ConvertTo-SingleLineErrorView {
    param( [System.Management.Automation.ErrorRecord]$InputObject )
    -join @(
        $originInfo = &{ Set-StrictMode -Version 1; $InputObject.OriginInfo }
        if (($null -ne $originInfo) -and ($null -ne $originInfo.PSComputerName)) {
            "[" + $originInfo.PSComputerName + "]: "
        }

        $errorDetails = &{ Set-StrictMode -Version 1; $InputObject.ErrorDetails }
        if (($null -ne $errorDetails) -and ($null -ne $errorDetails.Message) -and ($InputObject.FullyQualifiedErrorId -ne "NativeCommandErrorMessage")) {
            $errorDetails.Message
        } else {
            $InputObject.Exception.Message
        }

        if ($ErrorViewRecurse) {
            $Prefix = "`n         Exception: "
            $Exception = &{ Set-StrictMode -Version 1; $InputObject.Exception }
            do {
                $Prefix + $Exception.GetType().FullName
                $Prefix = "`n    InnerException: "
            } while ($Exception = $Exception.InnerException)
        }
    )
}
```

1. The function **must** use the `ConvertTo` verb and "ErrorView" noun, with _your view name as the prefix_.
2. The function **must** have an `InputObject` parameter of type `System.Management.Automation.ErrorRecord`
3. There is a new global variable: `$ErrorViewRecurse` which is set by `Format-Error -Recurse`