import AVFoundation
import Foundation

final class AudioManager: NSObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?

    func prepareAndPlay(filename: String) throws {
        let file = filename as NSString
        let resource = file.deletingPathExtension
        let ext = file.pathExtension

        let url =
            Bundle.main.url(forResource: resource, withExtension: ext) ??
            Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Resources/Songs")

        guard let url else {
            throw NSError(domain: "AudioManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing audio file \(filename)"])
        }

        player = try AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        player?.play()
    }

    func stop() {
        player?.stop()
    }

    func startPolling(interval: TimeInterval = 0.05, onTick: @escaping (TimeInterval) -> Void) {
        stopPolling()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, let player = self.player else { return }
            onTick(player.currentTime)
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }
}
