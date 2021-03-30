[CmdletBinding()]
param(

)

$ScriptLocation = $PSScriptRoot

$buildDir = [System.IO.Path]::Combine($ScriptLocation, "build\")
$buildModuleDir = [System.IO.Path]::Combine($buildDir, "AzureAD.MFA.Pwsh\")

$pwshProjectDir = [System.IO.Path]::Combine($ScriptLocation, "src\", "AzureAD.MFA.Pwsh\")

$csProjectDir = [System.IO.Path]::Combine($ScriptLocation, "src\", "AzureAD.MFA.Pwsh.Lib\")
$csProjectPublishDir = [System.IO.Path]::Combine($csProjectDir, "bin\", "Debug\", "net5.0\", "publish\")

$filesToCopy = [System.Collections.Generic.List[string[]]]@(
    ([System.IO.Path]::Combine($csProjectPublishDir, "AzureAD.MFA.Pwsh.dll"))
)

Push-Location -Path $csProjectDir

try {
    dotnet clean
    dotnet publish /property:PublishWithAspNetCoreTargetManifest=false
    #Start-Process -FilePath "dotnet" -ArgumentList @("clean") -Wait -NoNewWindow -ErrorAction Stop
    #Start-Process -FilePath "dotnet" -ArgumentList @("publish", "/property:PublishWithAspNetCoreTargetManifest=false") -Wait -NoNewWindow -ErrorAction Stop
}
finally {
    Pop-Location
}


if (Test-Path -Path $buildDir) {
    Remove-Item -Path $buildDir -Recurse -Force
}

$null = New-Item -Type Directory -Path $buildDir

Copy-Item -Path $pwshProjectDir -Destination $buildDir -Recurse

foreach ($item in $filesToCopy) {
    Copy-Item -Path $item -Destination $buildModuleDir
}