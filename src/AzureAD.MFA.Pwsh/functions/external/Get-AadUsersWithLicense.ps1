function Get-AadUsersWithLicense {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserDomainName,
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$SkuId = "e97c048c-37a4-45fb-ab50-922fbf07a370" #The default value is for the 'M365 A5 for Faculty' SKU.
    )

    #Filter function for faster processing (Compared to 'Where-Object') of users who have signed into their in the last `n` days.
    filter FilterByLastSignIn {
        param(
            [DateTime]$Threshold
        )

        if ($PSItem.LastSigninDateTime -ge $Threshold) {
            $PSItem
        }
    }

    $lastSignInDateThreshold = [datetime]::Now.AddDays(-30) #There could be users who haven't signed in within the last month, so let's ignore them for now.

    <#
    Get users based off the following info:
        - If their 'userPrincipalName' property ends with the domain name provided
        - If they have the provided 'skuId' assigned to their account
        - If 'accountEnabled' is set to true
#>
    Write-Verbose "Getting users"
    $usersWithLicenseRsp = Invoke-SendGraphApiRequest -GraphVersion beta -Method Get -Resource "/users?`$count=true&`$filter=endsWith(userPrincipalName, '@$($UserDomainName)') and assignedLicenses/any(c:c/skuId eq $($SkuId)) and accountEnabled eq true&`$select=id,userPrincipalName,assignedLicenses,signInActivity&`$orderBy=userPrincipalName" -Verbose:$false

    $usersWithLicense = foreach ($userItem in $usersWithLicenseRsp) {
        [AzureAD.MFA.Pwsh.Models.Graph.Users.User]@{
            "UserId" = $userItem.id;
            "UserPrincipalName" = $userItem.userPrincipalName;
            "LastSigninDateTime" = $userItem.signInActivity.lastSignInDateTime;
        }
    }

    #Filter out users who haven't signed into their account in the last 30 days.
    Write-Verbose "Filtering users who haven't signed-in in the last month."
    $usersWithLicense = $usersWithLicense | FilterByLastSignIn -Threshold $lastSignInDateThreshold

    return $usersWithLicense
}