function Get-AadUsersWithLicense {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserDomainName,
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SkuId = "e97c048c-37a4-45fb-ab50-922fbf07a370", #The default value is for the 'M365 A5 for Faculty' SKU.
        [Parameter(Position = 2)]
        [int]$LastSignInThresholdDays = 30
    )

    $null = Test-MsGraphModuleIsConnected -ErrorAction "Stop"

    $lastSignInDateThreshold = [datetime]::Now.AddDays(-($LastSignInThresholdDays)) #There could be users who haven't signed in within the last month, so let's ignore them for now.

    <#
    Get users based off the following info:
        - If their 'userPrincipalName' property ends with the domain name provided
        - If they have the provided 'skuId' assigned to their account
        - If 'accountEnabled' is set to true
#>
    Write-Verbose "Getting users"
    $usersWithLicense = Get-MgUser -Filter "endsWith(userPrincipalName, '@$($UserDomainName)') and assignedLicenses/any(c:c/skuId eq $($SkuId)) and accountEnabled eq true" -All -ConsistencyLevel Eventual -CountVariable "count" -Property @("id", "userPrincipalName", "assignedLicenses", "signInActivity")

    #Filter out users who haven't signed into their account in the last nn days.
    Write-Verbose "Filtering users who haven't signed-in in the last $($LastSignInThresholdDays) days."
    $usersWithLicense = $usersWithLicense | FilterByLastSignIn -Threshold $lastSignInDateThreshold

    return $usersWithLicense
}