filter UserIdsNotInList {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject[]]$InputObj
    )
    if ($PSItem.UserId -notin $groupMembersBase.Id) {
        $PSItem
    }
}