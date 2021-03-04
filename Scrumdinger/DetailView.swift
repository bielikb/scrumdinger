/*
 See LICENSE folder for this sample’s licensing information.
 */

import SwiftUI
import ComposableArchitecture

struct DetailViewState: Equatable, Identifiable {
    var id: UUID { scrum.id }
    var isPresented = false
    var meetingState: MeetingState
    var editViewState: EditViewState

    init(meetingState: MeetingState) {
        self.meetingState = meetingState
        self.editViewState = EditViewState(data: meetingState.scrum.data)
    }
}

extension DetailViewState {
    var scrum: DailyScrum {
        meetingState.scrum
    }
}

enum DetailViewAction: Equatable {
    case setIsPresented(Bool)
    case editTapped
    case editAction(EditViewAction)
    case cancelTapped
    case doneTapped(DailyScrum.Data)
    case meetingAction(MeetingAction)
}

struct DetailViewEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let meetingViewEnvironment: MeetingEnvironment
}

let detailViewReducer = Reducer<DetailViewState, DetailViewAction, DetailViewEnvironment>.combine(
    meetingViewReducer.pullback(state: \DetailViewState.meetingState,
                                action: /DetailViewAction.meetingAction,
                                environment: { $0.meetingViewEnvironment }),
    editViewReducer.pullback(state: \DetailViewState.editViewState,
                             action: /DetailViewAction.editAction,
                             environment: { _ in }),
    Reducer { state, action, _ in
        switch action {
        case .setIsPresented(let isPresented):
            state.isPresented = isPresented
            return .none

        case .editTapped:
            state.editViewState = EditViewState(data: state.scrum.data)
            return Effect(value: .setIsPresented(true))

        case .doneTapped(let data):
            state.meetingState.scrum.update(from: data)
            return Effect(value: .setIsPresented(false))

        case .cancelTapped:
            return Effect(value: .setIsPresented(false))

        case .editAction,
             .meetingAction:
            return .none
        }
    }
)

let detailViewEnvironment: (AnySchedulerOf<DispatchQueue>) -> DetailViewEnvironment = { mainQueue in
    DetailViewEnvironment(mainQueue: mainQueue,
                          meetingViewEnvironment: meetingViewEnvironment(mainQueue))
}

struct DetailView: View {

    let store: Store<DetailViewState, DetailViewAction>

    var body: some View {
        WithViewStore(store) { (viewStore: ViewStore<DetailViewState, DetailViewAction>) in
            List {
                Section(header: Text("Meeting Info")) {
                    NavigationLink(destination: MeetingView(store: store.scope(state: \.meetingState,
                                                                               action: DetailViewAction.meetingAction))) {
                        Label("Start Meeting", systemImage: "timer")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                            .accessibilityLabel(Text("Start meeting"))
                    }
                    HStack {
                        Label("Length", systemImage: "clock")
                            .accessibilityLabel(Text("Meeting length"))
                        Spacer()
                        Text("\(viewStore.scrum.lengthInMinutes) minutes")
                    }
                    HStack {
                        Label("Color", systemImage: "paintpalette")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(viewStore.scrum.color)
                    }
                    .accessibilityElement(children: .ignore)
                }
                Section(header: Text("Attendees")) {
                    ForEach(viewStore.scrum.attendees, id: \.self) { attendee in
                        Label(attendee, systemImage: "person")
                            .accessibilityLabel(Text("Person"))
                            .accessibilityValue(Text(attendee))
                    }
                }
                Section(header: Text("History")) {
                    if viewStore.scrum.history.isEmpty {
                        Label("No meetings yet", systemImage: "calendar.badge.exclamationmark")
                    }
                    ForEach(viewStore.scrum.history) { history in
                        NavigationLink(
                            destination: HistoryView(history: history)) {
                            HStack {
                                Image(systemName: "calendar")
                                Text(history.date, style: .date)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarItems(trailing: Button("Edit") {
                viewStore.send(.editTapped)
            })
            .navigationTitle(viewStore.scrum.title)
            .fullScreenCover(isPresented: viewStore.binding(get: \.isPresented,
                                                            send: DetailViewAction.setIsPresented)) {
                NavigationView {
                    EditView(store: store.scope(state: \.editViewState,
                                                action: DetailViewAction.editAction))
                        .navigationTitle(viewStore.scrum.title)
                        .navigationBarItems(leading: Button("Cancel") {
                            viewStore.send(.cancelTapped)
                        }, trailing: Button("Done") {
                            viewStore.send(.doneTapped(viewStore.editViewState.data))
                        })
                }
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            DetailView(store: Store<DetailViewState, DetailViewAction>(initialState: DetailViewState(meetingState: MeetingState(scrum: DailyScrum.data[0])),
                                                                       reducer: detailViewReducer,
                                                                       environment: detailViewEnvironment(DispatchQueue.main.eraseToAnyScheduler())))
        }
    }
}
