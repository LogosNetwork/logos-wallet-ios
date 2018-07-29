//
//  UtxBlock.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/28/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

struct StateBlock: BlockAdapter {

    enum Intent: String {
        case open
        case send
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
    var targets: UInt8 = 1
    /// Either send recipient or representative address to change to. Must match transactionAmounts size
    var targetAddresses: [String]?
    var transactionAmounts: [String]?
    var transactionFee: UInt8?
    var additionalSignatures: UInt8?
    var representative: String?
    var account: String?
    var previous: String = ZERO_AMT
    // Base 10 remaining balance as RAW
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
        guard let encodedAccount = signingKeys.lgnAccount,
            let accountData = WalletUtil.derivePublic(from: encodedAccount)?.hexData,
            let previousData = previous.hexData else {
            return false
        }

        var hexAmount: String?
        if self.intent == .send {
            guard let amount = self.transactionAmounts?.first,
                let amountValue = BInt(amount) else {
                return false
            }

            hexAmount = amountValue
                .asString(radix: 16)
                .leftPadding(toLength: 32, withPad: "0")
        }

        guard let targetAddress = self.targetAddresses?.first else {
            return false
        }
        
        // TODO: create correct digest
        guard let digest = NaCl.digest([
            STATEBLOCK_PREAMBLE.hexData!,
            accountData,
            previousData,
        ], outputLength: 32) else {
            return false
        }
        guard let sig = NaCl.sign(digest, secret: signingKeys.secretKey) else { return false }
        self.account = encodedAccount
        self.signature = sig.hexString.uppercased()

        return true
    }
    
    var json: [String: String] {
        return [
            "type": "state",
            "account": self.account ?? "",
            "previous": self.previous,
            "signature": self.signature ?? "",
            "work": self.work ?? ""
        ]
    }
}
