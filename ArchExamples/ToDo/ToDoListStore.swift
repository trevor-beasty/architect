//
//  ToDoListStore.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

struct ListToDo: Equatable {
    let toDo: ToDo
    var stagedIsCompleted: Bool?
}

enum ToDoListIntent: Equatable {
    case loadToDos
    case addToDo
    case showDetail(ToDo)
    case searchToDos(searchText: String?)
    case editToDo(ToDo, isCompleted: Bool)
    case dismissError
}

enum ToDoListChange: Equatable {
    case showLoading
    case updateToDos([ToDo])
    case error
    case searchToDos(searchText: String?)
    case updateListToDo(ListToDo)
    case revertToState(ToDoListState)
    case showToDos
}

enum ToDoListOutput: Equatable {
    case showToDoDetail(id: String)
}

struct ToDoListState: Equatable {
    var listToDos: [ListToDo]
    var screenState: ScreenState
    var searchText: String?
    
    var displayListToDos: [ListToDo] {
        let filteredToDos: [ListToDo]
        if let searchText = searchText, !searchText.isEmpty {
            filteredToDos = self.listToDos.filter({
                return $0.toDo.title.contains(searchText)
            })
        }
        else {
            filteredToDos = self.listToDos
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
    let viewController = ToDoListViewController()
    let store = createToDoListStore()
    viewController.state = store.stateSubject.asObservable()
    viewController.intentSubject = store.intentSubject
    store.subscribe()
    return viewController
}

typealias ToDoListStore = Store<ToDoListState, ToDoListIntent, ToDoListChange, ToDoListOutput>

func createToDoListStore() -> ToDoListStore {
    
    let initialState: ToDoListState = ToDoListState(listToDos: [], screenState: .toDos, searchText: nil)
    
    let toDoService = ToDoService()
    
    let reduceIntent: ToDoListStore.IntentReducer = { (intent, getState) -> Observable<ToDoListChange> in
        switch intent {
        case .loadToDos:
            return toDoService.readToDos().asObservable()
                .map({ (toDos: [ToDo]) -> ToDoListChange in
                    ToDoListChange.updateToDos(toDos)
                })
                .catchErrorJustReturn(.error)
                .startWith(.showLoading)
            
        case .searchToDos(searchText: let searchText):
            return Observable.just(.searchToDos(searchText: searchText))

        case .addToDo:
            fatalError()

        case .showDetail:
            fatalError()
            
        case let .editToDo(toDo, isCompleted: isCompleted):
            let state = getState()
            guard let matchingIndex = state.listToDos.firstIndex(where: { $0.toDo.id == toDo.id }) else { fatalError() }
            var staged = state.listToDos[matchingIndex]
            staged.stagedIsCompleted = isCompleted
            var errorState = state
            errorState.screenState = .error
            return toDoService.updateToDo(toDo: staged.toDo).asObservable()
                .map({ (_: ToDo) -> ToDoListChange in
                    return .showToDos
                })
                .catchErrorJustReturn(.revertToState(errorState))
                .startWith(.updateListToDo(staged), .showLoading)
            
        case .dismissError:
            return Observable<ToDoListChange>.just(.showToDos)
        }
    }
    
    let reduceChange: ToDoListStore.ChangeReducer = { (change, getState) -> ToDoListState in
        var state = getState()
        switch change {
        case .showLoading:
            state.screenState = .loading
            
        case .updateToDos(let toDos):
            state.listToDos = toDos.map({ return ListToDo(toDo: $0, stagedIsCompleted: nil) })
            state.screenState = .toDos
            
        case .error:
            state.screenState = .error
            
        case .searchToDos(searchText: let searchText):
            state.searchText = searchText
            
        case .updateListToDo(let listToDo):
            guard let matchingIndex = state.listToDos.firstIndex(where: { $0.toDo.id == listToDo.toDo.id }) else { break }
            state.listToDos[matchingIndex] = listToDo
            state.screenState = .toDos
            
        case .revertToState(let reversionState):
            state = reversionState
            
        case .showToDos:
            state.screenState = .toDos
        }
        return state
    }
    
    let outputForIntent: ToDoListStore.IntentOutputReducer = { (intent, getState) -> ToDoListOutput? in
        switch intent {
        case .showDetail(let toDo):
            return .showToDoDetail(id: toDo.id)
        default:
            return nil
        }
    }
    
    return ToDoListStore(state: initialState, reduceIntent: reduceIntent, reduceChange: reduceChange, outputForIntent: outputForIntent)
    
}
