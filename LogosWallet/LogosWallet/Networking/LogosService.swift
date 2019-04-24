//
//  LogosService.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/20/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import Moya

protocol RequestAdapter {
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
    case process(request: RequestAdapter)
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
    case tokenAccountInfo(account: String)
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
        switch self {
        case .accountInfo2(_):
            return "{\r\n \"type\": \"LogosAccount\",\r\n \"frontier\": \"C1D62F8F53F6623B4F64FA45F85E26283D5521D5D1BD64489008E4FF82F98ACB\",\r\n \"receive_tip\": \"B5FBECC6024D9FA763E273CC1211AD735CA46E61D1823959FD996CCF9BBC31F2\",\r\n \"open_block\": \"FE07DD6404075C692978AAABED8529E15BC6691D6368E89559C5C96A20875870\",\r\n \"representative_block\": \"0000000000000000000000000000000000000000000000000000000000000000\",\r\n \"balance\": \"903999998070000000000000000000000\",\r\n \"modified_timestamp\": \"1552965628\",\r\n \"request_count\": \"139\",\r\n \"sequence\": \"118\",\r\n \"tokens\": {\r\n  \"7D5B63D781C80A9FD441C948B4EFC8FE47EE2B08FC1AA1DA2ACDDE388B3899FB\": {\r\n   \"whitelisted\": \"false\",\r\n   \"frozen\": \"false\",\r\n   \"balance\": \"49930000\"\r\n  },\r\n  \"31C654F435FC34D3AFF05E043905B2FF05C179AAC07079E361D1C73D9BE08AEF\": {\r\n   \"whitelisted\": \"true\",\r\n   \"frozen\": \"false\",\r\n   \"balance\": \"90000000000000000000000000000000\"\r\n  },\r\n  \"8A00DF994608BB966F62E8DC664288246C3F9A39365F2F7C5A4EBC9CEAD6E059\": {\r\n   \"whitelisted\": \"false\",\r\n   \"frozen\": \"false\",\r\n   \"balance\": \"1682999999999999999999995999790000\"\r\n  }\r\n }\r\n}".data(using: .utf8)!
        default:
            return Data()
        }
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
                "targetURL": LogosDelegateService.loadBalancedUrl().absoluteString,
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
        case .tokenAccountInfo(let account), .accountInfo2(let account):
            return .requestParameters(parameters: [
                "account": account,
                "targetURL": LogosDelegateService.loadBalancedUrl().absoluteString,
                "rpc_action": "account_info",
            ], encoding: JSONEncoding.default)
        case .accountInfo(let account):
            return params(for: "account_info", params: ["account": account])
        case .accountHistory2(let account, let count):
            return .requestParameters(parameters: [
                "account": account,
                "targetURL": LogosDelegateService.loadBalancedUrl().absoluteString,
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
