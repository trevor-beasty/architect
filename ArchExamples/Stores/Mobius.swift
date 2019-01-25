//
//  Mobius.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

protocol EffectHandlerType: AnyObject {
    associatedtype Effect
    associatedtype Event
    
    func handleEffect(_ effect: Effect, emitEvent: @escaping (Event) -> Void)
}

class EffectHandler<Effect, Event>: EffectHandlerType {
    
    private let _handler: (Effect, @escaping (Event) -> Void) -> Void
    
    init(handler: @escaping (Effect, @escaping (Event) -> Void) -> Void) {
        self._handler = handler
    }
    
    func handleEffect(_ effect: Effect, emitEvent: @escaping (Event) -> Void) {
        _handler(effect, emitEvent)
    }
    
}

protocol MobiusStoreType: AnyObject {
    associatedtype State
    associatedtype Event
    associatedtype Effect
    
    typealias StateObserver = (State) -> Void
    
    func observeState(_ observer: @escaping (State) -> Void)
    func dispatchEvent(_ event: Event)
}

class MobiusStore<State, Event, Effect>: MobiusStoreType {
    
    typealias Reduce = (Event, State) -> (State, [Effect])
    
    let reduce: Reduce
    let effectHandler: EffectHandler<Effect, Event>
    
    private var state: State {
        didSet {
            stateObservers.forEach({ $0(state) })
        }
    }
    private var stateObservers: [StateObserver] = []
    
    init(initialState: State, reduce: @escaping Reduce, effectHandler: EffectHandler<Effect, Event>) {
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
        state = newState
        effects.forEach({
            effectHandler.handleEffect($0, emitEvent: { [weak self] (event) in
                guard let strongSelf = self else { return }
                strongSelf.dispatchEvent(event)
            })
        })
    }
    
}


