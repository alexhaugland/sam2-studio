import SwiftUI
import AVFoundation
import UIKit

struct CameraPreview: View {
    @StateObject private var model: DataModel
    @State private var orientation = UIDeviceOrientation.portrait
    
    init() {
        _model = StateObject(wrappedValue: DataModel())
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewLayer(session: model.camera.captureSession)
                    .edgesIgnoringSafeArea(.all)
                
                if let image = model.viewfinderImage {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .rotationEffect(rotationAngle)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            Task {
                await model.camera.start()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            orientation = UIDevice.current.orientation
        }
    }
    
    private var rotationAngle: Angle {
        switch orientation {
        case .landscapeLeft:
            return .degrees(90)
        case .landscapeRight:
            return .degrees(-90)
        case .portraitUpsideDown:
            return .degrees(180)
        default:
            return .degrees(0)
        }
    }
}

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoRotationAngle = 0
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            updatePreviewLayerOrientation(previewLayer)
        }
    }
    
    private func updatePreviewLayerOrientation(_ previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = previewLayer.connection else { return }
        
        let orientation = UIDevice.current.orientation
        
        switch orientation {
        case .portrait:
            connection.videoRotationAngle = 0
        case .landscapeRight:
            connection.videoRotationAngle = .pi / 2
        case .landscapeLeft:
            connection.videoRotationAngle = -.pi / 2
        case .portraitUpsideDown:
            connection.videoRotationAngle = .pi
        default:
            connection.videoRotationAngle = 0
        }
    }
}
