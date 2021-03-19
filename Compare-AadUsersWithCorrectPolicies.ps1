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

$groupObj = Get-MgGroup -GroupId $GroupId -ErrorAction "Stop"

$groupMembersBase = Get-MgGroupTransitiveMember -GroupId $groupObj.Id -All

<#
$groupMembers = [System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser1]]::new()
foreach ($member in $groupMembersBase) {
    $userObj = Get-MgUser -UserId $member.Id
}
#>

$usersNotEnabled = $UserObjects | UserIdsNotInList -InputObj $groupMembersBase

return $usersNotEnabled