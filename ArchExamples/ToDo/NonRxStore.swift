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
    
    typealias ReduceIntent = (Intent, () -> State, @escaping (Change) -> Void) -> Void
    
    func reduceIntent(_ intent: Intent, getState: () -> State, emitChange: @escaping (Change) -> Void)
}

protocol ObservableType: AnyObject {
    associatedtype Element
    
    typealias E = Element
    
    func observe(_ observer: @escaping (E) -> Void)
}

class FlatMapLatestReducer<Reducer: ReducerType>: ReducerType {
    typealias State = Reducer.State
    typealias Intent = Reducer.Intent
    typealias Change = Reducer.Change
    
    private var flagThreshold = 0
    
    private let reducer: Reducer
    
    init(_ reducer: Reducer) {
        self.reducer = reducer
    }
    
    func reduceIntent(_ intent: Intent, getState: () -> State, emitChange: @escaping (Change) -> Void) {
        // If this function has been invoked since the last invocation, do not send changes emitted from that reduction.
        flagThreshold += 1
        let flag = flagThreshold
        reducer.reduceIntent(intent, getState: getState, emitChange: { [weak self] change in
            guard
                let strongSelf = self,
                flag == strongSelf.flagThreshold
                else { return }
            emitChange(change)
        })
    }
    
}

class NonRxStore<IntentReducer: ReducerType>: ObservableType {
    typealias State = IntentReducer.State
    typealias Intent = IntentReducer.Intent
    typealias Change = IntentReducer.Change
    
    typealias ChangeReducer = (Change, () -> State) -> State
    
    private(set) var state: State {
        didSet {
            stateQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.observers.forEach({ $0(strongSelf.state) })
            }
        }
    }
    private var observers: [(State) -> Void] = []
    
    private let intentReducer: FlatMapLatestReducer<IntentReducer>
    private let reduceChange: ChangeReducer
    
    private let stateQueue: DispatchQueue
    private let intentQueue: DispatchQueue
    
    init(
        initialState: State,
        reducer: IntentReducer,
        reduceChange: @escaping ChangeReducer,
        stateQueue: DispatchQueue = DispatchQueue.main,
        intentQueue: DispatchQueue = DispatchQueue(label: "ReduceIntent", qos: DispatchQoS(qosClass: .userInitiated, relativePriority: 0))
        )
    {
        self.state = initialState
        self.intentReducer = FlatMapLatestReducer<IntentReducer>(reducer)
        self.reduceChange = reduceChange
        self.stateQueue = stateQueue
        self.intentQueue = intentQueue
    }
    
    func observe(_ observer: @escaping (State) -> Void) {
        observers.append(observer)
        observer(state)
    }
    
    func dispatchIntent(_ intent: Intent) {
        intentQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.intentReducer.reduceIntent(
                intent,
                getState: { return strongSelf.state },
                emitChange: { strongSelf.handleChange($0) }
            )
        }
    }
    
    private func handleChange(_ change: Change) {
        let newState = reduceChange(change, { return self.state })
        state = newState
    }
    
}
