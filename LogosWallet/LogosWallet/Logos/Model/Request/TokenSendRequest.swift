//
//  TokenSendRequest.swift
//  LogosWallet
//
//  Created by Ben Kray on 4/12/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

class TokenSendRequest: SendRequest {

    let tokenID: String
    let tokenFee: NSDecimalNumber

    init(tokenID: String, tokenFee: NSDecimalNumber) {
        self.tokenID = tokenID
        self.tokenFee = tokenFee
        super.init()
        self.type = .tokenSend
    }

    override var hashItems: [Data]? {
        guard
            let originData = self.originData,
            let previousData = self.previousData,
            let feeData = self.feeData,
            let sequenceData = self.sequenceData,
            let tokenIdData = self.tokenID.hexData,
            let tokenFeeData = self.tokenFee.hexString?.leftPadding(toLength: 32, withPad: "0").hexData,
            self.transactions.count > 0
        else {
            return nil
        }
        var items = [
            self.type.data,
            originData,
            previousData,
            feeData,
            sequenceData.byteSwap(),
            tokenIdData
        ]
        self.transactions.forEach {
            if let targetData = WalletUtil.derivePublic(from: $0.destination)?.hexData {
                items.append(targetData)
            }
            if let amountData = $0.amount.decimalNumber.hexString?.leftPadding(toLength: 32, withPad: "0").hexData {
                items.append(amountData)
            }
        }
        items.append(tokenFeeData)

        return items
    }

    override var json: [String: Any] {
        var result = super.json
        result["token_fee"] = self.tokenFee.stringValue
        result["token_id"] = self.tokenID
        return result
    }

}
