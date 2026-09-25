import AppIntents
import AppKit

struct TranslateScreenIntent: AppIntent {
    static let title: LocalizedStringResource = "Translate My Screen"
    static let description = IntentDescription("Captures the screen, extracts text, and shows a translated overlay.")
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        await Self.runPipeline()
        return .result()
    }

    @MainActor
    static func runPipeline() async {
        do {
            let image = try await ScreenCapture.captureFrontmostDisplay()
            let text = try await OCRService.extractText(from: image)

            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                presentError("No text found on screen.")
                return
            }

            let panel = OverlayPanel(sourceText: text)
            panel.makeKeyAndOrderFront(nil)
        } catch {
            presentError("Couldn't translate screen: \(error.localizedDescription)")
        }
    }

    @MainActor
    private static func presentError(_ message: String) {
        let panel = OverlayPanel(sourceText: message)
        panel.makeKeyAndOrderFront(nil)
    }
}

struct ScreenTranslateShortcuts: AppShortcutsProvider {
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
