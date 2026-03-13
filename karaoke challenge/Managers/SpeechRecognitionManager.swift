import Foundation
import Speech

final class SpeechRecognitionManager {
    enum SpeechError: LocalizedError {
        case recognizerUnavailable
        case notAuthorized
        case noResult

        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                return "Speech recognizer is unavailable for this locale."
            case .notAuthorized:
                return "Speech recognition permission is required."
            case .noResult:
                return "No transcript was recognized."
            }
        }
    }

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var activeTask: SFSpeechRecognitionTask?

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    func transcribeAudioFile(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        guard let recognizer, recognizer.isAvailable else {
            completion(.failure(SpeechError.recognizerUnavailable))
            return
        }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            completion(.failure(SpeechError.notAuthorized))
            return
        }

        activeTask?.cancel()

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        activeTask = recognizer.recognitionTask(with: request) { result, error in
            if let error {
                completion(.failure(error))
                self.activeTask = nil
                return
            }

            guard let result, result.isFinal else { return }
            let transcript = result.bestTranscription.formattedString
            completion(.success(transcript))
            self.activeTask = nil
        }
    }

    func stopTranscription() {
        activeTask?.cancel()
        activeTask = nil
    }
}
