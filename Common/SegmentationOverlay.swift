import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

#if os(iOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif

struct SegmentationOverlay: View {
    
    @Binding var segmentationImage: SAMSegmentation
    let imageSize: CGSize
    
    var origin: CGPoint = .zero
    var shouldAnimate: Bool = false
    
    var body: some View {
        imageView
            .resizable()
            .scaledToFit()
            .allowsHitTesting(false)
            .frame(width: imageSize.width, height: imageSize.height)
            .opacity(segmentationImage.isHidden ? 0 : 0.6)
    }

    @ViewBuilder
    private var imageView: Image {
        #if os(iOS)
        let image = UIImage(cgImage: segmentationImage.cgImage)
        Image(uiImage: image)
        #elseif os(macOS)
        let image = NSImage(cgImage: segmentationImage.cgImage, size: imageSize)
        Image(nsImage: image)
        #endif
    }
}
