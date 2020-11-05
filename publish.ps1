[CmdLetBinding()]
param(
	[Parameter(Mandatory=$false)]
	[string]$Configuration = "Release",
	[string]$NuGetApiKey
)

# The environment variable MSBUILDSINGLELOADCONTEXT must be set to get GitVersion task working with MSBuild 16.5
# See https://github.com/GitTools/GitVersion/issues/2063
$env:MSBUILDSINGLELOADCONTEXT = 1

# compile
& dotnet build --configuration $Configuration

# For publishing we need a folder with the same name as the module
$moduleTargetPath = Join-Path $PSScriptRoot "Module" "7Zip4Powershell"
if (Test-Path $moduleTargetPath) {
	Remove-Item $moduleTargetPath -Recurse
}
New-Item $moduleTargetPath -ItemType Directory | Out-Null

# copy all required files to that folder
Copy-Item -Path (Join-Path $PSScriptRoot "7Zip4Powershell" "bin" $configuration "net461" "*.*") -Exclude "JetBrains.Annotations.dll" -Destination $moduleTargetPath

# determine the version
$versionInfo = (Get-Command (Join-Path $moduleTargetPath "7Zip4PowerShell.dll")).FileVersionInfo
$version = "$($versionInfo.FileMajorPart).$($versionInfo.FileMinorPart).$($versionInfo.FileBuildPart)"

# patch the version in the .PSD1 file
$psd1File = Join-Path $moduleTargetPath "7Zip4PowerShell.psd1"
Write-Host "Patching version in $psd1File file to $version"
((Get-Content $psd1File -Raw) -replace '\$version\$',$version) | Set-Content $psd1File

# finally publish the 
if (!([string]::IsNullOrEmpty($NuGetApiKey))) {
    Publish-Module -Path $moduleTargetPath -NuGetApiKey $NuGetApiKey
}
