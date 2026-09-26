import AppIntents
import UIKit

struct TranslateScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Translate My Screen"
    static let description = IntentDescription("Reads a screenshot from the clipboard, OCRs it, and shows a translation. Chain it after Shortcuts' \"Take Screenshot\" + \"Copy to Clipboard\" actions.")

    // Background/Siri-triggered execution can't show iOS's cross-app "Allow
    // Paste" consent popup, so UIPasteboard.general reads silently come back
    // empty in that context (confirmed via logging: numberOfItems=0 on every
    // retry). Forcing the app to actually open gives it real foreground
    // status, so the paste-permission prompt can appear and be approved.
    static let openAppWhenRun: Bool = true

    // Because openAppWhenRun is true, the app's own foreground UI takes over
    // right as this runs — a returned Snippet View gets torn down before its
    // async translation can finish (confirmed: OCR completed, text was ready,
    // but the snippet vanished with nothing shown). So instead of returning a
    // snippet, hand the extracted text to AppState and let the app's own
    // foreground view display and translate it — that view isn't ephemeral.
    func perform() async throws -> some IntentResult {
        Log.intent.debug("iOS pipeline started")

        await MainActor.run {
            // Starts the instant the app opens, so the Dynamic Island shows
            // "Translating..." right away instead of the user just seeing a
            // blank app flash open with no feedback.
            LiveActivityManager.start()
        }

        guard let uiImage = await Self.readClipboardImageWithRetries() else {
            Log.intent.error("no image found on clipboard after retries")
            let message = "No image found on the clipboard. Make sure \"Take Screenshot\" then \"Copy to Clipboard\" run right before this."
            await MainActor.run { AppState.shared.pendingSourceText = message }
            await LiveActivityManager.finish(status: .failed, text: message)
            return .result()
        }

        guard let cgImage = uiImage.cgImage else {
            Log.intent.error("clipboard image had no cgImage")
            let message = "Clipboard image couldn't be decoded."
            await MainActor.run { AppState.shared.pendingSourceText = message }
            await LiveActivityManager.finish(status: .failed, text: message)
            return .result()
        }

        let text: String
        do {
            text = try await OCRService.extractText(from: cgImage)
        } catch {
            Log.intent.error("OCR failed: \(error.localizedDescription, privacy: .public)")
            let message = "OCR failed: \(error.localizedDescription)"
            await MainActor.run { AppState.shared.pendingSourceText = message }
            await LiveActivityManager.finish(status: .failed, text: message)
            return .result()
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Log.intent.error("OCR returned empty text")
            let message = "No text found in that screenshot."
            await MainActor.run { AppState.shared.pendingSourceText = message }
            await LiveActivityManager.finish(status: .failed, text: message)
            return .result()
        }

        // Actual on-device translation runs in ContentView (needs a live
        // SwiftUI view — see TranslationSnippetView), which reports back via
        // AppState.onTranslationComplete once it finishes, updating the Live
        // Activity from there.
        await MainActor.run {
            AppState.shared.pendingSourceText = text
        }
        return .result()
    }

    /// UIPasteboard.general reads have been unreliable right after Shortcuts'
    /// "Copy to Clipboard" step when this intent runs via Siri/Shortcuts
    /// (possibly a permission-prompt or timing race in that execution
    /// context, vs. a normal foregrounded app). Retries with backoff and logs
    /// pasteboard state at each attempt to pin down what's actually happening.
    private static func readClipboardImageWithRetries() async -> UIImage? {
        for attempt in 1...6 {
            let pasteboard = UIPasteboard.general
            Log.intent.debug("clipboard attempt \(attempt, privacy: .public): hasImages=\(pasteboard.hasImages, privacy: .public) numberOfItems=\(pasteboard.numberOfItems, privacy: .public) changeCount=\(pasteboard.changeCount, privacy: .public)")

            if let image = pasteboard.image {
                Log.intent.debug("clipboard attempt \(attempt, privacy: .public): got image \(image.size.width, privacy: .public)x\(image.size.height, privacy: .public)")
                return image
            }

            if attempt < 6 {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
        return nil
    }
}

struct ScreenTranslateiOSShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TranslateScreenIntent(),
            phrases: [
                "Translate my screen with \(.applicationName)",
                "\(.applicationName) translate my screen"
            ],
            shortTitle: "Translate Screen",
            systemImageName: "text.bubble"
        )
    }
}
