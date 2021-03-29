function Compare-AadUsersWithCorrectPolicies {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,
        [Parameter(Position = 1, Mandatory)]
        [pscustomobject[]]$UserObjects
    )

    filter UserIdsNotInList {
        param(
            [Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject[]]$InputObj
        )
        if ($PSItem.id -notin $groupMembersBase.Id) {
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