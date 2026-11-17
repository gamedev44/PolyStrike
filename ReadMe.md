# Beyond Protocol: Native Edition — README

Welcome to **Beyond Protocol: Native Edition** (formerly PolyStrike). This repository contains the project configuration, source assets, and bootstrap tools for local development, testing, and execution under Unreal Engine 5.8.

## 📂 Project Overview & Build State Notice

* **Engine Version:** Unreal Engine 5.8

* **Execution Model:** Editor-backed standalone preview (`-game` flag via Unreal Editor binary).

* **Current Distribution State:** Semi-standalone project distribution.

* **Known Build State:** Due to the complex architectural framework migration from Unreal Engine 5.3 to 5.8, direct building from source can encounter local compilation hurdles. Rather than a standalone packaged executable, this project relies on launching through the Unreal Editor binaries via script-based environment bootstrapping.

## ⚙️ Environment Configuration & Path Adjustments

By default, the helper batch scripts assume standard installation paths on drive **C:**. **Path adjustments are only required if your project files and editor are not located on your C: drive.**

If your editor and project reside elsewhere, you will need to modify the paths inside the following helper batch files to match your local file structure:

1. `PolyStrike/PlayStandalone.bat`

2. `PolyStrike/StartEditor.bat`

*Verification:* Open each `.bat` file in a text editor (such as Notepad or Cursor), locate the directory path variables, and verify they point precisely to where Unreal Engine 5.8 and your workspace reside on your machine.

---

## 🛠️ Prerequisites

To Play ,Run and or Edit/Mod this project, you will need the Unreal Engine 5.8 editor installed on your system. 
* If you don't already have the Epic Games Launcher installed, you can download it here: [Epic Games Launcher Installer](https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherSetup-x86_64.exe)

---

## 🚀 Launch Instructions

Once your paths are configured (or if you are using the default C: drive setup):

* **To run the editor in standalone game preview mode:** Execute `PolyStrike/PlayStandalone.bat` to spin up the Unreal Editor directly with the `-game` standalone execution flag.

* **To launch the full editor workspace:** Execute `PolyStrike/StartEditor.bat` to initialize the project container inside the standard Unreal Engine 5.8 editor UI.

*Verification:* After running either script, check your Windows Task Manager or system process list to confirm that `UnrealEditor.exe` has launched successfully with the correct project arguments.