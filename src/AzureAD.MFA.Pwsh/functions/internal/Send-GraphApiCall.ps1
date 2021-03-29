function Send-GraphApiCall {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory)]
        [System.Net.Http.HttpClient]$GraphClient,
        [Parameter(Position = 1, Mandatory)]
        [System.Net.Http.HttpMethod]$Method,
        [Parameter(Position = 2, Mandatory)]
        [System.Uri]$Uri,
        [Parameter(Position = 3)]
        [hashtable]$RequestBody,
        [switch]$AddConsistencyLevel
    )

    $clientObj = $GraphClient
    switch ($AddConsistencyLevel) {
        $true {
            $clientObj.DefaultRequestHeaders.Add("ConsistencyLevel", "eventual")
            break
        }
    }

    $resourcePathRegex = [System.Text.RegularExpressions.Regex]::new("(?>(?>https|http):\/\/graph.microsoft.com\/(?>beta|v1\.0)\/|(?>\/|))(?'resourcePath'.+)")
    $resourcePathMatch = $resourcePathRegex.Match($Uri)

    $resourcePath = $resourcePathMatch.Groups['resourcePath'].Value

    Write-Verbose "Sending API call to: '$($resourcePath)'"

    $requestMessage = [System.Net.Http.HttpRequestMessage]::new($Method, $resourcePath)

    switch ($null -ne $RequestBody) {
        $true {
            $requestBodyJsonString = $RequestBody | ConvertTo-Json -Depth 20

            $requestBodyStringContent = [System.Net.Http.StringContent]::new($requestBodyJsonString)
            $requestBodyStringContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::new("application/json")

            $requestMessage.Content = $requestBodyStringContent
            
            break
        }
    }

    $clientRsp = $clientObj.SendAsync($requestMessage).GetAwaiter().GetResult()
    $clientRspContentString = $clientRsp.Content.ReadAsStringAsync().GetAwaiter().GetResult()

    $rspObj = $clientRspContentString | ConvertFrom-Json

    return $rspObj
}