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
    
    // () -> State: ReducerType may read state synchronously, but cannot read state asynchronously (at invocation time of delayed Change)
    //
    // @escaping (Change) -> Void: Changes may be emitted synchronously or asynchronously.
    //     - a simple reduction would immediately emit a change
    //     - a complex reduction would emit a change at some later point
    //     - this api is agnostic to sync / async, all changes are emitted via: @escaping (Change) -> Void
    //     - in Rx speak, @escaping (Change) -> Void is an 'Observer'
    //
    // Typically a reduction would have a synchronous return value: (A, B) -> C. This is a nuanced 'reduction',
    // which could perhaps be interpreted as 'plural reduction': (A, B, @escaping (C) - > Void) -> Void.
    
    typealias ReduceIntent = (Intent, () -> State, @escaping (Change) -> Void) -> Void
    
    func reduceIntent(_ intent: Intent, getState: () -> State, emitChange: @escaping (Change) -> Void)
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
        // Do not emit changes emitted from a prior intent reduction.
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

class NonRxStore<IntentReducer: ReducerType, Output> {
    typealias State = IntentReducer.State
    typealias Intent = IntentReducer.Intent
    typealias Change = IntentReducer.Change
    
    typealias ChangeReducer = (Change, () -> State) -> State
    typealias OutputReducer = (Intent, () -> State) -> Output?
    
    private var state: State {
        didSet {
            // In a UI domain, all observers should be executed on the main thread.
            // State value must be captured immediately due to threading considerations.
            let _state = state
            stateQueue.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.stateObservers.forEach({ $0(_state) })
            }
        }
    }
    private var stateObservers: [(State) -> Void] = []
    private var outputObservers: [(Output) -> Void] = []
    
    private let intentReducer: FlatMapLatestReducer<IntentReducer>
    private let reduceChange: ChangeReducer
    private let reduceOutput: OutputReducer
    
    private let stateQueue: DispatchQueue
    private let intentQueue = DispatchQueue(label: "ReduceIntent", qos: DispatchQoS(qosClass: .userInitiated, relativePriority: 0))
    
    init(
        initialState: State,
        reducer: IntentReducer,
        reduceChange: @escaping ChangeReducer,
        reduceOutput: @escaping OutputReducer,
        stateQueue: DispatchQueue = DispatchQueue.main
        )
    {
        self.state = initialState
        self.intentReducer = FlatMapLatestReducer<IntentReducer>(reducer)
        self.reduceChange = reduceChange
        self.reduceOutput = reduceOutput
        self.stateQueue = stateQueue
    }
    
    func observeState(_ observer: @escaping (State) -> Void) {
        stateObservers.append(observer)
        observer(state)
    }
    
    func dispatchIntent(_ intent: Intent) {
        // Intent processing is UI agnostic and is thus performed off the main thread.
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
    
    func observeOutput(_ observer: @escaping (Output) -> Void) {
        outputObservers.append(observer)
    }
    
}
