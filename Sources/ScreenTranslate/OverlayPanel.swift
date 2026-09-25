import SwiftUI
import Translation
import AppKit

final class OverlayPanel: NSPanel {
    init(sourceText: String) {
        let rect = NSRect(x: 0, y: 0, width: 420, height: 260)
        super.init(
            contentRect: rect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .hudWindow],
            backing: .buffered,
            defer: false
        )

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
                } else {
                    Text(translatedText)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(16)
        .frame(width: 420, height: 260)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.2), lineWidth: 1))
        .onAppear {
            configuration = TranslationSession.Configuration(
                source: nil,
                target: Locale.Language(identifier: Locale.current.language.languageCode?.identifier ?? "en")
            )
        }
        .translationTask(configuration) { session in
            do {
                let response = try await session.translate(sourceText)
                translatedText = response.targetText
            } catch {
                translatedText = "Translation failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
