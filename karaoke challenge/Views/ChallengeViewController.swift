import UIKit

final class ChallengeViewController: UIViewController {
    private let song: Song

    private let cameraManager = CameraManager()
    private let audioManager = AudioManager()
    private let lyricsManager = LyricsManager()
    private let speechManager = SpeechRecognitionManager()

    private var recordingTimer: Timer?
    private var dropTriggered = false
    private var isRecording = false
    private let recordingWindowSeconds: TimeInterval = 5.0

    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 22
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let unavailableLabel: UILabel = {
        let label = UILabel()
        label.text = "Camera preview unavailable"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let borderView: BrandedBorderView = {
        let view = BrandedBorderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let lyricLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap Start to begin"
        label.textColor = .white
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = .white.withAlphaComponent(0.9)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let feedbackBadge: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private let startButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Start"
        config.cornerStyle = .large
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let doneButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Done"
        config.cornerStyle = .large
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    init(song: Song) {
        self.song = song
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = song.title

        setupLayout()
        bindActions()

        do {
            try lyricsManager.loadLyrics(filename: song.lyricsFilename)
        } catch {
            lyricLabel.text = "Lyrics unavailable"
            promptLabel.text = error.localizedDescription
        }

        speechManager.requestAuthorization { [weak self] granted in
            guard let self, !granted else { return }
            self.feedbackBadge.isHidden = false
            self.feedbackBadge.text = "Speech permission needed"
            self.feedbackBadge.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        prepareCameraPreview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.updatePreviewFrame(previewContainer.bounds)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        recordingTimer?.invalidate()
        audioManager.stopPolling()
        audioManager.stop()
        if isMovingFromParent || isBeingDismissed {
            cameraManager.stopSession()
        }
    }

    private func setupLayout() {
        view.addSubview(previewContainer)
        previewContainer.addSubview(unavailableLabel)
        previewContainer.addSubview(borderView)
        previewContainer.addSubview(lyricLabel)
        previewContainer.addSubview(promptLabel)
        previewContainer.addSubview(feedbackBadge)

        view.addSubview(startButton)
        view.addSubview(doneButton)

        NSLayoutConstraint.activate([
            previewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            previewContainer.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.62),

            unavailableLabel.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            unavailableLabel.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            unavailableLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previewContainer.leadingAnchor, constant: 20),
            unavailableLabel.trailingAnchor.constraint(lessThanOrEqualTo: previewContainer.trailingAnchor, constant: -20),

            borderView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            borderView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            lyricLabel.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor, constant: 20),
            lyricLabel.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor, constant: -20),
            lyricLabel.bottomAnchor.constraint(equalTo: promptLabel.topAnchor, constant: -8),

            promptLabel.leadingAnchor.constraint(equalTo: lyricLabel.leadingAnchor),
            promptLabel.trailingAnchor.constraint(equalTo: lyricLabel.trailingAnchor),
            promptLabel.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: -24),

            feedbackBadge.topAnchor.constraint(equalTo: previewContainer.topAnchor, constant: 16),
            feedbackBadge.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            feedbackBadge.heightAnchor.constraint(equalToConstant: 28),
            feedbackBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),

            startButton.topAnchor.constraint(equalTo: previewContainer.bottomAnchor, constant: 24),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 180),
            startButton.heightAnchor.constraint(equalToConstant: 50),

            doneButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 14),
            doneButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            doneButton.widthAnchor.constraint(equalToConstant: 120),
            doneButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func bindActions() {
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
    }

    private func prepareCameraPreview() {
        cameraManager.prepareSession { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.cameraManager.attachPreview(to: self.previewContainer)
                self.cameraManager.updatePreviewFrame(self.previewContainer.bounds)
                self.cameraManager.startSession()
                self.unavailableLabel.isHidden = true
            case .failure(let error):
                self.unavailableLabel.isHidden = false
                self.promptLabel.text = error.localizedDescription
            }
        }
    }

    @objc private func startTapped() {
        guard !dropTriggered else { return }

        feedbackBadge.isHidden = true
        borderView.apply(state: .idle)
        promptLabel.text = "Listen carefully..."
        startButton.isEnabled = false

        do {
            try audioManager.prepareAndPlay(filename: song.audioFilename)
        } catch {
            startButton.isEnabled = true
            promptLabel.text = error.localizedDescription
            return
        }

        updateLyrics(for: 0)
        audioManager.startPolling(interval: 0.05) { [weak self] currentTime in
            self?.handlePlaybackTick(time: currentTime)
        }
    }

    @objc private func doneTapped() {
        stopRecordingAndEvaluate()
    }

    private func handlePlaybackTick(time: TimeInterval) {
        updateLyrics(for: time)

        guard !dropTriggered else { return }
        if time >= song.stopTime {
            triggerLyricDrop()
        }
    }

    private func updateLyrics(for time: TimeInterval) {
        guard let index = lyricsManager.lineIndex(at: time), index < lyricsManager.lyrics.count else {
            return
        }

        let line = lyricsManager.lyrics[index]
        lyricLabel.text = line.text
    }

    private func triggerLyricDrop() {
        dropTriggered = true
        audioManager.stopPolling()
        audioManager.stop()

        lyricLabel.text = "___"
        promptLabel.text = "Your turn. Sing the missing lyric."
        borderView.apply(state: .singing)

        startRecordingWindow()
    }

    private func startRecordingWindow() {
        isRecording = true
        doneButton.isHidden = false

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("karaoke_\(UUID().uuidString).mov")

        cameraManager.startRecording(to: fileURL) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let outputURL):
                self.evaluateRecording(at: outputURL)
            case .failure(let error):
                self.promptLabel.text = error.localizedDescription
                self.startButton.isEnabled = true
                self.doneButton.isHidden = true
            }
        }

        recordingTimer = Timer.scheduledTimer(withTimeInterval: recordingWindowSeconds, repeats: false) { [weak self] _ in
            self?.stopRecordingAndEvaluate()
        }
    }

    private func stopRecordingAndEvaluate() {
        guard isRecording else { return }
        isRecording = false

        recordingTimer?.invalidate()
        recordingTimer = nil
        doneButton.isHidden = true
        promptLabel.text = "Analyzing your lyric..."

        cameraManager.stopRecording()
    }

    private func evaluateRecording(at fileURL: URL) {
        speechManager.transcribeAudioFile(url: fileURL) { [weak self] result in
            guard let self else { return }

            let transcript: String
            switch result {
            case .success(let text):
                transcript = text
            case .failure:
                transcript = ""
            }

            let evaluation = ScoringEngine.evaluate(transcript: transcript, expectedPhrase: self.song.expectedPhrase)
            self.feedbackBadge.isHidden = false
            self.feedbackBadge.text = evaluation.isCorrect ? "Correct" : "Not quite"
            self.feedbackBadge.backgroundColor = evaluation.isCorrect
                ? UIColor.systemGreen.withAlphaComponent(0.85)
                : UIColor.systemRed.withAlphaComponent(0.85)

            self.borderView.apply(state: evaluation.isCorrect ? .success : .failure)
            self.promptLabel.text = "Score: \(evaluation.matchScore)"

            let resultVC = ResultViewController(result: evaluation, recordingURL: fileURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                self.navigationController?.pushViewController(resultVC, animated: true)
            }
        }
    }
}
