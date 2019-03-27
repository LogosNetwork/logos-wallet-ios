//
//  SendRequest.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/26/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

class SendRequest: Request {

    var transactions: [Transaction] = []

    override init() {
        super.init()
        self.type = .send
    }

    override var json: [String: Any] {
        var result = super.json
        result["transactions"] = self.transactions.map { $0.json }
        return result
    }
    
    override var hashItems: [Data]? {
        guard
            var items = super.hashItems,
            self.transactions.count > 0
        else {
            return nil
        }

        self.transactions.forEach {
            if let targetData = WalletUtil.derivePublic(from: $0.destination)?.hexData {
                items.append(targetData)
            }
            if let amountData = $0.amount.decimalNumber.hexString?.leftPadding(toLength: 32, withPad: "0").hexData {
                items.append(amountData)
            }
        }
        return items
    }

}
