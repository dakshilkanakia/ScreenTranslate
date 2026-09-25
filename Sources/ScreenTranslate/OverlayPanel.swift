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
    @State private var alreadyTargetLanguage = false

    private var targetLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
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

            ScrollView {
                if isLoading {
                    ProgressView("Translating…")
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else if alreadyTargetLanguage {
                    Text(sourceText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
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
            let detected = Self.dominantLanguage(in: sourceText)

            if let detected, detected == targetLanguageCode {
                alreadyTargetLanguage = true
                isLoading = false
                return
            }

            configuration = TranslationSession.Configuration(
                source: detected.map { Locale.Language(identifier: $0) },
                target: Locale.Language(identifier: targetLanguageCode)
            )
        }
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(sourceText)
                translatedText = response.targetText
            } catch {
                // Framework refused a same-language pair despite our pre-check;
                // just show the original text instead of an error.
                alreadyTargetLanguage = true
            }
            isLoading = false
        }
    }

    /// Detects dominant language weighted by character count per line, ignoring
    /// short lines (UI chrome like "PDF", "New Chrome available") that would
    /// otherwise skew whole-blob detection on mixed-language screenshots.
    private static func dominantLanguage(in text: String) -> String? {
        var weights: [String: Int] = [:]

        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count >= 12 else { continue }
            guard let lang = NLLanguageRecognizer.dominantLanguage(for: trimmed)?.rawValue else { continue }
            weights[lang, default: 0] += trimmed.count
        }

        if let winner = weights.max(by: { $0.value < $1.value })?.key {
            return winner
        }

        // Fall back to whole-blob detection if every line was too short.
        return NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue
    }
}
