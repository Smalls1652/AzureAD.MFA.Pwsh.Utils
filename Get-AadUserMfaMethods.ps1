[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateNotNullOrEmpty()]
    [pscustomobject[]]$UserObj
)

begin {
    class MfaMethodType {
        [string]$MethodName
        [string]$MethodId
        [bool]$IsUsableAsPrimary
    }

    class AadUserInfo {
        [string]$UserId
        [string]$UserPrincipalName
        [MfaMethodType[]]$MfaMethods
        [int]$MethodCount
    }
}

process {
    $userCount = ($UserObj | Measure-Object).Count
    $loopCount = 0
    foreach ($user in $UserObj) {
        $loopCount++

        Write-Verbose "Processing user [$($loopCount)/$($userCount)]: '$($user.userPrincipalName)'"

        $userMethods = Invoke-CustomGraphRequest -GraphVersion "beta" -Method "Get" -Resource "/users/$($user.id)/authentication/methods" -ErrorAction "Stop"

        $parsedUserMethods = [System.Collections.Generic.List[MfaMethodType]]::new()
        foreach ($method in $userMethods) {
            $methodObj = $null

            switch ($method.'@odata.type') {
                "#microsoft.graph.fido2AuthenticationMethod" {
                    $methodObj = [MfaMethodType]@{
                        "MethodName"        = "FIDO2 Security Key";
                        "MethodId"          = $method.id;
                        "IsUsableAsPrimary" = $true;
                    }
                    break
                }

                "#microsoft.graph.phoneAuthenticationMethod" {
                    switch ($method.phoneType) {
                        "mobile" {
                            $methodObj = [MfaMethodType]@{
                                "MethodName"        = "Mobile Phone";
                                "MethodId"          = $method.id;
                                "IsUsableAsPrimary" = $true;
                            }
                            break
                        }
                    }
                    break
                }

                "#microsoft.graph.emailAuthenticationMethod" {
                    $methodObj = [MfaMethodType]@{
                        "MethodName"        = "Email";
                        "MethodId"          = $method.id;
                        "IsUsableAsPrimary" = $false;
                    }
                    break
                }

                "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                    $methodObj = [MfaMethodType]@{
                        "MethodName"        = "Authenticator App (TOTP/Push Notification)";
                        "MethodId"          = $method.id;
                        "IsUsableAsPrimary" = $true;
                    }
                    break
                }
            }

            switch ($null -eq $methodObj) {
                $false {
                    $parsedUserMethods.Add($methodObj)
                    break
                }
            }
        }

        $returnData = [AadUserInfo]@{
            "UserId"            = $user.Id;
            "UserPrincipalName" = $user.UserPrincipalName;
            "MfaMethods"        = $parsedUserMethods;
            "MethodCount"       = ($parsedUserMethods | Measure-Object).Count;
        }

        $returnData
    }
}