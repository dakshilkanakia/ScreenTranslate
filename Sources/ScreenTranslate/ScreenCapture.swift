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

        let image = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )

        return cropTopChrome(of: image)
    }

    /// Browser windows (and many toolbar-heavy apps) put their own chrome —
    /// tab strip, address bar, "update available" banners — in a fixed-height
    /// band at the top of the window. That chrome is pure English UI text
    /// that was skewing language detection on foreign-language pages, so it's
    /// cropped out before OCR ever sees it. ~92pt covers a typical Chrome tab
    /// strip + toolbar; doubled to match the 2x capture scale above.
    private static func cropTopChrome(of image: CGImage) -> CGImage {
        let cropPoints: CGFloat = 92
        let captureScale: CGFloat = 2.0 // matches config.width/height * 2 above
        let cropPixels = Int(cropPoints * captureScale)

        guard cropPixels > 0, cropPixels < image.height else { return image }

        let rect = CGRect(x: 0, y: cropPixels, width: image.width, height: image.height - cropPixels)
        guard let cropped = image.cropping(to: rect) else {
            Log.capture.error("failed to crop top chrome, using full image")
            return image
        }

        Log.capture.debug("cropped top \(cropPixels, privacy: .public)px chrome, new size=\(cropped.width, privacy: .public)x\(cropped.height, privacy: .public)")
        return cropped
    }

    enum CaptureError: Error {
        case noDisplay
        case noFrontmostApp
        case noWindow
    }
}
