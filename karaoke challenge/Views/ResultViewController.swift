import AVFoundation
import AVKit
import UIKit

final class ResultViewController: UIViewController {
    private let result: EvaluationResult
    private let recordingURL: URL?

    private let statusLabel = UILabel()
    private let expectedLabel = UILabel()
    private let transcriptLabel = UILabel()
    private let scoreLabel = UILabel()
    private let confidenceLabel = UILabel()

    private let tryAnotherButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Try another song"
        config.cornerStyle = .large
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let replayButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Replay recording"
        config.cornerStyle = .large
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    init(result: EvaluationResult, recordingURL: URL?) {
        self.result = result
        self.recordingURL = recordingURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Result"

        setupLabels()
        setupLayout()
        bindActions()
        populateData()
    }

    private func setupLabels() {
        [statusLabel, expectedLabel, transcriptLabel, scoreLabel, confidenceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.numberOfLines = 0
            $0.textAlignment = .center
            view.addSubview($0)
        }

        statusLabel.font = .systemFont(ofSize: 34, weight: .heavy)
        expectedLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        transcriptLabel.font = .systemFont(ofSize: 16, weight: .regular)
        transcriptLabel.textColor = .secondaryLabel
        scoreLabel.font = .systemFont(ofSize: 20, weight: .bold)
        confidenceLabel.font = .systemFont(ofSize: 18, weight: .medium)
    }

    private func setupLayout() {
        view.addSubview(tryAnotherButton)
        view.addSubview(replayButton)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            expectedLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 24),
            expectedLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            expectedLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),

            transcriptLabel.topAnchor.constraint(equalTo: expectedLabel.bottomAnchor, constant: 14),
            transcriptLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            transcriptLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),

            scoreLabel.topAnchor.constraint(equalTo: transcriptLabel.bottomAnchor, constant: 20),
            scoreLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            scoreLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),

            confidenceLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 10),
            confidenceLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            confidenceLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),

            tryAnotherButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tryAnotherButton.bottomAnchor.constraint(equalTo: replayButton.topAnchor, constant: -12),
            tryAnotherButton.widthAnchor.constraint(equalToConstant: 220),
            tryAnotherButton.heightAnchor.constraint(equalToConstant: 50),

            replayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            replayButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            replayButton.widthAnchor.constraint(equalToConstant: 220),
            replayButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        replayButton.isHidden = (recordingURL == nil)
    }

    private func bindActions() {
        tryAnotherButton.addTarget(self, action: #selector(tryAnotherTapped), for: .touchUpInside)
        replayButton.addTarget(self, action: #selector(replayTapped), for: .touchUpInside)
    }

    private func populateData() {
        statusLabel.text = result.isCorrect ? "Correct" : "Incorrect"
        statusLabel.textColor = result.isCorrect ? .systemGreen : .systemRed

        expectedLabel.text = "Expected: \"\(result.expectedPhrase)\""
        let transcript = result.transcript.isEmpty ? "(No speech detected)" : result.transcript
        transcriptLabel.text = "You said: \"\(transcript)\""
        scoreLabel.text = "Match Score: \(result.matchScore)"
        confidenceLabel.text = "Confidence: \(result.confidenceBucket.rawValue)"
    }

    @objc private func tryAnotherTapped() {
        if let selectionVC = navigationController?.viewControllers.first(where: { $0 is SongSelectionViewController }) {
            navigationController?.popToViewController(selectionVC, animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }

    @objc private func replayTapped() {
        guard let recordingURL else { return }
        let player = AVPlayer(url: recordingURL)
        let playerVC = AVPlayerViewController()
        playerVC.player = player
        present(playerVC, animated: true) {
            player.play()
        }
    }
}
