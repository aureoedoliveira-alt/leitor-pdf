import SwiftUI
import AVFoundation

@main
struct LeitorPDFApp: App {
    init() {
        // Permite que a leitura continue com a tela bloqueada ou o app em segundo plano.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
    }

    var body: some Scene {
        WindowGroup {
            BibliotecaView()
        }
    }
}
