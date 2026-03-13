import Foundation

struct Song: Codable {
    let id: String
    let title: String
    let artist: String
    let audioFilename: String
    let lyricsFilename: String
    let stopTime: Double
    let expectedPhrase: String
    let artworkFilename: String?
}
