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
    Write-Information "ENTER GetListRecursive END $($InputObject.GetType().FullName) $indent $depth" -Tags 'Trace', 'Enter', 'GetListRecursive'
    Write-Information (Get-PSCallStack) -Tags 'Trace', 'StackTrace', 'GetListRecursive'
    $output = [System.Text.StringBuilder]::new()
    $prefix = ' ' * $indent

    $expandTypes = @(
        'Microsoft.Rest.HttpRequestMessageWrapper'
        'Microsoft.Rest.HttpResponseMessageWrapper'
        'System.Management.Automation.InvocationInfo'
    )

    # The built-in DetailedView aligns all the ":" characters, so we need to find the longest property name
    $propLength = 0
    foreach ($prop in $InputObject.PSObject.Properties) {
        if ($null -ne $prop.Value -and $prop.Value -ne [string]::Empty -and $prop.Name.Length -gt $propLength) {
            $propLength = $prop.Name.Length
        }
    }

    $addedProperty = $false
    foreach ($prop in $InputObject.PSObject.Properties) {
        # don't show empty properties or our added property for $error[index]
        if ($null -ne $prop.Value -and $prop.Value -ne [string]::Empty -and $prop.Value.count -gt 0 -and $prop.Name -ne 'PSErrorIndex') {
            $addedProperty = $true
            $null = $output.Append($prefix)
            $null = $output.Append($accentColor)
            $null = $output.Append($prop.Name)
            $null = $output.Append(' ',($propLength - $prop.Name.Length))
            $null = $output.Append(' : ')
            $null = $output.Append($resetColor)

            $newIndent = $indent + 2

            # only show nested objects that are Exceptions, ErrorRecords, or types defined in $expandTypes and types not in $ignoreTypes
            if ($prop.Value -is [Exception] -or
                $prop.Value -is [System.Management.Automation.ErrorRecord] -or
                $expandTypes -contains $prop.TypeNameOfValue -or
                        ($null -ne $prop.TypeNames -and $expandTypes -contains $prop.TypeNames[0])) {

                if ($depth -ge $maxDepth) {
                    $null = $output.Append($ellipsis)
                } else {
                    if ($prop.Value -is [Exception]) {
                        $null = $output.Append($newline)
                        $null = $output.Append((
                            GetListRecursive ([PSCustomObject]@{
                                                "Type" = $errorAccentColor + $prop.Value.GetType().FullName + $resetColor
                                            }) $newIndent ($depth + 1)
                        ))
                    }
                    $null = $output.Append($newline)
                    $null = $output.Append((GetListRecursive $prop.Value $newIndent ($depth + 1)))
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
                    $null = $output.Append((GetListRecursive $targetSite $newIndent ($depth + 1)))
                }
            } elseif ($prop.Name -eq 'StackTrace') {
                # `StackTrace` is handled specifically because the lines are typically long but necessary so they are left justified without additional indentation
                # for a stacktrace which is usually quite wide with info, we left justify it
                $null = $output.Append($newline)
                $null = $output.Append($prop.Value)
            } elseif ($prop.Value.GetType().Name.StartsWith('Dictionary') -or $prop.Value.GetType().Name -eq 'Hashtable') {
                # Dictionary and Hashtable we want to show as Key/Value pairs, we don't do the extra whitespace alignment here
                $isFirstElement = $true
                foreach ($key in $prop.Value.Keys) {
                    if ($isFirstElement) {
                        $null = $output.Append($newline)
                    }

                    if ($key -eq 'Authorization') {
                        $null = $output.Append("${prefix}    ${accentColor}${key}: ${resetColor}${ellipsis}${newline}")
                    } else {
                        $null = $output.Append("${prefix}    ${accentColor}${key}: ${resetColor}$($prop.Value[$key])${newline}")
                    }

                    $isFirstElement = $false
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
                        if (!$isFirstElement) {
                            $null = $output.Append($newline)
                        }
                        $null = $output.Append((GetListRecursive $value $newIndent ($depth + 1)))
                        $isFirstElement = $false
                    }
                }
            } else {
                # Anything else, we convert to string.
                # ToString() can throw so we use LanguagePrimitives.TryConvertTo() to hide a convert error
                $value = $null
                if ([System.Management.Automation.LanguagePrimitives]::TryConvertTo($prop.Value, [string], [ref]$value) -and $null -ne $value) {
                    $value = $value.Trim()
                    if ($prop.Name -eq 'PositionMessage') {
                        $value = $value.Insert($value.IndexOf('~'), $errorColor)
                    } elseif ($prop.Name -eq 'Message') {
                        $value = $errorColor + $value
                    }

                    $isFirstLine = $true
                    if ($value.Contains($newline)) {
                        # the 3 is to account for ' : '
                        # $valueIndent = ' ' * ($prop.Name.Length + 2)
                        $valueIndent = ' ' * ($propLength + 3)
                        # need to trim any extra whitespace already in the text
                        foreach ($line in $value.Split($newline)) {
                            if (!$isFirstLine) {
                                $null = $output.Append("${newline}${prefix}${valueIndent}")
                            }
                            $null = $output.Append($line.Trim())
                            $isFirstLine = $false
                        }
                    } else {
                        $null = $output.Append($value)
                    }
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
