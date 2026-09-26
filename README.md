# ScreenTranslate

Say "Hey Siri, translate my screen" — it captures the frontmost window, OCRs the text, translates it, and shows the result in a small floating overlay panel. No app switching, no copy-paste.

## How it works

1. `ScreenCapture.swift` grabs the frontmost app's main window via ScreenCaptureKit (not the whole display — avoids sweeping up other windows), then crops off the top ~92pt to strip out browser chrome (tab strip, address bar, update banners), which otherwise pollutes both OCR and language detection.
2. `OCRService.swift` runs Vision text recognition on the captured image, sorting results into proper top-to-bottom reading order (Vision's raw array order isn't guaranteed to match it).
3. `OverlayPanel.swift` shows a floating `NSPanel` with the extracted text, translated on-device via the `Translation` framework. Source language is auto-detected by the framework itself (`source: nil`) — an earlier attempt to pre-detect it locally proved unreliable on mixed-language/technical text.
4. `TranslateScreenIntent` (App Intents) is the Siri/Shortcuts entry point, registered via `ScreenTranslateShortcuts`.
5. Menu bar icon (`ScreenTranslateApp.swift`) also triggers it manually (⌘⇧T), no Siri needed.

## Setup

1. **Generate the Xcode project** (not tracked in git — regenerable from `project.yml`, and this avoids baking your personal Apple Developer Team ID into a committed file):
   ```
   brew install xcodegen   # one-time
   xcodegen generate
   ```
2. Open `ScreenTranslate.xcodeproj` in Xcode (Xcode 16+, macOS 15 Sequoia+ required for the `Translation` framework).
3. Select the `ScreenTranslate` target → **Signing & Capabilities** → set **Team** to your Apple ID, signing certificate **"Development"** (not "Sign to Run Locally" — that's ad-hoc and won't register with Siri/Shortcuts or Translation's trusted download flow). A free "Personal Team" is enough, no paid enrollment needed.
4. Build & run (⌘R). First run: macOS prompts for **Screen Recording** permission — grant it in System Settings → Privacy & Security, then relaunch.
5. Launch it at least once so Siri/Shortcuts indexes the app's App Shortcuts (happens on launch, not on build).

## Wiring up the Siri phrase

App Shortcut phrases registered directly in code must include the app name (an Apple platform requirement), so to get a bare custom phrase like "translate my screen":

1. Open the **Shortcuts** app → new shortcut → search actions for "Screen Translate" → add its action.
2. Name the shortcut exactly what you want to say, e.g. **"Translate my screen"**. On current macOS, a saved shortcut's name is automatically usable as a Siri trigger phrase — no separate "Add to Siri" step needed.
3. Say "Hey Siri, translate my screen" on any foreign-language window.

If the app doesn't show up as an action in Shortcuts at all: make sure you're running the signed `.xcodeproj` build (step 3 above) — a loose `swift build` binary has no trusted bundle identity and won't register.

## Known limitations

- First use of a new source language triggers a system dialog to download that on-device language model (one-time per language).
- The top-chrome crop (92pt) is tuned for Chrome's tab strip + toolbar; other apps or a hidden Chrome tab bar may need a different value.
- macOS only. No draw-over-other-apps overlay exists on iOS, so a phone version would need a different UI approach (App Intent Snippet View) — not built here.

## Status

- [x] Frontmost-window capture (ScreenCaptureKit), cropped to skip browser chrome
- [x] OCR with reading-order sorting (Vision)
- [x] On-device translation, framework auto-detects source language (Translation framework)
- [x] Floating overlay panel
- [x] Siri/Shortcuts trigger via a real signed app target
- [ ] Language picker (currently always translates to system language)
- [ ] iOS target
