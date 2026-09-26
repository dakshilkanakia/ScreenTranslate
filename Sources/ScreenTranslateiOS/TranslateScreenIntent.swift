import AppIntents
import UIKit

struct TranslateScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Translate My Screen"
    static let description = IntentDescription("Reads a screenshot from the clipboard, OCRs it, and shows a translation. Chain it after Shortcuts' \"Take Screenshot\" + \"Copy to Clipboard\" actions.")

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        Log.intent.debug("iOS pipeline started")

        guard let uiImage = await Self.readClipboardImageWithRetries() else {
            Log.intent.error("no image found on clipboard after retries")
            return .result(view: TranslationSnippetView(sourceText: "No image found on the clipboard. Make sure \"Take Screenshot\" then \"Copy to Clipboard\" run right before this."))
        }

        guard let cgImage = uiImage.cgImage else {
            Log.intent.error("clipboard image had no cgImage")
            return .result(view: TranslationSnippetView(sourceText: "Clipboard image couldn't be decoded."))
        }

        let text: String
        do {
            text = try await OCRService.extractText(from: cgImage)
        } catch {
            Log.intent.error("OCR failed: \(error.localizedDescription, privacy: .public)")
            return .result(view: TranslationSnippetView(sourceText: "OCR failed: \(error.localizedDescription)"))
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Log.intent.error("OCR returned empty text")
            return .result(view: TranslationSnippetView(sourceText: "No text found in that screenshot."))
        }

        return .result(view: TranslationSnippetView(sourceText: text))
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
