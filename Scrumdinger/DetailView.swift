/*
 See LICENSE folder for this sample’s licensing information.
 */

import SwiftUI
import ComposableArchitecture

struct DetailViewState: Equatable {
    var scrum: DailyScrum
    var isPresented = false
    var editView = EditViewState(data: DailyScrum.Data())
}

enum DetailViewAction: Equatable {
    case meeting(DailyScrum)
    case setIsPresented(Bool)
    case editTapped
    case editAction(EditViewAction)
    case cancelTapped
    case doneTapped(DailyScrum.Data)
}

struct DetailViewEnvironment {}

let detailViewReducer = Reducer<DetailViewState, DetailViewAction, DetailViewEnvironment>.combine(
    editViewReducer.pullback(state: \DetailViewState.editView,
                             action: /DetailViewAction.editAction,
                             environment: { _ in EditViewEnvironment() }),
    Reducer { state, action, _ in
        switch action {
        case .meeting(let scrum):
            state.scrum = scrum
            return .none
        case .setIsPresented(let isPresented):
            state.isPresented = isPresented
            return .none
        case .editTapped:
            state.editView = EditViewState(data: state.scrum.data)
            return Effect(value: .setIsPresented(true))
        case .doneTapped(let data):
            state.scrum.update(from: data)
            return Effect(value: .setIsPresented(false))
        case .cancelTapped:
            return Effect(value: .setIsPresented(false))
        case .editAction:
            return .none
        }
    }
)

struct DetailView: View {

    let store: Store<DetailViewState, DetailViewAction>

    var body: some View {
        WithViewStore(self.store) { (viewStore: ViewStore<DetailViewState, DetailViewAction>) in
            List {
                Section(header: Text("Meeting Info")) {
                    NavigationLink(
                        destination: MeetingView(scrum: viewStore.binding(
                                                    get: \.scrum,
                                                    send: DetailViewAction.meeting))) {
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
                    EditView(store: self.store.scope(state: \.editView,
                                                     action: DetailViewAction.editAction))
                        .navigationTitle(viewStore.scrum.title)
                        .navigationBarItems(leading: Button("Cancel") {
                            viewStore.send(.cancelTapped)
                        }, trailing: Button("Done") {
                            viewStore.send(.doneTapped(viewStore.editView.data))
                        })
                }
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailView(store: Store<DetailViewState, DetailViewAction>(initialState: DetailViewState(scrum: DailyScrum.data[0]),
                                                                       reducer: detailViewReducer,
                                                                       environment: DetailViewEnvironment()))
        }
    }
}
