# Create the Perfectly Sized Virtual Monitor for Sunshine

This guide helps you set up a virtual monitor to use with Sunshine, particularly if you have a non-standard monitor configuration that isn't working well with Sunshine. The solution involves creating a virtual monitor that matches your laptop's resolution and using Nirsoft's `MultiMonitorTool.exe` to toggle between your real monitors and the virtual monitor when connecting and disconnecting from Sunshine.

## Scenario

- **Desktop Monitor**: Ultra-wide monitor (5120 x 2160).
- **Laptop Monitor**: Windows Laptop with a resolution of 2496 x 1644 (non-standard resolution).

### Solution Overview

1. **Create a Virtual Monitor**: Set up a virtual monitor that matches the resolution of your laptop screen.
2. **Use MultiMonitorTool**: Enable the virtual monitor and disable the main monitors when connecting to Sunshine. Reverse this process when disconnecting to make the desktop usable again.

## Usage Example

### Preparing for Sunshine

Use `MultiMonitorTool.exe` to identify the numbers of your displays. You will disable your real monitors and enable the virtual monitor.

> **Note**: Use RDP or TeamViewer to test these settings, as disabling your monitors without a remote session might make it difficult to control your computer.

- **Real Monitors**: Let's assume the real monitors are `1, 2, 3`.
- **Virtual Monitor**: The virtual monitor is `5`.

After completing the setup instructions, open your [Sunshine Panel](https://localhost:47990/) and go to **Applications > Desktop > Edit**.

In the "Command Preparations" section, add the following:

#### Command to Connect:
```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\IddSampleDriver\SetMonitors.ps1" -EnableMonitorNumbers 5 -DisableMonitorNumbers 1,2,3
```

#### Command to Disconnect:
```bash
powershell.exe -ExecutionPolicy Bypass -File "C:\IddSampleDriver\SetMonitors.ps1" -EnableMonitorNumbers 1,2,3 -DisableMonitorNumbers 5
```

## Step-by-Step Setup

### 1. Virtual Display Installation

To create the virtual display, use the IddSampleDriver:

1. **Download the Driver**: Get the latest version from the [IddSampleDriver repository](https://github.com/ge9/IddSampleDriver) releases page and extract the contents to a folder.

(Included the version I used in this repo as their license allows it)

2. **Copy Configuration File**: Copy `option.txt` to `C:\IddSampleDriver\option.txt` before installing the driver. This step is important.
3. **Install the Driver Certificate**: Right-click on the `*.bat` file and run it as an Administrator to add the driver certificate as a trusted root certificate.
4. **Skip INF File Installation**: Do **not** install the `inf` file directly.
5. **Open Device Manager**:
   - Click on any device, then go to the "Action" menu and select **Add Legacy Hardware**.
6. **Install Legacy Hardware**:
   - Select **Add hardware from a list (Advanced)**, then choose **Display adapters**.
   - Click **Have Disk...**, then **Browse...** to navigate to the extracted files and select the `inf` file.
7. **Finalize Setup**:
   - You are done! Go to **Display Settings** to customize the resolution of the additional displays. The virtual displays should now appear in Sunshine, Oculus, or VR settings and be streamable.
8. **Toggle Monitors**:
   - You can enable or disable the display adapter to manage the monitors.

### 2. Install MultiMonitorTool

Download [MultiMonitorTool.exe](https://www.nirsoft.net/utils/multimonitortool.zip) and extract the files to `C:\IddSampleDriver`.

### 3. Download and Save `SetMonitors.ps1`

1. Download `SetMonitors.ps1` from this repository.
2. Save it to `C:\IddSampleDriver`.

This script ensures that monitor switching is handled gracefully, avoiding issues like leaving the desktop in an unusable state.