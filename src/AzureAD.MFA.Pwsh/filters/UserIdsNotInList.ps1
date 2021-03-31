filter UserIdsNotInList {
    param(
        [Microsoft.Graph.PowerShell.Models.MicrosoftGraphDirectoryObject[]]$InputObj
    )
    if ($PSItem.Id -notin $groupMembersBase.Id) {
        $PSItem
    }
}