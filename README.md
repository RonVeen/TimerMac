# TimerMac

A macOS SwiftUI port of the Timer CLI application. Tracks activities/jobs using an SQLite backend and matches the original CLI features with a desktop UI.

## Building and Running

```bash
swift build
swift run TimerMac
```

## Creating a `.app` Bundle

1. Build a release binary:
   ```bash
   swift build --configuration release
   ```
2. Create bundle folders:
   ```bash
   APP=TimerMac.app
   mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
   ```
3. Write `Info.plist`:
   ```bash
   cat > "$APP/Contents/Info.plist" <<'PLIST'
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CFBundleIdentifier</key><string>org.veenix.timermac</string>
       <key>CFBundleName</key><string>TimerMac</string>
       <key>CFBundleExecutable</key><string>TimerMac</string>
       <key>CFBundlePackageType</key><string>APPL</string>
       <key>LSMinimumSystemVersion</key><string>13.0</string>
   </dict>
   </plist>
   PLIST
   ```
4. Copy the binary:
   ```bash
   cp .build/release/TimerMac "$APP/Contents/MacOS/TimerMac"
   chmod +x "$APP/Contents/MacOS/TimerMac"
   ```
5. (Optional) Add an icon (`TimerMac.icns`) to `Contents/Resources` and add `CFBundleIconFile` to `Info.plist`.

Double-click the resulting `TimerMac.app` to launch, or sign/notarize it using `codesign` as needed.
