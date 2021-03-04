/*
 See LICENSE folder for this sample’s licensing information.
 */

import Foundation
import ComposableArchitecture
import Combine

private var dependencies: [AnyHashable: Dependencies] = [:]
private struct Dependencies {
  let delegate: ScrumTimerDelegate
  let subscriber: Effect<ScrumTimer.Action, Never>.Subscriber
}

struct ScrumTimerClient {
    var onActiveSpeakerChange: (String) -> Effect<String, Never>
    var onSecondsElapsed: (Int) -> Effect<Int, Never>
    var onSecondsRemaining: (Int) -> Effect<Int, Never>
}

private class ScrumTimerDelegate {

    var onActiveSpeakerChange: (String) -> Void
    var onSecondsElapsed: (Int) -> Void
    var onSecondsRemaining: (Int) -> Void

    /// A closure that is executed when a new attendee begins speaking.
    var speakerChangedAction: () -> Void

    init(onActiveSpeakerChange: @escaping (String) -> Void,
         onSecondsElapsed: @escaping (Int) -> Void,
         onSecondsRemaining: @escaping (Int) -> Void,
         speakerChangedAction: @escaping () -> Void) {
        self.onActiveSpeakerChange = onActiveSpeakerChange
        self.onSecondsElapsed = onSecondsElapsed
        self.onSecondsRemaining = onSecondsRemaining
        self.speakerChangedAction = speakerChangedAction
    }
}

/// Keeps time for a daily scrum meeting. Keep track of the total meeting time, the time for each speaker, and the name of the current speaker.
class ScrumTimer: Identifiable {

    let id = UUID().uuidString

    /// A struct to keep track of meeting attendees during a meeting.
    struct Speaker: Identifiable, Equatable {
        /// The attendee name.
        let name: String
        /// True if the attendee has completed their turn to speak.
        var isCompleted: Bool
        /// Id for Identifiable conformance.
        let id = UUID()
    }

    enum Action: Equatable {
        case didChangeActiveSpeaker(String)
        case speakerChangedAction
        case didChangeSecondsElapsed(Int)
        case didChangeSecondsRemaining(Int)
        case skipSpeaker
    }

    fileprivate weak var delegate: ScrumTimerDelegate?
    
    /// The name of the meeting attendee who is speaking.
    private var activeSpeaker = "" {
        didSet {
            delegate?.onActiveSpeakerChange(activeSpeaker)
        }
    }
    /// The number of seconds since the beginning of the meeting.
    private var secondsElapsed = 0 {
        didSet {
            delegate?.onSecondsElapsed(secondsElapsed)
        }
    }
    /// The number of seconds until all attendees have had a turn to speak.
    private var secondsRemaining = 0 {
        didSet {
            delegate?.onSecondsRemaining(secondsRemaining)
        }
    }
    /// All meeting attendees, listed in the order they will speak.
    var speakers: [Speaker] = []

    /// The scrum meeting length.
    var lengthInMinutes: Int

    private var timer: Timer?
    private var timerStopped = false
    private var frequency: TimeInterval { 1.0 / 60.0 }
    private var lengthInSeconds: Int { lengthInMinutes * 60 }
    private var secondsPerSpeaker: Int {
        (lengthInMinutes * 60) / speakers.count
    }
    private var secondsElapsedForSpeaker: Int = 0
    private var speakerIndex: Int = 0
    private var speakerText: String {
        return "Speaker \(speakerIndex + 1): " + speakers[speakerIndex].name
    }
    private var startDate: Date?
    
    /**
     Initialize a new timer. Initializing a time with no arguments creates a ScrumTimer with no attendees and zero length.
     Use `startScrum()` to start the timer.
     
     - Parameters:
     - lengthInMinutes: The meeting length.
     -  attendees: The name of each attendee.
     */
    init(lengthInMinutes: Int = 0,
         attendees: [String] = []) {
        self.lengthInMinutes = lengthInMinutes
        self.speakers = attendees.isEmpty ? [Speaker(name: "Player 1", isCompleted: false)] : attendees.map { Speaker(name: $0, isCompleted: false) }
        secondsRemaining = lengthInSeconds
        activeSpeaker = speakerText
    }
    /// Start the timer.
    func startScrum() -> Effect<Action, Never> {
        Effect.run { [weak self] subscriber in
            guard let self = self else {
                return AnyCancellable{ subscriber.send(completion: .finished) }
            }

            let delegate = ScrumTimerDelegate(
                onActiveSpeakerChange: { subscriber.send(.didChangeActiveSpeaker($0)) },
                onSecondsElapsed: { subscriber.send(.didChangeSecondsElapsed($0)) },
                onSecondsRemaining: { subscriber.send(.didChangeSecondsRemaining($0)) },
                speakerChangedAction: { subscriber.send(.speakerChangedAction) }
            )
            self.delegate = delegate
            self.changeToSpeaker(at: 0)
            dependencies[self.id] = Dependencies(delegate: delegate, subscriber: subscriber)

            return AnyCancellable {
                dependencies[self.id]?.subscriber.send(completion: .finished)
                dependencies[self.id] = nil
            }
        }
    }
    /// Stop the timer.
    func stopScrum() -> Effect<Never, Never> {
        .fireAndForget { [weak self] in
            guard let self = self else { return }

            self.timer?.invalidate()
            self.timer = nil
            self.timerStopped = true

            dependencies[self.id]?.subscriber.send(completion: .finished)
            dependencies[self.id] = nil
        }
    }
    /// Advance the timer to the next speaker.
    func skipSpeaker() -> Effect<Never, Never> {
        .fireAndForget { [weak self] in
            guard let self = self else { return }
            self.changeToSpeaker(at: self.speakerIndex + 1)
        }
    }

    private func changeToSpeaker(at index: Int) {
        if index > 0 {
            let previousSpeakerIndex = index - 1
            speakers[previousSpeakerIndex].isCompleted = true
        }
        secondsElapsedForSpeaker = 0
        guard index < speakers.count else { return }
        speakerIndex = index
        activeSpeaker = speakerText

        secondsElapsed = index * secondsPerSpeaker
        secondsRemaining = lengthInSeconds - secondsElapsed
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] timer in
            if let self = self, let startDate = self.startDate {
                let secondsElapsed = Date().timeIntervalSince1970 - startDate.timeIntervalSince1970
                self.update(secondsElapsed: Int(secondsElapsed))
            }
        }
    }

    private func update(secondsElapsed: Int) {
        secondsElapsedForSpeaker = secondsElapsed
        self.secondsElapsed = secondsPerSpeaker * speakerIndex + secondsElapsedForSpeaker
        guard secondsElapsed <= secondsPerSpeaker else {
            return
        }
        secondsRemaining = max(lengthInSeconds - self.secondsElapsed, 0)

        guard !timerStopped else { return }

        if secondsElapsedForSpeaker >= secondsPerSpeaker {
            changeToSpeaker(at: speakerIndex + 1)
            delegate?.speakerChangedAction()
        }
    }
    
    /**
     Reset the timer with a new meeting length and new attendees.
     
     - Parameters:
     - lengthInMinutes: The meeting length.
     - attendees: The name of each attendee.
     */
    func reset(lengthInMinutes: Int, attendees: [String]) -> Effect<Never, Never> {
        .fireAndForget { [weak self] in
            guard let self = self else { return }

            self.lengthInMinutes = lengthInMinutes
            self.speakers = attendees.isEmpty ? [Speaker(name: "Player 1", isCompleted: false)] : attendees.map { Speaker(name: $0, isCompleted: false) }
            self.secondsRemaining = self.lengthInSeconds
            self.activeSpeaker = self.speakerText
        }
    }
}

extension DailyScrum {
    /// A new `ScrumTimer` using the meeting length and attendees in the `DailyScrum`.
    var timer: ScrumTimer {
        ScrumTimer(lengthInMinutes: lengthInMinutes, attendees: attendees)
    }
}
