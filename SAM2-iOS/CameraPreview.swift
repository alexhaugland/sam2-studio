import SwiftUI
import AVFoundation

struct CameraPreview: View {
    @ObservedObject var model: DataModel
    
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
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .onAppear {
            Task {
                await model.camera.start()
            }
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
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
