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
    
    private var toDos: [ToDo] = [
        ToDo(title: "Put on deodorant", description: "Pronto", isCompleted: false, createdDate: Date()),
        ToDo(title: "Buy cool backpack", description: nil, isCompleted: false, createdDate: Date()),
        ToDo(title: "Get paid", description: "lots", isCompleted: true, createdDate: Date())
    ]
    
    func readToDos() -> Single<[ToDo]> {
        return delayedSingle({ return Result<[ToDo]>.success(self.toDos) })
    }
    
    func createToDo(title: String, description: String?) -> Single<ToDo> {
        let newToDo = ToDo(title: title, description: description, isCompleted: false, createdDate: Date())
        toDos.append(newToDo)
        return delayedSingle({ return Result<ToDo>.success(newToDo) })
    }
    
    func updateToDo(id: String, title: String? = nil, description: String? = nil, isCompleted: Bool? = nil) {
        
    }
    
    private func delayedSingle<T>(_ result: @escaping () -> Result<T>) -> Single<T> {
        return Single<T>.create { (single) -> Disposable in
            DispatchQueue.global().async {
                sleep(2)
                let _result = result()
                switch _result {
                case .success(let value):
                    single(.success(value))
                case .failure(let error):
                    single(.error(error))
                }
                
            }
            return Disposables.create()
        }
    }
    
    private enum Result<T> {
        case success(T)
        case failure(Error)
    }
    
}


