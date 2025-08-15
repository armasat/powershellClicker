param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,

    [Parameter(Mandatory=$false)]
    [int]$Loops = 1  # default to 1 if not provided
)

if (-Not (Test-Path $ConfigFile)) {
    Write-Host "Configuration file not found: $ConfigFile"
    exit
}

# Load JSON config
$config = Get-Content $ConfigFile | ConvertFrom-Json

$clickCount = $config.ClickCount
$coords = $config.Coords
$delays = $config.Delays
$doubleClickFlags = $config.DoubleClickFlags

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class MouseHelper {
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

    public const int MOUSEEVENTF_LEFTDOWN = 0x02;
    public const int MOUSEEVENTF_LEFTUP   = 0x04;

    static Random rand = new Random();

    public static void Click(int x, int y) {
        SetCursorPos(x, y);
        mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
        mouse_event(MOUSEEVENTF_LEFTUP, x, y, 0, 0);
    }

    public static void DoubleClick(int x, int y) {
        SetCursorPos(x, y);
        Click(x, y);
        Thread.Sleep(150);
        Click(x, y);
    }

    public static void MoveSmoothHuman(int startX, int startY, int endX, int endY) {
        int steps = rand.Next(25, 35);
        for(int i=1; i<=steps; i++) {
            double t = (double)i / steps;
            int x = startX + (int)((endX-startX)*t);
            int y = startY + (int)((endY-startY)*t);
            SetCursorPos(x, y);
            Thread.Sleep(rand.Next(5, 12));
        }
    }
}
"@

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

# Get current mouse position
$prevPos = [MouseHelperCapture]::GetPos()
$prevX = $prevPos.X
$prevY = $prevPos.Y
$rand = New-Object System.Random

for ($loop = 1; $loop -le $Loops; $loop++) {
    Write-Host "Starting loop $loop of $Loops..."
    for ($i = 0; $i -lt $clickCount; $i++) {
        $targetX = $coords[$i][0]
        $targetY = $coords[$i][1]

        [MouseHelper]::MoveSmoothHuman($prevX, $prevY, $targetX, $targetY)
        $prevX = $targetX
        $prevY = $targetY

        if ($doubleClickFlags[$i]) {
            [MouseHelper]::DoubleClick($prevX, $prevY)
            Write-Host ("Double-clicked at X={0}, Y={1}" -f $prevX, $prevY)
        } else {
            [MouseHelper]::Click($prevX, $prevY)
            Write-Host ("Clicked at X={0}, Y={1}" -f $prevX, $prevY)
        }

        $delayMs = [int](($delays[$i]*1000) + $rand.Next(-200,300))
        if ($delayMs -le 0) { $delayMs = 50 }
        Start-Sleep -Milliseconds $delayMs
    }
    Start-Sleep -Milliseconds $rand.Next(300, 800)
}

Write-Host "Completed all $Loops loops."
