import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechInputManager: NSObject, ObservableObject {
    enum SpeechInputError: LocalizedError {
        case unavailable
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Speech recognition is not available on this device."
            case .permissionDenied:
                return "Speech or microphone permission was denied."
            }
        }
    }

    @Published private(set) var transcript = ""
    @Published private(set) var isRecording = false

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasAudioTap = false

    func start() async throws {
        guard recognizer?.isAvailable == true else {
            throw SpeechInputError.unavailable
        }

        let granted = await requestAuthorization()
        guard granted else {
            throw SpeechInputError.permissionDenied
        }

        stop()
        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1_024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        hasAudioTap = true

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self?.stop()
                }
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if hasAudioTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasAudioTap = false
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    private func requestAuthorization() async -> Bool {
        async let speechAuthorized = requestSpeechAuthorization()
        async let microphoneAuthorized = requestMicrophoneAuthorization()
        return await speechAuthorized && microphoneAuthorized
    }

    private func requestSpeechAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophoneAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
