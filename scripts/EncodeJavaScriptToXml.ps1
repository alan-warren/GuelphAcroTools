<#
.SYNOPSIS
Encodes a JavaScript file content into an XML template, replacing a placeholder.

.DESCRIPTION
This script takes a JavaScript file, reads its content, XML-encodes it,
and then inserts the encoded JavaScript into a provided XML template file,
replacing a placeholder string (default: "%%SCRIPTSOURCE%%").
The modified XML is then saved to a new file.

.PARAMETER ScriptPath
The path to the JavaScript (.js) file.

.PARAMETER XmlTemplatePath
The path to the XML template file.

.PARAMETER Placeholder
The placeholder string in the XML template to be replaced with the encoded JavaScript.
Defaults to "%%SCRIPTSOURCE%%".

.EXAMPLE
.\EncodeJavaScriptToXml.ps1 -ScriptPath ".\my_script.js" -XmlTemplatePath ".\template.xml"

This example will read "my_script.js", encode its content,
replace "%%SCRIPTSOURCE%%" in "template.xml" with the encoded script,
and save the result to "template_modified.xml".

.EXAMPLE
.\EncodeJavaScriptToXml.ps1 -ScriptPath ".\another_script.js" -XmlTemplatePath ".\custom_template.xml" -Placeholder "##JS_CODE##"

This example uses "##JS_CODE##" as the placeholder in "custom_template.xml".

.NOTES
Requires PowerShell v3 or later for Get-Content -Raw.
#>
param (
    [Parameter(Mandatory=$true, HelpMessage="Path to the JavaScript (.js) file")]
    [string]
    $ScriptPath,

    [Parameter(Mandatory=$true, HelpMessage="Path to the XML template file")]
    [string]
    $XmlTemplatePath,

    [string]
    $Placeholder = "%%SCRIPTSOURCE%%"
)

#region --- Input Validation ---
# Check if script file exists
if (!(Test-Path -Path $ScriptPath -PathType Leaf)) {
    Write-Error "Script file not found: '$ScriptPath'"
    return
}

# Check if XML template file exists
if (!(Test-Path -Path $XmlTemplatePath -PathType Leaf)) {
    Write-Error "XML template file not found: '$XmlTemplatePath'"
    return
}
#endregion

#region --- Read Files and Encode JavaScript ---
Write-Verbose "Reading JavaScript file: '$ScriptPath'"
try {
    $scriptContent = Get-Content -Raw -Path $ScriptPath -Encoding UTF8 # Ensure UTF8 encoding for JS content
}
catch {
    Write-Error "Error reading JavaScript file: $($_.Exception.Message)"
    return
}

Write-Verbose "XML Encoding JavaScript content..."
try {
    # XML Encode the JavaScript content using .NET Framework SecurityElement class
    $encodedScript = [System.Security.SecurityElement]::Escape($scriptContent)
}
catch {
    Write-Error "Error encoding JavaScript content: $($_.Exception.Message)"
    return
}

Write-Verbose "Reading XML template file: '$XmlTemplatePath'"
try {
    $xmlTemplate = Get-Content -Path $XmlTemplatePath -Encoding UTF8 # Ensure UTF8 for XML too
}
catch {
    Write-Error "Error reading XML template file: $($_.Exception.Message)"
    return
}
#endregion

#region --- Replace Placeholder and Save XML ---
Write-Verbose "Replacing placeholder '$Placeholder' in XML template..."
$modifiedXml = $xmlTemplate -replace [regex]::Escape($Placeholder), $encodedScript

# Determine output file path (e.g., template_modified.xml in the same directory)
$outputPath = Join-Path -Path (Split-Path -Path "../$XmlTemplatePath" -Parent) -ChildPath ("{0}_modified{1}" -f ([System.IO.Path]::GetFileNameWithoutExtension($XmlTemplatePath)), ([System.IO.Path]::GetExtension($XmlTemplatePath)))

Write-Verbose "Saving modified XML to: '$outputPath'"
try {
    Set-Content -Path $outputPath -Value $modifiedXml -Encoding UTF8
}
catch {
    Write-Error "Error saving modified XML file: $($_.Exception.Message)"
    return
}
#endregion

Write-Host "Successfully encoded JavaScript from '$ScriptPath' and inserted into XML template."
Write-Host "Modified XML saved to: '$outputPath'"
