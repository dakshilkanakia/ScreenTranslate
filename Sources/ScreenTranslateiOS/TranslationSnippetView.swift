import SwiftUI
import Translation

struct TranslationSnippetView: View {
    let sourceText: String
    var onComplete: ((ScreenTranslateAttributes.ContentState.Status, String) -> Void)? = nil

    @State private var configuration: TranslationSession.Configuration?
    @State private var translatedText: String = ""
    @State private var status: Status = .loading

    private enum Status {
        case loading
        case translated
        case error(String)
    }

    private var targetLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch status {
            case .loading:
                ProgressView("Translating…")
                    .frame(maxWidth: .infinity, minHeight: 80)
            case .translated:
                Text(translatedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .error(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .onAppear {
            Log.translate.debug("iOS snippet: source length=\(sourceText.count, privacy: .public)")
            configuration = TranslationSession.Configuration(
                source: nil,
                target: Locale.Language(identifier: targetLanguageCode)
            )
        }
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(sourceText)
                translatedText = response.targetText
                status = .translated
                Log.translate.debug("iOS snippet: translation succeeded")
                onComplete?(.done, response.targetText)
            } catch {
                let nsError = error as NSError
                Log.translate.error("iOS snippet translation failed: domain=\(nsError.domain, privacy: .public) code=\(nsError.code, privacy: .public) desc=\(nsError.localizedDescription, privacy: .public)")

                let description = "\(nsError.localizedDescription) \(nsError.userInfo)"
                if description.localizedCaseInsensitiveContains("match supported locale pair") {
                    status = .translated
                    translatedText = sourceText
                    onComplete?(.done, sourceText)
                } else {
                    let message = "Translation failed (\(nsError.domain) code \(nsError.code)): \(nsError.localizedDescription)"
                    status = .error(message)
                    onComplete?(.failed, message)
                }
            }
        }
    }
}
