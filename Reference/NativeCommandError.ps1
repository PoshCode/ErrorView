$errorColor = ''
$commandPrefix = ''
if (@('NativeCommandErrorMessage','NativeCommandError') -notcontains $_.FullyQualifiedErrorId -and @('CategoryView','ConciseView','DetailedView') -notcontains $ErrorView)
{
    $myinv = $_.InvocationInfo
    if ($Host.UI.SupportsVirtualTerminal) {
        $errorColor = $PSStyle.Formatting.Error
    }

    $commandPrefix = if ($myinv -and $myinv.MyCommand) {
        switch -regex ( $myinv.MyCommand.CommandType )
        {
            ([System.Management.Automation.CommandTypes]::ExternalScript)
            {
                if ($myinv.MyCommand.Path)
                {
                    $myinv.MyCommand.Path + ' : '
                }

                break
            }

            ([System.Management.Automation.CommandTypes]::Script)
            {
                if ($myinv.MyCommand.ScriptBlock)
                {
                    $myinv.MyCommand.ScriptBlock.ToString() + ' : '
                }

                break
            }
            default
            {
                if ($myinv.InvocationName -match '^[&amp;\.]?$')
                {
                    if ($myinv.MyCommand.Name)
                    {
                        $myinv.MyCommand.Name + ' : '
                    }
                }
                else
                {
                    $myinv.InvocationName + ' : '
                }

                break
            }
        }
    }
    elseif ($myinv -and $myinv.InvocationName)
    {
        $myinv.InvocationName + ' : '
    }
}

$errorColor + $commandPrefix