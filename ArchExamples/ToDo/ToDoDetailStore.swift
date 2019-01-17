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

enum ToDoDetailChange: Equatable {
    
}

enum ToDoDetailOutput: Equatable {
    
}

typealias ToDoDetailStore = Store<ToDoDetailState, ToDoDetailIntent, ToDoDetailChange, ToDoDetailOutput>
