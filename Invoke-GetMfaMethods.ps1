[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string[]]$UserId,
    [Parameter(Position = 1)]
    [switch]$RunGarbageCollection
)

$userIdCount = ($UserId | Measure-Object).Count
$loopCount = 0

$threadedJobs = foreach ($uid in $UserId) {
    $loopCount++
    Write-Verbose "Creating thread job $($loopCount) out of $($userIdCount)."
    Start-ThreadJob -ScriptBlock {
        .\Get-AadUserMfaMethods.ps1 -UserId $args[0]
        $null = [System.GC]::Collect()
    } -ThrottleLimit 10 -ArgumentList $uid
}

Write-Verbose "Waiting for all jobs to finish."
$receivedData = $threadedJobs | Wait-Job | Receive-Job
$threadedJobs | Remove-Job -Force

switch ($RunGarbageCollection) {
    $true {
        Write-Warning "Running garbage collection."
        $null = [System.GC]::Collect()
    }
}

return $receivedData