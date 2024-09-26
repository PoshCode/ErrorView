function GetYamlRecursive {
    <#
        .SYNOPSIS
            Creates a description of an ErrorRecord that looks like valid Yaml
        .DESCRIPTION
            This produces valid Yaml output from ErrorRecord you pass to it, recursively.
    #>
    [CmdletBinding()]
    param(
        # The object that you want to convert to YAML
        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject,

        # Optionally, a limit on the depth to recurse properties (defaults to 16)
        [parameter()]
        [int]$depth = 16,

        # If set, include empty and null properties in the output
        [switch]$IncludeEmpty,

        # Recursive use only. Handles indentation for formatting
        [parameter(DontShow)]
        [int]$NestingLevel = 0,

        # use OuterXml instead of treating XmlDocuments like objects
        [parameter(DontShow)]
        [switch]$XmlAsXml
    )
    process {
        $wrap = [Console]::BufferWidth - 1 - ($NestingLevel * 2)
        @(
            if ($Null -eq $InputObject) { return 'null' } # if it is null return null
            if ($NestingLevel -eq 0 -and $local:__hasoutput) { '---' } # if we have output before, add a yaml separator
            $__hasoutput = $true
            $padding = "`n$('  ' * $NestingLevel)" # lets just create our left-padding for the block
            $Recurse = @{
                'Depth'        = $depth - 1
                'NestingLevel' = $NestingLevel + 1
                'XmlAsXml'     = $XmlAsXml
            }
            $Wrap =

            try {
                switch ($InputObject) {
                    # prevent these values being expanded
                    <# if ($Type -in @( 'guid',
                            , 'datatable', 'List`1','SqlDataReader', 'datarow', 'type',
                            'MemberTypes', 'RuntimeModule', 'RuntimeType', 'ErrorCategoryInfo', 'CommandInfo', 'CmdletInfo' )) {
                    #>
                    { $InputObject -is [scriptblock] } {
                        "{$($InputObject.ToString())}"
                        break
                    }
                    { $InputObject -is [type] } {
                        "'[$($InputObject.FullName)]'"
                        break
                    }
                    { $InputObject -is [System.Xml.XmlDocument] -or $InputObject -is [System.Xml.XmlElement] } {
                        "|"
                        $InputObject.OuterXml | WrapString $Wrap $padding -Colors:$LineColors
                        break
                    }
                    { $InputObject -is [datetime] -or $InputObject -is [datetimeoffset] } {
                        # s=SortableDateTimePattern (based on ISO 8601) using local time
                        $InputObject.ToString('s')
                        break
                    }
                    { $InputObject -is [timespan] -or $InputObject -is [version] -or $InputObject -is [uri] } {
                        # s=SortableDateTimePattern (based on ISO 8601) using local time
                        "'$InputObject'"
                        break
                    }
                    # yaml case for booleans
                    { $InputObject -is [bool] } {
                        if ($InputObject) { 'true' } else { 'false' }
                        break
                    }
                    # If we're going to go over our depth, just output like it's a value type
                    # ValueTypes are just output with no possibility of wrapping or recursion
                    { $InputObject -is [Enum] -or $InputObject.GetType().BaseType -eq [ValueType] -or $depth -eq 1 } {
                        "$InputObject"
                        break
                    }
                    # 'PSNoteProperty' {
                    #     # Write-Verbose "$($padding)Show $($property.Name)"
                    #     GetYamlRecursive -InputObject $InputObject.Value @Recurse }
                    { $InputObject -is [System.Collections.IDictionary] } {
                        foreach ($kvp in  $InputObject.GetEnumerator()) {
                            # Write-Verbose "$($padding)Enumerate $($property.Name)"
                            "$padding$accentColor$($kvp.Name):$resetColor " +
                            (GetYamlRecursive -InputObject $kvp.Value @Recurse)
                        }
                        break
                    }

                    { $InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string] } {
                        foreach ($item in $InputObject) {
                            # Write-Verbose "$($padding)Enumerate $($property.Name)"
                            $Value = GetYamlRecursive -InputObject $item @Recurse
                            # if ($Value -ne 'null' -or $IncludeEmpty) {
                            "$accentColor$padding$resetColor- $Value"
                            # }
                        }
                        break
                    }

                    # Limit recursive enumeration to specific types:
                    { $InputObject -is [Exception] -or $InputObject -is [System.Management.Automation.ErrorRecord] -or
                        $InputObject.PSTypeNames[0] -in @(
                            'System.Exception'
                            'System.Management.Automation.ErrorRecord'
                            'Microsoft.Rest.HttpRequestMessageWrapper'
                            'Microsoft.Rest.HttpResponseMessageWrapper'
                            'System.Management.Automation.InvocationInfo'
                        ) } {
                        # For exceptions, output a fake property for the exception type
                        if ($InputObject -is [Exception]) {
                            "$padding${accentColor}#Type:$resetColor ${errorAccentColor}" + $InputObject.GetType().FullName + $resetColor
                        }
                        foreach ($property in $InputObject.PSObject.Properties) {
                            if ($property.Value) {
                                $Value = GetYamlRecursive -InputObject $property.Value @Recurse
                                # For special cases, add some color:
                                if ($property.Name -eq "PositionMessage") {
                                    $Value = $Value -replace "(\+\s+)(~+)", "`$1$errorColor`$2$resetColor"
                                }
                                if ($InputObject -is [Exception] -and $property.Name -eq "Message") {
                                    $Value = "$errorColor$Value$resetColor"
                                }
                                if ((-not [string]::IsNullOrEmpty($Value) -and $Value -ne 'null' -and $Value.Count -gt 0) -or $IncludeEmpty) {
                                    "$padding$accentColor$($property.Name):$resetColor " + $Value
                                }
                            }
                        }
                        break
                    }
                    # 'generic' {
                    #     foreach($key in $InputObject.Keys) {
                    #         # Write-Verbose "$($padding)Enumerate $($key)"
                    #         $Value = GetYamlRecursive -InputObject $InputObject.$key @Recurse
                    #         if ((-not [string]::IsNullOrEmpty($Value) -and $Value -ne 'null') -or $IncludeEmpty) {
                    #             "$padding$accentColor$($key):$resetColor " + $Value
                    #         }
                    #     }
                    # }
                    default {
                        # Treat anything else as a string
                        $StringValue = $null
                        if ([System.Management.Automation.LanguagePrimitives]::TryConvertTo($InputObject, [string], [ref]$StringValue) -and $null -ne $StringValue) {
                            $StringValue = $StringValue.Trim()
                            if ($StringValue -match '[\r\n]' -or $StringValue.Length -gt $wrap) {
                                ">" # signal that we are going to use the readable 'newlines-folded' format
                                $StringValue | WrapString $Wrap $padding -Colors:$LineColors
                            } elseif ($StringValue.Contains(":")) {
                                "'$($StringValue -replace '''', '''''')'" # single quote it
                            } else {
                                "$($StringValue -replace '''', '''''')"
                            }
                        } else {
                            Write-Warning "Unable to convert $($InputObject.GetType().FullName) to string"
                        }
                    }
                }
            } catch {
                Write-Error "Error'$($_)' in script $($_.InvocationInfo.ScriptName) $($_.InvocationInfo.Line.Trim()) (line $($_.InvocationInfo.ScriptLineNumber)) char $($_.InvocationInfo.OffsetInLine) executing $($_.InvocationInfo.MyCommand) on $type object '$($InputObject)' Class: $($InputObject.GetType().Name) BaseClass: $($InputObject.GetType().BaseType.Name) "
            }
        ) -join ""
    }
}