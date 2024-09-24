import AVFoundation
import SwiftUI
import os.log
import Combine
import Dispatch

actor SAMActor {
    var lastFrame: CIImage?
    var sam2Model: SAM2?
    
    func initialize() async throws {
        sam2Model = try await SAM2.load()
        logger.info("SAM2 initialized successfully")
    }
    
    func updateLastFrame(_ image: CIImage) {
        lastFrame = image
    }
    
    nonisolated func performSegmentation(selectedPoints: [SAMPoint], imageSize: CGSize) async throws -> SAMSegmentation? {
        guard let buffer = await lastFrame?.pixelBuffer(width: 1024, height: 1024) else {
            return nil
        }
        guard let model = await sam2Model else { return nil }
        
        try await model.getImageEncoding(from: buffer)
        try await model.getPromptEncoding(from: selectedPoints, with: imageSize)
        
        if let mask = try await model.getMask(for: imageSize) {
            return SAMSegmentation(image: mask, title: "Camera Segmentation")
        }
        
        return nil
    }
}

@MainActor
final class DataModel: ObservableObject {
    private let samActor = SAMActor()
    private let camera = Camera()
    
    @Published var samReady: Bool = false
    @Published var viewfinderImage: Image?
    @Published var segmentation: SAMSegmentation?
    @Published var isPerformingSegmentation = false
    
    private var cancellables = Set<AnyCancellable>()
    
    nonisolated init() {
        Task { await initialize() }
    }
    
    private func initialize() async {
        do {
            try await samActor.initialize()
            await camera.start()
            samReady = true
        } catch {
            logger.error("Failed to initialize SAM2: \(error.localizedDescription)")
        }
        
        await handleCameraPreviews()
    }
    
    private func handleCameraPreviews() async {
        let imageStream = camera.previewStream.map { $0 }
        
        for await image in imageStream {
            viewfinderImage = image.image
            await samActor.updateLastFrame(image)
        }
    }
    
    func performSegmentation(selectedPoints: [SAMPoint], imageSize: CGSize) {
        guard !isPerformingSegmentation else { return }
        isPerformingSegmentation = true
        
        Task {
            do {
                if let result = try await samActor.performSegmentation(selectedPoints: selectedPoints, imageSize: imageSize) {
                    self.segmentation = result
                }
            } catch {
                print("Error performing segmentation: \(error)")
            }
            self.isPerformingSegmentation = false
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
