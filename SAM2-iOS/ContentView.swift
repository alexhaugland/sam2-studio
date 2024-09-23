//

import AVFoundation
import SwiftUI

struct ContentView: View {
    @StateObject private var camera = Camera()
    
    var body: some View {
        CameraPreview()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
