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
}

enum ToDoListChange: Equatable {
    case fetchingToDos
    case fetchedToDos([ToDo])
    case error
    case searchToDos(searchText: String?)
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
                    ToDoListChange.fetchedToDos(toDos)
                })
                .catchErrorJustReturn(.error)
                .startWith(.fetchingToDos)
            
        case .searchToDos(searchText: let searchText):
            return Observable.just(.searchToDos(searchText: searchText))

        case .addToDo:
            fatalError()

        case .showDetail(let toDo):
            fatalError()
        }
    }
    
    let reduceChange: ToDoListStore.ChangeReducer = { (change, getState) -> ToDoListState in
        var newState = getState()
        switch change {
        case .fetchingToDos:
            newState.screenState = .loading
            
        case .fetchedToDos(let toDos):
            newState.toDos = toDos
            newState.screenState = .toDos
            
        case .error:
            newState.screenState = .error
            
        case .searchToDos(searchText: let searchText):
            newState.searchText = searchText
        }
        return newState
    }
    
    return ToDoListStore(state: initialState, reduceIntent: reduceIntent, reduceChange: reduceChange)
    
}
