function Test-MsGraphModuleIsConnected {
    [CmdletBinding()]
    param()

    $null = Get-MsGraphModuleContext -ErrorAction "Stop"
    $null = Test-MsGraphModuleProfile -ErrorAction "Stop"
}