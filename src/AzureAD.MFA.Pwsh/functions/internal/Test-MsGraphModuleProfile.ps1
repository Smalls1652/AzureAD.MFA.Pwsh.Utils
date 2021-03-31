function Test-MsGraphModuleProfile {
    [CmdletBinding()]
    param()

    $graphProfile = Get-MgProfile
    
    switch ($graphProfile.Name -eq "beta") {
        $false {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("The current profile selected is not the 'beta' profile on the 'Microsoft.Graph.Authentication' module. 'Select-MgProfile -Name `"beta`"' needs to be ran before running."),
                    "IncorrectGraphProfile",
                    [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                    $graphProfile
                )
            )
            break
        }
    }
}