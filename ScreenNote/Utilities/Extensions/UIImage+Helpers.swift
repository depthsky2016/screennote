import SwiftUI
import UIKit

extension UIImage {
    static var previewPlaceholder: UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        return renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 300, height: 300)))
            let text = "ScreenNote"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.white
            ]
            let size = text.size(withAttributes: attributes)
            let rect = CGRect(x: (300 - size.width) / 2, y: (300 - size.height) / 2, width: size.width, height: size.height)
            text.draw(in: rect, withAttributes: attributes)
        }
    }

    func thumbnail(maxDimension: CGFloat) -> UIImage? {
        let maxSide = max(size.width, size.height)
        guard maxSide > 0 else { return nil }
        let scale = maxDimension / maxSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

extension Note {
    var previewImage: UIImage? {
        if let thumbnailData, let image = UIImage(data: thumbnailData) {
            return image
        }
        return UIImage(data: imageData)
    }

    var shareText: String {
        [aiTitle, aiSummary, userNote]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n\n")
    }
}
