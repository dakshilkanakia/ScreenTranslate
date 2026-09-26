# ScreenTranslate

Say "Hey Siri, translate my screen" — it screenshots the display, OCRs the text, translates it, and shows the result in a small translucent overlay panel. No app switching.

## How it works

1. `TranslateScreenIntent` (App Intents) is the Siri entry point, registered via `ScreenTranslateShortcuts`.
2. `ScreenCapture.swift` grabs the frontmost display via ScreenCaptureKit.
3. `OCRService.swift` runs Vision text recognition on the captured image.
4. `OverlayPanel.swift` shows a floating `NSPanel` with the extracted text, translated on-device via the `Translation` framework.
5. Menu bar icon (`ScreenTranslateApp.swift`) also lets you trigger it manually (⌘⇧T) without Siri.

## Setup

**Open `ScreenTranslate.xcodeproj`, not `Package.swift`.** The project is a real signed macOS App target (generated via [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`) — a loose SwiftPM executable can't register with Siri/Shortcuts or reliably use the Translation framework's download flow, since neither has a trusted bundle identity to hand the system.

1. Open `ScreenTranslate.xcodeproj` in Xcode (Xcode 16+, macOS 15 Sequoia+ required for the `Translation` framework).
2. Select the `ScreenTranslate` target → **Signing & Capabilities** → set **Team** to your Apple ID (a free "Personal Team" is enough for local device testing, no paid enrollment needed).
3. Build & run (⌘R). First run: macOS prompts for **Screen Recording** permission — grant it in System Settings → Privacy & Security, then relaunch.
4. Launch it at least once so Siri/Shortcuts indexes the App Shortcuts (happens on launch, not on build).
5. In the **Shortcuts** app, search actions for "Screen Translate" — it should now appear. Build a Shortcut around it and use "Add to Siri" to record any custom phrase you want (e.g. bare "Translate my screen"), bypassing the `\(.applicationName)`-in-phrase requirement that direct App Shortcut phrases have.

### Regenerating the Xcode project

If you edit `project.yml` (e.g. change bundle ID, add capabilities), regenerate with:
```
brew install xcodegen  # one-time
xcodegen generate
```

### Package.swift

Still present for quick `swift build` sanity checks from the command line — but it's not what you should open in Xcode for real testing, since it can't do Siri/Shortcuts registration or the Translation framework's trusted download flow.

## Status

- [x] Screen capture (ScreenCaptureKit)
- [x] OCR (Vision)
- [x] On-device translation (Translation framework)
- [x] Floating overlay panel
- [x] Siri phrase trigger
- [ ] Language picker (currently auto-detects source, translates to system language)
- [ ] iOS target (Snippet View version)
