function Invoke-SendGraphApiRequest {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateSet("v1.0", "beta")]
        [string]$GraphVersion = "v1.0",
        [Parameter(Position = 1)]
        [ValidateSet(
            "Get",
            "Post",
            "Patch",
            "Put",
            "Delete"
        )]
        [System.Net.Http.HttpMethod]$Method = [System.Net.Http.HttpMethod]::Get,
        [Parameter(Position = 2, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Resource,
        [Parameter(Position = 3)]
        [hashtable]$Body
    )

    $graphClient = Get-GraphClientObject -GraphVersion $GraphVersion
    
    $graphApiCallSplat = @{
        "GraphClient" = $graphClient;
        "Method"      = $Method;
        "Uri"         = $Resource;
    }

    switch ($null -ne $Body) {
        $true {
            $graphApiCallSplat.Add("RequestBody", $Body)
            break
        }
    }

    $convertedRsp = Send-GraphApiCall @graphApiCallSplat -AddConsistencyLevel

    $clientRspObj = $null
    $paginationCount = 1
    switch ($null -eq $convertedRsp.'@odata.nextLink') {
        $false {
            $clientRspObj = [System.Collections.Generic.List[pscustomobject]]::new()
            foreach ($item in $convertedRsp.value) {
                $clientRspObj.Add($item)
            }

            $hasNextLink = ($null -ne ($convertedRsp.PSObject.Properties | Where-Object { $PSItem.Name -eq "@odata.nextLink" }) )
            while ($hasNextLink -eq $true) {
                Write-Verbose "Next Page: $($paginationCount.ToString("00"))"
                
                $nextLink = $convertedRsp.'@odata.nextLink'
                $convertedRsp = Send-GraphApiCall -GraphClient $graphClient -Method $Method -Uri $nextLink

                foreach ($item in $convertedRsp.value) {
                    $clientRspObj.Add($item)
                }

                $hasNextLink = ($null -ne ($convertedRsp.PSObject.Properties | Where-Object { $PSItem.Name -eq "@odata.nextLink" }) )
                Write-Verbose "Has next link: $($hasNextLink)"
                $paginationCount++
            }

            break
        }

        Default {
            switch ($null -eq $convertedRsp.value) {
                $false {
                    $clientRspObj = [System.Collections.Generic.List[pscustomobject]]::new()
                    foreach ($item in $convertedRsp.value) {
                        $clientRspObj.Add($item)
                    }
                    break
                }

                Default {
                    $clientRspObj = $convertedRsp
                    break
                }
            }
            break
        }
    }

    return $clientRspObj
}