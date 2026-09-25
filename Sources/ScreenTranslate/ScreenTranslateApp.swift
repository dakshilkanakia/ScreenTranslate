import SwiftUI

@main
struct ScreenTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Screen Translate", systemImage: "text.bubble") {
            Button("Translate Screen Now") {
                Task { await TranslateScreenIntent.runPipeline() }
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
