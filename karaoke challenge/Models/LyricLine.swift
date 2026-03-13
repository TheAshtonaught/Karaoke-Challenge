import Foundation

struct LyricLine: Codable {
    let start: Double
    let end: Double
    let text: String
    let pauseAfter: Bool
    let expectedPhrase: String?

    init(start: Double, end: Double, text: String, pauseAfter: Bool = false, expectedPhrase: String? = nil) {
        self.start = start
        self.end = end
        self.text = text
        self.pauseAfter = pauseAfter
        self.expectedPhrase = expectedPhrase
    }

    private enum CodingKeys: String, CodingKey {
        case start
        case end
        case text
        case pauseAfter
        case expectedPhrase
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(Double.self, forKey: .start)
        end = try container.decode(Double.self, forKey: .end)
        text = try container.decode(String.self, forKey: .text)
        pauseAfter = try container.decodeIfPresent(Bool.self, forKey: .pauseAfter) ?? false
        expectedPhrase = try container.decodeIfPresent(String.self, forKey: .expectedPhrase)
    }
}
