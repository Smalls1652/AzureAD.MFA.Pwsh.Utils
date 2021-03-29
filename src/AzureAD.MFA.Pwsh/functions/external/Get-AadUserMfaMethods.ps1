function Get-AadUserMfaMethods {
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
            [int]$UsableSignInMethodCount
        }

        class GraphBatchBody {
            [GraphBatchRequest[]]$requests
        }

        class GraphBatchRequest {
            [int]$id
            [string]$method
            [string]$url
        }
    }

    process {
        $maxBatchRequests = 20 #Max requests in one batch to the Graph API is 20
        $userCount = ($UserObj | Measure-Object).Count

        #Initialize the batch request loop counters
        $startCount = 0
        $endCount = ($maxBatchRequests - 1)

        #This regex is used for pull the UserId used during a batch request. It's then used to match it back to the original user object from the input.
        $userIdOdataRegex = [System.Text.RegularExpressions.Regex]::new("https:\/\/graph.microsoft.com\/(?>v1\.0|beta)\/\`$metadata#users\('(?'userId'.+?)'\)\/authentication\/methods")

        while ($startCount -le ($userCount - 1)) {
            switch ($endCount -ge ($userCount - 1)) {
                $true {
                    $endCount = ($userCount - 1)
                    break
                }
            }

            $batchRequestList = [System.Collections.Generic.List[GraphBatchRequest]]::new()
            $loopCount = 1

            #Build the request objects for the batch request.
            foreach ($item in $UserObj[$startCount..$endCount]) {
                $batchRequestObj = [GraphBatchRequest]@{
                    "id"     = $loopCount;
                    "method" = "GET";
                    "url"    = "/users/$($item.id)/authentication/methods";
                }

                $batchRequestList.Add($batchRequestObj)
                $loopCount++
            }

            #Create a hashtable for the post body.
            $batchBodyObj = @{
                "requests" = $batchRequestList;
            }

            #Send the batch requests to the Graph API.
            $requestWasSuccessful = $false
        
            while ($requestWasSuccessful -eq $false) {
                Write-Verbose "Running batch request for items $($startCount) - $($endCount)."
                $batchRequestRsp = Invoke-CustomGraphRequest -GraphVersion "beta" -Method "Post" -Resource "/`$batch" -Body $batchBodyObj

                switch (429 -in $batchRequestRsp.responses.status) {
                    $true {
                        $retryAfterHeader = [int](($batchRequestRsp.responses.headers.'Retry-After' | Sort-Object)[-1])
                        $retryInSeconds = ($retryAfterHeader + 15)
                        Write-Warning "One or more items in the batch request were throttled."
                        Write-Warning "Waiting for '$($retryInSeconds) second(s)' to rerun the requests."
                        Start-Sleep -Seconds $retryInSeconds
                        break
                    }

                    Default {
                        $requestWasSuccessful = $true
                        break
                    }
                }
            }

            foreach ($rspItem in $batchRequestRsp.responses) {
                $userMethods = $rspItem.body.value
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

                $userIdMatch = $userIdOdataRegex.Match($rspItem.body.'@odata.context')
                $userIdItem = $userIdMatch.Groups['userId'].Value

                $user = $UserObj | Where-Object { $PSItem.Id -eq $userIdItem }

                $returnData = [AadUserInfo]@{
                    "UserId"                  = $user.Id;
                    "UserPrincipalName"       = $user.UserPrincipalName;
                    "MfaMethods"              = $parsedUserMethods;
                    "MethodCount"             = ($parsedUserMethods | Measure-Object).Count;
                    "UsableSignInMethodCount" = ($parsedUserMethods | Where-Object { $PSItem.IsUsableAsPrimary -eq $true } | Measure-Object).Count;
                }
    
                $returnData
            }

            $startCount = ($startCount + $maxBatchRequests)
            $endCount = ($endCount + $maxBatchRequests)

        }
    }
}