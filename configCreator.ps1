# ============================
# Auto-Clicker Config Creator
# ============================

# Step 1: Number of clicks
$clickCount = Read-Host "Enter the number of clicks"
$clickCount = [int]$clickCount

$coords = @()
$delays = @()
$doubleClickFlags = @()

for ($i = 1; $i -le $clickCount; $i++) {
    $waitCapture = Read-Host ("Seconds to wait before capturing coordinate {0}" -f $i)
    $waitCapture = [int]$waitCapture
    Write-Host "Move mouse to coordinate $i. Waiting $waitCapture seconds..."
    Start-Sleep -Seconds $waitCapture

    Add-Type @"
using System;
using System.Runtime.InteropServices;

public class MouseHelperCapture {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }
    public static POINT GetPos() {
        POINT p;
        GetCursorPos(out p);
        return p;
    }
}
"@

    $pos = [MouseHelperCapture]::GetPos()
    $coords += ,@($pos.X, $pos.Y)
    Write-Host ("Captured coordinate {0}: X={1}, Y={2}" -f $i, $pos.X, $pos.Y)

    $doubleClickInput = Read-Host ("Should this be a double-click? (Y/N)")
    $doubleClickFlags += ($doubleClickInput -match '^[Yy]')

    $nextIndex = if ($i -lt $clickCount) { $i + 1 } else { 1 }
    $delay = Read-Host ("Delay (seconds) between click {0} and click {1}" -f $i, $nextIndex)
    $delays += [double]$delay
}

# Ask user for config filename
$configName = Read-Host "Enter a name for this configuration file (no extension)"
$configFile = "$configName.json"

# Build JSON object
$config = @{
    ClickCount = $clickCount
    Coords = $coords
    Delays = $delays
    DoubleClickFlags = $doubleClickFlags
}

# Save as JSON
$config | ConvertTo-Json | Set-Content $configFile

Write-Host "Configuration saved to $configFile"
