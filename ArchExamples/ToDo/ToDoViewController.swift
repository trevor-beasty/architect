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
    var intentSubject: PublishSubject<ToDoViewIntent>!
    
    private let bag = DisposeBag()
    
    private let searchBar = UISearchBar()
    private let addButton = UIButton()
    private let addButtonLayoutGuide = UILayoutGuide()
    private let table = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        bindState()
        bindIntents()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        intentSubject.onNext(.loadToDos)
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
    
    private func bindState() {
    
        // table
        
        state.asObservable()
            .map({ $0.toDos })
            .bind(to: table.rx.items(cellIdentifier: "ToDoCell", cellType: ToDoCell.self)) { row, toDo, cell in
                cell.configure(toDo: toDo)
            }
            .disposed(by: bag)
        
        state.asObservable()
            .subscribe(onNext: { state in
                fatalError()
            })
            .disposed(by: bag)
        
    }
    
    private func bindIntents() {
        
        searchBar.rx.text.asObservable()
            .map({ ToDoViewIntent.searchToDos(searchText: $0) })
            .bind(to: intentSubject)
            .disposed(by: bag)
        
        addButton.rx
            .controlEvent(.touchUpInside)
            .throttle(2.0, scheduler: MainScheduler.instance)
            .asObservable()
            .map({ return ToDoViewIntent.addToDo })
            .bind(to: intentSubject)
            .disposed(by: bag)
        
        table.rx
            .modelSelected(ToDo.self)
            .throttle(2.0, scheduler: MainScheduler.instance)
            .asObservable()
            .map({ return ToDoViewIntent.showDetail($0) })
            .bind(to: intentSubject)
            .disposed(by: bag)
        
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
