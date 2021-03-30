$moduleFilters = Get-ChildItem -Path ([System.IO.Path]::Combine($PSScriptRoot, "filters\")) -Recurse | Where-Object { $PSItem.Extension -eq ".ps1" }
foreach ($item in $moduleFilters) {
    . "$($item.FullName)"
}

$internalFunctions = Get-ChildItem -Path ([System.IO.Path]::Combine($PSScriptRoot, "functions\internal\")) -Recurse | Where-Object { $PSItem.Extension -eq ".ps1" }
foreach ($item in $internalFunctions) {
    . "$($item.FullName)"
}

$exportableFunctions = Get-ChildItem -Path ([System.IO.Path]::Combine($PSScriptRoot, "functions\external\")) -Recurse | Where-Object { $PSItem.Extension -eq ".ps1" }
foreach ($item in $exportableFunctions) {
    . "$($item.FullName)"
}