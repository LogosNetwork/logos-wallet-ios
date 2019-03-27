//
//  LogosStore.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/21/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

class LogosStore {

    enum StorageKey: String {
        case accounts
        case transactions
    }

    fileprivate init() { }

    static func setup(with account: String) {
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

    // MARK: - Account Info

    static func getAllWalletAccountInfo(for accounts: [String]) -> [LogosAccountInfo] {
        return accounts.compactMap { Storage.retrieve(StorageKey.accounts.rawValue + "/\($0)/info", as: LogosAccountInfo.self) }
    }

    static func update(account: String, info: LogosAccountInfo, completion: (() -> Void)? = nil) {
        Storage.store(info, as: "info", directoryPath: StorageKey.accounts.rawValue + "/\(account)", completion: completion)
    }

    // MARK: - Account History

    static func getHistory(for account: String?) -> LogosAccountHistory? {
        guard let account = account else { return nil }
        return Storage.retrieve(StorageKey.accounts.rawValue + "/\(account)/history", as: LogosAccountHistory.self)
    }

    static func updateHistory(for account: String, history: LogosAccountHistory) {
        Storage.store(history, as: "history", directoryPath: StorageKey.accounts.rawValue + "/\(account)")
    }

}
