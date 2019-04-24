//
//  LogosTokenManager.swift
//  LogosWallet
//
//  Created by Ben Kray on 4/1/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import Foundation

class LogosTokenManager {

    private(set) var tokenAccounts = [String: LogosTokenAccountInfo]()
    static let shared = LogosTokenManager()

    func fetchTokenInfo(for publicKey: String, completion: (() -> Void)? = nil) {
        guard
            self.tokenAccounts[publicKey] == nil,
            let publicKeyHex = publicKey.hexData,
            let encodedAccount = try? WalletUtil.deriveLGSAccount(from: publicKeyHex)
        else {
            completion?()
            return
        }

        NetworkAdapter.getTokenAccountInfo(for: encodedAccount) { info, _ in
            if let info = info {
                self.tokenAccounts[publicKey] = info
            }
            completion?()
        }
    }

}
