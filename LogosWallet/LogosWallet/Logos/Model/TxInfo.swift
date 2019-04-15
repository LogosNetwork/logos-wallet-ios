//
//  TxInfo.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/31/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct TxInfo {
    var tokenID: String?
    var recipientName: String
    var recipientAddress: String
    var amount: String
    var account: LogosAccount
}
