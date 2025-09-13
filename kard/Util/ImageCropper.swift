// ImageCropper.swift
// Stage 2: Center crop utility to enforce 1.59:1 aspect ratio
import UIKit

enum ImageCropper {
    // Target aspect ratio width:height
    private static let targetRatio: CGFloat = 1.59
    
    static func cropCenterToCardAspect(_ image: UIImage) -> UIImage {
        let fixed = image.normalizedOrientation()
        let size = fixed.size
        let currentRatio = size.width / size.height
        var cropRect: CGRect
        if abs(currentRatio - targetRatio) < 0.0001 {
            cropRect = CGRect(origin: .zero, size: size)
        } else if currentRatio > targetRatio { // too wide -> trim width
            let newWidth = size.height * targetRatio
            let x = (size.width - newWidth) / 2.0
            cropRect = CGRect(x: x, y: 0, width: newWidth, height: size.height)
        } else { // too tall -> trim height
            let newHeight = size.width / targetRatio
            let y = (size.height - newHeight) / 2.0
            cropRect = CGRect(x: 0, y: y, width: size.width, height: newHeight)
        }
        guard let cg = fixed.cgImage else { return fixed }
        let scale = fixed.scale
        let scaledRect = CGRect(x: cropRect.origin.x * scale,
                                y: cropRect.origin.y * scale,
                                width: cropRect.size.width * scale,
                                height: cropRect.size.height * scale)
        guard let croppedCG = cg.cropping(to: scaledRect) else { return fixed }
        return UIImage(cgImage: croppedCG, scale: fixed.scale, orientation: fixed.imageOrientation)
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
