//
//  ScrumdingerAppTests.swift
//  ScrumdingerTests
//
//  Created by Boris Bielik on 06/03/2021.
//

import XCTest
import ComposableArchitecture
import Combine
import SwiftUI

@testable import Scrumdinger

//class ScrumdingerAppTests: XCTestCase {
//
//    let scheduler = DispatchQueue.testScheduler
//    let globalScheduler = DispatchQueue.testScheduler
//
//    func testItLoadsScrums() {
//        let mainQueue = self.scheduler.eraseToAnyScheduler()
//        let testData = DailyScrum.testData
//        let state = AppState(scrumsState: ScrumsViewState(isPresented: false,
//                                                          scrums: [],
//                                                          editViewState: EditViewState(data: testData)))
//
//        let scrums = DailyScrum.data
//        let store = TestStore(initialState: state,
//                              reducer: appReducer,
//                              environment: AppEnvironment(mainQueue: mainQueue,
//                                                          scrumData: ScrumData(global: globalScheduler.eraseToAnyScheduler(),
//                                                                               fileManager: FileManager.default,
//                                                                               initialData: scrums),
//                                                          scrumsViewEnvironment: scrumsViewEnvironment(mainQueue)))
//
//        store.assert(
//            .send(.loadScrums) {
//                $0 = state
//            },
//            .do { self.globalScheduler.run() },
//            .do { self.scheduler.advance(by: .seconds(1)) },
//            .receive(.didLoadScrums(.success(testData))) { _ in
//                //$0.scrumsState = expectedScrumsState
//            }
//        )
//    }
//
//}
