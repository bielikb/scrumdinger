//
//  MeetingFooterViewTests.swift
//  ScrumdingerTests
//
//  Created by Boris Bielik on 06/03/2021.
//

import XCTest
import ComposableArchitecture
import Combine
import SwiftUI

@testable import Scrumdinger

class MeetingFooterViewTests: XCTestCase {
    func testSkipAction() {
        let state = MeetingFooterState(speakers: [ScrumTimer.Speaker(name: "John Doe",
                                                                     isCompleted: false)])
        let store = TestStore(initialState: state,
                              reducer: Reducer<MeetingFooterState, MeetingFooterAction, Void>.empty,
                              environment: ())

        store.assert(
            .send(.skipSpeaker) {
                $0 = state
            }
        )
    }
}
