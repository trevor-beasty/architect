//
//  MobiusExample.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

enum ScreenState {
    case itemListScreen
    case createItemScreen(CreateItemStore)
}

struct Item {
    let name: String
    let price: Double
}

class App {
    
    private var screenState: ScreenState = .itemListScreen
    private var savedItems: [Item] = []
    
    func launch() {
        showItemListScreen()
    }
    
    func createItem(name: String, price: Double) -> Item {
        let newItem = Item(name: name, price: price)
        app.savedItems.append(newItem)
        return newItem
    }
    
    func showItemListScreen() {
        
    }
    
    func showCreateItemScreen() {
        let createItemStore = constructCreateItemStore(app: self)
        screenState = .createItemScreen(createItemStore)
    }
    
}

private let app = App()




enum ViewItemsStoreEvent {
    case didSelectItem(Item)
    case didPressDelete(Item)
}

enum ViewItemsStoreEffect {
    case showItem(Item)
    case deleteItem(Item)
}






struct CreateItemStoreState {
    var name: String?
    var price: Double?
}

enum CreateItemStoreEvent {
    case didUpdateName(String?)
    case didUpdatePrice(Double?)
    case didPressCreate
    case didPressCancel
    case didCreateItem(Item)
}

enum CreateItemStoreEffect {
    case createItem(name: String, price: Double)
    case showItems
}

extension CreateItemStoreState {
    
    var canCreate: Bool {
        guard let name = name, !name.isEmpty, let price = price, price > 0 else { return false }
        return true
    }
    
}

typealias CreateItemStore = MobiusStore<CreateItemStoreState, CreateItemStoreEvent, CreateItemStoreEffect>

func constructCreateItemStore(app: App) -> CreateItemStore {
    
    let reduce: (CreateItemStoreEvent, CreateItemStoreState) -> (CreateItemStoreState?, [CreateItemStoreEffect]?) = { event, state in
        switch event {
        case .didPressCancel:
            return (nil, [.showItems])
            
        case .didPressCreate:
            guard let name = state.name, let price = state.price else { fatalError() }
            return (nil, [.createItem(name: name, price: price)])
            
        case .didUpdateName(let name):
            var newState = state
            newState.name = name
            return (newState, nil)
            
        case .didUpdatePrice(let price):
            var newState = state
            newState.price = price
            return (newState, nil)
            
        case .didCreateItem:
            return (nil, [.showItems])
        }
    }
    
    let effectHandler = MobiusEffectHandler<CreateItemStoreEffect, CreateItemStoreEvent> { [weak app] (effect, emitEvent) in
        guard let app = app else { return }
        switch effect {
        case let .createItem(name: name, price: price):
            let newItem = app.createItem(name: name, price: price)
            emitEvent(.didCreateItem(newItem))
            
        case .showItems:
            app.showItemListScreen()
        }
    }
    
    return CreateItemStore(initialState: .init(name: nil, price: nil), reduce: reduce, effectHandler: effectHandler)
    
}
