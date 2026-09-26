import SwiftUI
import Translation
import UIKit

/// Siri finalizes/tears down the remote Snippet View as soon as
/// TranslateScreenIntent.perform() returns, regardless of whether the
/// returned view's own async work (its .translationTask) has finished —
/// confirmed via logs: translation succeeded, but only after the visible
/// snippet had already vanished. So translation has to complete BEFORE
/// perform() returns a view, not inside the view it returns.
///
/// The same .translationTask mechanism does work in this execution context
/// (that's how it eventually succeeded), so this drives that identical
/// mechanism to completion headlessly via a throwaway UIHostingController,
/// then hands back a plain finished string.
@MainActor
enum HeadlessTranslator {
    static func translate(_ text: String, targetLanguageCode: String) async -> String {
        await withCheckedContinuation { continuation in
            var controller: UIHostingController<HeadlessTranslateView>?
            let view = HeadlessTranslateView(sourceText: text, targetLanguageCode: targetLanguageCode) { result in
                continuation.resume(returning: result)
                controller = nil
            }
            let hosting = UIHostingController(rootView: view)
            controller = hosting
            _ = hosting.view // force SwiftUI to load/appear the view, triggering onAppear/translationTask
        }
    }
}

struct HeadlessTranslateView: View {
    let sourceText: String
    let targetLanguageCode: String
    let completion: (String) -> Void

    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .onAppear {
                Log.translate.debug("headless translate: starting, source length=\(sourceText.count, privacy: .public)")
                configuration = TranslationSession.Configuration(
                    source: nil,
                    target: Locale.Language(identifier: targetLanguageCode)
                )
            }
            .translationTask(configuration) { session in
                do {
                    let response = try await session.translate(sourceText)
                    Log.translate.debug("headless translate: succeeded")
                    completion(response.targetText)
                } catch {
                    let nsError = error as NSError
                    Log.translate.error("headless translate failed: domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public) desc=\(nsError.localizedDescription, privacy: .public)")

                    let description = "\(nsError.localizedDescription) \(nsError.userInfo)"
                    if description.localizedCaseInsensitiveContains("match supported locale pair") {
                        completion(sourceText)
                    } else {
                        completion("Translation failed (\(nsError.domain) code \(nsError.code)): \(nsError.localizedDescription)")
                    }
                }
            }
    }
}
