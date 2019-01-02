//
//  AccountInfo.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/13/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import RealmSwift

class AccountInfo: Object {
    @objc dynamic var frontier: String = ZERO_AMT
    @objc dynamic var openBlock: String = ""
    @objc dynamic var representativeBlock: String = ""
    @objc dynamic var balance: String = "0"
    @objc dynamic var modifiedTimestamp: String = ""
    @objc dynamic var blockCount: Int = 0
    @objc dynamic var representative: String = ""
    @objc dynamic var index: Int = 0
    @objc dynamic var pending: Int = 0
    @objc dynamic var address: String?
    @objc dynamic var name: String?
    let blockHistory = List<SimpleBlock>()

    var mlgsBalance: String {
        return balance.decimalNumber.mlgsString
    }

    var formattedBalance: String {
        return self.mlgsBalance.formattedAmount
    }
    
    static func fromJSON(_ json: [String: Any]?, account: String) -> AccountInfo? {
        let accountInfo = AccountInfo()
        guard let accountsJSON = json?["accounts"] as? [String: Any],
            let infoJSON = accountsJSON[account] as? [String: Any] else { return nil }
        accountInfo.frontier = infoJSON["frontier"] as? String ?? ""
        accountInfo.openBlock = infoJSON["open_block"] as? String ?? ""
        accountInfo.representativeBlock = infoJSON["representative_block"] as? String ?? ""
        accountInfo.balance = infoJSON["balance"] as? String ?? "0"
        accountInfo.modifiedTimestamp = infoJSON["modified_timestamp"] as? String ?? ""
        accountInfo.blockCount = Int(infoJSON["block_count"] as? String ?? "0") ?? 0
        accountInfo.representative = infoJSON["representative"] as? String ?? ""
        accountInfo.pending = Int(infoJSON["pending"] as? String ?? "0") ?? 0
        return accountInfo
    }
//    required init() {
//
//    }
//
//    init(json: [String: Any]) {
//    }
    
    /// Copies relevant properties from one AccountInfo obj to another. All other properties not copied below are locally generated, and should already be in memory.
    ///
    /// - Parameter from: The AccountInfo object to copy from (originating from a node RPC response).
    func copyProperties(from rpcResponse: AccountInfo) {
        self.openBlock = rpcResponse.openBlock
        self.frontier = rpcResponse.frontier
        self.representativeBlock = rpcResponse.representativeBlock
        self.balance = rpcResponse.balance
        self.modifiedTimestamp = rpcResponse.modifiedTimestamp
        self.blockCount = rpcResponse.blockCount
        self.representative = rpcResponse.representative
        self.pending = rpcResponse.pending
    }

    func copyProperties(from rpcResponse: AccountInfoResponse) {
        self.openBlock = rpcResponse.openBlock
        self.frontier = rpcResponse.frontier
        self.representative = rpcResponse.representativeBlock
        self.balance = rpcResponse.balance
        self.modifiedTimestamp = rpcResponse.modifiedTimestamp
        self.blockCount = Int(rpcResponse.blockCount) ?? 0
    }

    func repair() {
        self.openBlock = ""
        self.frontier = ""
        self.representative = ""
        self.balance = "0"
        self.modifiedTimestamp = ""
        self.blockCount = 0
    }

}
