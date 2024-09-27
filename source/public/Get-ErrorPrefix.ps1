filter Get-ErrorPrefix {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    if (@('NativeCommandErrorMessage', 'NativeCommandError') -notcontains $_.FullyQualifiedErrorId) {
        if ($InputObject -is [System.Exception]) {
            $InputObject.GetType().FullName + " : "
        } else {
            $myinv = $InputObject.InvocationInfo
            if ($myinv -and $myinv.MyCommand) {
                switch -regex ( $myinv.MyCommand.CommandType ) {
                    ([System.Management.Automation.CommandTypes]::ExternalScript) {
                        if ($myinv.MyCommand.Path) {
                            $myinv.MyCommand.Path + ' : '
                        }

                        break
                    }

                    ([System.Management.Automation.CommandTypes]::Script) {
                        if ($myinv.MyCommand.ScriptBlock) {
                            $myinv.MyCommand.ScriptBlock.ToString() + ' : '
                        }

                        break
                    }
                    default {
                        if ($myinv.InvocationName -match '^[&amp;\.]?$') {
                            if ($myinv.MyCommand.Name) {
                                $myinv.MyCommand.Name + ' : '
                            }
                        } else {
                            $myinv.InvocationName + ' : '
                        }

                        break
                    }
                }
            } elseif ($myinv -and $myinv.InvocationName) {
                $myinv.InvocationName + ' : '
            }
        }
    }
}