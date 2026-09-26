# ScreenTranslate

Say "Hey Siri, translate my screen" — it captures whatever's on screen, OCRs the text, and shows a translation. Two targets: a macOS app (floating overlay, stays on top of whatever you were doing) and an iOS app (app opens briefly to show the result — see [iOS](#ios) below for why).

## How it works (macOS)

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

## iOS

Also builds as an iOS app (`ScreenTranslateiOS` target, `Sources/ScreenTranslateiOS/`), with real trade-offs forced by the platform:

- **No self-capture.** iOS blocks an app from capturing another app's screen. The screenshot comes from Shortcuts' own **"Take Screenshot"** action, then **"Copy to Clipboard"**, then our **"Translate My Screen"** action reads it from `UIPasteboard.general`.
- **The app has to actually open** (`openAppWhenRun = true`). Tried hard to avoid this (see below) — it's required because a background/Siri-triggered execution can't show iOS's cross-app "Allow Paste" consent popup, so clipboard reads silently return empty without it.
- Translation result is shown in the app's own foreground view (`AppState.pendingSourceText` drives `ContentView`'s content directly — no `.sheet`/`.fullScreenCover`, since presenting one at cold-launch-from-intent time crashes: `-[_UISceneHostingController _setSheetConfiguration:]`).
- Build the Shortcut once: **Take Screenshot → Copy to Clipboard → Translate My Screen** (no fields to configure on the last step). Trigger by saying the shortcut's own name, same trick as macOS.
- Requires iOS 18+ (`TranslationSession` API) and a real device — the Simulator can't meaningfully test Siri or the screenshot flow.
- Free personal-team provisioning on a real iPhone expires after 7 days; rebuild/reinstall from Xcode to renew (or use a paid $99/yr account to avoid this).

**Abandoned approach** (tried, didn't work — kept on branch `ios-intentfile-snippet` for reference): passing the screenshot as a typed `IntentFile` parameter (drag-connected from Shortcuts' "Take Screenshot" output) instead of via the clipboard, paired with a Snippet View (`.result(view:)`) so the app never has to open, staying on top of whatever app you were using. The `IntentFile` + drag-connect part actually worked — no clipboard permission wall. But Siri tears down the remote Snippet View as soon as `perform()` returns, regardless of whether the returned view's own async work (on-device translation) has finished; confirmed on-device that translation succeeded every time, just after the visible UI had already vanished. A headless pre-translation attempt (running the same `.translationTask` via a throwaway `UIHostingController` before returning any view) also failed — a hosting controller never gets a real SwiftUI lifecycle without being attached to an actual window, and there's no window available in a no-app-open execution context. No supported way around this was found.

## Status

- [x] macOS: frontmost-window capture (ScreenCaptureKit), cropped to skip browser chrome
- [x] macOS: floating overlay panel
- [x] OCR with reading-order sorting (Vision, shared by both platforms)
- [x] On-device translation, framework auto-detects source language (Translation framework)
- [x] Siri/Shortcuts trigger via a real signed app target (both platforms)
- [x] iOS: screenshot via Shortcuts + clipboard, shown in the app's foreground view
- [ ] Language picker (currently always translates to system language)
- [ ] iOS without opening the app (blocked by the Snippet View teardown timing above)
