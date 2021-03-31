filter FilterByLastSignIn {
    param(
        [DateTime]$Threshold
    )

    if ($PSItem.SignInActivity.LastSigninDateTime -ge $Threshold) {
        $PSItem
    }
}