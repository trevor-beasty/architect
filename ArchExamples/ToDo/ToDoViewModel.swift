//
//  ToDoViewModel.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

protocol ViewModelViewInterface: AnyObject {
    associatedtype State
    associatedtype Action
    var state: Observable<State> { get }
    func process(action: Action)
}

protocol ViewModelProtocol: ViewModelViewInterface {
    associatedtype Change
    var variable: Variable<State> { get }
    var bag: DisposeBag { get }
    static func change(for action: Action, state: State) -> Single<Change>
    static func reduce(state: State, for change: Change) -> State
    static func reduce(state: State, for error: Error) -> State
}

extension ViewModelProtocol {
    
    func process(action: Action) {
        Self.change(for: action, state: variable.value)
            .subscribe(
                onSuccess: { [weak self] (change) in
                    guard let strongSelf = self else { return }
                    strongSelf.variable.value = Self.reduce(state: strongSelf.variable.value, for: change)
                },
                onError: { [weak self] (error) in
                    guard let strongSelf = self else { return }
                    strongSelf.variable.value = Self.reduce(state: strongSelf.variable.value, for: error)
                }
            )
            .disposed(by: bag)
    }
    
}

class ToDoViewModel {
    
    let variable = Variable(ToDoViewState(toDos: []))
    let bag = DisposeBag()
    
}

extension ToDoViewModel: ViewModelProtocol {
    typealias State = ToDoViewState
    typealias Action = ToDoViewAction
    typealias Change = ToDoViewChange
    
    var state: Observable<State> {
        return variable.asObservable()
    }
    
    static func change(for action: Action, state: State) -> Single<Change> {
        fatalError()
    }
    
    static func reduce(state: State, for change: Change) -> State {
        fatalError()
    }
    
    static func reduce(state: State, for error: Error) -> State {
        fatalError()
    }
    
}
