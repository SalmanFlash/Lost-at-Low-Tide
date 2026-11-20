# Lost at Low Tide Android build

## Windows lab PC

1. Godot **4.5.1 Standard** ka Windows build unzip karein. Godot mein **Editor → Manage Export Templates** se isi version ke templates install karein. [Godot 4.5.1](https://godotengine.org/download/archive/4.5.1-stable/)
2. OpenJDK **17** aur Android Studio install karein. Android Studio ke **SDK Manager** mein Android **15 / API 35** select karein. **SDK Tools → Show Package Details** mein Platform-Tools, latest Command-line Tools, Build-Tools **35.0.0**, NDK **28.1.13356709** aur CMake **3.10.2.4988404** select karein. [Godot Android setup](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_android.html)
3. Godot mein `game-off-2025-waves/project.godot` import karein. **Editor → Editor Settings → Export → Android** mein JDK folder **Java SDK Path** aur Android SDK folder **Android SDK Path** set karein. JDK folder ke andar `bin\java.exe` aur SDK folder ke andar `platform-tools\adb.exe` hona chahiye.
4. **Project → Export → Android → Export Project** kholein, **Export With Debug** select karein aur `Lost-at-Low-Tide.apk` save karein. Godot ka default debug keystore signing ke liye use hota hai. Preset mein ARM64 aur ARMv7 dono enabled hain.

Editor Settings set karne ke baad yahi build PowerShell se bhi bana sakte hain. Source ke top-level folder mein commands run karein aur Godot exe ka path apni installation ke mutabiq set karein.

```powershell
$GameGodot = 'C:\Tools\Godot\Godot_v4.5.1-stable_win64_console.exe'
& $GameGodot --headless --path "$PWD\game-off-2025-waves" --editor --import
& $GameGodot --headless --path "$PWD\game-off-2025-waves" --export-debug Android "$PWD\Lost-at-Low-Tide.apk"
```

## Android phone

APK phone mein copy karke install karein. USB debugging ke saath Platform-Tools se bhi install kar sakte hain.

```powershell
adb devices
adb install -r .\Lost-at-Low-Tide.apk
```

Landscape mein title aur menu kholein. Movement pakar kar doosri ungli se Tide +, Tide −, Use aur Drop test karein. Control se bahar ungli chhor kar release check karein. Teen fragments aur final exit tak khelein. Restart, Play again, app background aur resume, screen scaling aur airplane mode mein cold launch check karein.

## Cloud mein verify kiya gaya

- Godot 4.5.1 se Android APK export aur sign hua. Package `com.lostatlowtide.game`, minimum API 24 aur target API 35 hai. Signature, 16 KB alignment, landscape manifest aur packed assets verify kiye.
- Godot Cloud tests mein sab puzzle scenes load hue. Touch movement, tide, release aur cancel, simulated pause aur resume, rock pickup aur drop, fragment triggers, completion screen aur replay verify hue. Baad ke puzzles ke liye test script ne seedha relevant game state set ki.
- Headless Godot band hote waqt editor aur audio cleanup messages aaye. Phone par installation, touch behavior, scaling aur offline relaunch ki testing baqi hai.
