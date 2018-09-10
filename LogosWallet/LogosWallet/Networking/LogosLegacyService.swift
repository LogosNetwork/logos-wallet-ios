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
    var json: [String: String] { get }
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

enum LogosLegacyService {
    case serverStatus
    case process(block: BlockAdapter)
    case generateWork(hash: String)
    case accountHistory(address: String, count: Int)
    case ledger(address: String, count: Int)
    case blockInfo(hashes: [String])
    case pending(accounts: [String], count: Int)
    case createServerAccount(walletID: String, username: String, password: String)
    case accountInfo(account: String)

    // Temp RPC calls
    case blockCreate(parameters: BlockCreateParameters)
}

extension LogosLegacyService: TargetType {
    var baseURL: URL {
        // TODO: update url
        return URL(string: NetworkAdapter.baseNodeUrl)!
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
        case .generateWork(let hash):
            return params(for: "work_generate", params: ["hash": hash])
        case .ledger(let address, let count):
            return params(for: "ledger", params: ["account": address, "count": count, "representative": true, "pending": true])
        case .process(let block):
            guard let jsonData = try? JSONSerialization.data(withJSONObject: block.json, options: []),
                let blockString = String(data: jsonData, encoding: .ascii) else { return .requestPlain }
            return params(for: "process", params: ["block": blockString])
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
