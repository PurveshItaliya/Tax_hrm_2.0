import Foundation
import UIKit


public extension UIImage {
    
    func cropFace(faceBox: FaceBox) -> UIImage? {
        guard let cg = self.cgImage else { return nil }
        let imageWidth = CGFloat(cg.width)
        let imageHeight = CGFloat(cg.height)

        let centerX = CGFloat(faceBox.x1 + faceBox.x2) / 2.0
        let centerY = CGFloat(faceBox.y1 + faceBox.y2) / 2.0
        let cropWidth = CGFloat(faceBox.x2 - faceBox.x1) * 1.4
        let cropHeight = cropWidth
        
        var cropX = centerX - (cropWidth / 2.0)
        var cropY = centerY - (cropHeight / 2.0)

        // Clamp to image bounds
        if cropX < 0 { cropX = 0 }
        if cropY < 0 { cropY = 0 }
        let finalWidth = min(cropWidth, imageWidth - cropX)
        let finalHeight = min(cropHeight, imageHeight - cropY)

        if finalWidth <= 0 || finalHeight <= 0 {
            return nil
        }

        let cropRect = CGRect(x: cropX, y: cropY, width: finalWidth, height: finalHeight)
        guard let croppedCg = cg.cropping(to: cropRect) else { return nil }

        let faceImage = UIImage(cgImage: croppedCg)
        let targetSize = CGSize(width: 150, height: 150)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            faceImage.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Extension to fix orientation of an UIImage without EXIF
    func fixOrientation() -> UIImage {
        guard let cgImage = cgImage else { return self }
        if imageOrientation == .up { return self }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
          transform = transform.translatedBy(x: size.width, y: size.height)
          transform = transform.rotated(by: CGFloat(Double.pi))
            
        case .left, .leftMirrored:
          transform = transform.translatedBy(x: size.width, y: 0)
          transform = transform.rotated(by: CGFloat(Double.pi/2))
            
        case .right, .rightMirrored:
          transform = transform.translatedBy(x: 0, y: size.height)
          transform = transform.rotated(by: CGFloat(-Double.pi/2))
            
        case .up, .upMirrored:
          break
        @unknown default:
          break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
          transform = transform.translatedBy(x: size.width, y: 0)
          transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
          transform = transform.translatedBy(x: size.height, y: 0)
          transform = transform.scaledBy(x: -1, y: 1)
            
        case .up, .down, .left, .right:
          break
        @unknown default:
          break
        }
        
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        if let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            ctx.concatenate(transform)
            
            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
              ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            default:
              ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
            
            if let finalImage = ctx.makeImage() {
              return (UIImage(cgImage: finalImage))
            }
        }
        
        return self
    }
    
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            context.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return rotatedImage ?? self
        }
        return self
    }
        
    // Extension to flip UIImage horizontally
    func flipHorizontally() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        context.translateBy(x: size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        draw(in: CGRect(origin: .zero, size: size))
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage ?? self
    }
}
