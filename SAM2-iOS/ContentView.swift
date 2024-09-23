//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @StateObject private var model = DataModel()
    
    var body: some View {
        ZStack {
            CameraPreview(model: model)
            
            if model.sam2Model != nil {
                // UI elements for interacting with the SAM2 model
            } else {
                ProgressView("Initializing SAM2 model...")
            }
        }
    }
}

#Preview {
    ContentView()
}
