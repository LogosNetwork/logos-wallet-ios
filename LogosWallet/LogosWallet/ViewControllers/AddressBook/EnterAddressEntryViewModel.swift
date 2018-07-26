//
//  EnterAddressEntryViewModel.swift
//  RaiBlocksWallet
//
//  Created by Ben Kray on 2/25/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct EnterAddressEntryViewModel {
    let isEditing: Bool
    let title: String
    let name: String?
    let address: String?
    let addressOnly: Bool
    
    init(title: String, name: String? = nil, address: String? = nil, isEditing: Bool = false, addressOnly: Bool = false) {
        self.title = title
        self.name = name
        self.address = address
        self.isEditing = isEditing
        self.addressOnly = addressOnly
    }
}
