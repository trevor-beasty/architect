//
//  ToDoListViewController.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 12/31/18.
//  Copyright © 2018 Trevor Beasty. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ToDoListViewController: UIViewController {
    
    var state: Observable<ToDoListState>!
    var intentSubject: PublishSubject<ToDoListIntent>!
    
    private let bag = DisposeBag()
    
    private let searchBar = UISearchBar()
    private let addButton = UIButton()
    private let addButtonLayoutGuide = UILayoutGuide()
    private let table = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    private var screenState: ScreenState = .toDos
    
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
            [searchBar, addButton, table, activityIndicator].forEach({
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            })
            view.bringSubviewToFront(activityIndicator)
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
                table.rightAnchor.constraint(equalTo: view.rightAnchor),
                activityIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                activityIndicator.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                activityIndicator.leftAnchor.constraint(equalTo: view.leftAnchor),
                activityIndicator.rightAnchor.constraint(equalTo: view.rightAnchor)
                ])
        }
        
        func setUpTable() {
            table.register(ToDoCell.self, forCellReuseIdentifier: "ToDoCell")
        }
        
        func style() {
            view.backgroundColor = .white
            addButton.setTitle("Add", for: .normal)
            addButton.setTitleColor(.blue, for: .normal)
            activityIndicator.backgroundColor = .black
            activityIndicator.alpha = 0.5
            activityIndicator.hidesWhenStopped = true
        }
        
        setUpConstraints()
        setUpTable()
        style()
        activityIndicator.isHidden = true
    }
    
    private func bindState() {
    
        // table
        
        state.asObservable()
            .observeOn(MainScheduler.instance)
            .map({ $0.displayListToDos })
            .bind(to: table.rx.items(cellIdentifier: "ToDoCell", cellType: ToDoCell.self)) { row, listToDo, cell in
                cell.configure(listToDo: listToDo)
                cell.intentSubject = self.intentSubject
            }
            .disposed(by: bag)
        
        state.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { state in
                self.render(screenState: state.screenState)
            })
            .disposed(by: bag)
        
    }
    
    private func bindIntents() {
        
        searchBar.rx.text.asObservable()
            .map({ ToDoListIntent.searchToDos(searchText: $0) })
            .bind(to: intentSubject)
            .disposed(by: bag)
        
        addButton.rx
            .controlEvent(.touchUpInside)
            .throttle(2.0, scheduler: MainScheduler.instance)
            .asObservable()
            .map({ return ToDoListIntent.addToDo })
            .bind(to: intentSubject)
            .disposed(by: bag)
        
        table.rx
            .modelSelected(ToDo.self)
            .throttle(2.0, scheduler: MainScheduler.instance)
            .asObservable()
            .map({ return ToDoListIntent.showDetail($0) })
            .bind(to: intentSubject)
            .disposed(by: bag)
        
    }
    
    private func render(screenState: ToDoListState.ScreenState) {
        switch (screenState, self.screenState) {
        case (.toDos, .toDos), (.loading, .loading), (.error, .error):
            return
        default:
            break
        }
        switch self.screenState {
        case .loading(activityIndicator: let activityIndicator):
            activityIndicator.stopAnimating()
        case .error(let alertController):
            if presentedViewController === alertController {
                alertController.dismiss(animated: true, completion: nil)
            }
        case .toDos:
            break
        }
        let newScreenState: ScreenState
        switch screenState {
        case .loading:
            activityIndicator.startAnimating()
            newScreenState = .loading(activityIndicator: activityIndicator)
        case .error:
            let alertController = UIAlertController(title: "Error", message: "Probably a backend issue", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in self.intentSubject.onNext(.dismissError) })
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            newScreenState = .error(alertController)
        case .toDos:
            newScreenState = .toDos
        }
        self.screenState = newScreenState
    }
   
}

extension ToDoListViewController {
    
    private enum ScreenState {
        case toDos
        case loading(activityIndicator: UIActivityIndicatorView)
        case error(UIAlertController)
    }
    
}

class ToDoCell: UITableViewCell {
    
    var intentSubject: PublishSubject<ToDoListIntent>!
    private var listToDo: ListToDo?
    
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let completedLabel = UILabel()
    private let switchControl = UISwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError() }
    
    private func setUp() {
        
        func setUpConstraints() {
            [titleLabel, descriptionLabel, completedLabel, switchControl].forEach({
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
                contentView.heightAnchor.constraint(equalToConstant: 100),
                switchControl.rightAnchor.constraint(equalTo: contentView.rightAnchor),
                switchControl.bottomAnchor.constraint(equalTo: completedLabel.topAnchor)
                ])
        }
        
        func setUpSwitchControl() {
            switchControl.addTarget(self, action: #selector(switchControlValueDidChange), for: .valueChanged)
        }
        
        setUpConstraints()
        setUpSwitchControl()
    }
    
    @objc private func switchControlValueDidChange() {
        guard let listToDo = listToDo else { return }
        intentSubject.onNext(.editToDo(listToDo.toDo, isCompleted: switchControl.isOn))
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        descriptionLabel.text = nil
        completedLabel.text = nil
    }
    
    func configure(listToDo: ListToDo) {
        titleLabel.text = listToDo.toDo.title
        descriptionLabel.text = listToDo.toDo.description
        completedLabel.text = listToDo.toDo.isCompleted ? "Completed" : "Incomplete"
        // NOTE: Business logic!
        let isCompleted = listToDo.stagedIsCompleted ?? listToDo.toDo.isCompleted
        if switchControl.isOn != listToDo.toDo.isCompleted {
            switchControl.setOn(isCompleted, animated: false)
        }
        self.listToDo = listToDo
    }
    
}
