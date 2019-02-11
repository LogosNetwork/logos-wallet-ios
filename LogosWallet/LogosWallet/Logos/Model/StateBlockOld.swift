//
//  UtxBlock.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/28/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct StateBlockOld: BlockAdapter {

    enum Intent: String {
        case send
        // temporary case
        case receive
        case change
    }

    enum MessageType: UInt8 {
        case prePrepare = 0
        case prepare
        case postPrepare
        case commit
        case postCommit
        case prePrepareReject
        case postPrepareReject
        case singleStateBlock
    }

    var version: UInt8?
    // client should only be sending single state block
    let messageType: MessageType = .singleStateBlock
    // hardcoded for now since we're only sending to 1 target
//    var targets: UInt8 = 1
    /// Either send recipient or representative address to change to. Must match transactionAmounts size
//    var targetAddresses: [String]?
//    var transactionAmounts: [String]?
//    var transactionFee: UInt8?
//    var additionalSignatures: UInt8?
    var link: String?
    var representative: String?
    var account: String?
    /// RAW amount
    var amount: NSDecimalNumber?
    /// RAW transaction fee
    var transactionFee: NSDecimalNumber?
    var previous: String = ZERO_AMT
    var signature: String?
    var work: String?
    let intent: Intent

    init(intent: Intent) {
        self.intent = intent
    }
    
    /// Builds and signs a state block.
    /// - Parameter signingKeys: The keys to sign the block with.
    /// Note: The target addresses, amounts, and tx fee are required to be set before calling this function.
    /// An example of a state block with the intent to send would be as follows:
    /// let b = StateBlock(.send)
    /// b.targetAddresses = [<destination address>]
    /// b.transactionAmounts = [<transaction amount>]
    /// b.account = <block creator's address>
    /// b.previous = <current account's head block>
    /// b.amount = <amount to send>
    /// b.build(with: <account keyPair>
    mutating func build(with signingKeys: KeyPair) -> Bool {
        guard
            let encodedAccount = signingKeys.lgsAccount,
            let accountData = WalletUtil.derivePublic(from: encodedAccount)?.hexData,
            let linkData = self.link?.hexData,
            let previousData = self.previous.hexData,
            let representative = self.representative,
            let repData = WalletUtil.derivePublic(from: representative)?.hexData,
            let hexAmount = self.amount?.hexString,
            let hexTransactionFee = self.transactionFee?.hexString,
            let amountData = hexAmount.leftPadding(toLength: 32, withPad: "0").hexData,
            let transactionFeeData = hexTransactionFee.leftPadding(toLength: 32, withPad: "0").hexData
        else {
            return false
        }

        let items: [Data] = [
            STATEBLOCK_PREAMBLE.hexData!,
            accountData,
            previousData,
            repData,
            amountData,
            transactionFeeData,
            linkData
        ]

        guard
            let digest = NaCl.digest(items, outputLength: 32),
            let sig = NaCl.sign(digest, secret: signingKeys.secretKey)
        else {
            return false
        }

        self.account = encodedAccount
        self.signature = sig.hexString.uppercased()

        return true
    }
    
    var json: [String: Any] {
        return [
            "type": "state",
            "account": self.account ?? "",
            "previous": self.previous,
            "signature": self.signature ?? "",
            "representative": self.representative ?? "",
            "amount": self.amount?.stringValue ?? "",
            "link": self.link ?? "",
            "work": self.work ?? "",
            "transaction_fee": self.transactionFee?.stringValue ?? "",
        ]
    }
}
