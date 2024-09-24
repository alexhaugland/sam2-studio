//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @StateObject private var model = DataModel()
    
    @State private var selectedPoints: [SAMPoint] = []
    @State private var imageSize: CGSize = .zero
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            CameraPreview(model: model, segmentation: $model.segmentation, imageSize: $imageSize)
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
                .overlay {
                    if !model.samReady {
                        ProgressView("Initializing SAM2 model...")
                    }
                }
            SelectedPointsOverlay(points: selectedPoints, imageSize: imageSize)
        }
        .onAppear {
            startSegmentationTimer()
        }
        .onDisappear {
            stopSegmentationTimer()
        }
    }
    
    private func startSegmentationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            Task { @MainActor in
                await model.performSegmentation(selectedPoints: selectedPoints, imageSize: imageSize)
            }
        }
    }
    
    private func stopSegmentationTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func addCenterPoints(size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let offset: CGFloat = 10
        
        selectedPoints = [
            SAMPoint(coordinates: CGPoint(x: (centerX - offset) / size.width, y: (centerY - offset) / size.height), category: .foreground),
            SAMPoint(coordinates: CGPoint(x: (centerX + offset) / size.width, y: (centerY - offset) / size.height), category: .foreground),
            SAMPoint(coordinates: CGPoint(x: (centerX - offset) / size.width, y: (centerY + offset) / size.height), category: .foreground),
            SAMPoint(coordinates: CGPoint(x: (centerX + offset) / size.width, y: (centerY + offset) / size.height), category: .foreground)
        ]
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct SelectedPointsOverlay: View {
    let points: [SAMPoint]
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(points.indices, id: \.self) { index in
                Circle()
                    .fill(Color.green)
                    .frame(width: 2, height: 2)
                    .position(
                        x: points[index].coordinates.x * geometry.size.width,
                        y: points[index].coordinates.y * geometry.size.height
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
