//
//  NonRxStoreTests.swift
//  ArchExamplesTests
//
//  Created by Trevor Beasty on 1/18/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import ArchExamples

struct MockState: Equatable { }
struct MockIntent: Equatable { }
struct MockChange: Equatable { }

class MockReducer<State, Intent, Change>: ReducerType {

    var _handler: ReduceIntent!

    func reduceIntent(_ intent: Intent, getState: () -> State, emitChange: @escaping (Change) -> Void) {
        _handler(intent, getState, emitChange)
    }

}

class NonRxStoreTests: XCTestCase {

    var subject: Store!
    var queue: DispatchQueue!
    var stateSequence: [IntentReducer.State]!

    typealias IntentReducer = MockReducer<MockState, MockIntent, MockChange>
    typealias Store = NonRxStore<IntentReducer>
    typealias ChangeReducer = Store.ChangeReducer

    private func setUpWith(initialState: IntentReducer.State, reduceIntent: @escaping IntentReducer.ReduceIntent, changeReducer: @escaping ChangeReducer) {
        queue = DispatchQueue.main
        stateSequence = []
        let intentReducer = MockReducer<MockState, MockIntent, MockChange>()
        intentReducer._handler = reduceIntent
        subject = Store(initialState: initialState, reducer: intentReducer, reduceChange: changeReducer, stateQueue: queue, intentQueue: queue)
        subject.observe({ state in self.stateSequence.append(state) })
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_GivenSingleSyncChange_IntentEvent_EmitsState() {
        // given
        setUpWith(
            initialState: MockState(),
            reduceIntent: { _, _, emitChange in emitChange(MockChange()) },
            changeReducer: { _, _ in return MockState() })
        
        // when
        subject.dispatchIntent(MockIntent())
        let queueExhausted = expectation(description: "queue exhausted")
        queue.async {
            queueExhausted.fulfill()
        }
        waitForExpectations(timeout: 1.0, handler: nil)
        
        // then
        XCTAssertEqual(stateSequence, [MockState()])
    }

}
