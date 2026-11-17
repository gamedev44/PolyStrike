@echo off
setlocal enabledelayedexpansion

:: 1. Auto-detect the .uproject file in the same folder as this .bat
set "UPROJECT="
for %%F in ("%~dp0*.uproject") do (
    set "UPROJECT=%%~fF"
)

if "%UPROJECT%"=="" (
    echo [ERROR] No .uproject file found in %~dp0
    pause
    exit /b 1
)

:: 2. Exact working map path
set "MAP_PATH=/Game/InfimaGames/LowPolyShooterPack/Maps/L_LPSP_Menu_Main"

:: 3. Check default UE_5.8 path, or check other drives/folders, or ask user
set "EDITOR_EXE=C:\Program Files\Epic Games\UE_5.8\Engine\Binaries\Win64\UnrealEditor.exe"

if not exist "%EDITOR_EXE%" (
    echo Default UE 5.8 path not found. Searching common drives...
    for %%D in (C D E F G) do (
        if exist "%%D:\Program Files\Epic Games\UE_5.8\Engine\Binaries\Win64\UnrealEditor.exe" (
            set "EDITOR_EXE=%%D:\Program Files\Epic Games\UE_5.8\Engine\Binaries\Win64\UnrealEditor.exe"
        )
        if exist "%%D:\Epic Games\UE_5.8\Engine\Binaries\Win64\UnrealEditor.exe" (
            set "EDITOR_EXE=%%D:\Epic Games\UE_5.8\Engine\Binaries\Win64\UnrealEditor.exe"
        )
    )
)

:: 4. If still not found, open a native Windows File Picker dialog
if not exist "%EDITOR_EXE%" (
    echo Could not find UnrealEditor.exe automatically. Please select it...
    for /f "delims=" %%I in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'UnrealEditor.exe|UnrealEditor.exe'; $f.Title = 'Select UnrealEditor.exe (UE 5.8)'; if ($f.ShowDialog() -eq 'OK') { $f.FileName }"') do (
        set "EDITOR_EXE=%%I"
    )
)

if not exist "%EDITOR_EXE%" (
    echo [ERROR] UnrealEditor.exe was not selected. Exiting.
    pause
    exit /b 1
)

:: 5. Launch Standalone Game
echo Launching: "%UPROJECT%"
echo Map: %MAP_PATH%
start "" "%EDITOR_EXE%" "%UPROJECT%" %MAP_PATH% -game
