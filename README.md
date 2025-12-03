# 📦 APK Extractor Tool (PowerShell)

A Windows PowerShell utility for extracting APK files from Android devices or emulators using ADB.
Supports single package, lists from a .txt file, auto-detect downloaded apps, multiple devices, and custom output directories.

---

## 🚀 Features

* Extract APKs from:
  
  * a single package
  * a list of packages (file input)
  * a command-line list (comma/space separated)
  * auto-detected installed apps
* Supports **multiple devices** (interactive selection or `-d`)
* Automatically cleans package names (removes `package:` prefixes)
* Filters system packages if needed
* Custom output directory support
* Safe folder naming (removes invalid characters)
* Works on:

  * Android phones
  * Android emulators (AVD / Genymotion)
  * Any ADB-compatible device

---

## 📝 Requirements

* Windows 10 / 11
* PowerShell 5 or later
* Android SDK Platform Tools installed (adb.exe)
* USB debugging enabled on device OR an emulator running

---

## 📥 Installation

Place the script (`apk_to_win.ps1` or your renamed version) inside your
**Android SDK platform-tools** folder or any folder containing:

```
adb.exe
```

Example location:

```
C:\Users\<you>\AppData\Local\Android\Sdk\platform-tools\
```

Run PowerShell there:

```ps
cd C:\Users\<you>\AppData\Local\Android\Sdk\platform-tools\
```

---

## ⚙️ Usage

### Show help

```ps
.\apk_to_win.ps1 -h
```

---

# 📌 Modes

## 1️⃣ Input Mode (`-i`)

Extract APKs from a file containing one package name per line.

**Example file (`packages.txt`):**

```
com.android.chrome
com.whatsapp
com.notion.id
```

**Run:**

```ps
.\apk_to_win.ps1 -i packages.txt
```

---

## 2️⃣ Command Line Mode (`-c`)

Provide one or more packages directly:

**Supports:**

* comma-separated
* space-separated
* mixed
* `package:` prefixes

**Examples:**

```ps
.\apk_to_win.ps1 -c com.whatsapp
.\apk_to_win.ps1 -c com.whatsapp,com.instagram.android
.\apk_to_win.ps1 -c "package:com.a, com.b  com.c"
```

All are accepted.

---

## 3️⃣ Auto Mode (`-a`)

### Exclude system apps

```ps
.\apk_to_win.ps1 -a auto
```

Equivalent forms:

```
-a default
-a auto
```

### Include ALL packages

```ps
.\apk_to_win.ps1 -a all
```

---

## 4️⃣ List Packages (`-l`)

### List only user-installed packages

```ps
.\apk_to_win.ps1 -l auto
```

### List all packages

```ps
.\apk_to_win.ps1 -l all
```

---

## 5️⃣ Device Selection (`-d`)

If multiple devices are detected, the script will prompt you to select one.

Force a device manually:

```ps
.\apk_to_win.ps1 -d emulator-5554 -a all
```

If you omit `-d`, the script:

* selects automatically if only 1 device is found
* prompts you if more than 1 is found

---

## 6️⃣ Output Directory (`-o`)

Default:

```
.\apks-<device_serial>\
```

Custom output:

```ps
.\apk_to_win.ps1 -c com.whatsapp -o C:\DumpedAPKs
```

---

# 📂 Output Structure

APK files are saved as:

```
<output folder>\
    com.package1\
        base.apk
        split_config.arm64.apk
        ...
    com.package2\
        ...
```

Each package gets its own folder.

---

## 🔧 Example Workflows

### Extract APKs from AVD:

```ps
.\apk_to_win.ps1 -a auto
```

### Extract only Chrome APK:

```ps
.\apk_to_win.ps1 -c com.android.chrome
```

### Extract everything (system + user apps):

```ps
.\apk_to_win.ps1 -a all
```

### Extract from specific device:

```ps
.\apk_to_win.ps1 -d R58N62MM123 -c com.whatsapp
```

---

# 🧹 Input Formats Accepted

`-c` and `-i` support the following formats:

```
com.app.one,com.app.two
com.app.one com.app.two
package:com.app.one package:com.app.two
com.a,   com.b    com.c
```

The script cleans all forms automatically.

---

# 🛑 Notes / Limitations

* Does not repackage split APKs into .apks or .apk-m bundles
* Does not extract OBB or data directories (APK only)
* Requires ADB authorization on the device

---
