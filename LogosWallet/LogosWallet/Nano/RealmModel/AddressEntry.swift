//
//  AddressEntry.swift
//  RaiBlocksWallet
//
//  Created by Ben Kray on 1/23/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import RealmSwift

class AddressEntry: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var address: String = ""
}
