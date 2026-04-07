import CryptoKit
import Foundation
import UIKit

struct ProcessedImageData: Equatable {
    let imageData: Data
    let thumbnailData: Data?
    let hash: String
}

protocol ImageProcessorProtocol {
    func prepareImageData(_ data: Data) throws -> ProcessedImageData
    func decodeImage(data: Data) throws -> UIImage
}

struct ImageProcessor: ImageProcessorProtocol {
    func prepareImageData(_ data: Data) throws -> ProcessedImageData {
        let image = try decodeImage(data: data)
        guard let compressed = image.jpegData(compressionQuality: 0.8) else {
            throw ImageProcessingError.compressionFailed
        }
        let thumbnail = image.thumbnail(maxDimension: 300)?.jpegData(compressionQuality: 0.7)
        return ProcessedImageData(
            imageData: compressed,
            thumbnailData: thumbnail,
            hash: SHA256.hash(data: compressed).compactMap { String(format: "%02x", $0) }.joined()
        )
    }

    func decodeImage(data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw OCRError.invalidImage
        }
        return image
    }
}
