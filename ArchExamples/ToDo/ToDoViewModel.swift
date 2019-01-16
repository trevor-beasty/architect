//
//  ToDoViewModel.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

struct ToDo: Equatable {
    var title: String
    var description: String?
    var isCompleted: Bool
    var createdDate: Date
}

enum ToDoViewIntent: Equatable {
    case loadToDos
    case addToDo
    case showDetail(ToDo)
    case searchToDos(searchText: String?)
}

struct ToDoViewState: Equatable {
    var toDos: [ToDo]
    var state: State
    var searchText: String?
    
    var displayToDos: [ToDo] {
        let filteredToDos: [ToDo]
        if let searchText = searchText, !searchText.isEmpty {
            filteredToDos = self.toDos.filter({
                return $0.title.contains(searchText)
            })
        }
        else {
            filteredToDos = self.toDos
        }
        return filteredToDos
    }
    
    enum State: Equatable {
        case loading
        case error
        case toDos
    }
    
}

func constructToDoModule() -> UIViewController {
    let viewController = ToDoViewController()
    let viewModel = ToDoViewModel(toDos: [])
    viewController.state = viewModel.stateVariable.asObservable()
    viewController.intentSubject = viewModel.intentSubject
    viewModel.subscribe()
    return viewController
}

class ToDoViewModel {
    
    let stateVariable: Variable<ToDoViewState>
    let intentSubject = PublishSubject<ToDoViewIntent>()
    private let bag = DisposeBag()
    private let toDoService = ToDoService()
    
    init(toDos: [ToDo]) {
        let state = ToDoViewState(toDos: toDos, state: .toDos, searchText: nil)
        self.stateVariable = Variable(state)
    }
    
    func subscribe() {
        
        intentSubject.asObservable()
            .subscribe(onNext: { intent in self.process(intent: intent) })
            .disposed(by: bag)
        
    }
    
    private func process(intent: ToDoViewIntent) {
        switch intent {
        case .loadToDos:
            
            updateState(for: .fetchingToDos)
            toDoService.getToDos()
                .subscribe(
                    onSuccess: { (toDos) in
                        self.updateState(for: .fetchedToDos(toDos))
                },
                    onError: { (error) in
                        self.updateState(for: .error)
                })
                .disposed(by: bag)
            
        default:
            fatalError()
        }
    }
    
    
    private func updateState(for change: ToDoViewChange) {
        let newState = reduce(state: stateVariable.value, for: change)
        stateVariable.value = newState
    }
    
    private func reduce(state: ToDoViewState, for change: ToDoViewChange) -> ToDoViewState {
        var reduced = stateVariable.value
        switch change {
        case .fetchingToDos:
            reduced.state = .loading
        case .fetchedToDos(let toDos):
            reduced.toDos = toDos
            reduced.state = .toDos
        case .error:
            reduced.state = .error
        }
        return reduced
    }

    private enum ToDoViewChange {
        case fetchingToDos
        case fetchedToDos([ToDo])
        case error
    }
    
}
