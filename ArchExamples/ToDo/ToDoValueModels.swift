//
//  ToDoValueModels.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import Foundation

struct ToDo {
    var title: String
    var description: String
    var isCompleted: Bool
    var createdDate: Date
}

struct ToDoViewState {
    var toDos: [ToDo]
}

enum ToDoViewAction {
    
}
