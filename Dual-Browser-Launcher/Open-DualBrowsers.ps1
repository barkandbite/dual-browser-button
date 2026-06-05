# Dual Browser Dual Monitor Launcher
# Opens the current site in the opposite browser on the other monitor
# Pin this script to taskbar for quick access

# No admin required - runs with user permissions

# ===== ADD ASSEMBLIES FIRST =====
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WindowManager {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
    
    public const uint SWP_NOZORDER = 0x0004;
}
"@ -ErrorAction SilentlyContinue

# ===== DEFINE FUNCTIONS =====

# Function to get monitor info
function Get-MonitorInfo {
    [System.Windows.Forms.Screen]::AllScreens | ForEach-Object {
        [PSCustomObject]@{
            DeviceName = $_.DeviceName
            IsPrimary = $_.Primary
            Bounds = $_.Bounds
            WorkingArea = $_.WorkingArea
        }
    }
}

# Function to extract URL from active browser using UI Automation
function Get-CurrentURL {
    param([string]$BrowserName)
    
    try {
        $processName = if ($BrowserName -eq "Chrome") { "chrome" } else { "msedge" }
        $process = Get-Process -Name $processName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1
        
        if ($null -eq $process) {
            return $null
        }
        
        Write-Host "Attempting to read URL from $BrowserName..." -ForegroundColor Cyan
        
        # Try UI Automation to read the address bar
        $windowHandle = $process.MainWindowHandle
        $rootElement = [System.Windows.Automation.AutomationElement]::FromHandle($windowHandle)
        
        # Strategy 1: Look for edit controls with URL patterns
        $condition = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
            [System.Windows.Automation.ControlType]::Edit
        )
        
        $editControls = $rootElement.FindAll([System.Windows.Automation.TreeScope]::Descendants, $condition)
        
        foreach ($control in $editControls) {
            try {
                $url = $control.Current.Value
                # Look for URL pattern
                if ($url -match "^https?://|^www\.|^ftp://") {
                    Write-Host "Found URL via address bar: $url" -ForegroundColor Green
                    return $url
                }
            }
            catch { }
        }
        
        # Strategy 2: Look for text patterns in the first edit control
        if ($editControls.Count -gt 0) {
            foreach ($control in $editControls) {
                try {
                    $valuePattern = $control.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
                    $value = $valuePattern.Current.Value
                    if ($value -match "^https?://|^www\.|^ftp://") {
                        Write-Host "Found URL via value pattern: $value" -ForegroundColor Green
                        return $value
                    }
                }
                catch { }
            }
        }
        
        # Fallback: Check clipboard
        $clipboardUrl = Get-Clipboard -Format Text -ErrorAction SilentlyContinue
        if ($clipboardUrl -match "^https?://") {
            Write-Host "Found URL via clipboard: $clipboardUrl" -ForegroundColor Green
            return $clipboardUrl
        }
        
        Write-Host "Could not extract URL. Using Google." -ForegroundColor Yellow
        return "https://www.google.com"
    }
    catch {
        Write-Host "Error reading URL: $_. Using Google." -ForegroundColor Yellow
        return "https://www.google.com"
    }
}

# Function to detect which browser window is currently in focus
function Get-ActiveBrowser {
    try {
        $fgWindow = [WindowManager]::GetForegroundWindow()
        $processId = 0
        [WindowManager]::GetWindowThreadProcessId($fgWindow, [ref]$processId) | Out-Null
        
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        
        if ($process.Name -eq "chrome") {
            return "Chrome"
        } elseif ($process.Name -eq "msedge") {
            return "Edge"
        }
        
        # If foreground isn't a browser, check what's open
        $chromeProcess = Get-Process -Name "chrome" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1
        $edgeProcess = Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1
        
        if ($null -ne $edgeProcess) { return "Edge" }
        if ($null -ne $chromeProcess) { return "Chrome" }
        
        throw "No browser window found!"
    }
    catch {
        return $null
    }
}

# Function to reposition both browser windows for 50/50 split on single monitor
function Position-BothWindows {
    param([string]$ActiveBrowserName, [string]$NewBrowserName, [object]$Monitor)
    
    Start-Sleep -Milliseconds 500
    
    try {
        $activeProcess = Get-Process -Name $(if ($ActiveBrowserName -eq "Chrome") { "chrome" } else { "msedge" }) -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | Select-Object -First 1
        $newProcess = Get-Process -Name $(if ($NewBrowserName -eq "Chrome") { "chrome" } else { "msedge" }) -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -ne "" } | Sort-Object -Property StartTime -Descending | Select-Object -First 1
        
        if ($null -eq $activeProcess -or $null -eq $newProcess) {
            Write-Host "Waiting for new window to open..." -ForegroundColor Yellow
            return
        }
        
        $bounds = $Monitor.WorkingArea
        $leftX = $bounds.X
        $rightX = [int]($bounds.X + ($bounds.Width / 2))
        $y = $bounds.Y
        $width = [math]::Floor($bounds.Width / 2)
        $height = $bounds.Height
        
        # Position active browser on left
        $result1 = [WindowManager]::MoveWindow(
            $activeProcess.MainWindowHandle,
            $leftX,
            $y,
            $width,
            $height,
            $true
        )
        
        # Position new browser on right
        $result2 = [WindowManager]::MoveWindow(
            $newProcess.MainWindowHandle,
            $rightX,
            $y,
            $width,
            $height,
            $true
        )
        
        if ($result1 -and $result2) {
            Write-Host "Both windows positioned in 50/50 split." -ForegroundColor Green
        } else {
            Write-Host "Note: Could not auto-position windows. You may need to move them manually." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error positioning windows: $_" -ForegroundColor Yellow
    }
}

# ===== MAIN LOGIC =====

try {
    Write-Host "Detecting active browser..." -ForegroundColor Cyan
    
    # Get the currently focused browser
    $activeBrowser = Get-ActiveBrowser
    $oppositeBrowser = if ($activeBrowser -eq "Chrome") { "Edge" } else { "Chrome" }
    
    Write-Host "Active browser: $activeBrowser" -ForegroundColor Green
    Write-Host "Opening in: $oppositeBrowser" -ForegroundColor Green
    
    # Get the current URL
    Write-Host "Extracting URL..." -ForegroundColor Cyan
    $url = Get-CurrentURL -BrowserName $activeBrowser
    Write-Host "URL: $url" -ForegroundColor Green
    
    # Get monitor information
    $monitors = Get-MonitorInfo | Sort-Object { $_.Bounds.X }
    $singleMonitor = $monitors.Count -lt 2
    
    if ($singleMonitor) {
        Write-Host "Single monitor detected. Will position both windows in 50/50 split." -ForegroundColor Green
        $targetMonitor = $monitors[0]
    } else {
        Write-Host "Dual monitor detected. Using separate monitors." -ForegroundColor Green
        $targetMonitor = if ($monitors[0].IsPrimary) { $monitors[1] } else { $monitors[0] }
    }
    
    Write-Host "Launching $oppositeBrowser..." -ForegroundColor Cyan
    
    # Launch the opposite browser
    if ($oppositeBrowser -eq "Chrome") {
        Start-Process "C:\Program Files\Google\Chrome\Application\chrome.exe" -ArgumentList @("--new-window", $url) -NoNewWindow
    } else {
        Start-Process "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" -ArgumentList @("-new-window", $url) -NoNewWindow
    }
    
    # Position windows
    if ($singleMonitor) {
        # Wait for new window and position both
        Start-Sleep -Milliseconds 1000
        Position-BothWindows -ActiveBrowserName $activeBrowser -NewBrowserName $oppositeBrowser -Monitor $targetMonitor
    } else {
        # Dual monitor - just let windows open naturally
        Write-Host "Windows will open on separate monitors." -ForegroundColor Green
    }
    
    Write-Host "Done! Your page is now open in $oppositeBrowser." -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Error: $_"
    Read-Host "Press Enter to exit"
    exit 1
}
