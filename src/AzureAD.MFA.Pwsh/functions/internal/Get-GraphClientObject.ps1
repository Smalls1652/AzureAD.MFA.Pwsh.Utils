function Get-GraphClientObject {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("v1.0", "beta")]
        [string]$GraphVersion = "v1.0"
    )

    $graphContext = Get-MgContext

    switch ($null -eq $graphContext) {
        $true {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("No context was found with the 'Microsoft.Graph.Authentication' module. 'Connect-Graph' needs to be ran before running."),
                    "NoGraphContextFound",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $graphContext
                )
            )
            break
        }
    }

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