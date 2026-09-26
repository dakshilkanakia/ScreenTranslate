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
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Screen Translate")
                .font(.title2.bold())

            Text("This app works through Shortcuts, not by opening it directly.\n\nIn the Shortcuts app, build a shortcut with:\n1. \"Take Screenshot\"\n2. \"Translate My Screen\" (this app's action)\n\nName the shortcut what you want to say, then trigger it with \"Hey Siri, <name>\".")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}
