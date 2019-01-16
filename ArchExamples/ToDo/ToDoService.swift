//
//  ToDoService.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/15/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation
import RxSwift

class ToDoService {
    
    func getToDos() -> Single<[ToDo]> {
        return Single<[ToDo]>.create { (single) -> Disposable in
            sleep(2)
            let toDos: [ToDo] = [
                ToDo(title: "Put on deodorant", description: "Pronto", isCompleted: false, createdDate: Date()),
                ToDo(title: "Buy cool backpack", description: nil, isCompleted: false, createdDate: Date()),
                ToDo(title: "Get paid", description: "lots", isCompleted: true, createdDate: Date())
            ]
            single(.success(toDos))
            return Disposables.create()
        }
    }
    
}


