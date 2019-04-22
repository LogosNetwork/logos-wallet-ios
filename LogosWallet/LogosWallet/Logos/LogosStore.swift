//
//  LogosStore.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/21/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

class LogosStore {

    fileprivate init() { }

    static func setup(for account: String) {
        let accountsUrl = Storage.documentsUrl.appendingPathComponent("accounts")
        let accountUrl = accountsUrl.appendingPathComponent(account)
        if !FileManager.default.fileExists(atPath: accountsUrl.path) {
            try? FileManager.default.createDirectory(atPath: accountsUrl.path, withIntermediateDirectories: false)
        }
        if !FileManager.default.fileExists(atPath: accountUrl.path) {
            Lincoln.log("Store setup for \(account)")
            try? FileManager.default.createDirectory(atPath: accountUrl.path, withIntermediateDirectories: false)
        }
    }

    static func clearAll() {
        Storage.clearAll()
    }

    static func clearAccountData(for account: String) {
        Storage.clear(directory: Storage.documentsUrl.appendingPathComponent("accounts/\(account)"))
    }

    // MARK: - Account Info

    static func getAllWalletAccountInfo(for accounts: [String]) -> [LogosAccountInfo] {
        return accounts.compactMap { Storage.retrieve("accounts/\($0)/info", as: LogosAccountInfo.self) }
    }

    static func update(account: String, info: LogosAccountInfo, completion: (() -> Void)? = nil) {
        Storage.store(info, as: "info", directoryPath: "accounts/\(account)", completion: completion)
    }

    // MARK: - Account History

    static func getHistory(for account: String?) -> LogosAccountHistory? {
        guard let account = account else { return nil }
        return Storage.retrieve("accounts/\(account)/history", as: LogosAccountHistory.self)
    }

    static func updateHistory(for account: String, history: LogosAccountHistory, completion: (() -> Void)? = nil) {
        var accountHistory = history
        if let existing = self.getHistory(for: account) {
            var existingHistory = existing.history
            let existingHashes = existingHistory.map { $0.hash }
            history.history.forEach {
                if !existingHashes.contains($0.hash) {
                    existingHistory.insert($0, at: 0)
                }
            }
            accountHistory.history = existingHistory
        }
        Storage.store(accountHistory, as: "history", directoryPath: "accounts/\(account)", completion: completion)
    }

}
