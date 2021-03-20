[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateNotNullOrEmpty()]
    [pscustomobject[]]$UserObj,
    [Parameter(Position = 1)]
    [int]$ThrottleLimit = 5
)

#These variables are used for verbose information while creating jobs.
$userObjCount = ($UserObj | Measure-Object).Count
$loopCount = 0

<#
    Create threaded jobs to get the data. This will speed up the data gather process, which is especially useful when there are over 1,000 user objects.
    By default it will only run 5 jobs at once. This can be controlled with the '-ThrottleLimit' parameter.

    During my tests, I had:
        - 1,890 user objects to process
        - Running synchronously it took:
            * 
        - Running asynchronously (Using parallel threads) it took:
            * 6 minutes and 5 seconds (00:06:05)
#>
$threadedJobs = foreach ($user in $UserObj) {
    $loopCount++
    Write-Verbose "Creating thread job $($loopCount) out of $($userObjCount)."
    Start-ThreadJob -ScriptBlock {
        .\Get-AadUserMfaMethods.ps1 -UserObj $args[0]
    } -ThrottleLimit $ThrottleLimit -ArgumentList $user
}

#Instead of running 'Wait-Job', we're running a while statement so we can monitor that status of the jobs.
while (($threadedJobs.State -contains "Running") -and ($threadedJobs.State -contains "NotStarted")) {
    $completedCount = ($threadedJobs | Where-Object { $PSItem.State -eq "Completed" } | Measure-Object).Count
    $notStartedCount = ($threadedJobs | Where-Object { $PSItem.State -eq "NotStarted" } | Measure-Object).Count

    #Should probably switch to 'Write-Progress', since it won't be as taxing as it's only executed every 10 seconds.
    Write-Verbose "`n/ Job Status /`nTotal Jobs Completed: $($completedCount)`nJobs Not Started: $($notStartedCount)`n-------------------"

    #Need to put a limiter in here (Sleep for 10 seconds) so it's not constantly outputting information and wasting CPU resources.
    Start-Sleep -Seconds 10
}

#Receive the data from the jobs and remove them.
$receivedData = $threadedJobs | Receive-Job
$threadedJobs | Remove-Job -Force

<#
    Because of the amount of memory that can be used during this script, we'll forcefully run garbage collection.
    
    I've seen memory usage for pwsh.exe spike on a Windows and macOS system to over 3GB during execution.
    This can be problematic if that memory never gets released. 
    Forcefully running garbage collection dropped memory usage down from 2.6GB during one run to ~400MB afterwards.

    This isn't an ideal setup, if I'm being honest. I'm looking into alternative ways of ensuring memory usage doesn't balloon during execution and afterwards.
#>
Write-Warning "Running garbage collection."
$null = [System.GC]::Collect()

return $receivedData