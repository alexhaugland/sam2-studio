//

import AVFoundation
import SwiftUI

struct ContentView: View {
    var body: some View {
        CameraPreview()
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
