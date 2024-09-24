import AVFoundation
import SwiftUI
import os.log
import Combine

final class DataModel: ObservableObject {
    let camera = Camera()
    
    @Published var viewfinderImage: Image?
    @Published var sam2Model: SAM2?
    
    @Published var lastFrame: CIImage?
    
    @Published var segmentation: SAMSegmentation?
    @Published var isPerformingSegmentation = false
    
    private var cancellables = Set<AnyCancellable>()
    
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
            .map { $0 }
        
        for await image in imageStream {
            viewfinderImage = image.image
            lastFrame = image
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
    
    func donePerformingSegmentation() async {
        await MainActor.run {
            self.isPerformingSegmentation = false
        }
    }
    
    func performSegmentation(selectedPoints: [SAMPoint], imageSize: CGSize) {
        guard !isPerformingSegmentation else { return }
        isPerformingSegmentation = true
        
        Task.detached(priority: .userInitiated) {
            do {
                guard let buffer = self.lastFrame?.pixelBuffer(width: 1024, height: 1024) else {
                    await self.donePerformingSegmentation()
                    return
                }
                
                try await self.sam2Model?.getImageEncoding(from: buffer)
                try await self.sam2Model?.getPromptEncoding(from: selectedPoints, with: imageSize)
                
                if let mask = try await self.sam2Model?.getMask(for: imageSize) {
                    await MainActor.run {
                        self.segmentation = SAMSegmentation(image: mask, title: "Camera Segmentation")
                        self.isPerformingSegmentation = false
                    }
                } else {
                    await self.donePerformingSegmentation()
                }
            } catch {
                print("Error performing segmentation: \(error)")
                await self.donePerformingSegmentation()
            }
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
