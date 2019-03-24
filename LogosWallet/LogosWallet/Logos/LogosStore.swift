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

    // MARK: - Account Info

    static func getAllWalletAccountInfo() -> [LogosAccountInfo] {
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: Storage.documentsUrl.path + "/\(StorageKey.accounts.rawValue)") {
            return contents.compactMap { Storage.retrieve(StorageKey.accounts.rawValue + "/\($0)", as: LogosAccountInfo.self) }
        } else {
            return []
        }
    }

    static func update(account: String, info: LogosAccountInfo) {
        Storage.store(info, as: account, directoryPath: StorageKey.accounts.rawValue)
    }

    // MARK: - Account Chain

    static func getChain(for account: String) -> 

}
