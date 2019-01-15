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
    private let addButtonLayoutGuide = UILayoutGuide()
    private let table = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        bindObservables()
    }
    
    private func setUp() {
        
        func setUpConstraints() {
            [searchBar, addButton, table].forEach({
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            })
            view.addLayoutGuide(addButtonLayoutGuide)
            NSLayoutConstraint.activate([
                searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                searchBar.leftAnchor.constraint(equalTo: view.leftAnchor),
                addButtonLayoutGuide.leftAnchor.constraint(equalTo: searchBar.rightAnchor),
                addButtonLayoutGuide.rightAnchor.constraint(equalTo: view.rightAnchor),
                addButtonLayoutGuide.widthAnchor.constraint(equalToConstant: 100),
                addButton.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor),
                addButton.centerXAnchor.constraint(equalTo: addButtonLayoutGuide.centerXAnchor),
                table.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                table.leftAnchor.constraint(equalTo: view.leftAnchor),
                table.rightAnchor.constraint(equalTo: view.rightAnchor)
                ])
        }
        
        func setUpTable() {
            table.register(ToDoCell.self, forCellReuseIdentifier: "ToDoCell")
        }
        
        func style() {
            view.backgroundColor = .white
            addButton.setTitle("Add", for: .normal)
            addButton.setTitleColor(.blue, for: .normal)
        }
        
        setUpConstraints()
        setUpTable()
        style()
    }
    
    private func bindObservables() {
        
        let toDos = state.asObservable().map({ state -> [ToDo] in
            switch state {
            case .loading, .error:
                return []
            case .toDos(let toDos):
                return toDos
            }
        })
        
        // table
        
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
    
    var didPressAdd: Observable<()> {
        return addButton.rx
            .controlEvent(.touchUpInside)
            .throttle(2.0, scheduler: MainScheduler.instance)
            .asObservable()
    }
    
    var didSelectToDo: Observable<ToDo> {
        return table.rx
            .modelSelected(ToDo.self)
            .throttle(2.0, scheduler: MainScheduler.instance)
            .asObservable()
    }
    
}

class ToDoCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let completedLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    private func setUp() {
        [titleLabel, descriptionLabel, completedLabel].forEach({
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        })
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            descriptionLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            completedLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            completedLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            contentView.heightAnchor.constraint(equalToConstant: 100)
            ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        descriptionLabel.text = nil
        completedLabel.text = nil
    }
    
    func configure(toDo: ToDo) {
        titleLabel.text = toDo.title
        descriptionLabel.text = toDo.description
        completedLabel.text = toDo.isCompleted ? "Completed" : "Incomplete"
    }
    
}
