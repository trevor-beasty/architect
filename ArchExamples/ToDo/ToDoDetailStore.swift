//
//  ToDoDetailStore.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/16/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

struct ToDoDetailState: Equatable {
    var toDo: ToDo
    var stagedTitle: String?
    var stagedDescription: String?
    var stagedIsCompleted: Bool
}

enum ToDoDetailIntent: Equatable {
    case stageTitle(String?)
    case stageDescription(String?)
    case stageIsCompleted(Bool)
    case commitUpdate()
}

class ToDoDetailStore {
    
    let stateSubject: Variable<ToDoDetailState>
    let intentSubject = PublishSubject<ToDoDetailIntent>()
    
    init(toDo: ToDo) {
        let state = ToDoDetailState(toDo: toDo, stagedTitle: toDo.title, stagedDescription: toDo.description, stagedIsCompleted: toDo.isCompleted)
        self.stateSubject = Variable(state)
    }
    
}
