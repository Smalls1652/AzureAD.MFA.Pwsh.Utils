function Get-MsGraphModuleContext {
    [CmdletBinding()]
    param()

    $graphContext = Get-MgContext

    switch ($null -eq $graphContext) {
        $true {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("No context was found with the 'Microsoft.Graph.Authentication' module. 'Connect-MgGraph' needs to be ran before running."),
                    "NoGraphContextFound",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $graphContext
                )
            )
            break
        }

        Default {
            return $graphContext
        }
    }
}