//
//  Store.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/16/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

class Store<State, Intent, Change, Output> {
    
    let stateSubject: Variable<State>
    let intentSubject = PublishSubject<Intent>()
    let outputSubject = PublishSubject<Output>()
    private let bag = DisposeBag()
    
    let reduceIntent: IntentReducer
    let reduceChange: ChangeReducer
    let outputForIntent: IntentOutputReducer
    
    typealias IntentReducer = (Intent, () -> State) -> Observable<Change>
    typealias ChangeReducer = (Change, () -> State) -> State
    typealias IntentOutputReducer = (Intent, () -> State) -> Output?
    
    init(state: State, reduceIntent: @escaping IntentReducer, reduceChange: @escaping ChangeReducer, outputForIntent: @escaping IntentOutputReducer) {
        self.stateSubject = Variable(state)
        self.reduceIntent = { (intent, getState) -> Observable<Change> in
            print("\nIntent:\n     \(intent)\n")
            return reduceIntent(intent, getState)
        }
        self.reduceChange = { (change, getState) -> State in
            let newState = reduceChange(change, getState)
            print("\nChange & New State:\nchange:\n     \(change)\nnew state:\n     \(newState)\n")
            return newState
        }
        self.outputForIntent = outputForIntent
    }
    
    func subscribe() {
        
        intentSubject.asObservable()
            .flatMapLatest({
                return self.reduceIntent($0, { return self.state })
            })
            .subscribe(onNext: {
                let newState = self.reduceChange($0, { return self.state })
                self.update(newState)
            })
            .disposed(by: bag)
        
        intentSubject.asObservable()
            // TODO: There must be a better way to do this - if nil output, do not onNext for outputSubject.
            .flatMap({ intent -> Observable<Output> in
                if let output = self.outputForIntent(intent, { return self.state }) {
                    return Observable.just(output)
                }
                else {
                    return Observable.empty()
                }
            })
            .bind(to: outputSubject)
            .disposed(by: bag)
        
    }
    
    private var state: State {
        return stateSubject.value
    }
    
    private func update(_ state: State) {
        stateSubject.value = state
    }
    
}
