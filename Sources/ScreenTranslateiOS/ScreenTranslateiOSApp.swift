import SwiftUI

@main
struct ScreenTranslateiOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var showTestTranslate = false
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Screen Translate")
                .font(.title2.bold())

            Text("This app works through Shortcuts, not by opening it directly.\n\nIn the Shortcuts app, build a shortcut with:\n1. \"Take Screenshot\"\n2. \"Copy to Clipboard\"\n3. \"Translate My Screen\" (this app's action)\n\nName the shortcut what you want to say, then trigger it with \"Hey Siri, <name>\".")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Test Translation & Download Language") {
                showTestTranslate = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Text("Run this once from inside the app — it can show the system's language-download prompt reliably here, which may not work when triggered from Shortcuts/Siri in the background.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
        .sheet(isPresented: $showTestTranslate) {
            TestTranslateView()
        }
        .fullScreenCover(isPresented: Binding(
            get: { appState.pendingSourceText != nil },
            set: { if !$0 { appState.pendingSourceText = nil } }
        )) {
            if let text = appState.pendingSourceText {
                NavigationStack {
                    ScrollView {
                        TranslationSnippetView(sourceText: text)
                    }
                    .navigationTitle("Translation")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                appState.pendingSourceText = nil
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TestTranslateView: View {
    @State private var sampleText = "Hallo, wie geht es dir? Das ist ein Test."

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Sample text (edit to test a different language):")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $sampleText)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.3)))

                TranslationSnippetView(sourceText: sampleText)
                    .id(sampleText)
            }
            .padding()
            .navigationTitle("Test Translate")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
