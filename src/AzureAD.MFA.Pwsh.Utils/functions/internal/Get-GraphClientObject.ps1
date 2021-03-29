function Get-GraphClientObject {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("v1.0", "beta")]
        [string]$GraphVersion = "v1.0"
    )

    $graphContext = Get-MgContext

    $graphClient = [Microsoft.Graph.PowerShell.Authentication.Helpers.HttpHelpers]::GetGraphHttpClient($graphContext)

    $baseAddress = $null
    switch ($GraphVersion) {
        "beta" {
            $baseAddress = [System.Uri]::new("https://graph.microsoft.com/beta/")
            break
        }

        Default {
            $baseAddress = [System.Uri]::new("https://graph.microsoft.com/v1.0/")
            break
        }
    }

    $graphClient.BaseAddress = $baseAddress

    return $graphClient
}