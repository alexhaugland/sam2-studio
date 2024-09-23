import CoreImage
import VideoToolbox

extension CIImage {
    /**
     Converts the image to an ARGB `CVPixelBuffer`.
     */
    public func pixelBuffer() -> CVPixelBuffer? {
        return pixelBuffer(width: Int(extent.width), height: Int(extent.height))
    }

    /**
     Resizes the image to `width` x `height` and converts it to an ARGB
     `CVPixelBuffer`.
     */
    public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                           pixelFormatType: kCVPixelFormatType_32ARGB,
                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                           alphaInfo: .noneSkipFirst)
    }

    /**
     Resizes the image to `width` x `height` and converts it to a `CVPixelBuffer`
     with the specified pixel format, color space, and alpha channel.
     */
    public func pixelBuffer(width: Int, height: Int,
                            pixelFormatType: OSType,
                            colorSpace: CGColorSpace,
                            alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         pixelFormatType,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)

        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }

        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
            return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }

        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue)
        else {
            return nil
        }

        let ciContext = CIContext(cgContext: context, options: nil)
        let scaledImage = self.transformed(by: CGAffineTransform(scaleX: CGFloat(width) / extent.width,
                                                                 y: CGFloat(height) / extent.height))
        ciContext.render(scaledImage, to: pixelBuffer)

        return pixelBuffer
    }
}