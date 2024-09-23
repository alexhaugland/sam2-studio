//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @StateObject private var model = DataModel()
    
    @State private var selectedPoints: [SAMPoint] = []
    @State private var segmentation: SAMSegmentation?
    @State private var imageSize: CGSize = .zero
    
    var body: some View {
        ZStack {
            CameraPreview(model: model, segmentation: $segmentation, imageSize: $imageSize)
                .overlay(
                    GeometryReader { geometry in
                        Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
                    }
                )
                .onPreferenceChange(SizePreferenceKey.self) { size in
                    imageSize = size
                    if selectedPoints.isEmpty {
                        addCenterPoints(size: size)
                    }
                }
                .onTapGesture {
                    performSegmentation()
                }
                .overlay {
                    if model.sam2Model == nil {
                        ProgressView("Initializing SAM2 model...")
                    }
                }
        }
        .onChange(of: selectedPoints) { _ in
            performSegmentation()
        }
    }
    
    private func addCenterPoints(size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let offset: CGFloat = 20
        
        selectedPoints = [
            SAMPoint(coordinates: CGPoint(x: (centerX - offset) / size.width, y: centerY / size.height), category: .foreground),
            SAMPoint(coordinates: CGPoint(x: (centerX + offset) / size.width, y: centerY / size.height), category: .foreground)
        ]
    }
    
    private func performSegmentation() {
        Task {
            do {
                guard let buffer = model.lastFrame?.pixelBuffer(width: 1024, height: 1024) else { return }
                try await model.sam2Model?.getImageEncoding(from: buffer)
                try await model.sam2Model?.getPromptEncoding(from: selectedPoints, with: imageSize)
                
                if let mask = try await model.sam2Model?.getMask(for: imageSize) {
                    DispatchQueue.main.async {
                        self.segmentation = SAMSegmentation(image: mask, title: "Camera Segmentation")
                    }
                }
            } catch {
                print("Error performing segmentation: \(error)")
            }
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

#Preview {
    ContentView()
}
