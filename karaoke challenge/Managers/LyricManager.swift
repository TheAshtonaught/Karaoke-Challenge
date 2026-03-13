import Foundation

enum LyricsManagerError: LocalizedError {
    case fileMissing(String)

    var errorDescription: String? {
        switch self {
        case .fileMissing(let name):
            return "Could not find lyrics file: \(name)."
        }
    }
}

final class LyricsManager {
    private(set) var lyrics: [LyricLine] = []

    func loadLyrics(filename: String) throws {
        let file = filename as NSString
        let resource = file.deletingPathExtension
        let ext = file.pathExtension.isEmpty ? "json" : file.pathExtension

        let url =
            Bundle.main.url(forResource: resource, withExtension: ext) ??
            Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Resources/Songs")

        guard let url else {
            throw LyricsManagerError.fileMissing(filename)
        }

        let data = try Data(contentsOf: url)
        lyrics = try JSONDecoder().decode([LyricLine].self, from: data)
    }

    func lineIndex(at time: TimeInterval) -> Int? {
        lyrics.firstIndex { time >= $0.start && time < $0.end }
    }

    func line(at time: TimeInterval) -> LyricLine? {
        guard let index = lineIndex(at: time) else { return nil }
        return lyrics[index]
    }
}
