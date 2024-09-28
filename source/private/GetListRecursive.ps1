function GetListRecursive {
    <#
        .SYNOPSIS
            Internal implementation of the Detailed error view to support recursion and indentation
    #>
    [CmdletBinding()]
    param(
        $InputObject,
        [int]$indent = 0,
        [int]$depth = 1
    )
    $output = [System.Text.StringBuilder]::new()
    $padding = ' ' * $indent

    $expandTypes = @(
        'Microsoft.Rest.HttpRequestMessageWrapper'
        'Microsoft.Rest.HttpResponseMessageWrapper'
        'System.Management.Automation.InvocationInfo'
    )

    # The built-in DetailedView aligns all the ":" characters, but it's awful

    $addedProperty = $false
    foreach ($prop in $InputObject.PSObject.Properties) {
        # PowerShell creates an ErrorRecord property on Exceptions that points back to the parent ErrorRecord.
        # This is basically a circular reference that causes repeated informtion, so we're going to skip them
        if ($prop.Value -is [System.Management.Automation.ErrorRecord] -and $depth -ge 2) {
            continue
        }
        # don't show empty properties or our added property for $error[index]
        if ($null -ne $prop.Value -and $prop.Value -ne [string]::Empty -and $prop.Value.count -gt 0 -and $prop.Name -ne 'PSErrorIndex') {
            $addedProperty = $true
            $null = $output.Append($padding)
            $null = $output.Append($accentColor)
            $null = $output.Append($prop.Name)
            $null = $output.Append(': ')
            $null = $output.Append($resetColor)

            [int]$nextIndent = $indent + 2
            [int]$nextDepth = $depth + 1
            $nextPadding = ' ' * $nextIndent

            # only show nested objects that are Exceptions, ErrorRecords, or types defined in $expandTypes
            if ($prop.Value -is [Exception] -or
                $prop.Value -is [System.Management.Automation.ErrorRecord] -or
                $expandTypes -contains $prop.TypeNameOfValue -or
                        ($null -ne $prop.TypeNames -and $expandTypes -contains $prop.TypeNames[0])) {

                if ($depth -ge $maxDepth) {
                    $null = $output.Append($ellipsis)
                } else {
                    # For Exceptions, add a fake "Type" property
                    if ($prop.Value -is [Exception]) {
                        $null = $output.Append(( $accentColor + "[" + $prop.Value.GetType().FullName + "]" + $resetColor))
                    }
                    $null = $output.Append($newline)
                    $null = $output.Append((GetListRecursive $prop.Value $nextIndent $nextDepth))
                }
            } elseif ($prop.Name -eq 'TargetSite' -and $prop.Value.GetType().Name -eq 'RuntimeMethodInfo') {
                # `TargetSite` has many members that are not useful visually, so we have a reduced view of the relevant members
                if ($depth -ge $maxDepth) {
                    $null = $output.Append($ellipsis)
                } else {
                    $targetSite = [PSCustomObject]@{
                        Name          = $prop.Value.Name
                        DeclaringType = $prop.Value.DeclaringType
                        MemberType    = $prop.Value.MemberType
                        Module        = $prop.Value.Module
                    }

                    $null = $output.Append($newline)
                    $null = $output.Append((GetListRecursive $targetSite $nextIndent $nextDepth))
                }
            } elseif ($prop.Name -eq 'StackTrace') {
                # StackTrace is handled specifically because the lines are typically long but we can't trucate them, so we don't indent it any more
                $null = $output.Append($newline)
                # $null = $output.Append($prop.Value)
                $Wrap = @{
                    Width = $Host.UI.RawUI.BufferSize.Width - 2
                    IndentPadding = ""
                    HangingIndent = "   "
                }
                $null = $output.Append(($prop.Value | WrapString @Wrap))
            } elseif ($prop.Name -eq 'HResult') {
                # `HResult` is handled specifically so we can format it in hex
                # $null = $output.Append($newline)
                $null = $output.Append("0x{0:x} ({0})" -f $prop.Value)
            } elseif ($prop.Name -eq 'PipelineIterationInfo') {
                # I literally have no idea what use this is
                $null = $output.Append($prop.Value -join ', ')
            } elseif ($prop.Value.GetType().Name.StartsWith('Dictionary') -or $prop.Value.GetType().Name -eq 'Hashtable') {
                # Dictionary and Hashtable we want to show as Key/Value pairs
                $null = $output.Append($newline)
                foreach ($key in $prop.Value.Keys) {
                    if ($key -eq 'Authorization') {
                        $null = $output.Append("${nextPadding}${accentColor}${key}: ${resetColor}${ellipsis}${newline}")
                    } else {
                        $null = $output.Append("${nextPadding}${accentColor}${key}: ${resetColor}$($prop.Value[$key])${newline}")
                    }
                }
            } elseif (!($prop.Value -is [System.String]) -and $null -ne $prop.Value.GetType().GetInterface('IEnumerable') -and $prop.Name -ne 'Data') {
                # if the object implements IEnumerable and not a string, we try to show each object
                # We ignore the `Data` property as it can contain lots of type information by the interpreter that isn't useful here

                if ($depth -ge $maxDepth) {
                    $null = $output.Append($ellipsis)
                } else {
                    $isFirstElement = $true
                    foreach ($value in $prop.Value) {
                        $null = $output.Append($newline)

                        if ($value -is [Type]) {
                            # Just show the typename instead of it as an object
                            $null = $output.Append("${nextPadding}[$($value.ToString())]")
                        } elseif ($value -is [string] -or $value.GetType().IsPrimitive) {
                            $null = $output.Append("${nextPadding}${value}")
                        } else {
                            if (!$isFirstElement) {
                                $null = $output.Append($newline)
                            }
                            $null = $output.Append((GetListRecursive $value $nextIndent $nextDepth))
                        }
                        $isFirstElement = $false
                    }
                }
            }  elseif ($prop.Value -is [Type]) {
                # Just show the typename instead of it as an object
                $null = $output.Append("[$($prop.Value.ToString())]")
            } else {
                # Anything else, we convert to string.
                # ToString() can throw so we use LanguagePrimitives.TryConvertTo() to hide a convert error
                $value = $null
                if ([System.Management.Automation.LanguagePrimitives]::TryConvertTo($prop.Value, [string], [ref]$value) -and $null -ne $value) {
                    $value = $value.Trim()
                    if ($InputObject -is [System.Management.Automation.InvocationInfo] -and $prop.Name -eq 'PositionMessage') {
                        # Make the underline red
                        $value = $value.Insert($value.IndexOf('~'), $errorColor)
                    } elseif ( ($InputObject -is [System.Management.Automation.ErrorRecord] -or
                                $InputObject -is [System.Exception]) -and $prop.Name -in 'Message', 'FullyQualifiedErrorId', 'CategoryInfo') {
                        $value = $errorColor + $value
                    }
                    $Wrap = @{
                        Width = $Host.UI.RawUI.BufferSize.Width - 2
                        IndentPadding = " " * ($nextIndent + $prop.Name.Length)
                    }

                    $null = $output.Append(($value | WrapString @Wrap).TrimStart())
                }
            }

            $null = $output.Append($newline)
        }
    }

    # if we had added nested properties, we need to remove the last newline
    if ($addedProperty) {
        $null = $output.Remove($output.Length - $newline.Length, $newline.Length)
    }

    $output.ToString()
    Write-Information "EXIT GetListRecursive END $($InputObject.GetType().FullName) $indent $depth (of $maxDepth)" -Tags 'Trace', 'Enter', 'GetListRecursive'
}
