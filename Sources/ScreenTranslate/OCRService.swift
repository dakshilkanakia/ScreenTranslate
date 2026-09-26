import Vision
import CoreGraphics

enum OCRService {
    static func extractText(from image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []

                // Vision's array order isn't guaranteed to be reading order.
                // boundingBox origin is bottom-left, normalized 0...1, so sort
                // top-to-bottom (descending y), then left-to-right (ascending x).
                let sorted = observations.sorted { a, b in
                    let ay = a.boundingBox.midY
                    let by = b.boundingBox.midY
                    if abs(ay - by) > 0.01 {
                        return ay > by
                    }
                    return a.boundingBox.minX < b.boundingBox.minX
                }

                let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
                let text = lines.joined(separator: "\n")
                Log.ocr.debug("extracted \(lines.count, privacy: .public) lines, \(text.count, privacy: .public) chars")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.automaticallyDetectsLanguage = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
