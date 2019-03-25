//
//  AccountInfo.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/13/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import RealmSwift

class LogosAccount: Object {
    @objc dynamic var index: Int = 0
    @objc dynamic var address: String?
    @objc dynamic var name: String?
    var info: LogosAccountInfo?
}

extension LogosAccount {
    var blockCount: Int {
        return Int(self.info?.requestCount ?? "0") ?? 0
    }
}
