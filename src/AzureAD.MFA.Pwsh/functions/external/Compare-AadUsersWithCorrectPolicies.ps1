function Compare-AadUsersWithCorrectPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,
        [Parameter(Position = 1, Mandatory)]
        [AzureAD.MFA.Pwsh.Models.Graph.Users.User[]]$UserObjects
    )

    Write-Verbose "Getting group object"
    $groupObj = Get-MgGroup -GroupId $GroupId -ErrorAction "Stop"

    Write-Verbose "Getting current group members."
    $groupMembersBase = Get-MgGroupTransitiveMember -GroupId $groupObj.Id -All -ErrorAction "Stop"

    Write-Verbose "Comparing input users."
    $usersNotEnabled = $UserObjects | UserIdsNotInList -InputObj $groupMembersBase

    return $usersNotEnabled
}