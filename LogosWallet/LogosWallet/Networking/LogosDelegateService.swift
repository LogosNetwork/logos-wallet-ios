//
//  LogosDelegateService.swift
//  LogosWallet
//
//  Created by Ben Kray on 12/11/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import Moya

enum LogosDelegateService {

    static var accountInfo: AccountInfo?

    case delegates

    /// Transaction load balancing on 32 delegates. This requires the current
    /// account in focus to be set to the static prop above.
    static func loadBalancedIndex() -> Int {
        guard
            let accountInfo = self.accountInfo,
            let address = accountInfo.address,
            let publicKey = WalletUtil.derivePublic(from: address),
            accountInfo.frontier.isEmpty == false
        else {
            return 0
        }

        let delegateIndex: Int
        if accountInfo.frontier == ZERO_AMT {
            delegateIndex = Int(String(publicKey.suffix(2)), radix: 16) ?? 0
        } else {
            delegateIndex = Int(String(accountInfo.frontier.suffix(2)), radix: 16) ?? 0
        }
        return delegateIndex % 32
    }

    static func loadBalancedUrl() -> URL {
        if !WalletManager.shared.networkDelegates.isEmpty,
            let delegateIP = WalletManager.shared.networkDelegates["\(LogosDelegateService.loadBalancedIndex())"],
            let url = URL(string: "http://" + delegateIP + ":55000") {
            return url
        } else {
            return NetworkAdapter.baseNodeUrl
        }
    }
}

extension LogosDelegateService: TargetType {
    var baseURL: URL {
        return URL(string: "https://pla.bs/delegates")!
    }
    var path: String {
        return ""
    }
    var method: Moya.Method {
        return .get
    }
    var sampleData: Data {
        return Data()
    }
    var task: Task {
        return .requestPlain
    }
    var headers: [String : String]? {
        return nil
    }

}
