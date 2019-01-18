//
//  NonRxStoreTests.swift
//  ArchExamplesTests
//
//  Created by Trevor Beasty on 1/18/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import ArchExamples

enum MockState: Equatable {
    case A
    case B
    case C
}
enum MockIntent: Equatable {
    case A
    case B
    case C
}
enum MockChange: Equatable {
    case A
    case B
    case C
}

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
    
    func test_Observing_EmitsInitialState() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { _, _, emitChange in return emitChange(MockChange.A) },
            changeReducer: { _, _ in return MockState.A }
        )
        clearStateSequence()
        
        // when
        subject.dispatchIntent(MockIntent.A)
        exhaustQueue()
        
        // then
        XCTAssertEqual(stateSequence, [MockState.A])
    }

    func test_GivenImmediateReduceIntent_WhenIntent_EmitsState() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { _, _, emitChange in emitChange(MockChange.A) },
            changeReducer: { _, _ in return MockState.A }
        )
        clearStateSequence()
        
        // when
        subject.dispatchIntent(MockIntent.A)
        exhaustQueue()
        
        // then
        XCTAssertEqual(stateSequence, [MockState.A])
    }
    
    func test_GivenImmediateAndDelayedReduceIntent_WhenIntent_EmitsState() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { _, _, emitChange in
                emitChange(MockChange.A)
                self.queue.asyncAfter(deadline: .now() + 0.3, execute: { emitChange(MockChange.A) })
        },
            changeReducer: { _, _ in return MockState.A }
        )
        clearStateSequence()
        
        // when
        subject.dispatchIntent(MockIntent.A)
        exhaustQueue(maxDelay: 0.3)

        
        // then
        XCTAssertEqual(stateSequence, [MockState.A, MockState.A])
    }
    
    func test_GivenDelayedReduceIntentA_WhenIntentAThenIntenB_IgnoresDelayedChange() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { intent, _, emitChange in
                switch intent {
                case .A:
                    self.queue.asyncAfter(deadline: .now() + 0.3, execute: { emitChange(MockChange.A) })
                case .B:
                    emitChange(MockChange.B)
                case .C:
                    fatalError()
                }
                
        },
            changeReducer: { change, _ in
                switch change {
                case .A:
                    return MockState.A
                case .B:
                    return MockState.B
                case .C:
                    fatalError()
                }
        })
        clearStateSequence()
        
        // when
        subject.dispatchIntent(MockIntent.A)
        subject.dispatchIntent(MockIntent.B)
        exhaustQueue(maxDelay: 0.3)
        
        
        // then
        XCTAssertEqual(stateSequence, [MockState.B])
    }
    
    private func exhaustQueue(_ timeout: Double = 0.001) {
        let queueExhausted = expectation(description: "queue exhausted")
        queue.asyncAfter(deadline: .now() + timeout) {
            queueExhausted.fulfill()
        }
        waitForExpectations(timeout: 1.0 + timeout, handler: nil)
    }
    
    private func exhaustQueue(maxDelay: Double) {
        exhaustQueue(maxDelay + 0.1)
    }
    
    private func clearStateSequence() {
        stateSequence = []
    }

}
