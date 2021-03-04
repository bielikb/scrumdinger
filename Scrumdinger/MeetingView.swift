/*
 See LICENSE folder for this sample’s licensing information.
 */

import SwiftUI
import AVFoundation
import ComposableArchitecture
import Combine

struct MeetingState: Equatable {
    var scrum: DailyScrum
    var transcript = ""
    var isRecording = false
    var secondsElapsed = 0
    var secondsRemaining = 0
    var speakers: [ScrumTimer.Speaker] = []
}

extension MeetingState {
    var meetingFooterState: MeetingFooterState {
        MeetingFooterState(speakers: speakers)
    }
}

enum MeetingAction: Equatable {
    case reset
    case record
    case didRecord(Result<SpeechRecognizer.Action, SpeechRecognizer.RecognizerError>)
    case stopRecording
    case startScrum
    case didStartScrum(ScrumTimer.Action)
    case stopScrum
    case skipSpeaker(MeetingFooterAction)
    case saveHistory
}

struct MeetingEnvironment {
    let scrumTimer: ScrumTimer
    var player: AVPlayer { AVPlayer.sharedDingPlayer }
    let speechRecognizer: SpeechRecognizer
    let mainQueue: AnySchedulerOf<DispatchQueue>
}

let meetingViewReducer = Reducer<MeetingState, MeetingAction, MeetingEnvironment> { state, action, environment in
    switch action {
    case .reset:
        return environment.scrumTimer.reset(lengthInMinutes: state.scrum.lengthInMinutes,
                                            attendees: state.scrum.attendees)
            .fireAndForget()
        
    case .skipSpeaker:
        return environment.scrumTimer
            .skipSpeaker()
            .fireAndForget()
        
    case .record:
        state.isRecording = true
        return environment.speechRecognizer
            .record()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(MeetingAction.didRecord)
        
    case let .didRecord(.success(action)):
        state.transcript = action.speech
        return .none
        
    case let .didRecord(.failure(errorDescription)):
        state.transcript = ""
        return .none
        
    case .stopRecording:
        state.isRecording = false
        return environment.speechRecognizer.stopRecording()
            .fireAndForget()
        
    case .startScrum:
        return environment.scrumTimer.startScrum()
            .map(MeetingAction.didStartScrum)
        
    case .didStartScrum(let action):
        switch action {
        case .didChangeActiveSpeaker:
            state.speakers = environment.scrumTimer.speakers
            return .none
            
        case .speakerChangedAction:
            return .fireAndForget {
                environment.player.seek(to: .zero)
                environment.player.play()
            }
            
        case .didChangeSecondsElapsed(let seconds):
            state.secondsElapsed = seconds
            return .none
            
        case .didChangeSecondsRemaining(let seconds):
            state.secondsRemaining = seconds
            return .none
            
        case .skipSpeaker:
            return .init(value: MeetingAction.skipSpeaker(.skipSpeaker))
        }
        
    case .stopScrum:
        return environment.scrumTimer.stopScrum()
            .fireAndForget()
        
    case .saveHistory:
        let newHistory = History(attendees: state.scrum.attendees,
                                 lengthInMinutes: state.secondsElapsed / 60,
                                 transcript: state.transcript)
        state.scrum.history.insert(newHistory, at: 0)
        return .none
    }
}

let meetingViewEnvironment: (AnySchedulerOf<DispatchQueue>) -> MeetingEnvironment = { mainQueue in
    MeetingEnvironment(scrumTimer: ScrumTimer(),
                       speechRecognizer: SpeechRecognizer(),
                       mainQueue: mainQueue)
}

struct MeetingView: View {
    
    let store: Store<MeetingState, MeetingAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                RoundedRectangle(cornerRadius: 16.0)
                    .fill(viewStore.scrum.color)
                VStack {
                    MeetingHeaderView(secondsElapsed: viewStore.secondsElapsed,
                                      secondsRemaining: viewStore.secondsRemaining,
                                      scrumColor: viewStore.scrum.color)
                    MeetingTimerView(speakers: viewStore.speakers,
                                     isRecording: viewStore.isRecording,
                                     scrumColor: viewStore.scrum.color)
                    MeetingFooterView(store: store.scope(state: \.meetingFooterState,
                                                         action: MeetingAction.skipSpeaker))
                }
            }
            .padding()
            .foregroundColor(viewStore.scrum.color.accessibleFontColor)
            .onAppear {
                viewStore.send(.reset)
                viewStore.send(.record)
                viewStore.send(.startScrum)
            }
            .onDisappear {
                viewStore.send(.stopScrum)
                viewStore.send(.stopRecording)
            }
        }
    }
}

struct MeetingView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingView(store: Store<MeetingState, MeetingAction>(initialState: MeetingState(scrum: DailyScrum.data[0]),
                                                              reducer: meetingViewReducer,
                                                              environment:
                                                                meetingViewEnvironment(DispatchQueue.main.eraseToAnyScheduler()))
        )
    }
}
