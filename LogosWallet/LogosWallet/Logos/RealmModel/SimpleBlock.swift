//
//  SimpleBlock.swift
//  LogosWallet
//
//  Created by Ben Kray on 2/6/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import RealmSwift

protocol SimpleBlockBridge {
    var type: String { get set }
    var account: String { get set }
    var amount: String { get set }
    var owner: String { get set }
    var target: String { get set }
    var blockHash: String { get set }
}

class SimpleBlock: Object, SimpleBlockBridge {
    @objc dynamic var type: String = ""
    @objc dynamic var account: String = ""
    @objc dynamic var amount: String = ""
    @objc dynamic var blockHash: String = ""
    @objc dynamic var owner: String = ""
    @objc dynamic var target: String = ""

    static func fromJSON(_ json: [String: String]) -> SimpleBlock {
        let block = SimpleBlock()
        block.blockHash = json["hash"] ?? ""
        block.type = json["type"] ?? ""
        block.account = json["account"] ?? ""
        block.amount = json["amount"] ?? ""
        return block
    }
}
