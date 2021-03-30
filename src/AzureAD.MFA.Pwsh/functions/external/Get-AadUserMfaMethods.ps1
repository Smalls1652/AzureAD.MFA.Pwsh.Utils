function Get-AadUserMfaMethods {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [AzureAD.MFA.Pwsh.Models.Graph.Users.User[]]$UserObj,
        [Parameter(Position = 1)]
        [int]$ThrottleBufferSeconds = 0
    )

    process {
        $maxBatchRequests = 20 #Max requests in one batch to the Graph API is 20
        $userCount = ($UserObj | Measure-Object).Count

        #Initialize the batch request loop counters
        $startCount = 0
        $endCount = ($maxBatchRequests - 1)

        #This regex is used for pull the UserId used during a batch request. It's then used to match it back to the original user object from the input.
        $userIdOdataRegex = [System.Text.RegularExpressions.Regex]::new("https:\/\/graph.microsoft.com\/(?>v1\.0|beta)\/\`$metadata#users\('(?'userId'.+?)'\)\/authentication\/methods")

        while ($startCount -le ($userCount - 1)) {
            switch ($endCount -ge ($userCount - 1)) { #If the 'endCount' is actually greater than the actual user count, then set it to that.
                $true {
                    $endCount = ($userCount - 1)
                    break
                }
            }

            $batchRequestList = [System.Collections.Generic.List[AzureAD.MFA.Pwsh.Models.Graph.Batch.BatchRequest]]::new()
            $loopCount = 1

            #Build the request objects for the batch request.
            foreach ($item in $UserObj[$startCount..$endCount]) {
                $batchRequestObj = [AzureAD.MFA.Pwsh.Models.Graph.Batch.BatchRequest]@{
                    "id"     = $loopCount;
                    "method" = "GET";
                    "url"    = "/users/$($item.UserId)/authentication/methods";
                }

                $batchRequestList.Add($batchRequestObj)
                $loopCount++
            }

            #Create a hashtable for the post body.
            $batchBodyObj = [AzureAD.MFA.Pwsh.Models.Graph.Batch.BatchBody]@{
                "requests" = $batchRequestList;
            }

            #Send the batch requests to the Graph API.
            $requestWasSuccessful = $false
            while ($requestWasSuccessful -eq $false) { #Run the batch request until we set the 'requestWasSuccessful' to true
                $batchRequestRsp = Invoke-SendGraphApiRequest -GraphVersion "beta" -Method "Post" -Resource "/`$batch" -Body ($batchBodyObj.ConvertToHashtable()) -Verbose:$false -ErrorAction "Stop"

                #Check to see if the batch request was successful or if it had been throttled
                switch (429 -in $batchRequestRsp.responses.status) {
                    $true {
                        <#
                            If any response came back as being throttled, use the 'Retry-After' header's wait time and add a buffer if it's been provided.
                            Once the time has passed, re-run the batch request.
                        #>
                        $retryAfterHeader = [int](($batchRequestRsp.responses.headers.'Retry-After' | Sort-Object)[-1]) #Get all of the 'Retry-After' headers and get the highest value in the list.
                        $retryInSeconds = ($retryAfterHeader + $ThrottleBufferSeconds)

                        Write-Warning "One or more items in the batch request were throttled."
                        Write-Warning "Waiting for '$($retryInSeconds) second(s)' to rerun the requests."
                        Start-Sleep -Seconds $retryInSeconds
                        break
                    }

                    Default {
                        <#
                            Set 'requestWasSuccessful' to true if and continue to the next step.
                        #>
                        $requestWasSuccessful = $true
                        break
                    }
                }
            }

            #Process each response returned from the batch request.
            foreach ($rspItem in $batchRequestRsp.responses) {
                $userMethods = $rspItem.body.value
                $parsedUserMethods = [System.Collections.Generic.List[AzureAD.MFA.Pwsh.Models.MfaMethodType]]::new()
                foreach ($method in $userMethods) {
                    $methodObj = $null

                    switch ($method.'@odata.type') { #Parse each returned method and identify if it's usable for sign-in purposes
                        "#microsoft.graph.fido2AuthenticationMethod" {
                            $methodObj = [AzureAD.MFA.Pwsh.Models.MfaMethodType]@{
                                "MethodName"        = "FIDO2 Security Key";
                                "MethodId"          = $method.id;
                                "IsUsableAsPrimary" = $true;
                            }
                            break
                        }

                        "#microsoft.graph.phoneAuthenticationMethod" {
                            switch ($method.phoneType) {
                                "mobile" {
                                    $methodObj = [AzureAD.MFA.Pwsh.Models.MfaMethodType]@{
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
                            $methodObj = [AzureAD.MFA.Pwsh.Models.MfaMethodType]@{
                                "MethodName"        = "Email";
                                "MethodId"          = $method.id;
                                "IsUsableAsPrimary" = $false;
                            }
                            break
                        }

                        "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                            $methodObj = [AzureAD.MFA.Pwsh.Models.MfaMethodType]@{
                                "MethodName"        = "Authenticator App (TOTP/Push Notification)";
                                "MethodId"          = $method.id;
                                "IsUsableAsPrimary" = $true;
                            }
                            break
                        }
                    }

                    switch ($null -eq $methodObj) { #If 'methodObj' isn't null, then add it to the parsed methods list.
                        $false {
                            $parsedUserMethods.Add($methodObj)
                            break
                        }
                    }
                }

                #Get the userId from the '@odata.context' property and match it with the user object list provided to the script
                $userIdMatch = $userIdOdataRegex.Match($rspItem.body.'@odata.context')
                $userIdItem = $userIdMatch.Groups['userId'].Value
                $user = $UserObj | Where-Object { $PSItem.UserId -eq $userIdItem }

                #Build the user info object
                $returnData = [AzureAD.MFA.Pwsh.Models.AadUserInfo]@{
                    "UserId"                  = $user.UserId;
                    "UserPrincipalName"       = $user.UserPrincipalName;
                    "MfaMethods"              = $parsedUserMethods;
                    "MethodCount"             = ($parsedUserMethods | Measure-Object).Count;
                    "UsableSignInMethodCount" = ($parsedUserMethods | Where-Object { $PSItem.IsUsableAsPrimary -eq $true } | Measure-Object).Count;
                }

                Write-Verbose "Successfully processed registered MFA methods for '$($user.UserPrincipalName)'."
    
                #Write the user info object to the console
                Write-Output $returnData
            }

            #Increment for the next batch request
            $startCount = ($startCount + $maxBatchRequests)
            $endCount = ($endCount + $maxBatchRequests)
        }
    }
}