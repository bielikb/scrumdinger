/*
 See LICENSE folder for this sample’s licensing information.
 */

import SwiftUI
import ComposableArchitecture

struct AppState: Equatable {
    var scrumsState: ScrumsViewState
    var scrums: [DailyScrum] {
        scrumsState.scrums.map(\.scrum)
    }
}

enum AppAction: Equatable {
    case loadScrums
    case didLoadScrums(Result<[DailyScrum], ScrumData.Error>)
    case saveScrums
    case didSaveScrums(Result<Bool, ScrumData.Error>)
    case updateScrumsState(ScrumsViewAction)
}

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let scrumData: ScrumData
    let scrumsViewEnvironment: ScrumsViewEnvironment
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
    scrumsReducer.pullback(state: \AppState.scrumsState,
                           action: /AppAction.updateScrumsState,
                           environment: \.scrumsViewEnvironment),
    Reducer { state, action, environment in
        switch action {
        case .loadScrums:
            return environment.scrumData.load()
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(AppAction.didLoadScrums)
            
        case let .didLoadScrums(.success(dailyScrums)):
            let scrumStates = dailyScrums
                .map { MeetingState(scrum: $0) }
                .map { DetailViewState(meetingState: $0) }

            state.scrumsState = ScrumsViewState(scrums: scrumStates)
            return .none
            
        case let .didLoadScrums(.failure(error)):
            return .none
            
        case .saveScrums:
            return environment.scrumData.save(scrums: state.scrums)
                .receive(on: environment.mainQueue)
                .catchToEffect()
                .map(AppAction.didSaveScrums)
            
        case .didSaveScrums:
            return .none
            
        case .updateScrumsState:
            return .none
        }
    }
)

let appEnvironment: AppEnvironment = {
    let mainQueue: AnySchedulerOf<DispatchQueue> = DispatchQueue.main.eraseToAnyScheduler()
    return AppEnvironment(mainQueue: mainQueue,
                          scrumData: ScrumData(global: DispatchQueue.global().eraseToAnyScheduler(),
                                               fileManager: FileManager.default,
                                               initialData: DailyScrum.data),
                          scrumsViewEnvironment: scrumsViewEnvironment(mainQueue))
}()

@main
struct ScrumdingerApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    var store: Store<AppState, AppAction> = {
        return Store(initialState: AppState(scrumsState: ScrumsViewState()),
                     reducer: appReducer,
                     environment: appEnvironment)
    }()
    
    var body: some Scene {
        WindowGroup {
            WithViewStore(store) { viewStore in
                NavigationView {
                    ScrumsView(store: store.scope(state: \.scrumsState,
                                                  action: AppAction.updateScrumsState))
                }
                .onAppear {
                    viewStore.send(.loadScrums)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .inactive {
                        viewStore.send(.saveScrums)
                    }
                }
            }
        }
    }
}
