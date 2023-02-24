//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 03.12.2021.
//

import XCTest
@testable import PureduxStore

final class RootStoreRefCyclesTests: XCTestCase {
    let timeout: TimeInterval = 3

    func test_WhenGetStore_ThenNoStrongRefToRootStore() {
        weak var rootStore: RootStore<TestState, Action>? = nil
        var store: Store<TestState, Action>? = nil

        autoreleasepool {
            let strongRootStore = RootStore<TestState, Action>(
                initialState: TestState(currentIndex: 1)) { state, action  in

                state.reduce(action: action)
            }

            store = strongRootStore.store()
            rootStore = strongRootStore
        }

        XCTAssertNil(rootStore)
        XCTAssertNotNil(store)
    }
}

extension RootStoreRefCyclesTests {
    static var allTests = [
        ("test_WhenGetStore_ThenNoStrongRefToRootStore",
         test_WhenGetStore_ThenNoStrongRefToRootStore)
    ]
}
