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
    case searchText(String?)
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

//func constructToDoModule() -> UIViewController {
//    let viewController = ToDoListViewController()
//    let store = ToDoListStore(toDos: [])
//    viewController.state = store.stateVariable.asObservable()
//    viewController.intentSubject = store.intentSubject
//    store.subscribe()
//    return viewController
//}

typealias ToDoListStore = Store<ToDoListState, ToDoListIntent, ToDoListChange>

func createToDoListStore() -> ToDoListStore {
    
    let initialState: ToDoListState = ToDoListState(toDos: [], screenState: .toDos, searchText: nil)
    
    let reduceIntent: ToDoListStore.IntentReducer = { (intent, getState) -> Observable<ToDoListChange> in
//        switch intent {
//        case .loadToDos:
//            updateState(for: .fetchingToDos)
//            toDoService.readToDos()
//                .subscribe(
//                    onSuccess: { (toDos) in
//                        self.updateState(for: .fetchedToDos(toDos))
//                },
//                    onError: { (error) in
//                        self.updateState(for: .error)
//                })
//                .disposed(by: bag)
//
//        case .searchToDos(searchText: let searchText):
//            updateState(for: .searchText(searchText))
//
//        case .addToDo:
//            fatalError()
//
//        case .showDetail(let toDo):
//            fatalError()
//
//        default:
//            fatalError()
//        }
        fatalError()
    }
    
    let reduceChange: ToDoListStore.ChangeReducer = { (change, getState) -> ToDoListState in
//        var reduced = stateVariable.value
//        switch change {
//        case .fetchingToDos:
//            reduced.screenState = .loading
//        case .fetchedToDos(let toDos):
//            reduced.toDos = toDos
//            reduced.screenState = .toDos
//        case .error:
//            reduced.screenState = .error
//        case .searchText(let searchText):
//            reduced.searchText = searchText
//        }
//        return reduced
        fatalError()
    }
    
    return ToDoListStore(state: initialState, reduceIntent: reduceIntent, reduceChange: reduceChange)
    
}
