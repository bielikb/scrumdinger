/*
 See LICENSE folder for this sample’s licensing information.
 */

import SwiftUI
import ComposableArchitecture

struct ScrumsViewState: Equatable {
    var isPresented = false
    var scrums: [DetailViewState] = []
    var editViewState = EditViewState(data: DailyScrum.Data())
}

enum ScrumsViewAction: Equatable {
    case addScrum
    case detailView(index: Int, action: DetailViewAction)
    case editAction(EditViewAction)
    case presentSheet(Bool)
    case dismiss
}

struct ScrumsViewEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let detailViewEnvironment: DetailViewEnvironment
}

let scrumsReducer = Reducer<ScrumsViewState, ScrumsViewAction, ScrumsViewEnvironment>.combine(
    editViewReducer.pullback(state: \ScrumsViewState.editViewState,
                             action: /ScrumsViewAction.editAction,
                             environment: { _ in }),
    detailViewReducer.forEach(state: \ScrumsViewState.scrums,
                              action: /ScrumsViewAction.detailView(index:action:),
                              environment: \.detailViewEnvironment),
    Reducer { state, action, environment in
        switch action {
        case .presentSheet(let isPresented):
            state.isPresented = isPresented
            return .none

        case .dismiss:
            return .init(value: .presentSheet(false))

        case .addScrum:
            let newScrumData = state.editViewState.data
            let newScrum = DailyScrum(title: newScrumData.title,
                                      attendees: newScrumData.attendees,
                                      lengthInMinutes: Int(newScrumData.lengthInMinutes),
                                      color: newScrumData.color)
            state.scrums.append(DetailViewState(meetingState: MeetingState(scrum: newScrum)))
            return .init(value: .presentSheet(false))

        case .detailView,
             .editAction:
            return .none
        }
    }
)

let scrumsViewEnvironment: (AnySchedulerOf<DispatchQueue>) -> ScrumsViewEnvironment = { mainQueue in
    ScrumsViewEnvironment(mainQueue: mainQueue,
                      detailViewEnvironment: detailViewEnvironment(mainQueue))
}

struct ScrumsView: View {

    let store: Store<ScrumsViewState, ScrumsViewAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                ForEachStore(store.scope(state: \.scrums,
                                         action: ScrumsViewAction.detailView(index:action:))) { store in
                    WithViewStore(store) { detailViewStore in
                        NavigationLink(destination: DetailView(store: store)) {
                            CardView(scrum: detailViewStore.scrum)
                        }
                        .listRowBackground(detailViewStore.scrum.color)
                    }
                }
            }
            .navigationTitle("Daily Scrums")
            .navigationBarItems(trailing: Button(action: {
                viewStore.send(.presentSheet(true))
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: viewStore.binding(
                    get: \.isPresented,
                    send: ScrumsViewAction.presentSheet)
            ) {
                NavigationView {
                    EditView(store: store.scope(state: \.editViewState,
                                                action: ScrumsViewAction.editAction))
                        .navigationBarItems(leading: Button("Dismiss") {
                            viewStore.send(.presentSheet(false))
                        }, trailing: Button("Add") {
                            viewStore.send(.addScrum)
                        })
                }
            }

        }
    }
}

struct ScrumsView_Previews: PreviewProvider {
    static var scrumStates: [DetailViewState] {
        DailyScrum.data.map { DetailViewState(meetingState: MeetingState(scrum: $0)) }
    }

    static var previews: some View {
        NavigationView {
            ScrumsView(store: Store<ScrumsViewState, ScrumsViewAction>(initialState: ScrumsViewState(scrums: scrumStates),
                                                               reducer: scrumsReducer,
                                                               environment: scrumsViewEnvironment(DispatchQueue.main.eraseToAnyScheduler())))
        }
    }
}
