import AVFoundation
import SwiftUI
import os.log

final class DataModel: ObservableObject {
    let camera = Camera()
    
    @Published var viewfinderImage: Image?
    
    init() {
        Task {
            await handleCameraPreviews()
        }
    }
    
    @MainActor
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0.image }

        for await image in imageStream {
            viewfinderImage = image
        }
    }
}

fileprivate extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

fileprivate let logger = Logger(subsystem: "co.twodi.SAM2-iOS", category: "DataModel")
