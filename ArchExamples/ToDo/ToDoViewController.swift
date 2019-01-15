//
//  ToDoViewController.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ToDoViewController: UIViewController {
    
    var state: Observable<ToDoViewState>!
    
    private let bag = DisposeBag()
    
    private let searchBar = UISearchBar()
    private let addButton = UIButton()
    private let table = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        bindObservables()
    }
    
    private func setUp() {
        
        func setUpConstraints() {
            
        }
        
        func setUpTable() {
            table.register(ToDoCell.self, forCellReuseIdentifier: "ToDoCell")
        }
        
        setUpConstraints()
        setUpTable()
    }
    
    private func bindObservables() {
        
        // table
        
        let toDos = state.asObservable().map({ state -> [ToDo] in
            switch state {
            case .loading, .error:
                return []
            case .toDos(let toDos):
                return toDos
            }
        })
        
        toDos
            .bind(to: table.rx.items(cellIdentifier: "ToDoCell", cellType: ToDoCell.self)) { row, toDo, cell in
                cell.configure(toDo: toDo)
            }
            .disposed(by: bag)
        
        
        
    }
    
}

extension ToDoViewController {
    
    var searchText: Observable<String?> {
        return searchBar.rx.text.asObservable()
    }
    
    var addToDoPress: Observable<()> {
        return addButton.rx
            .controlEvent(.touchUpInside)
            .throttle(2.0, scheduler: MainScheduler.instance)
            .asObservable()
    }
    
}

class ToDoCell: UITableViewCell {
    
    func configure(toDo: ToDo) {
        textLabel?.text = toDo.title + " : " + (toDo.isCompleted ? "Complete" : "Incomplete")
        detailTextLabel?.text = toDo.description
    }
    
}
