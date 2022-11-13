//
//  File.swift
//  
//
//  Created by Sergey Kazakov on 13.11.2022.
//

import XCTest
@testable import PureduxStore

final class DetachedStoreDispatchActionsTests: XCTestCase {
    let timeout: TimeInterval = 10

    func test_WhenDispatchedToMainStore_ThenNotReducedOnDetachedStore() {
        let actionsCount = 100

        let unexpected = (0..<actionsCount).map {
            let exp = XCTestExpectation(description: "index \($0)")
            exp.isInverted = true
            return exp
        }

        let mainStore = MainStore<TestState, Action>(
            initialState: TestState(currentIndex: 0),
            reducer: { state, action  in
                state.reduce(action: action)
            }
        )

        let detachedStore = mainStore.detachedStore(
            initialState: DetachedTestState(currentIndex: 0),
            stateMapping: { rootState, detachedState in
                StateComposition(state: rootState, detachedState: detachedState)
            },
            reducer: { state, action  in
                state.reduce(action: action)
                guard let action = (action as? UpdateIndex) else {
                    return
                }

                unexpected[action.index].fulfill()
            }
        )

        let actions = (0..<actionsCount).map { UpdateIndex(index: $0) }
        let store = mainStore.store()
        actions.forEach { store.dispatch($0) }

        wait(for: unexpected, timeout: timeout, enforceOrder: true)
    }

    func test_WhenDispatchedToDetachedStoreA_ThenNotReducedOnDetachedStoreB() {
        let actionsCount = 100
        let expectations = (0..<actionsCount).map {
            XCTestExpectation(description: "index \($0)")
        }
        let unexpected = (0..<actionsCount).map {
            let exp = XCTestExpectation(description: "index \($0)")
            exp.isInverted = true
            return exp
        }

        let mainStore = MainStore<TestState, Action>(
            initialState: TestState(currentIndex: 0),
            reducer: { state, action  in
                state.reduce(action: action)
            }
        )

        let detachedStoreA = mainStore.detachedStore(
            initialState: DetachedTestState(currentIndex: 0),
            stateMapping: { rootState, detachedState in
                StateComposition(state: rootState, detachedState: detachedState)
            },
            reducer: { state, action  in
                state.reduce(action: action)
                guard let action = (action as? UpdateIndex) else {
                    return
                }

                expectations[action.index].fulfill()
            }
        )

        let detachedStoreB = mainStore.detachedStore(
            initialState: DetachedTestState(currentIndex: 0),
            stateMapping: { rootState, detachedState in
                StateComposition(state: rootState, detachedState: detachedState)
            },
            reducer: { state, action  in
                state.reduce(action: action)
                guard let action = (action as? UpdateIndex) else {
                    return
                }

                unexpected[action.index].fulfill()
            }
        )

        let actions = (0..<actionsCount).map { UpdateIndex(index: $0) }
        actions.forEach { detachedStoreA.dispatch($0) }

        wait(for: unexpected, timeout: timeout, enforceOrder: true)
        wait(for: expectations, timeout: timeout, enforceOrder: true)
    }

    func test_WhenDispatchedToDetachedStore_ThenReducedOnMainStore() {
        let actionsCount = 100
        let expectations = (0..<actionsCount).map {
            XCTestExpectation(description: "index \($0)")
        }

        let mainStore = MainStore<TestState, Action>(
            initialState: TestState(currentIndex: 0),
            reducer: { state, action  in
                state.reduce(action: action)
                guard let action = (action as? UpdateIndex) else {
                    return
                }

                expectations[action.index].fulfill()
            }
        )

        let detachedStore = mainStore.detachedStore(
            initialState: DetachedTestState(currentIndex: 0),
            stateMapping: { rootState, detachedState in
                StateComposition(state: rootState, detachedState: detachedState)
            },
            reducer: { state, action  in
                state.reduce(action: action)
            }
        )

        let actions = (0..<actionsCount).map { UpdateIndex(index: $0) }
        actions.forEach { detachedStore.dispatch($0) }

        wait(for: expectations, timeout: timeout, enforceOrder: true)
    }

    func test_WhenDispatchedToDetachedStore_ThenReducenOnDetachedStore() {
        let actionsCount = 100
        let expectations = (0..<actionsCount).map {
            XCTestExpectation(description: "index \($0)")
        }

        let mainStore = MainStore<TestState, Action>(
            initialState: TestState(currentIndex: 0),
            reducer: { state, action  in
                state.reduce(action: action)
            }
        )

        let detachedStore = mainStore.detachedStore(
            initialState: DetachedTestState(currentIndex: 0),
            stateMapping: { rootState, detachedState in
                StateComposition(state: rootState, detachedState: detachedState)
            },
            reducer: { state, action  in
                state.reduce(action: action)
                guard let action = (action as? UpdateIndex) else {
                    return
                }

                expectations[action.index].fulfill()
            }
        )

        let actions = (0..<actionsCount).map { UpdateIndex(index: $0) }
        actions.forEach { detachedStore.dispatch($0) }

        wait(for: expectations, timeout: timeout, enforceOrder: true)
    }

}