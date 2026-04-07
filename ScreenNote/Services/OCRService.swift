import Foundation
import UIKit
import Vision

protocol OCRServiceProtocol {
    func recognizeText(from image: UIImage) async throws -> String
}

struct OCRService: OCRServiceProtocol {
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
            request.usesLanguageCorrection = true

            do {
                let handler = VNImageRequestHandler(cgImage: cgImage)
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
