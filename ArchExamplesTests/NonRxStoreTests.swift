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
enum MockOutput: Equatable {
    case A
    case B
    case C
}

class MockReducer<State, Intent, Change>: ReducerType {

    var _handler: ReduceIntent!

    func reduceIntent(_ intent: Intent, state: State, emitChange: @escaping (Change) -> Void) {
        _handler(intent, state, emitChange)
    }

}

class NonRxStoreTests: XCTestCase {

    var subject: Store!
    var queue: DispatchQueue!
    var stateSequence: [IntentReducer.State]!

    typealias IntentReducer = MockReducer<MockState, MockIntent, MockChange>
    typealias Store = NonRxStore<IntentReducer>
    typealias ChangeReducer = Store.ChangeReducer
    typealias ModuleHook = Store.ModuleHook
    
    private func setUpWith(
        initialState: IntentReducer.State,
        reduceIntent: @escaping IntentReducer.ReduceIntent = { _, _, _ in return },
        changeReducer: @escaping ChangeReducer = { _, _ in return MockState.A }
        )
    {
        queue = DispatchQueue.main
        stateSequence = []
        let intentReducer = MockReducer<MockState, MockIntent, MockChange>()
        intentReducer._handler = reduceIntent
        subject = Store(initialState: initialState, reducer: intentReducer, reduceChange: changeReducer, stateQueue: queue)
        subject.observeState({ state in self.stateSequence.append(state) })
    }
    
    override func tearDown() {
        subject = nil
        super.tearDown()
    }
    
    
    // MARK: - Internal
    
    func test_Observing_EmitsInitialState() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { _, _, emitChange in return emitChange(MockChange.A) },
            changeReducer: { _, state in return state }
        )
        
        // when
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
                self.emitDelayedChange({ emitChange(MockChange.A) }, delay: 0.3)
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
    
    func test_GivenMapping_WhenImmediateAndDelayedReduceIntent_StateInDelayedChangeIsNotMutated() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { _, state, emitChange in
                // Given that change A produces state B, the state must necessarily be state B following change A. We do
                // not have read access to this new state immediately following the synchronous change. We will only ever be aware of the state at the
                // moment of the intent. This greatly reduces complexity - if we were able to synchronously
                // read state, () -> State, we open the door to more complex business logic based on the new state following a
                // synchronous mutation. Consider:
                //                let readState: () -> MockState = { fatalError() }
                //                XCTAssertEqual(readState(), MockState.A)
                //                emitChange(MockChange.A)
                //                XCTAssertEqual(readState(), MockState.B)
                emitChange(MockChange.A)
                XCTAssertEqual(state, MockState.A)
                
                self.emitDelayedChange(
                    {
                        // Similarly, we cannot read mutated state at the moment of a delayed change, which would require
                        // @escaping () -> State.
                        XCTAssertEqual(state, MockState.A)
                        emitChange(MockChange.B)
                },
                    delay: 0.3)
        },
            changeReducer: { change, _ in
                switch change {
                case .A:
                    return MockState.B
                case .B:
                    return MockState.C
                case .C:
                    fatalError()
                }
        }
        )
        clearStateSequence()
        
        // when
        subject.dispatchIntent(MockIntent.A)
        exhaustQueue(maxDelay: 0.3)
    }
    
    func test_GivenDelayedReduceIntentA_WhenIntentAThenIntenB_IgnoresDelayedChange() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { intent, _, emitChange in
                switch intent {
                case .A:
                    self.emitDelayedChange({ emitChange(MockChange.A) }, delay: 0.3)
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
    
    func test_GivenMapping_WhenImmediateIntents_ExpectedStateBehavior() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { intent, state, emitChange in
                switch intent {
                case .A:
                    XCTAssertEqual(state, MockState.A)
                    emitChange(MockChange.A)
                case .B:
                    XCTAssertEqual(state, MockState.B)
                    emitChange(MockChange.B)
                case .C:
                    fatalError()
                }
                
        },
            changeReducer: { change, _ in
                switch change {
                case .A:
                    return MockState.B
                case .B:
                    return MockState.C
                case .C:
                    fatalError()
                }
        })
        clearStateSequence()
        
        // when
        subject.dispatchIntent(MockIntent.A)
        subject.dispatchIntent(MockIntent.B)
        exhaustQueue()
        
        
        // then
        XCTAssertEqual(stateSequence, [MockState.B, MockState.C])
    }
    
    func test_GivenMapping_WhenDelayedIntents_ExpectedStateBehavior() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { intent, state, emitChange in
                switch intent {
                case .A:
                    XCTAssertEqual(state, MockState.A)
                    self.emitDelayedChange({ emitChange(MockChange.A) }, delay: 0.3)
                case .B:
                    XCTAssertEqual(state, MockState.A)
                    emitChange(MockChange.B)
                case .C:
                    fatalError()
                }
                
        },
            changeReducer: { change, _ in
                switch change {
                case .A:
                    return MockState.B
                case .B:
                    return MockState.C
                case .C:
                    fatalError()
                }
        })
        clearStateSequence()
        
        // when
        subject.dispatchIntent(MockIntent.A)
        subject.dispatchIntent(MockIntent.B)
        exhaustQueue()
        
        
        // then
        XCTAssertEqual(stateSequence, [MockState.C])
    }
    
    // MARK: Module Hooks
    
    func test_GivenModuleHook_WhenIntent_ModuleHookExecuted() {
        // given
        setUpWith(initialState: MockState.A)
        
        let moduleHook: ModuleHook = { intent, state, _ in
            // then
            XCTAssertEqual(intent, MockIntent.A)
            XCTAssertEqual(state, MockState.A)
        }
        
        // when
        subject.hookIn(moduleHook)
        subject.dispatchIntent(MockIntent.A)
        exhaustQueue()
    }
    
    func test_GivenMappingAndModuleHook_WhenIntent_ModuleHookImmediateChangeExecuted() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { _, _, _ in return },
            changeReducer: { change, state in
                switch change {
                case .A:
                    return MockState.B
                default:
                    fatalError()
                }
        })
        clearStateSequence()
        
        let moduleHook: ModuleHook = { _, _, emitChange in emitChange(MockChange.A) }
        
        // when
        subject.hookIn(moduleHook)
        subject.dispatchIntent(MockIntent.A)
        exhaustQueue()
        
        // then
        XCTAssertEqual(stateSequence, [MockState.B])
    }
    
    func test_GivenMappingAndModuleHook_WhenIntent_ModuleHookDelayedChangeExecuted() {
        // given
        setUpWith(
            initialState: MockState.A,
            reduceIntent: { _, _, _ in return },
            changeReducer: { change, state in
                switch change {
                case .A:
                    return MockState.B
                default:
                    fatalError()
                }
        })
        clearStateSequence()
        
        let moduleHook: ModuleHook = { _, _, emitChange in self.emitDelayedChange({ emitChange(MockChange.A) }, delay: 0.3) }
        
        // when
        subject.hookIn(moduleHook)
        subject.dispatchIntent(MockIntent.A)
        exhaustQueue(maxDelay: 0.3)
        
        // then
        XCTAssertEqual(stateSequence, [MockState.B])
    }

}

extension NonRxStoreTests {
    
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
    
    private func emitDelayedChange(_ emitChange: @escaping () -> Void, delay: Double) {
        queue.asyncAfter(
            deadline: .now() + delay,
            execute: emitChange
        )
    }
    
}
