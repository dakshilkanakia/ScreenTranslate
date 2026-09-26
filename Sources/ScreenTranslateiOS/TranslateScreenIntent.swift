import AppIntents
import UIKit

struct TranslateScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Translate My Screen"
    static let description = IntentDescription("OCRs a screenshot and shows a translation, without opening the app. In Shortcuts, connect \"Take Screenshot\"'s output to this action's Screenshot field by dragging the variable onto it (tapping it opens a manual file picker instead).")

    @Parameter(title: "Screenshot", supportedContentTypes: [.image])
    var screenshot: IntentFile

    static var parameterSummary: some ParameterSummary {
        Summary("Translate \(\.$screenshot)")
    }

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        Log.intent.debug("iOS pipeline started (IntentFile variant)")

        guard let uiImage = UIImage(data: screenshot.data), let cgImage = uiImage.cgImage else {
            Log.intent.error("failed to decode screenshot IntentFile data")
            return .result(view: StaticResultView(text: "Couldn't read the screenshot."))
        }

        let text: String
        do {
            text = try await OCRService.extractText(from: cgImage)
        } catch {
            Log.intent.error("OCR failed: \(error.localizedDescription, privacy: .public)")
            return .result(view: StaticResultView(text: "OCR failed: \(error.localizedDescription)"))
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Log.intent.error("OCR returned empty text")
            return .result(view: StaticResultView(text: "No text found in that screenshot."))
        }

        let targetLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        let translated = await HeadlessTranslator.translate(text, targetLanguageCode: targetLanguageCode)

        return .result(view: StaticResultView(text: translated))
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
