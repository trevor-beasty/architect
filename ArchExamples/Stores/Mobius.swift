//
//  Mobius.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

class MobiusEffectHandler<Effect, Event> {
    
    private let _handler: (Effect, @escaping (Event) -> Void) -> Void
    
    init(handler: @escaping (Effect, @escaping (Event) -> Void) -> Void) {
        self._handler = handler
    }
    
    func handleEffect(_ effect: Effect, emitEvent: @escaping (Event) -> Void) {
        _handler(effect, emitEvent)
    }
    
}

class MobiusStore<State, Event, Effect> {
    
    typealias Reduce = (Event, State) -> (State?, [Effect]?)
    typealias EffectHandler = MobiusEffectHandler<Effect, Event>
    typealias StateObserver = (State) -> Void
    
    let reduce: Reduce
    let effectHandler: EffectHandler
    
    private var state: State {
        didSet {
            stateObservers.forEach({ $0(state) })
        }
    }
    private var stateObservers: [StateObserver] = []
    
    init(initialState: State, reduce: @escaping Reduce, effectHandler: EffectHandler) {
        self.state = initialState
        self.reduce = reduce
        self.effectHandler = effectHandler
    }
    
    func observeState(_ observer: @escaping (State) -> Void) {
        stateObservers.append(observer)
        observer(state)
    }
    
    func dispatchEvent(_ event: Event) {
        let (newState, effects) = reduce(event, state)
        
        if let someNewState = newState {
            state = someNewState
        }
        
        if let someEffects = effects {
            someEffects.forEach({
                effectHandler.handleEffect($0, emitEvent: { [weak self] (event) in
                    guard let strongSelf = self else { return }
                    strongSelf.dispatchEvent(event)
                })
            })
        }
    }
    
}


