[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("Dev", "Release")]
    [string]$PublishType = "Dev"
)

$ScriptLocation = $PSScriptRoot

$buildLogSplat = @{
    "Tags"              = @("BuildLog");
    "InformationAction" = "Continue"
}

$buildDir = Join-Path -Path $ScriptLocation -ChildPath "build\"
$buildModuleDir = Join-Path -Path $buildDir -ChildPath "AzureAD.MFA.Pwsh\"

$srcDir = Join-Path -Path $ScriptLocation -ChildPath "src\"
$pwshProjectDir = Join-Path -Path $srcDir -ChildPath "AzureAD.MFA.Pwsh\"

$csProjectDir = Join-Path -Path $srcDir -ChildPath "AzureAD.MFA.Pwsh.Lib\"
$csProjectPublishDir = Join-Path -Path $csProjectDir -ChildPath "bin\$($PublishType)\netstandard2.1\publish\"

$filesToCopy = [System.Collections.Generic.List[string[]]]@(
    (Join-Path -Path $csProjectPublishDir -ChildPath "AzureAD.MFA.Pwsh.dll")
)

$dotnetProcSplat = @{
    "FilePath"         = "dotnet";
    "NoNewWindow"      = $true;
    "PassThru"         = $true;
    "WorkingDirectory" = $csProjectDir;
    "ErrorAction"      = "Stop";
}

$dotnetCleanArgs = @(
    "clean",
    "--nologo",
    "--verbosity minimal"
)

$dotnetPublishArgs = @(
    "publish",
    "--nologo",
    "--configuration $($PublishType)",
    "--verbosity minimal",
    "/property:PublishWithAspNetCoreTargetManifest=false"
)

Write-Information @buildLogSplat -MessageData "Starting build for 'AzureAD.MFA.Pwsh'"
Write-Information @buildLogSplat -MessageData "---------------------"
Write-Information @buildLogSplat -MessageData "- Build location: '$($ScriptLocation)'"

Write-Information @buildLogSplat -MessageData "- Building class library: 'AzureAD.MFA.Pwsh.Lib'"
$dotnetCleanProcess = Start-Process @dotnetProcSplat -ArgumentList $dotnetCleanArgs
Wait-Process -InputObject $dotnetCleanProcess

$dotnetPublishProcess = Start-Process @dotnetProcSplat -ArgumentList $dotnetPublishArgs
Wait-Process -InputObject $dotnetPublishProcess

#dotnet clean --nologo --verbosity minimal
#dotnet publish --nologo --configuration "$($PublishType)" --verbosity minimal /property:PublishWithAspNetCoreTargetManifest=false

if (Test-Path -Path $buildDir) {
    Write-Information @buildLogSplat -MessageData "- Cleaning up previous build"
    Remove-Item -Path $buildDir -Recurse -Force
}

Write-Information @buildLogSplat -MessageData "- Creating build directory"
$null = New-Item -Type Directory -Path $buildDir

Write-Information @buildLogSplat -MessageData "- Building module at: '$($buildDir)'"

Write-Information @buildLogSplat -MessageData "`t- Copying '$($pwshProjectDir)'"
Copy-Item -Path $pwshProjectDir -Destination $buildDir -Recurse

foreach ($item in $filesToCopy) {
    Write-Information @buildLogSplat -MessageData "`t- Copying '$($item)'"
    Copy-Item -Path $item -Destination $buildModuleDir
}

$builtModule = Get-Item -Path $buildModuleDir

Write-Information @buildLogSplat -MessageData "Build complete!"
Write-Information @buildLogSplat -MessageData "---------------------"

Write-Output -InputObject $builtModule