$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:lastLaunch = [datetime]::MinValue

try {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PolyStrikeWin32 {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
}
'@
} catch { }

# Close any older launcher server still running, so its port is free.
function Stop-OldLauncherServers {
  try {
    $old = @(Get-CimInstance -ClassName Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" |
      Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -and $_.CommandLine -match 'LauncherServer\.ps1' })
    foreach ($p in $old) { Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue }
    if ($old.Count -gt 0) { Start-Sleep -Milliseconds 1000 }
  } catch { }
}

function Try-StartListener([int]$candidate) {
  $test = [System.Net.HttpListener]::new()
  $test.Prefixes.Add("http://127.0.0.1:$candidate/")
  try {
    $test.Start()
    return @{ Listener = $test; Url = "http://127.0.0.1:$candidate/" }
  } catch {
    $test.Close()
    return $null
  }
}

function Focus-Process($proc) {
  try {
    if (-not $proc -or $proc.MainWindowHandle -eq [IntPtr]::Zero) { return $false }
    [void][PolyStrikeWin32]::ShowWindow($proc.MainWindowHandle, 9)
    [void][PolyStrikeWin32]::SetForegroundWindow($proc.MainWindowHandle)
    (New-Object -ComObject WScript.Shell).AppActivate($proc.Id) | Out-Null
    return $true
  } catch { return $false }
}

# Returns $true if a launcher page window exists (and brings it forward).
function Focus-LauncherPage {
  $page = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero -and $_.MainWindowTitle -like '*POLYSTRIKE | Launcher*' } |
    Select-Object -First 1
  if (-not $page) { return $false }
  Focus-Process $page | Out-Null
  return $true
}

function Get-RunningEditors {
  try {
    $uproject = Get-ChildItem -LiteralPath $root -Filter '*.uproject' | Select-Object -First 1
    if (-not $uproject) { return @() }
    $needle = $uproject.FullName
    return @(Get-CimInstance -ClassName Win32_Process -Filter "Name = 'UnrealEditor.exe'" |
      Where-Object { $_.CommandLine -and $_.CommandLine.IndexOf($needle, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
  } catch { return @() }
}

function Focus-RunningEditor {
  foreach ($editor in Get-RunningEditors) {
    $proc = Get-Process -Id $editor.ProcessId -ErrorAction SilentlyContinue
    if (Focus-Process $proc) { return $true }
  }
  return $false
}

function Open-LauncherPage([string]$url) {
  Start-Process $url
}

function Send-Text($context, [int]$status, [string]$text) {
  $response = $context.Response
  $response.StatusCode = $status
  $response.ContentType = 'text/plain; charset=utf-8'
  $bytes = [Text.Encoding]::UTF8.GetBytes($text)
  $response.OutputStream.Write($bytes, 0, $bytes.Length)
  $response.Close()
}

function Handle-Request($context) {
  $path = $context.Request.Url.AbsolutePath
  $method = $context.Request.HttpMethod

  if ($method -eq 'GET' -and $path -eq '/') {
    $html = Get-Content -LiteralPath (Join-Path $root 'Launcher.html') -Raw -Encoding UTF8
    $bytes = [Text.Encoding]::UTF8.GetBytes($html)
    $context.Response.ContentType = 'text/html; charset=utf-8'
    $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $context.Response.Close()
    return
  }

  if ($method -ne 'POST' -or ($path -ne '/launch/play' -and $path -ne '/launch/mod')) {
    Send-Text $context 404 'Not found'
    return
  }

  if ($path -eq '/launch/play') {
    $target = Join-Path $root 'PlayStandalone.bat'
  } else {
    $target = Join-Path $root 'StartEditor.bat'
  }
  if (-not (Test-Path -LiteralPath $target)) {
    Send-Text $context 404 "Missing: $target"
    return
  }
  if (@(Get-RunningEditors).Count -gt 0) {
    Focus-RunningEditor | Out-Null
    Send-Text $context 200 'PolyStrike is already running. Brought it to the front.'
    return
  }
  if (((Get-Date) - $script:lastLaunch).TotalSeconds -lt 15) {
    Send-Text $context 200 'PolyStrike is already starting. Please wait a moment.'
    return
  }
  Start-Process -FilePath $target -WorkingDirectory $root
  $script:lastLaunch = Get-Date
  Send-Text $context 200 'Started'
}

# ---- Startup ----
Stop-OldLauncherServers

# Prefer port 9137. Wait briefly for it to free up, then use the next free port.
$started = $null
for ($i = 0; $i -lt 10 -and -not $started; $i++) {
  $started = Try-StartListener 9137
  if (-not $started) { Start-Sleep -Milliseconds 500 }
}
foreach ($candidate in 9138..9160) {
  if (-not $started) { $started = Try-StartListener $candidate }
}
if (-not $started) { throw 'No free port found between 9137 and 9160.' }

$listener = $started.Listener
$url = $started.Url

if (-not (Focus-LauncherPage)) { Open-LauncherPage $url }
Write-Host "PolyStrike launcher running at $url"
Write-Host 'Keep this window open while using the launcher. Press Ctrl+C to stop.'

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
    try {
      Handle-Request $context
    } catch {
      Write-Host "Request error: $($_.Exception.Message)"
      try { $context.Response.StatusCode = 500; $context.Response.Close() } catch { }
    }
  }
} finally {
  $listener.Stop()
  $listener.Close()
}