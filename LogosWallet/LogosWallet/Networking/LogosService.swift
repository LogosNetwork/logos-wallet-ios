//
//  LogosService.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/20/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import Moya

protocol BlockAdapter {
    var json: [String: Any] { get }
}

struct BlockCreateParameters {
    var account: String
    var amount: String
    var destination: String
    var previous: String
    // this is why this is temporary
    var privateKey: String
    var representative: String
}

enum LogosService {
    case serverStatus
    case process(block: BlockAdapter)
    case generateWork(hash: String)
    case accountHistory(address: String, count: Int)
    case ledger(address: String, count: Int)
    case blockInfo(hashes: [String])
    case block(hash: String)
    case pending(accounts: [String], count: Int)
    case createServerAccount(walletID: String, username: String, password: String)
    case accountInfo(account: String)
    // TEMP
    case accountInfo2(account: String)
    case accountHistory2(address: String, count: Int)

    // Temp RPC calls
    case blockCreate(parameters: BlockCreateParameters)
}

extension LogosService: TargetType {
    var baseURL: URL {
        // TEMP
        return URL(string: "https://pla.bs/rpc")!
//        let index = LogosDelegateService.loadBalancedIndex()
//        if !WalletManager.shared.networkDelegates.isEmpty,
//            let delegateIP = WalletManager.shared.networkDelegates["\(index)"],
//            let url = URL(string: "http://" + delegateIP + ":55000") {
//            return url
//        } else {
//            return NetworkAdapter.baseNodeUrl
//        }
    }
    
    var path: String {
        return ""
    }

    var method: Moya.Method {
        return .post
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .serverStatus:
            return params(for: "canoe_server_status")
        case .accountHistory(let address, let count):
            return params(for: "account_history", params: ["account": address, "count": count])
        case .blockInfo(let hashes):
            return params(for: "blocks_info", params: ["hashes": hashes, "source": true])
        case .block(hash: let hash):
            return params(for: "block", params: ["hash": hash])
        case .generateWork(let hash):
            return params(for: "work_generate", params: ["hash": hash])
        case .ledger(let address, let count):
            return params(for: "ledger", params: ["account": address, "count": count, "representative": true, "pending": true])
        case .process(let block):
            guard
                let jsonData = try? JSONSerialization.data(withJSONObject: block.json, options: []),
                let requestString = String(data: jsonData, encoding: .ascii)
            else {
                return .requestPlain
            }
            // TEMP
            return .requestParameters(parameters: [
                "request": requestString,
                "targetURL": "http://172.1.1.100:55000",
                "rpc_action": "process",
            ], encoding: JSONEncoding.default)
//            return params(for: "process", params: ["block": blockString])
        case .pending(let accounts, let count):
            return params(for: "accounts_pending", params: ["accounts": accounts, "count": count])
        case .createServerAccount(let walletID, let username, let password):
            return params(for: "create_server_account", params: ["wallet": walletID, "token": username, "tokenPass": password])
        case .blockCreate(let parameters):
            return params(for: "block_create", params: [
                "account": parameters.account,
                "amount": parameters.amount,
                "destination": parameters.destination,
                "previous": parameters.previous,
                "key": parameters.privateKey,
                "representative": parameters.representative,
                "type": "state",
            ])
        case .accountInfo(let account):
            return params(for: "account_info", params: ["account": account])
        // TEMP
        case .accountInfo2(let account):
            return .requestParameters(parameters: [
                "account": account,
                "targetURL": "http://172.1.1.100:55000",
                "rpc_action": "account_info",
            ], encoding: JSONEncoding.default)
        case .accountHistory2(let account, let count):
            return .requestParameters(parameters: [
                "account": account,
                "targetURL": "http://172.1.1.100:55000",
                "rpc_action": "account_history",
                "count": count,
                "raw": false,
            ], encoding: JSONEncoding.default)
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    fileprivate func params(for action: String, params: [String: Any] = [:]) -> Task {
        // TEMP
        var p: [String: Any] = ["action": action, "logos": ""]
        p.merge(params) { (current, _) in current }
        return .requestParameters(parameters: p, encoding: JSONEncoding.default)
    }
}
