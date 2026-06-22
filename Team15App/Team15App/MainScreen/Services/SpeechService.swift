import Foundation
import Combine
import Speech
import AVFoundation

// MARK: - Speech-to-Text Service

@MainActor
class SpeechService: ObservableObject {

    @Published var transcript:       String = ""
    @Published var isListening:      Bool   = false
    @Published var isAvailable:      Bool   = true
    @Published var permissionDenied: Bool   = false

    private var recognizer: SFSpeechRecognizer?
    private var request:    SFSpeechAudioBufferRecognitionRequest?
    private var task:       SFSpeechRecognitionTask?
    private let engine =    AVAudioEngine()
    private var tapInstalled = false

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        isAvailable = recognizer?.isAvailable ?? false
    }

    // MARK: - Permission Request

    func requestPermissions() async -> Bool {
        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            permissionDenied = true
            return false
        }
        let micGranted = await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        if !micGranted { permissionDenied = true }
        return micGranted
    }

    // MARK: - Start Listening

    func startListening() {
        guard let recognizer, recognizer.isAvailable, !engine.isRunning else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            request = SFSpeechAudioBufferRecognitionRequest()
            guard let request else { return }
            request.shouldReportPartialResults = true

            task = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }
                    if let error = error {
                        print("Speech recognition error: \(error.localizedDescription)")
                        if !self.engine.isRunning || result == nil {
                            self.stopListening()
                        }
                    } else if result?.isFinal == true {
                        self.stopListening()
                    }
                }
            }

            let inputNode = engine.inputNode
            let format    = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
                self?.request?.append(buf)
            }
            tapInstalled = true

            engine.prepare()
            try engine.start()
            isListening = true

        } catch {
            print("SpeechService error: \(error.localizedDescription)")
            isAvailable = false
        }
    }

    // MARK: - Stop Listening

    func stopListening() {
        engine.stop()
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        request?.endAudio()
        task?.finish()
        request = nil
        task    = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Helpers

    func toggle() {
        if isListening { stopListening() } else { startListening() }
    }

    func clearTranscript() {
        transcript = ""
    }
}
