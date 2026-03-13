import Foundation

enum ScoringEngine {
    static func evaluate(transcript: String, expectedPhrase: String) -> EvaluationResult {
        let normalizedTranscript = normalize(transcript)
        let normalizedExpected = normalize(expectedPhrase)

        let score = matchScore(transcript: normalizedTranscript, expected: normalizedExpected)
        let confidenceBucket: ConfidenceBucket

        switch score {
        case 85...100:
            confidenceBucket = .high
        case 60...84:
            confidenceBucket = .medium
        default:
            confidenceBucket = .low
        }

        return EvaluationResult(
            isCorrect: score >= 80,
            transcript: transcript,
            expectedPhrase: expectedPhrase,
            confidenceBucket: confidenceBucket,
            matchScore: score
        )
    }

    private static func normalize(_ text: String) -> String {
        let lowercase = text.lowercased()
        let filteredScalars = lowercase.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || CharacterSet.whitespaces.contains(scalar) {
                return Character(scalar)
            }
            return " "
        }
        let stripped = String(filteredScalars)
        return stripped
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func matchScore(transcript: String, expected: String) -> Int {
        guard !expected.isEmpty else { return 0 }
        guard !transcript.isEmpty else { return 0 }

        if transcript == expected {
            return 100
        }

        if transcript.contains(expected) {
            return 90
        }

        let transcriptTokens = Set(transcript.split(separator: " ").map(String.init))
        let expectedTokens = Set(expected.split(separator: " ").map(String.init))

        guard !transcriptTokens.isEmpty, !expectedTokens.isEmpty else { return 0 }

        let overlap = transcriptTokens.intersection(expectedTokens).count
        let union = transcriptTokens.union(expectedTokens).count
        let jaccard = Double(overlap) / Double(union)

        return Int((jaccard * 100.0).rounded())
    }
}
