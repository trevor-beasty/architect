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
    let id: String = UUID().uuidString
    var title: String
    var description: String?
    var isCompleted: Bool
    let createdDate: Date
}

enum ToDoViewIntent: Equatable {
    case loadToDos
    case addToDo
    case showDetail(ToDo)
    case searchToDos(searchText: String?)
}

struct ToDoViewState: Equatable {
    var toDos: [ToDo]
    var screenState: ScreenState
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
    
    enum ScreenState: Equatable {
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
        let state = ToDoViewState(toDos: toDos, screenState: .toDos, searchText: nil)
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
            toDoService.readToDos()
                .subscribe(
                    onSuccess: { (toDos) in
                        self.updateState(for: .fetchedToDos(toDos))
                },
                    onError: { (error) in
                        self.updateState(for: .error)
                })
                .disposed(by: bag)
            
        case .searchToDos(searchText: let searchText):
            updateState(for: .searchText(searchText))
            
        case .addToDo:
            fatalError()
            
        case .showDetail(let toDo):
            fatalError()
            
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
            reduced.screenState = .loading
        case .fetchedToDos(let toDos):
            reduced.toDos = toDos
            reduced.screenState = .toDos
        case .error:
            reduced.screenState = .error
        case .searchText(let searchText):
            reduced.searchText = searchText
        }
        return reduced
    }

    private enum ToDoViewChange {
        case fetchingToDos
        case fetchedToDos([ToDo])
        case error
        case searchText(String?)
    }
    
}
