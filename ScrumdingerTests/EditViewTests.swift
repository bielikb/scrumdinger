//
//  EditViewTests.swift
//  ScrumdingerTests
//
//  Created by Boris Bielik on 05/03/2021.
//

import XCTest
import ComposableArchitecture
import Combine
import SwiftUI

@testable import Scrumdinger

class EditViewTests: XCTestCase {

    func testItEditsScrumTitle() {
        // given
        let newTitle = "New Title"
        let data = DailyScrum.testData

        var expectedData = DailyScrum.testData
        expectedData.title = newTitle

        let store = TestStore(initialState: EditViewState(newAttendee: "", data: data),
                              reducer: editViewReducer,
                              environment: ())
        store.assert(
            // when
            .send(.setTitle(newTitle)) {

                // then
                $0.data = expectedData
            }
        )
    }

    func testItEditsScrumLength() {
        // given
        let length = 10.0
        let data = DailyScrum.testData

        var expectedData = DailyScrum.testData
        expectedData.lengthInMinutes = length

        let store = TestStore(initialState: EditViewState(newAttendee: "", data: data),
                              reducer: editViewReducer,
                              environment: ())

        store.assert(
            // when
            .send(.setMinutes(length)) {

                // then
                $0.data = expectedData
            }
        )
    }

    func testItEditsScrumColor() {
        // given
        let color = Color("Design")
        let data = DailyScrum.testData

        var expectedData = DailyScrum.testData
        expectedData.color = color

        let store = TestStore(initialState: EditViewState(newAttendee: "", data: data),
                              reducer: editViewReducer,
                              environment: ())
        store.assert(
            // when
            .send(.setColor(color)) {

                // then
                $0.data = expectedData
            }
        )
    }

    func testItAddsAttendee() {
        // given
        let attendee = "John Doe"
        let data = DailyScrum.testData

        var updatedData = DailyScrum.testData
        updatedData.attendees = [attendee]

        let store = TestStore(initialState: EditViewState(newAttendee: "", data: data),
                              reducer: editViewReducer,
                              environment: ())

        store.assert(
            // when
            .send(.setAttendee(attendee)) {

                // then
                $0.data = data
                $0.newAttendee = attendee
            },
            // when
            .send(.addAttendee) {

                // then
                $0.data = updatedData
            },
            .receive(.clearAttendee) {

                // then
                $0.data = updatedData
                $0.newAttendee = ""
            }
        )
    }

    func testItDeletesExistingAttendee() {
        // given
        let attendee = "John Doe"
        var data = DailyScrum.testData
        data.attendees = [attendee]

        let store = TestStore(initialState: EditViewState(newAttendee: "", data: data),
                              reducer: editViewReducer,
                              environment: ())

        store.assert(
            // when
            .send(.deleteAttendee(indices: IndexSet(integer: 0))) {
                // then
                $0.data = DailyScrum.testData
                $0.newAttendee = ""
            }
        )
    }
}

extension DailyScrum {
    static var testData: DailyScrum.Data {
        var data = DailyScrum.Data()
        data.color = .accentColor
        return data
    }
}
