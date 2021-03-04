/*
 See LICENSE folder for this sample’s licensing information.
 */

import SwiftUI
import ComposableArchitecture

struct EditViewState: Equatable {
    var newAttendee = ""
    var data: DailyScrum.Data
}

enum EditViewAction: Equatable {
    case setTitle(String)
    case setMinutes(Double)
    case setColor(Color)
    case addAttendee
    case deleteAttendee(indices: IndexSet)
    case clearAttendee
    case setAttendee(String)
}

let editViewReducer = Reducer<EditViewState, EditViewAction, Void> { state, action, environment in
    switch action {
    case .setTitle(let title):
        state.data.title = title
        return .none

    case .setMinutes(let minutes):
        state.data.lengthInMinutes = minutes
        return .none

    case .setColor(let color):
        state.data.color = color
        return .none

    case .addAttendee:
        state.data.attendees.append(state.newAttendee)
        return Effect(value: EditViewAction.clearAttendee)

    case .clearAttendee:
        state.newAttendee = ""
        return .none

    case .setAttendee(let attendee):
        state.newAttendee = attendee
        return .none

    case .deleteAttendee(let indices):
        state.data.attendees.remove(atOffsets: indices)
        return .none
    }
}

struct EditView: View {
    let store: Store<EditViewState, EditViewAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                Section(header: Text("Meeting Info")) {
                    TextField("Title", text: viewStore.binding(
                        get: \.data.title,
                        send: EditViewAction.setTitle
                    ))
                    HStack {
                        Slider(value: viewStore.binding(
                            get: \.data.lengthInMinutes,
                            send: EditViewAction.setMinutes
                        ), in: 5...30, step: 1.0) {
                            Text("Length")
                        }
                        .accessibilityValue(Text("\(Int(viewStore.data.lengthInMinutes)) minutes"))
                        Spacer()
                        Text("\(Int(viewStore.data.lengthInMinutes)) minutes")
                            .accessibilityHidden(true)
                    }
                    ColorPicker("Color", selection: viewStore.binding(
                                    get: \.data.color,
                                    send: EditViewAction.setColor))
                        .accessibilityLabel(Text("Color picker"))
                }
                Section(header: Text("Attendees")) {
                    ForEach(viewStore.data.attendees, id: \.self) { attendee in
                        Text(attendee)
                    }
                    .onDelete { indices in
                        viewStore.send(.deleteAttendee(indices: indices))
                    }
                    HStack {
                        TextField("New Attendee", text: viewStore.binding(
                            get: \.newAttendee,
                            send: EditViewAction.setAttendee
                        ))
                        Button(action: {
                            withAnimation {
                                viewStore.send(.addAttendee)
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .accessibilityLabel(Text("Add attendee"))
                        }
                        .disabled(viewStore.newAttendee.isEmpty)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        EditView(store: Store(initialState: EditViewState(newAttendee: "",
                                                          data: DailyScrum.Data()),
                              reducer: editViewReducer,
                              environment: ()))
    }
}
