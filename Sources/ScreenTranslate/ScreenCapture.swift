import ScreenCaptureKit
import CoreGraphics
import AppKit

enum ScreenCapture {
    /// Captures only the frontmost app's main window, not the whole display —
    /// avoids sweeping up menu bar, other windows, and browser chrome from other tabs.
    static func captureFrontmostDisplay() async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(
            true,
            onScreenWindowsOnly: true
        )

        guard let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            throw CaptureError.noFrontmostApp
        }

        let candidateWindows = content.windows.filter {
            $0.owningApplication?.processID == frontPID &&
            $0.windowLayer == 0 &&
            $0.frame.width > 100 &&
            $0.frame.height > 100
        }

        guard let window = candidateWindows.max(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
            Log.capture.error("no candidate window found for frontmost pid=\(frontPID, privacy: .public)")
            throw CaptureError.noWindow
        }

        Log.capture.debug("capturing window title=\(window.title ?? "?", privacy: .public) frame=\(String(describing: window.frame), privacy: .public)")

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        config.width = Int(window.frame.width * 2)
        config.height = Int(window.frame.height * 2)
        config.showsCursor = false

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    enum CaptureError: Error {
        case noDisplay
        case noFrontmostApp
        case noWindow
    }
}
