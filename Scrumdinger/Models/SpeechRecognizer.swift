/*
 See LICENSE folder for this sample’s licensing information.
 */

import AVFoundation
import Foundation
import Speech
import SwiftUI
import ComposableArchitecture
import Combine

/// A helper for transcribing speech to text using AVAudioEngine.
struct SpeechRecognizer {

    enum Action: Equatable {
        case requestingAccess(String)
        case accessGranted(String)
        case accessDenied(String)
        case bootingAudioSystem(String)
        case inputNodeFound(String)
        case preparingAudioEngine(String)
        case speech(String)

        var speech: String {
            switch self {
            case .requestingAccess(let text),
                 .accessGranted(let text),
                 .accessDenied(let text),
                 .bootingAudioSystem(let text),
                 .inputNodeFound(let text),
                 .preparingAudioEngine(let text),
                 .speech(let text):
                return text
            }
        }
    }

    enum RecognizerError: Error, Equatable {
        case unableToCreateAudioEngine
        case unableToCreateRequest
        case transcribingAudioHasFailed(String)
    }

    private class SpeechAssist {
        var audioEngine: AVAudioEngine?
        var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        var recognitionTask: SFSpeechRecognitionTask?
        let speechRecognizer = SFSpeechRecognizer()

        deinit {
            reset()
        }

        func reset() {
            recognitionTask?.cancel()
            audioEngine?.stop()
            audioEngine = nil
            recognitionRequest = nil
            recognitionTask = nil
        }
    }

    private let assistant = SpeechAssist()

    /**
     Begin transcribing audio.
     
     Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopRecording()`.
     The resulting transcription is continuously written to the provided text binding.
     
     -  Parameters:
     - speech: A binding to a string where the transcription is written.
     */
    func record() -> Effect<Action, RecognizerError> {
        Effect.run { subscriber in
            subscriber.send(.requestingAccess("Requesting access"))

            canAccess { authorized in
                guard authorized else {
                    subscriber.send(.accessDenied("Access denied"))
                    return
                }

                subscriber.send(.accessGranted("Access granted"))

                assistant.audioEngine = AVAudioEngine()
                guard let audioEngine = assistant.audioEngine else {
                    subscriber.send(completion: .failure(.unableToCreateAudioEngine))
                    return
                }
                assistant.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                guard let recognitionRequest = assistant.recognitionRequest else {
                    subscriber.send(completion: .failure(.unableToCreateRequest))
                    return
                }
                recognitionRequest.shouldReportPartialResults = true
                
                do {
                    subscriber.send(.bootingAudioSystem("Booting audio subsystem"))
                    
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    let inputNode = audioEngine.inputNode
                    subscriber.send(.inputNodeFound("Found input node"))
                    
                    let recordingFormat = inputNode.outputFormat(forBus: 0)
                    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                        recognitionRequest.append(buffer)
                    }
                    subscriber.send(.preparingAudioEngine("Preparing audio engine"))
                    audioEngine.prepare()
                    try audioEngine.start()
                    assistant.recognitionTask = assistant.speechRecognizer?.recognitionTask(with: recognitionRequest) { (result, error) in
                        var isFinal = false
                        if let result = result {
                            subscriber.send(.speech(result.bestTranscription.formattedString))
                            isFinal = result.isFinal
                        }

                        if error != nil || isFinal {
                            audioEngine.stop()
                            inputNode.removeTap(onBus: 0)
                            self.assistant.recognitionRequest = nil
                        }
                    }
                } catch {
                    let description = "Error transcibing audio: " + error.localizedDescription
                    subscriber.send(completion: .failure(.transcribingAudioHasFailed(description)))
                    assistant.reset()
                }
            }

            return AnyCancellable {}
        }
    }

    /// Stop transcribing audio.
    func stopRecording() -> Effect<Never, Never> {
        .fireAndForget {
            assistant.reset()
        }
    }
    
    private func canAccess(withHandler handler: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            if status == .authorized {
                AVAudioSession.sharedInstance().requestRecordPermission { authorized in
                    handler(authorized)
                }
            } else {
                handler(false)
            }
        }
    }
}
