//
//  KeyPair.swift
//  LogosWallet
//
//  Created by Ben Kray on 5/9/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct KeyPair {
    var publicKey: Data
    var secretKey: Data
}

extension KeyPair {
    var lgsAccount: String? {
        return try? WalletUtil.deriveLGSAccount(from: publicKey)
    }
}
