//
//  ToDoViewModel.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

protocol ViewModelProtocol: AnyObject {
    associatedtype State
    associatedtype Action
    var state: Observable<State> { get }
    func process(action: Action)
}

class ToDoViewModel {
    
    private let stateVariable = Variable(ToDoViewState(toDos: []))
    
}

extension ToDoViewModel: ViewModelProtocol {
    
    var state: Observable<ToDoViewState> {
        return stateVariable.asObservable()
    }
    
    func process(action: ToDoViewAction) {
        fatalError()
    }
    
}
