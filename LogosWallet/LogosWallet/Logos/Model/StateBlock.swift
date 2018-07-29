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
    var messageType: MessageType?
    var targets: UInt8?
    var targetAddresses: [String]?
    var transactionAmounts: [String]?
    var transactionFee: UInt8?
    var additionalSignatures: UInt8?

    // TODO: change to optional for consistency
    var account: String = ""
    var representative: String = ""
    var previous: String = ZERO_AMT
    // Base 10 remaining balance as RAW
    var balance: String = ""
    var link: String = ""
    var signature: String = ""
    var work: String = ""
    var intent: Intent
    var balanceValue: BInt? = nil
    
    init(_ intent: Intent) {
        self.intent = intent
    }
    
    /// Builds and signs a state block.
    /// - Parameter signingKeys: The keys to sign the block with.
    /// Note: The link, representative, account, previous, and balance are required to be set before calling this function.
    /// An example of a state block with the intent to send would be as follows:
    /// let b = StateBlock(.send)
    /// b.link = <destination address>
    /// b.account = <block creator's address>
    /// b.previous = <current account's head block>
    /// b.balance = <remaining balance after subtracting amount sent>
    /// b.representative = <either current or a new rep>
    /// b.build(with: <account keyPair>
    mutating func build(with signingKeys: KeyPair) -> Bool {
        guard var linkData = link.hexData,
            let encodedAccount = signingKeys.xrbAccount,
            let repData = WalletUtil.derivePublic(from: representative)?.hexData,
            let accountData = WalletUtil.derivePublic(from: encodedAccount)?.hexData,
            let previousData = previous.hexData,
            let decimalBalance = balanceValue?.asString(radix: 10) else { return false }
        let finalBalance = balanceValue?
            .asString(radix: 16)
            .leftPadding(toLength: 32, withPad: "0") ?? ZERO_AMT
        if intent == .send, let destinationData = WalletUtil.derivePublic(from: link)?.hexData {
            linkData = destinationData
        }
        if intent == .change {
            linkData = ZERO_AMT.hexData!
            link = ZERO_AMT
        }
        guard let balanceData = finalBalance.hexData else { return false }
        guard let digest = NaCl.digest([
            STATEBLOCK_PREAMBLE.hexData!,
            accountData,
            previousData,
            repData,
            balanceData,
            linkData
            ], outputLength: 32) else { return false }
        guard let sig = NaCl.sign(digest, secret: signingKeys.secretKey) else { return false }
        balance = decimalBalance
        account = encodedAccount
        signature = sig.hexString.uppercased()

        return true
    }
    
    var json: [String: String] {
        return [
            "type": "state",
            "account": account,
            "previous": previous,
            "link": link,
            "balance": balance,
            "representative": representative,
            "signature": signature,
            "work": work
        ]
    }
}
