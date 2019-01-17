//
//  ToDoListStore.swift
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

enum ToDoListIntent: Equatable {
    case loadToDos
    case addToDo
    case showDetail(ToDo)
    case searchToDos(searchText: String?)
    case editToDo(ToDo, isCompleted: Bool)
}

enum ToDoListChange: Equatable {
    case showLoading
    case showToDos([ToDo])
    case error
    case searchToDos(searchText: String?)
    case updateToDo(ToDo)
}

struct ToDoListState: Equatable {
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
    let viewController = ToDoListViewController()
    let store = createToDoListStore()
    viewController.state = store.stateSubject.asObservable()
    viewController.intentSubject = store.intentSubject
    store.subscribe()
    return viewController
}

typealias ToDoListStore = Store<ToDoListState, ToDoListIntent, ToDoListChange>

func createToDoListStore() -> ToDoListStore {
    
    let initialState: ToDoListState = ToDoListState(toDos: [], screenState: .toDos, searchText: nil)
    
    let toDoService = ToDoService()
    
    let reduceIntent: ToDoListStore.IntentReducer = { (intent, getState) -> Observable<ToDoListChange> in
        switch intent {
        case .loadToDos:
            return toDoService.readToDos().asObservable()
                .map({ (toDos: [ToDo]) -> ToDoListChange in
                    ToDoListChange.showToDos(toDos)
                })
                .catchErrorJustReturn(.error)
                .startWith(.showLoading)
            
        case .searchToDos(searchText: let searchText):
            return Observable.just(.searchToDos(searchText: searchText))

        case .addToDo:
            fatalError()

        case .showDetail(let toDo):
            fatalError()
            
        case let .editToDo(toDo, isCompleted: isCompleted):
            var updated = toDo
            updated.isCompleted = isCompleted
            return toDoService.updateToDo(toDo: updated).asObservable()
                .map({ (toDo: ToDo) -> ToDoListChange in
                    return .updateToDo(toDo)
                })
                .catchErrorJustReturn(.error)
                .startWith(.showLoading)
        }
    }
    
    let reduceChange: ToDoListStore.ChangeReducer = { (change, getState) -> ToDoListState in
        var state = getState()
        switch change {
        case .showLoading:
            state.screenState = .loading
            
        case .showToDos(let toDos):
            state.toDos = toDos
            state.screenState = .toDos
            
        case .error:
            state.screenState = .error
            
        case .searchToDos(searchText: let searchText):
            state.searchText = searchText
            
        case .updateToDo(let toDo):
            guard let matchingIndex = state.toDos.firstIndex(where: { $0.id == toDo.id }) else { break }
            state.toDos[matchingIndex] = toDo
            state.screenState = .toDos
        }
        return state
    }
    
    return ToDoListStore(state: initialState, reduceIntent: reduceIntent, reduceChange: reduceChange)
    
}
