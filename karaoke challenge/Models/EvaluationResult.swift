import Foundation

enum ConfidenceBucket: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct EvaluationResult {
    let isCorrect: Bool
    let transcript: String
    let expectedPhrase: String
    let confidenceBucket: ConfidenceBucket
    let matchScore: Int
}
