# ScreenTranslate

Say "Hey Siri, translate my screen" — it screenshots the display, OCRs the text, translates it, and shows the result in a small translucent overlay panel. No app switching.

## How it works

1. `TranslateScreenIntent` (App Intents) is the Siri entry point, registered via `ScreenTranslateShortcuts`.
2. `ScreenCapture.swift` grabs the frontmost display via ScreenCaptureKit.
3. `OCRService.swift` runs Vision text recognition on the captured image.
4. `OverlayPanel.swift` shows a floating `NSPanel` with the extracted text, translated on-device via the `Translation` framework.
5. Menu bar icon (`ScreenTranslateApp.swift`) also lets you trigger it manually (⌘⇧T) without Siri.

## Setup

1. Open `Package.swift` in Xcode (Xcode 16+, macOS 15 Sequoia+ required for the `Translation` framework).
2. First run: macOS will prompt for **Screen Recording** permission — grant it in System Settings → Privacy & Security, then relaunch.
3. Build & run once so the app registers itself and its Siri phrases with the system (App Shortcuts get indexed on first launch).
4. Say "Hey Siri, translate my screen with Screen Translate" (Siri needs the app name the first few times until it learns the shorter phrase).

### If Siri doesn't pick up the phrase

SPM executables sometimes don't get indexed as cleanly as a proper Xcode App target. If phrases aren't registering:
- In Xcode: File → New → Target → App, drag the `Sources/ScreenTranslate` files into it, set `Info.plist` and `ScreenTranslate.entitlements` as the target's files, and run from there instead.
- Make sure the app has actually launched at least once (Siri indexes App Shortcuts on launch, not on build).

### Apple Developer account

Running locally on your own Mac works with a free account (7-day resign limit unless you have a paid $99/yr account). Siri/App Intents work fine under the free tier for local testing.

## Status

- [x] Screen capture (ScreenCaptureKit)
- [x] OCR (Vision)
- [x] On-device translation (Translation framework)
- [x] Floating overlay panel
- [x] Siri phrase trigger
- [ ] Language picker (currently auto-detects source, translates to system language)
- [ ] iOS target (Snippet View version)
