//
//  NonRxStoreTests.swift
//  ArchExamplesTests
//
//  Created by Trevor Beasty on 1/18/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import XCTest
@testable import ArchExamples

enum MockState: Equatable { }
enum MockIntent: Equatable { }
enum MockChange: Equatable { }

class MockReducer<State, Intent, Change>: ReducerType {
    
    var _handler: ReduceIntent!
    
    func reduceIntent(_ intent: Intent, getState: () -> State, emitChange: @escaping (Change) -> Void) {
        _handler(intent, getState, emitChange)
    }
    
}

class NonRxStoreTests: XCTestCase {
    
    var subject: Store!
    var intentReducer: IntentReducer!
    var changeReducer: ChangeReducer!
    
    typealias IntentReducer = MockReducer<MockState, MockIntent, MockChange>
    typealias Store = NonRxStore<IntentReducer>
    typealias ChangeReducer = Store.ChangeReducer
    
    private func setUpWith(initialState: IntentReducer.State, reduceIntent: @escaping IntentReducer.ReduceIntent, changeReducer: @escaping ChangeReducer) {
        intentReducer = MockReducer<MockState, MockIntent, MockChange>()
        intentReducer._handler = reduceIntent
        self.changeReducer = changeReducer
        subject = Store(initialState: initialState, reducer: intentReducer, reduceChange: changeReducer)
    }

    override func tearDown() {
        
    }



}
