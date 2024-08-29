# Configuration - Set the monitor numbers to enable and disable
$EnableMonitorNumber = "\\.\DISPLAY5"   # Set this to the monitor name you want to enable
$DisableMonitorNumber = "\\.\DISPLAY1"  # Set this to the monitor name you want to disable

# Path to MultiMonitorTool.exe - Make sure to provide the correct path
$MultiMonitorTool = "C:\IddSampleDriver\MultiMonitorTool.exe"
$StatusFilePath = "C:\IddSampleDriver\monitor_status.txt"

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

    # Initialize flags
    $MonitorEnabled = $false
    $MonitorDisabled = $false

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
            # Determine if this monitor matches the one to enable or disable
            if ($currentMonitor -eq $EnableMonitorNumber -and $isEnabled) {
                $MonitorEnabled = $true
            }

            if ($currentMonitor -eq $DisableMonitorNumber -and -not $isEnabled) {
                $MonitorDisabled = $true
            }

            # Reset for the next monitor
            $currentMonitor = ""
            $isEnabled = $false
        }
    }

    # Return the monitor statuses
    return @{ MonitorEnabled = $MonitorEnabled; MonitorDisabled = $MonitorDisabled }
}

function Set-MonitorState {
    param (
        [bool]$EnableMonitor,
        [bool]$DisableMonitor
    )

    if (-not $EnableMonitor) {
        Write-Output "Monitor $EnableMonitorNumber is not enabled. Attempting to enable..."
        & $MultiMonitorTool /enable $EnableMonitorNumber
        Start-Sleep -Seconds 3
    }
    else {
        Write-Output "Monitor $EnableMonitorNumber is enabled."
    }

    if (-not $DisableMonitor) {
        Write-Output "Monitor $DisableMonitorNumber is not disabled. Attempting to disable..."
        & $MultiMonitorTool /disable $DisableMonitorNumber
        Start-Sleep -Seconds 3
    }
    else {
        Write-Output "Monitor $DisableMonitorNumber is disabled."
    }
}

while ($true) {
    # Check current status of monitors
    $status = Check-MonitorStatus

    # If the desired condition is met, exit the script
    if ($status.MonitorEnabled -and $status.MonitorDisabled) {
        Write-Output "Desired monitor state achieved. Exiting script."
        exit
    }

    # Set monitors based on the current status
    Set-MonitorState -EnableMonitor $status.MonitorEnabled -DisableMonitor $status.MonitorDisabled

    # Wait for 5 seconds before checking again
    Start-Sleep -Seconds 5
}
