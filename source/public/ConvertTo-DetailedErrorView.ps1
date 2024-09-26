function ConvertTo-DetailedErrorView {
    <#
        .SYNOPSIS
            Converts an ErrorRecord to a detailed error string
        .DESCRIPTION
            The default PowerShell "DetailedView" ErrorView
            Copied from the PowerShellCore.format.ps1xml
        .LINK
            https://github.com/PowerShell/PowerShell/blob/c444645b0941d73dc769f0bba6ab70d317bd51a9/src/System.Management.Automation/FormatAndOutput/DefaultFormatters/PowerShellCore_format_ps1xml.cs#L903
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'maxDepth')]
    [CmdletBinding()]
    param(
        # The ErrorRecord to display
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]
        $InputObject,

        # The maximum depth to recurse into the object
        [int]$maxDepth = 10
    )

    begin {

        Set-StrictMode -Off

        $ellipsis = "`u{2026}"
        $resetColor = ''
        $errorColor = ''
        $accentColor = ''
        $newline = [Environment]::Newline
        $OutputRoot = [System.Text.StringBuilder]::new()

        if ($Host.UI.SupportsVirtualTerminal -and ([string]::IsNullOrEmpty($env:__SuppressAnsiEscapeSequences))) {
            $resetColor = "$([char]0x1b)[0m"
            $errorColor = if ($PSStyle.Formatting.Error) { $PSStyle.Formatting.Error } else { "`e[1;31m" }
            $accentColor = if ($PSStyle.Formatting.ErrorAccent) { $PSStyle.Formatting.ErrorAccent } else { "`e[1;36m" }
        }

        function DetailedErrorView {
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
            $prefix = ' ' * $indent

            $expandTypes = @(
                'Microsoft.Rest.HttpRequestMessageWrapper'
                'Microsoft.Rest.HttpResponseMessageWrapper'
                'System.Management.Automation.InvocationInfo'
            )

            # if object is an Exception, add an ExceptionType property
            if ($InputObject -is [Exception]) {
                $InputObject | Add-Member -NotePropertyName Type -NotePropertyValue $InputObject.GetType().FullName -ErrorAction Ignore
            }

            # first find the longest property so we can indent properly
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
                    $null = $OutputRoot.Append($prefix)
                    $null = $OutputRoot.Append($accentColor)
                    $null = $OutputRoot.Append($prop.Name)
                    $null = $OutputRoot.Append(' ',($propLength - $prop.Name.Length))
                    $null = $OutputRoot.Append(' : ')
                    $null = $OutputRoot.Append($resetColor)

                    $newIndent = $indent + 4

                    # only show nested objects that are Exceptions, ErrorRecords, or types defined in $expandTypes and types not in $ignoreTypes
                    if ($prop.Value -is [Exception] -or $prop.Value -is [System.Management.Automation.ErrorRecord] -or
                        $expandTypes -contains $prop.TypeNameOfValue -or ($null -ne $prop.TypeNames -and $expandTypes -contains $prop.TypeNames[0])) {

                        if ($depth -ge $maxDepth) {
                            $null = $OutputRoot.Append($ellipsis)
                        }
                        else {
                            $null = $OutputRoot.Append($newline)
                            $null = $OutputRoot.Append((DetailedErrorView $prop.Value $newIndent ($depth + 1)))
                        }
                    }
                    # `TargetSite` has many members that are not useful visually, so we have a reduced view of the relevant members
                    elseif ($prop.Name -eq 'TargetSite' -and $prop.Value.GetType().Name -eq 'RuntimeMethodInfo') {
                        if ($depth -ge $maxDepth) {
                            $null = $OutputRoot.Append($ellipsis)
                        }
                        else {
                            $targetSite = [PSCustomObject]@{
                                Name = $prop.Value.Name
                                DeclaringType = $prop.Value.DeclaringType
                                MemberType = $prop.Value.MemberType
                                Module = $prop.Value.Module
                            }

                            $null = $OutputRoot.Append($newline)
                            $null = $OutputRoot.Append((DetailedErrorView $targetSite $newIndent ($depth + 1)))
                        }
                    }
                    # `StackTrace` is handled specifically because the lines are typically long but necessary so they are left justified without additional indentation
                    elseif ($prop.Name -eq 'StackTrace') {
                        # for a stacktrace which is usually quite wide with info, we left justify it
                        $null = $OutputRoot.Append($newline)
                        $null = $OutputRoot.Append($prop.Value)
                    }
                    # Dictionary and Hashtable we want to show as Key/Value pairs, we don't do the extra whitespace alignment here
                    elseif ($prop.Value.GetType().Name.StartsWith('Dictionary') -or $prop.Value.GetType().Name -eq 'Hashtable') {
                        $isFirstElement = $true
                        foreach ($key in $prop.Value.Keys) {
                            if ($isFirstElement) {
                                $null = $OutputRoot.Append($newline)
                            }

                            if ($key -eq 'Authorization') {
                                $null = $OutputRoot.Append("${prefix}    ${accentColor}${key} : ${resetColor}${ellipsis}${newline}")
                            }
                            else {
                                $null = $OutputRoot.Append("${prefix}    ${accentColor}${key} : ${resetColor}$($prop.Value[$key])${newline}")
                            }

                            $isFirstElement = $false
                        }
                    }
                    # if the object implements IEnumerable and not a string, we try to show each object
                    # We ignore the `Data` property as it can contain lots of type information by the interpreter that isn't useful here
                    elseif (!($prop.Value -is [System.String]) -and $null -ne $prop.Value.GetType().GetInterface('IEnumerable') -and $prop.Name -ne 'Data') {

                        if ($depth -ge $maxDepth) {
                            $null = $OutputRoot.Append($ellipsis)
                        }
                        else {
                            $isFirstElement = $true
                            foreach ($value in $prop.Value) {
                                $null = $OutputRoot.Append($newline)
                                if (!$isFirstElement) {
                                    $null = $OutputRoot.Append($newline)
                                }
                                $null = $OutputRoot.Append((DetailedErrorView $value $newIndent ($depth + 1)))
                                $isFirstElement = $false
                            }
                        }
                    }
                    # Anything else, we convert to string.
                    # ToString() can throw so we use LanguagePrimitives.TryConvertTo() to hide a convert error
                    else {
                        $value = $null
                        if ([System.Management.Automation.LanguagePrimitives]::TryConvertTo($prop.Value, [string], [ref]$value) -and $null -ne $value)
                        {
                            if ($prop.Name -eq 'PositionMessage') {
                                $value = $value.Insert($value.IndexOf('~'), $errorColor)
                            }
                            elseif ($prop.Name -eq 'Message') {
                                $value = $errorColor + $value
                            }

                            $isFirstLine = $true
                            if ($value.Contains($newline)) {
                                # the 3 is to account for ' : '
                                $valueIndent = ' ' * ($propLength + 3)
                                # need to trim any extra whitespace already in the text
                                foreach ($line in $value.Split($newline)) {
                                    if (!$isFirstLine) {
                                        $null = $OutputRoot.Append("${newline}${prefix}${valueIndent}")
                                    }
                                    $null = $OutputRoot.Append($line.Trim())
                                    $isFirstLine = $false
                                }
                            }
                            else {
                                $null = $OutputRoot.Append($value)
                            }
                        }
                    }

                    $null = $OutputRoot.Append($newline)
                }
            }

            # if we had added nested properties, we need to remove the last newline
            if ($addedProperty) {
                $null = $OutputRoot.Remove($OutputRoot.Length - $newline.Length, $newline.Length)
            }

            $OutputRoot.ToString()
        }
    }
    process {
        DetailedErrorView $InputObject
    }
}
