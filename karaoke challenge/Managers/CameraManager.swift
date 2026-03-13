import AVFoundation
import Foundation
import UIKit

final class CameraManager: NSObject {
    enum CameraError: LocalizedError {
        case unavailableOnSimulator
        case permissionDenied
        case configurationFailed
        case noFrontCamera
        case recordingFailed

        var errorDescription: String? {
            switch self {
            case .unavailableOnSimulator:
                return "Camera preview is unavailable on the simulator."
            case .permissionDenied:
                return "Camera and microphone permissions are required."
            case .configurationFailed:
                return "Could not configure camera session."
            case .noFrontCamera:
                return "Front camera was not found on this device."
            case .recordingFailed:
                return "Recording failed."
            }
        }
    }

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let movieOutput = AVCaptureMovieFileOutput()

    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    private var isConfigured = false
    private var recordingCompletion: ((Result<URL, Error>) -> Void)?

    func prepareSession(completion: @escaping (Result<Void, Error>) -> Void) {
#if targetEnvironment(simulator)
        completion(.failure(CameraError.unavailableOnSimulator))
        return
#endif
        requestPermissions { [weak self] granted in
            guard let self else { return }
            guard granted else {
                completion(.failure(CameraError.permissionDenied))
                return
            }

            self.sessionQueue.async {
                if !self.isConfigured {
                    do {
                        try self.configureSession()
                        self.isConfigured = true
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }

                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
    }

    func attachPreview(to containerView: UIView) {
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
        }

        guard let previewLayer else { return }
        previewLayer.frame = containerView.bounds
        if previewLayer.superlayer == nil {
            containerView.layer.insertSublayer(previewLayer, at: 0)
        }
    }

    func updatePreviewFrame(_ frame: CGRect) {
        previewLayer?.frame = frame
    }

    func startSession() {
        sessionQueue.async {
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            guard self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func startRecording(to outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        sessionQueue.async {
            guard self.isConfigured else {
                DispatchQueue.main.async {
                    completion(.failure(CameraError.configurationFailed))
                }
                return
            }

            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }

            self.recordingCompletion = completion
            self.movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }

    func stopRecording() {
        sessionQueue.async {
            guard self.movieOutput.isRecording else { return }
            self.movieOutput.stopRecording()
        }
    }

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var videoGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        var audioGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized

        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            group.enter()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                videoGranted = granted
                group.leave()
            }
        }

        if AVCaptureDevice.authorizationStatus(for: .audio) == .notDetermined {
            group.enter()
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                audioGranted = granted
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if AVCaptureDevice.authorizationStatus(for: .video) == .denied || AVCaptureDevice.authorizationStatus(for: .video) == .restricted {
                completion(false)
                return
            }

            if AVCaptureDevice.authorizationStatus(for: .audio) == .denied || AVCaptureDevice.authorizationStatus(for: .audio) == .restricted {
                completion(false)
                return
            }

            completion(videoGranted && audioGranted)
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        session.sessionPreset = .high

        defer {
            session.commitConfiguration()
        }

        guard
            let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let videoInput = try? AVCaptureDeviceInput(device: frontCamera),
            session.canAddInput(videoInput)
        else {
            throw CameraError.noFrontCamera
        }

        if session.inputs.isEmpty {
            session.addInput(videoInput)
        }

        if let mic = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(audioInput),
           !session.inputs.contains(where: { ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.audio) == true }) {
            session.addInput(audioInput)
        }

        if session.outputs.isEmpty, session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let error {
                self.recordingCompletion?(.failure(error))
            } else {
                self.recordingCompletion?(.success(outputFileURL))
            }
            self.recordingCompletion = nil
        }
    }
}
