/*
 See LICENSE folder for this sample’s licensing information.
 */

import SwiftUI
import ComposableArchitecture

struct MeetingFooterState: Equatable {
    var speakers: [ScrumTimer.Speaker]

    var speakerNumber: Int? {
        guard let index = speakers.firstIndex(where: { !$0.isCompleted }) else { return nil }
        return index + 1
    }

    var isLastSpeaker: Bool {
        return speakers.dropLast().allSatisfy { $0.isCompleted }
    }

    var speakerText: String {
        guard let speakerNumber = speakerNumber else { return "No more speakers" }
        return "Speaker \(speakerNumber) of \(speakers.count)"
    }
}

enum MeetingFooterAction: Equatable {
    case skipSpeaker
}

struct MeetingFooterView: View {

    let store: Store<MeetingFooterState, MeetingFooterAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                HStack {
                    if viewStore.isLastSpeaker {
                        Text("Last Speaker")
                    } else {
                        Text(viewStore.speakerText)
                        Spacer()
                        Button(action: { viewStore.send(.skipSpeaker) } ) {
                            Image(systemName: "forward.fill")
                        }
                        .accessibility(label: Text("Next speaker"))
                    }
                }
            }
            .padding([.bottom, .horizontal])
        }
    }
}

struct MeetingFooterView_Previews: PreviewProvider {
    static var speakers = [ScrumTimer.Speaker(name: "Kim", isCompleted: false), ScrumTimer.Speaker(name: "Bill", isCompleted: false)]
    static var previews: some View {
        MeetingFooterView(store: Store<MeetingFooterState, MeetingFooterAction>(initialState: MeetingFooterState(speakers: speakers),
                                                                                reducer: .empty,
                                                                                environment: ()))
            .previewLayout(.sizeThatFits)
    }
}
