//
//  Store.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/16/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

class Store<State, Intent, Change> where State: Equatable, Intent: Equatable, Change: Equatable {
    
    let stateSubject: Variable<State>
    let intentSubject = PublishSubject<Intent>()
    private let bag = DisposeBag()
    
    let reduceIntent: IntentReducer
    let reduceChange: ChangeReducer
    
    typealias IntentReducer = (Intent, () -> State) -> Observable<Change>
    typealias ChangeReducer = (Change, () -> State) -> State
    
    init(state: State, reduceIntent: @escaping IntentReducer, reduceChange: @escaping ChangeReducer) {
        self.stateSubject = Variable(state)
        self.reduceIntent = reduceIntent
        self.reduceChange = reduceChange
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
        
    }
    
    private var state: State {
        return stateSubject.value
    }
    
    private func update(_ state: State) {
        stateSubject.value = state
    }
    
}
