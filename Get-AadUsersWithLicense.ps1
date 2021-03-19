[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$UserDomainName,
    [Parameter(Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$SkuId = "e97c048c-37a4-45fb-ab50-922fbf07a370"
)

filter FilterByLastSignIn {
    param(
        [DateTime]$Threshold
    )

    if ($PSItem.signInActivity.lastSignInDateTime -ge $Threshold) {
        $PSItem
    }
}

$lastSignInDateThreshold = [datetime]::Now.AddDays(-30)

Write-Verbose "Getting users"
$usersWithLicense = Invoke-CustomGraphRequest -GraphVersion beta -Method Get -Resource "/users?`$count=true&`$filter=endsWith(userPrincipalName, '@$($UserDomainName)') and assignedLicenses/any(c:c/skuId eq $($SkuId)) and accountEnabled eq true&`$select=id,userPrincipalName,assignedLicenses,signInActivity&`$orderBy=userPrincipalName"

Write-Verbose "Filtering users who haven't signed-in in the last month."
$usersWithLicense = $usersWithLicense | FilterByLastSignIn -Threshold $lastSignInDateThreshold

return $usersWithLicense