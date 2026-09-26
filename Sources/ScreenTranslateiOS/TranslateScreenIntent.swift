import AppIntents
import UIKit

struct TranslateScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Translate My Screen"
    static let description = IntentDescription("Reads a screenshot from the clipboard, OCRs it, and shows a translation. Chain it after Shortcuts' \"Take Screenshot\" + \"Copy to Clipboard\" actions.")

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        Log.intent.debug("iOS pipeline started")

        guard let uiImage = UIPasteboard.general.image, let cgImage = uiImage.cgImage else {
            Log.intent.error("no image found on clipboard")
            return .result(view: TranslationSnippetView(sourceText: "No image found on the clipboard. Make sure \"Take Screenshot\" then \"Copy to Clipboard\" run right before this."))
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
