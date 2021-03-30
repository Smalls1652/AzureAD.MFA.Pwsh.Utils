function Compare-AadUsersWithCorrectPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,
        [Parameter(Position = 1, Mandatory)]
        [AzureAD.MFA.Pwsh.Models.Graph.Users.User[]]$UserObjects
    )

    filter UserIdsNotInList {
        param(
            [Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject[]]$InputObj
        )
        if ($PSItem.UserId -notin $groupMembersBase.Id) {
            $PSItem
        }
    }

    Write-Verbose "Getting group object"
    $groupObj = Get-MgGroup -GroupId $GroupId -ErrorAction "Stop"

    Write-Verbose "Getting current group members."
    $groupMembersBase = Get-MgGroupTransitiveMember -GroupId $groupObj.Id -All

    Write-Verbose "Comparing input users."
    $usersNotEnabled = $UserObjects | UserIdsNotInList -InputObj $groupMembersBase

    return $usersNotEnabled
}