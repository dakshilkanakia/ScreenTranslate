import AppIntents
import UIKit

struct TranslateScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Translate My Screen"
    static let description = IntentDescription("OCRs a screenshot you provide and shows a translation.")

    @Parameter(title: "Screenshot")
    var screenshot: IntentFile

    static var parameterSummary: some ParameterSummary {
        Summary("Translate \(\.$screenshot)")
    }

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        Log.intent.debug("iOS pipeline started")

        guard let uiImage = UIImage(data: screenshot.data), let cgImage = uiImage.cgImage else {
            Log.intent.error("failed to decode screenshot data")
            return .result(view: TranslationSnippetView(sourceText: "Couldn't read the screenshot."))
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
