import SwiftUI
import Translation
import AppKit
import NaturalLanguage

final class OverlayPanel: NSPanel {
    init(sourceText: String) {
        let rect = NSRect(x: 0, y: 0, width: 480, height: 420)
        super.init(
            contentRect: rect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .utilityWindow, .hudWindow, .resizable],
            backing: .buffered,
            defer: false
        )
        minSize = NSSize(width: 320, height: 220)

        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = .clear
        hasShadow = true

        let hosting = NSHostingView(rootView: OverlayView(sourceText: sourceText) { [weak self] in
            self?.close()
        })
        contentView = hosting

        center()
    }

    override var canBecomeKey: Bool { true }
}

struct OverlayView: View {
    let sourceText: String
    let onDismiss: () -> Void

    @State private var configuration: TranslationSession.Configuration?
    @State private var translatedText: String = ""
    @State private var isLoading = true
    @State private var status: Status = .loading

    private enum Status {
        case loading
        case translated
        case alreadyTargetLanguage
        case error(String)
    }

    private var targetLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Only substantial lines carry real content — short OCR fragments (icon
    /// labels, stray glyphs like "QD", "٦٢") are noise that skews detection
    /// and pollutes translation output, so they're dropped before either step.
    private var cleanedText: String {
        sourceText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 20 }
            .joined(separator: "\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Translation")
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
            }

            switch status {
            case .alreadyTargetLanguage:
                Label("Already in your language — nothing to translate", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .error(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            default:
                EmptyView()
            }

            ScrollView {
                switch status {
                case .loading:
                    ProgressView("Translating…")
                        .frame(maxWidth: .infinity, minHeight: 100)
                case .alreadyTargetLanguage, .error:
                    Text(cleanedText.isEmpty ? sourceText : cleanedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .translated:
                    Text(translatedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 320, minHeight: 220)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
        .onAppear {
            let textToTranslate = cleanedText.isEmpty ? sourceText : cleanedText
            let detected = Self.dominantLanguage(in: textToTranslate)

            if let detected, detected == targetLanguageCode {
                status = .alreadyTargetLanguage
                return
            }

            configuration = TranslationSession.Configuration(
                source: detected.map { Locale.Language(identifier: $0) },
                target: Locale.Language(identifier: targetLanguageCode)
            )
        }
        .translationTask(configuration) { session in
            let textToTranslate = cleanedText.isEmpty ? sourceText : cleanedText
            do {
                let response = try await session.translate(textToTranslate)
                translatedText = response.targetText
                status = .translated
            } catch {
                // Framework refused the language pairing (same language, or an
                // unsupported/misdetected one) — fall back to original text
                // rather than showing a raw error.
                status = .alreadyTargetLanguage
            }
        }
    }

    /// Detects dominant language on the full cleaned text (not per-line) so
    /// there's enough context for a confident result, and requires a
    /// reasonable confidence threshold before trusting it — otherwise a
    /// misdetected language (e.g. "pl" from a few odd characters) leads to an
    /// unsupported translation pairing.
    private static func dominantLanguage(in text: String) -> String? {
        guard !text.isEmpty else { return nil }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        guard let top = recognizer.languageHypotheses(withMaximum: 1).max(by: { $0.value < $1.value }),
              top.value > 0.5 else {
            return nil
        }

        return top.key.rawValue
    }
}
