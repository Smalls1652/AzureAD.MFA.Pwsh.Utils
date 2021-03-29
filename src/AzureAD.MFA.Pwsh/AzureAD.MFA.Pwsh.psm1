$internalFunctions = Get-ChildItem -Path ([System.IO.Path]::Combine($PSScriptRoot, "functions\internal\")) -Recurse | Where-Object { $PSItem.Extension -eq ".ps1" }

foreach ($item in $internalFunctions) {
    . "$($item.FullName)"
}

$functionsBefore = Get-ChildItem -Path "Function:\"
$exportableFunctions = Get-ChildItem -Path ([System.IO.Path]::Combine($PSScriptRoot, "functions\external\")) -Recurse | Where-Object { $PSItem.Extension -eq ".ps1" }
foreach ($item in $exportableFunctions) {
    . "$($item.FullName)"
}