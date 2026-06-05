# Dual Browser Split Screen Launcher

A PowerShell script that opens the current webpage in the opposite browser (Chrome ↔ Edge) with automatic window positioning for dual-monitor or split-screen setups.

## Features

- 🔄 **Auto-detects active browser** - Identifies which browser (Chrome or Edge) you're currently using
- 📋 **Extracts current URL** - Reads the URL from your active browser's address bar
- 🖥️ **Dual-monitor support** - Opens opposite browser on the second monitor (if available)
- 📱 **Single-monitor split** - Automatically splits your screen 50/50 between both browsers
- 📌 **Taskbar-pinnable** - Launch with a single click from your taskbar
- ✅ **No admin required** - Runs with standard user permissions
- 🎯 **Smart positioning** - Repositions both windows for clean side-by-side layout

## Requirements

- **Windows 10 or later**
- **Google Chrome** (installed at default location)
- **Microsoft Edge** (installed at default location)
- **PowerShell 5.0 or later**

## Installation

### Step 1: Download the Script

Clone or download this repository:
```bash
git clone https://github.com/yourusername/dual-browser-launcher.git
cd dual-browser-launcher
```

Or download the `Open-DualBrowsers.ps1` file directly.

### Step 2: Create a Batch Wrapper

Create a new file named `Open-DualBrowsers.bat` in the same folder with the following content:

```batch
@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\path\to\your\Open-DualBrowsers.ps1'"
pause
```

Replace `C:\path\to\your\` with the actual path to where you saved the `.ps1` file.

**Example:**
```batch
@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& 'C:\Users\YourUsername\Desktop\Open-DualBrowsers.ps1'"
pause
```

### Step 3: Pin to Taskbar

1. Right-click the `.bat` file
2. Select **"Send to"** → **"Desktop (create shortcut)"**
3. Right-click the shortcut on your desktop
4. Select **"Pin to Quick Access"** or drag it directly to your taskbar
5. Done! Click the icon to launch

## Usage

### Basic Usage

Simply click the taskbar icon. The script will:

1. Detect which browser you currently have in focus
2. Extract the URL from that browser's active tab
3. Launch the opposite browser with the same URL
4. **Single monitor**: Split your screen 50/50 (active browser on left, new on right)
5. **Dual monitors**: Open new browser on the second monitor

### Examples

**Example 1: Single Monitor**
- You're viewing `example.com` in Edge on the left half of your screen
- Click the launcher
- Chrome opens on the right half with the same page
- Both browsers now fill the screen side-by-side

**Example 2: Dual Monitors**
- You're viewing `github.com` in Chrome on Monitor 1
- Click the launcher
- Edge opens on Monitor 2 with the same page

## Troubleshooting

### Script won't run / "Execution Policy" error
The batch wrapper handles this automatically. If you see execution policy errors:
1. Right-click Command Prompt or PowerShell
2. Select "Run as administrator"
3. Run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### URL not being extracted (defaults to Google)
This can happen if:
- The browser's address bar isn't exposed to accessibility APIs
- A security policy blocks URL reading
- **Workaround**: Copy your URL to clipboard before running the script (Ctrl+C on the address bar)

### Windows not positioning correctly
- The script attempts to position windows; if this fails, you may need to move them manually
- This can happen with certain window managers or security policies
- The browsers will still launch with the correct URL

### Chrome/Edge not found
The script expects default installation paths:
- Chrome: `C:\Program Files\Google\Chrome\Application\chrome.exe`
- Edge: `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe`

If you installed elsewhere, edit the script and update the paths in the main logic section.

### One browser keeps launching instead of alternating
Make sure you're clicking on the window of the browser you want to be the "active" one before launching the script. The script detects the currently focused window.

## How It Works

1. **Browser Detection**: Uses Windows API to find which browser window has focus
2. **URL Extraction**: Reads the address bar via UI Automation with multiple fallback strategies
3. **Monitor Detection**: Queries system for available displays
4. **Window Positioning**: Uses Windows API to resize and move windows to exact positions

## Customization

### Change default URL
If URL extraction fails, the script defaults to `https://www.google.com`. To change this, edit the script:

In the `Get-CurrentURL` function, change:
```powershell
return "https://www.google.com"
```

To your preferred default URL.

### Custom browser paths
If your browsers are installed in non-standard locations, update the paths in the main logic:

```powershell
# For Chrome
Start-Process "C:\Your\Custom\Path\chrome.exe" -ArgumentList @("--new-window", $url) -NoNewWindow

# For Edge
Start-Process "C:\Your\Custom\Path\msedge.exe" -ArgumentList @("-new-window", $url) -NoNewWindow
```

## Known Limitations

- Only works with Chrome and Edge (not Firefox, Safari, etc.)
- Requires browsers to be installed at default Windows locations (customizable)
- On single monitor: Always positions active browser on left, new on right
- URL extraction may fail on certain websites due to security restrictions
- Clipboard fallback only works if you manually copy the URL first

## Frequently Asked Questions

**Q: Why does it need PowerShell?**  
A: PowerShell provides Windows API access for browser detection, URL reading, and precise window positioning.

**Q: Can I use this with other browsers?**  
A: Currently only Chrome and Edge are supported. Adding other browsers would require modifying the script.

**Q: Does it work with Chromium browsers?**  
A: Only with official Chrome and Edge. Other Chromium browsers (Brave, Vivaldi, etc.) would need custom code.

**Q: What if both browsers are open but I want to pick which one is "active"?**  
A: Click on the browser window you want to detect first, then run the script. The focused window is considered "active."

**Q: Can I edit which side each browser goes on?**  
A: Yes! In the `Position-BothWindows` function, swap the `$leftX` and `$rightX` assignments.

## License

This project is open source and available under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! Feel free to submit issues and pull requests.

## Support

If you encounter issues:
1. Check the **Troubleshooting** section above
2. Run the `.ps1` directly (not via batch) to see detailed error messages
3. Ensure both Chrome and Edge are installed and accessible

---

Made with ❤️ for power users who need efficient dual-browser workflows
