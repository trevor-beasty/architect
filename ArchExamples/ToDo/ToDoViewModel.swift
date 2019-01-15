//
//  ToDoViewModel.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

struct ToDo {
    var title: String
    var description: String?
    var isCompleted: Bool
    var createdDate: Date
}

enum ToDoViewState {
    case loading
    case error
    case toDos([ToDo])
}

func constructToDoModule() -> UIViewController {
    let toDos: [ToDo] = [
        ToDo(title: "Put on deodorant", description: "Pronto", isCompleted: false, createdDate: Date()),
        ToDo(title: "Buy cool backpack", description: nil, isCompleted: false, createdDate: Date()),
        ToDo(title: "Get paid", description: "lots", isCompleted: true, createdDate: Date())
    ]
    let viewModel = ToDoViewModel(toDos: toDos)
    let viewController = ToDoViewController()
    viewController.state = viewModel.stateSubject.asObservable()
    viewModel.searchText = viewController.searchText
    viewModel.didPressAdd = viewController.didPressAdd
    viewModel.didSelectToDo = viewController.didSelectToDo
    viewModel.subscribe()
    return viewController
}

class ToDoViewModel {
    
    var searchText: Observable<String?>!
    var didPressAdd: Observable<()>!
    var didSelectToDo: Observable<ToDo>!
    
    let stateSubject: Variable<ToDoViewState>
    private let bag = DisposeBag()
    
    private var toDos: [ToDo]
    
    init(toDos: [ToDo]) {
        self.toDos = toDos
        self.stateSubject = Variable(ToDoViewState.toDos(toDos))
    }
    
    func subscribe() {
        
        searchText
            .subscribe(onNext: { searchText in
                let filteredToDos: [ToDo]
                if let searchText = searchText, !searchText.isEmpty {
                    filteredToDos = self.toDos.filter({
                        return $0.title.contains(searchText)
                    })
                }
                else {
                    filteredToDos = self.toDos
                }
                self.stateSubject.value = .toDos(filteredToDos)
            })
            .disposed(by: bag)
        
    }
    
}

extension ToDoViewModel {
    
}
