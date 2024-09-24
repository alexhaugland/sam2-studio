import SwiftUI
import AVFoundation

struct CameraPreview: View {
    @ObservedObject var model: DataModel
    @Binding var segmentation: SAMSegmentation?
    @Binding var imageSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = model.viewfinderImage {
                    image
                        .resizable()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .overlay {
                            if let segmentation = segmentation {
                                SegmentationOverlay(segmentationImage: .constant(segmentation), imageSize: imageSize, shouldAnimate: true)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                }
            }
        }
    }
}
