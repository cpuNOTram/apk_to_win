param(
    [string]$i,                 # input mode
    [string]$c,                 # command line package
    [string]$a,                 # auto mode
    [string]$o,                 # output directory
    [string]$l,                 # list packages
    [string]$d,                 # device serial number
    [switch]$h,                 # help menu
    [string]$adb = "./adb.exe"  # adb path
)

# ----------------------------------------------------------
# HELP MENU
# ----------------------------------------------------------
if ($h) {
  Write-Host "Usage:"
  Write-Host "  -i <file>         Input mode (packages from file)"
  Write-Host "  -s <package>      Single package mode"
  Write-Host "  -a <mode>         Auto mode:"
  Write-Host "                      auto/default = exclude system apks"
  Write-Host "                      all = include all apks"
  Write-Host "  -l <mode>         Lists Mode:"
  Write-Host "                      auto/default = exclude system packages"
  Write-Host "                      all = include all packages"
  Write-Host "  -d <serial>       Specify device serial number (optional)"
  Write-Host "  -o <directory>    Output directory (default: ./apks-gpt)"
  Write-Host ""
  Write-Host "Examples:"
  Write-Host "  .\apk_to_win -s com.android.chrome"
  Write-Host "  .\apk_to_win -i packages.txt -o C:\APKs"
  Write-Host "  .\apk_to_win -a auto -o extracted"
  Write-Host "  .\apk_to_win -l all"
  Write-Host "  .\apk_to_win -d emulator-5554 -a all"
  Write-Host ""
  Write-Host "Device Selection:"
  Write-Host "  If multiple devices are connected, you will be prompted to select one."
  Write-Host "  Use -d to specify a device serial number directly."
  exit
}

# ----------------------------------------------------------
# DEVICE SELECTION
# ----------------------------------------------------------
function Select-Device {
  Write-Host "Checking connected devices..." -ForegroundColor Cyan
  
  # Get list of devices
  $deviceList = & $adb devices | Select-Object -Skip 1 | Where-Object { $_.Trim() -ne "" }
  
  if (-not $deviceList) {
    Write-Host "No devices found. Please connect a device and enable USB debugging." -ForegroundColor Red
    exit
  }
  
  # Parse devices
  $devices = @()
  foreach ($line in $deviceList) {
    if ($line -match "(\S+)\s+device") {
      $devices += $matches[1]
    }
  }
  
  if ($devices.Count -eq 0) {
    Write-Host "No devices in 'device' state. Check device authorization." -ForegroundColor Red
    exit
  }
  
  if ($devices.Count -eq 1) {
    Write-Host "Found 1 device: $($devices[0])" -ForegroundColor Green
    return $devices[0]
  }
  
  # Multiple devices - show selection menu
  Write-Host "Multiple devices detected:" -ForegroundColor Yellow
  for ($i = 0; $i -lt $devices.Count; $i++) {
    Write-Host "  [$($i + 1)] $($devices[$i])"
  }
  
  do {
    $selection = Read-Host "`nSelect device number (1-$($devices.Count))"
    $selectionNum = [int]$selection
  } while ($selectionNum -lt 1 -or $selectionNum -gt $devices.Count)
  
  $selectedDevice = $devices[$selectionNum - 1]
  Write-Host "Selected device: $selectedDevice" -ForegroundColor Green
  return $selectedDevice
}

# Determine which device to use
if ($d) {
  Write-Host "Using specified device: $d" -ForegroundColor Green
  $selectedDevice = $d
}
else {
  $selectedDevice = Select-Device
}

# Store device argument separately
$adbDevice = @("-s", $selectedDevice)

# Default output directory = ./apks
if ($o) {
  $BaseOut = $o
}
else {
  $FolderName = "apks-"+$selectedDevice -replace "[\/:*?""<>|]", "-"
  $BaseOut = Join-Path (Get-Location) $FolderName
}

# Ensure base output directory exists
if (-not (Test-Path $BaseOut)) {
  New-Item -ItemType Directory -Path $BaseOut | Out-Null
}

function Copy-APK {
  param(
    [string]$pkg
  )
  # Cleans package name
  $pkgClean = $pkg | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | ForEach-Object { $_ -replace "^package:", "" }
  Write-Host "`n=== Fetching APK for: $pkgClean ===" -ForegroundColor Blue
  
  # Gets exact path
  $paths = & $adb @adbDevice shell pm path $pkgClean | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | ForEach-Object { $_ -replace "^package:", "" }
  
  if (-not $paths) {
    Write-Host "No paths found for $pkgClean. Check package name or device connection."  -ForegroundColor Red
    return
  }
  
  # package-specific subdirectory
  $pkgOut = Join-Path $BaseOut $pkgClean
  if (-not (Test-Path $pkgOut)) { New-Item -ItemType Directory -Path $pkgOut | Out-Null }
  
  foreach ($p in $paths) {
    & $adb @adbDevice pull $p $pkgOut
  }
  
  Write-Host "Saved APKs in: $pkgOut" -ForegroundColor Green
}

# ----------------------------------------------------------
# MODE HANDLING
# ----------------------------------------------------------

# INPUT MODE
if ($i) {
  if (-not (Test-Path $i)) {
    Write-Host "File not found: $i" -ForegroundColor Red
    exit
  }
  Write-Host "Running list mode from file: $i"
  
  $packages = Get-Content $i | Where-Object { $_.Trim() -ne "" }
  foreach ($pkg in $packages) {
    Copy-APK -pkg $pkg.Trim()
  }
  
  Write-Host "`nOutput saved to: $BaseOut" -ForegroundColor Cyan
}

# COMMAND LINE MODE
if ($c) {
  Write-Host "Command line mode"

  $pkgList = $c -split "[,\s]+" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
  foreach ($pkg in $pkgList) {
    Copy-APK -pkg $pkg
  }

  Write-Host "`nOutput saved to: $BaseOut" -ForegroundColor Cyan
}

# AUTO MODE
if ($a) {
  # Normalize input for comparison
  $autoMode = $a.Trim().ToLower()
  
  if ($autoMode -eq "auto" -or $autoMode -eq "default") {
    Write-Host "Auto mode (excluding system packages)" -ForegroundColor Magenta
    $packages = & $adb @adbDevice shell pm list packages |
    Where-Object { $_ -notmatch "google|android|system|gms" }
  }
  elseif ($autoMode -eq "all") {
    Write-Host "Auto mode (including system packages)" -ForegroundColor Magenta
    $packages = & $adb @adbDevice shell pm list packages
  }
  else {
    Write-Host "Unknown auto mode value: $a" -ForegroundColor Red
    Write-Host "Use -a=auto, -a=default, or -a=all"
    exit
  }
  
  # Process the packages
  foreach ($pkg in $packages) {
    Copy-APK -pkg $pkg.Trim()
  }
  
  Write-Host "`nOutput saved to: $BaseOut" -ForegroundColor Cyan
}

# ----------------------------------------------------------
# LIST PACKAGES
# ----------------------------------------------------------
if ($l) {
  $listMode = $l.Trim().ToLower()
  
  if ($listMode -eq "auto" -or $listMode -eq "default" ) {
    Write-Host "List of Packages [installed]:" -ForegroundColor Magenta
    $packages = & $adb @adbDevice shell pm list packages | Where-Object { $_ -notmatch "google|android|system|gms" }
    $packages | ForEach-Object { Write-Host $_ }
  }
  elseif ($listMode -eq "all") {
    Write-Host "List of Packages [all]:" -ForegroundColor Magenta
    $packages = & $adb @adbDevice shell pm list packages
    $packages | ForEach-Object { Write-Host $_ }
  }
  else {
    Write-Host "Unknown list mode value: $l" -ForegroundColor Red
    Write-Host "Use -l=auto, -l=default, or -l=all"
    exit
  }
}

