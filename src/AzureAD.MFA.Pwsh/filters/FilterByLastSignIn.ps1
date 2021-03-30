filter FilterByLastSignIn {
    param(
        [DateTime]$Threshold
    )

    if ($PSItem.LastSigninDateTime -ge $Threshold) {
        $PSItem
    }
}