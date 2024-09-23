import AVFoundation
import SwiftUI
import os.log

final class DataModel: ObservableObject {
    let camera = Camera()
    
    @Published var viewfinderImage: Image?
    @Published var sam2Model: SAM2?
    
    init() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.initializeSAM2Model() }
                group.addTask { await self.handleCameraPreviews() }
            }
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
    
    @MainActor
    private func initializeSAM2Model() async {
        do {
            sam2Model = try await SAM2.load()
            logger.info("SAM2 model initialized successfully")
        } catch {
            logger.error("Failed to initialize SAM2 model: \(error.localizedDescription)")
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
