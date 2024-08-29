param (
    [int[]]$EnableMonitorNumbers,  # Array of monitor numbers to enable (e.g., 1, 2, 3)
    [int[]]$DisableMonitorNumbers  # Array of monitor numbers to disable (e.g., 4, 5, 6)
)

# Path to MultiMonitorTool.exe - Make sure to provide the correct path
$MultiMonitorTool = "C:\IddSampleDriver\MultiMonitorTool.exe"
$StatusFilePath = "C:\IddSampleDriver\monitor_status.txt"

function Format-MonitorName {
    param (
        [int[]]$MonitorNumbers  # Array of monitor numbers (e.g., 1, 2, 3)
    )
    
    # Format monitor names
    return $MonitorNumbers | ForEach-Object { "\\.\DISPLAY$_" }
}

function Check-MonitorStatus {
    # Delete the old monitor status file if it exists
    if (Test-Path $StatusFilePath) {
        Remove-Item $StatusFilePath
    }

    # Get the current status of monitors and save to a text file
    & $MultiMonitorTool /stext $StatusFilePath

    # Wait for the file to be written
    while (-not (Test-Path $StatusFilePath)) {
        Start-Sleep -Milliseconds 500
    }

    Start-Sleep -Seconds 2

    # Initialize hashtables for monitor statuses
    $MonitorsEnabled = @{}
    $MonitorsDisabled = @{}

    # Read monitor status from the text file
    $monitorStatus = Get-Content -Path $StatusFilePath

    # Variables to keep track of the current monitor being read
    $currentMonitor = ""
    $isEnabled = $false

    # Parse the monitor status file
    foreach ($line in $monitorStatus) {
        if ($line -like "Name              :*") {
            # Extract the monitor name
            $currentMonitor = $line -replace "Name              :", ""
            $currentMonitor = $currentMonitor.Trim()
        }
        
        if ($line -like "Active            :*") {
            # Check if the current monitor is active
            $isEnabled = $line -like "*Yes*"
        }

        # Check if the end of the monitor block is reached
        if ($line -like "==================================================") {
            if ($currentMonitor) {
                # Store monitor status in hashtables
                $MonitorsEnabled[$currentMonitor] = $isEnabled
                $MonitorsDisabled[$currentMonitor] = -not $isEnabled
            }
            # Reset for the next monitor
            $currentMonitor = ""
            $isEnabled = $false
        }
    }

    # Return the monitor statuses
    return @{ MonitorsEnabled = $MonitorsEnabled; MonitorsDisabled = $MonitorsDisabled }
}

function Set-MonitorState {
    param (
        [hashtable]$MonitorsEnabled,
        [hashtable]$MonitorsDisabled
    )

    foreach ($monitor in $FormattedEnableMonitors) {
        if ($MonitorsEnabled[$monitor] -ne $true) {
            Write-Output "Monitor $monitor is not enabled. Attempting to enable..."
            & $MultiMonitorTool /enable $monitor
            Start-Sleep -Seconds 3
        }
        else {
            Write-Output "Monitor $monitor is enabled."
        }
    }

    foreach ($monitor in $FormattedDisableMonitors) {
        if ($MonitorsDisabled[$monitor] -ne $true) {
            Write-Output "Monitor $monitor is not disabled. Attempting to disable..."
            & $MultiMonitorTool /disable $monitor
            Start-Sleep -Seconds 3
        }
        else {
            Write-Output "Monitor $monitor is disabled."
        }
    }
}

# Format the input numbers to monitor names
$FormattedEnableMonitors = Format-MonitorName -MonitorNumbers $EnableMonitorNumbers
$FormattedDisableMonitors = Format-MonitorName -MonitorNumbers $DisableMonitorNumbers

while ($true) {
    # Check current status of monitors
    $status = Check-MonitorStatus

    # Determine if all desired conditions are met
    $allEnabled = $FormattedEnableMonitors | ForEach-Object { $status.MonitorsEnabled[$_] -eq $true } | Where-Object { $_ -eq $false } | Measure-Object
    $allDisabled = $FormattedDisableMonitors | ForEach-Object { $status.MonitorsDisabled[$_] -eq $true } | Where-Object { $_ -eq $false } | Measure-Object

    if ($allEnabled.Count -eq 0 -and $allDisabled.Count -eq 0) {
        Write-Output "Desired monitor state achieved. Exiting script."
        exit
    }

    # Set monitors based on the current status
    Set-MonitorState -MonitorsEnabled $status.MonitorsEnabled -MonitorsDisabled $status.MonitorsDisabled

    # Wait for 5 seconds before checking again
    Start-Sleep -Seconds 5
}
