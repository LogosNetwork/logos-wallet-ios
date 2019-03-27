//
//  StateBlock.swift
//  LogosWallet
//
//  Created by Ben Kray on 2/8/19.
//  Copyright © 2019 Promethean Labs. All rights reserved.
//

import Foundation

// https://github.com/LogosNetwork/logos-core/blob/d00ac73ea5ff59d8cd819ab2d4e91f8372fa3b49/logos/consensus/messages/state_block.hpp

struct StateBlock: RequestAdapter {

    enum RequestType: UInt8 {
        case send
        case change
        case tokenSend = 14
        case unknown = 0xff

        var data: Data {
            return Data(bytes: [self.rawValue])
        }

        var string: String {
            switch self {
            case .send:
                return "send"
            case .change:
                return "change"
            case .tokenSend:
                return "token_send"
            case .unknown:
                return "unknown"

            }
        }

        static func from(string: String) -> RequestType? {
            switch string {
            case RequestType.send.string:
                return .send
            case RequestType.change.string:
                return .change
            case RequestType.unknown.string:
                return .unknown
            default:
                return nil
            }
        }
    }

    var hash = ""
    var origin = ""
    var previous = ""
    var sequence: NSDecimalNumber = 0
    var type: RequestType = .unknown
    var fee: NSDecimalNumber = 0
    var signature = ""
    var work = ""
    var transactions: [MultiSendTransaction] = []
    var transactionCount: NSDecimalNumber {
        return NSDecimalNumber(integerLiteral: self.transactions.count)
    }

    mutating func build(with signingKeys: KeyPair) -> Bool {
        guard
            let encodedOrigin = signingKeys.lgsAccount,
            let originData = WalletUtil.derivePublic(from: encodedOrigin)?.hexData,
            let previousData = self.previous.hexData,
            let hexFee = self.fee.hexString,
            let sequenceData = self.sequence.hexString?.leftPadding(toLength: 8, withPad: "0").hexData,
            let feeData = hexFee.leftPadding(toLength: 32, withPad: "0").hexData
        else {
            return false
        }

        // sequence and trans count are little endian
        var hashItems: [Data] = [
            self.type.data,
            originData,
            previousData,
            feeData,
            sequenceData.byteSwap(),
        ]

        self.transactions.forEach {
            if let targetData = WalletUtil.derivePublic(from: $0.destination)?.hexData {
                hashItems.append(targetData)
            }
            if let amountData = $0.amount.hexString?.leftPadding(toLength: 32, withPad: "0").hexData {
                hashItems.append(amountData)
            }
        }

        guard
            let digest = NaCl.digest(hashItems, outputLength: 32),
            let sig = NaCl.sign(digest, secret: signingKeys.secretKey)
        else {
            return false
        }

        self.hash = digest.hexString.uppercased()
        self.origin = encodedOrigin
        self.signature = sig.hexString.uppercased()

        return true
    }

    var json: [String: Any] {
        return [
            "hash": self.hash,
            "type": self.type.string,
            "origin": self.origin,
            "previous": self.previous,
            "signature": self.signature,
            "work": self.work,
            "fee": self.fee.stringValue,
            "transactions": self.transactions.map { $0.json },
            "number_transactions": self.transactionCount.intValue,
            "sequence": self.sequence.stringValue,
            // TEMP
            "next": GENESIS_HASH,
        ]
    }
}

extension StateBlock {

    init(type: RequestType) {
        self.type = type
    }

}

struct MultiSendTransaction {

    var destination: String
    var amount: NSDecimalNumber

    var json: [String: String] {
        return [
            "destination": self.destination,
            "amount": self.amount.stringValue,
        ]
    }
}
