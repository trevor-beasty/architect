//
//  NonRxStore.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/17/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

protocol ReducerType: AnyObject {
    associatedtype State
    associatedtype Intent
    associatedtype Change
    
    func reduceIntent(_ intent: Intent, getState: () -> State, emitChange: @escaping (Change) -> Void)
}

class NonRxStore<State, Intent, Change, IntentReducer: ReducerType>
where IntentReducer.State == State, IntentReducer.Intent == Intent, IntentReducer.Change == Change {
    
    private(set) var state: State {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.observers.forEach({ $0(strongSelf.state) })
            }
        }
    }
    private var observers: [(State) -> Void] = []
    
    let intentReducer: IntentReducer
    let reduceChange: ChangeReducer
    
    typealias ChangeReducer = (Change, () -> State) -> State
    
    init(initialState: State, intentReducer: IntentReducer, reduceChange: @escaping ChangeReducer) {
        self.state = initialState
        self.intentReducer = intentReducer
        self.reduceChange = reduceChange
    }
    
    func observe(_ observer: @escaping (State) -> Void) {
        observers.append(observer)
        observer(state)
    }
    
    func dispatchIntent(_ intent: Intent) {
        intentReducer.reduceIntent(intent, getState: { return self.state }, emitChange: { self.handleChange($0) })
    }
    
    private func handleChange(_ change: Change) {
        let newState = reduceChange(change, { return self.state })
        state = newState
    }
    
}
