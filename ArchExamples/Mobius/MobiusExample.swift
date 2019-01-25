//
//  MobiusExample.swift
//  ArchExamples
//
//  Created by Trevor Beasty on 1/25/19.
//  Copyright © 2019 Trevor Beasty. All rights reserved.
//

import Foundation

enum ScreenState {
    case A
    case B
}

struct Item {
    let name: String
    let price: Double
}

class App {
    
    private var screenState: ScreenState = .A
    private var savedItems: [Item] = []
    
}




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
}

enum CreateItemStoreEffect {
    case createItem(name: String, price: Double)
    case showItems()
}

extension CreateItemStoreState {
    
    var canCreate: Bool {
        guard let name = name, !name.isEmpty, let price = price, price > 0 else { return false }
        return true
    }
    
}

func constructCreateItemStore() -> MobiusStore<CreateItemStoreState, CreateItemStoreEvent, CreateItemStoreEffect> {
    fatalError()
}
