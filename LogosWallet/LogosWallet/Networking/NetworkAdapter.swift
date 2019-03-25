//
//  NetworkAdapter.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/20/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import Moya
import Result

public struct NetworkAdapter {
    
    enum APIError: Error {
        case fork
        case oldBlock
        case badResponse
        // May actually be known, just didnt account for it here yet
        case unknown(message: String)
        
        static func parseError(_ msg: String?) -> APIError? {
            guard let msg = msg else { return nil }
            switch msg {
            case "Fork":
                return .fork
            case "Old block":
                return .oldBlock
            default:
                return .unknown(message: msg)
            }
        }
        
        var message: String {
            switch self {
            case .fork: return "Fork detected"
            case .oldBlock: return "Old block detected"
            case .badResponse: return "Bad response"
            case .unknown(message: let msg): return msg
            }
        }
        // TODO: get other error messages
    }

    static var baseNodeUrl: URL {
        get {
            if let url = UserDefaults.standard.url(forKey: "baseNodeUrl") {
                return url
            } else {
                return URL(string: "http://107.22.128.62:55000")!
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "baseNodeUrl")
        }
    }
    static let provider = MoyaProvider<LogosService>()
    static let ninjaProvider = MoyaProvider<NanoNodeNinjaService>()
    static let delegateProvider = MoyaProvider<LogosDelegateService>()

    // MARK: - Logos Delegate

    static func networkDelegates(_ completion: @escaping ([String: String]?, APIError?) -> Void) {
        self.request(target: .delegates, success: { (response) in
            do {
                let json = try JSONSerialization.jsonObject(with: response.data, options: [])
                completion(json as? [String: String], nil)
            } catch {
                completion(nil, .badResponse)
            }
        })
    }

    // MARK: - Logos

    static func blockInfo(hash: String, completion: @escaping (TransactionBlock?, APIError?) -> Void) {
        request(target: .block(hash: hash), success:  { (response) in
            do {
                let block = try JSONDecoder().decode(TransactionBlock.self, from: response.data)
                completion(block, nil)
            } catch {
                completion(nil, .badResponse)
            }
        })
    }

    static func blockInfo(hashes: [String], completion: @escaping ([BlockInfo], APIError?) -> Void) {
        request(target: .blockInfo(hashes: hashes), success:  { (response) in
            guard let json = try? response.mapJSON() as? [String: Any],
                let blocks = json?["blocks"] as? [String: [String: Any]] else {
                completion([], APIError.badResponse)
                return
            }
            completion(hashes.map { BlockInfo(blocks[$0]) }, nil)
        })
    }

    // Temp action
    static func createBlock(parameters: BlockCreateParameters, completion: ((APIError?) -> Void)? = nil) {
        Lincoln.log("Creating block with parameters: \(parameters)")
        request(target: .blockCreate(parameters: parameters), success: { (response) in
            guard let json = try? response.mapJSON() as? [String: String] else {
                completion?(APIError.badResponse)
                return
            }
            Lincoln.log("Block Create Response: \(json ?? [:])", inConsole: true)
            let error = APIError.parseError(json?["error"])
            completion?(error)
        })
    }

    static func accountInfo2(for account: String, completion: ((LogosAccountInfo?, APIError?) -> Void)? = nil) {
        request(target: .accountInfo2(account: account), success: { (response) in
            if let accountInfo = Decoda.decode(LogosAccountInfo.self, strategy: .useDefaultKeys, from: response.data) {
                completion?(accountInfo, nil)
            } else {
                completion?(nil, .badResponse)
            }
        })
    }

    static func accountInfo(for account: String, completion: ((AccountInfoResponse?, APIError?) -> Void)? = nil) {
        request(target: .accountInfo(account: account), success: { (response) in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let accountInfo = try decoder.decode(AccountInfoResponse.self, from: response.data)
                completion?(accountInfo, nil)
            } catch {
                completion?(nil, .badResponse)
            }
        })
    }

    static func process(block: BlockAdapter, completion: ((String?, APIError?) -> Void)? = nil) {
        Lincoln.log("Broadcasting block '\(block.json)'", inConsole: true)
        request(target: .process(block: block), success: { (response) in
            guard let json = try? response.mapJSON() as? [String: String] else {
                completion?(nil, APIError.badResponse)
                return
            }
            Lincoln.log("Process Response: \(json ?? [:])", inConsole: true)
            let hash = json?["hash"]
            let error = APIError.parseError(json?["error"])
            completion?(hash, error)
        })
    }
    
    static func createAccountForSub(_ walletID: String, username: String, password: String, completion: @escaping (String?) -> Void) {
        request(target: .createServerAccount(walletID: walletID, username: username, password: password), success: { (response) in
            guard let json = try? response.mapJSON() as? [String: String] else { completion(nil); return }
            completion(json?["status"])
        })
    }
    
    static func getAccountHistory(account: String, count: Int, completion: @escaping ([TransactionBlock], Error?) -> Void) {
        request(target: .accountHistory(address: account, count: count), success: { (response) in
            let history: [TransactionBlock]
            var error: Error?
            if let accountHistory = Decoda.decode(AccountHistory.self, strategy: .useDefaultKeys, from: response.data) {
                history = accountHistory.history
            } else {
                history = []
                if let errorJson = try? response.mapJSON() as? [String: String],
                    let errorString = errorJson?["error"] {
                    error = NSError(domain: "NetworkAdapter", code: 1337, userInfo: [NSLocalizedDescriptionKey: errorString])
                }
            }
            completion(history, error)
        })
    }

    static func getAccountHistory2(account: String, count: Int, completion: @escaping (LogosAccountHistory?, Error?) -> Void) {
        request(target: .accountHistory2(address: account, count: count), success: { (response) in
            var result: LogosAccountHistory?
            var error: Error?
            if let accountHistory = Decoda.decode(LogosAccountHistory.self, strategy: .useDefaultKeys, from: response.data) {
                result = accountHistory
            } else {
                if let errorJson = try? response.mapJSON() as? [String: String],
                    let errorString = errorJson?["error"] {
                    let err = NSError(domain: "NetworkAdapter", code: 1337, userInfo: [NSLocalizedDescriptionKey: errorString])
                    error = err
                }
            }
            completion(result, error)
        })
    }
    
    static func getWork(hash: String, completion: @escaping (String?) -> Void) {
        Lincoln.log("Fetching work on '\(hash)'", inConsole: true)
        request(target: .generateWork(hash: hash), success: { (response) in
            let json = try? response.mapJSON() as? [String: String]
            completion(json??["work"])
        })
    }
    
    static func getPending(for account: String, count: Int = 4096, completion: @escaping ([String]) -> Void) {
        request(target: .pending(accounts: [account], count: count), success: { (response) in
            do {
                let json = try response.mapJSON() as? [String: Any]
                guard let blocks = json?["blocks"] as? [String: Any],
                    let pending = blocks[account] as? [String] else { completion([]); return }
                Lincoln.log("Pending blocks \(pending)", inConsole: true)
                completion(pending)
            } catch {
                completion([])
            }
        })
    }
    
    // MARK: - Nano Node Ninja
    
    static func getVerifiedReps(completion: @escaping ([VerifiedAccount]) -> Void) {
        request(target: .verified, success: { (response) in
            do {
                let accounts = try JSONDecoder().decode([VerifiedAccount].self, from: response.data)
                completion(accounts)
            } catch {
                completion([])
            }
        })
    }
    // MARK: - Helper

    static func request(target: LogosDelegateService, success successCallback: @escaping (Response) -> Void, error errorCallback: ((Swift.Error) -> Void)? = nil, failure failureCallback: ((MoyaError) -> Void)? = nil) {
        delegateProvider.request(target) { (result) in
            handleResult(result, success: successCallback, error: errorCallback, failure: failureCallback)
        }
    }

    static func request(target: NanoNodeNinjaService, success successCallback: @escaping (Response) -> Void, error errorCallback: ((Swift.Error) -> Void)? = nil, failure failureCallback: ((MoyaError) -> Void)? = nil) {
        ninjaProvider.request(target) { (result) in
            handleResult(result, success: successCallback, error: errorCallback, failure: failureCallback)
        }
    }
    
    static func request(target: LogosService, success successCallback: @escaping (Response) -> Void, error errorCallback: ((Swift.Error) -> Void)? = nil, failure failureCallback: ((MoyaError) -> Void)? = nil) {
        provider.request(target) { (result) in
            handleResult(result, success: successCallback, error: errorCallback, failure: failureCallback)
        }
    }
    
    fileprivate static func handleResult(_ result: Result<Response, MoyaError>, success successCallback: @escaping (Response) -> Void, error errorCallback: ((Swift.Error) -> Void)? = nil, failure failureCallback: ((MoyaError) -> Void)? = nil) {
        switch result {
        case .success(let response):
            #if DEBUG
                if let url = response.request?.url?.absoluteString, let json = try? response.mapJSON() {
                    var status = "\nSTATUS CODE: \(response.statusCode)\nURL: \(url)"
                    if let requestData = response.request?.httpBody, let requestBody = String(data: requestData, encoding: .utf8) {
                        status += "\nREQUEST BODY: \(requestBody)"
                    }
                    status += "\nRESPONSE BODY: \(json)"
                    Lincoln.log(status)
                }
            #endif
            if response.statusCode >= 200 && response.statusCode <= 300 {
                successCallback(response)
            } else {
                let error = NSError(domain: "com.prometheanlabs.logoswallet", code: 420, userInfo: [NSLocalizedDescriptionKey: "Network Error"])
                errorCallback?(error)
            }
        case .failure(let error):
            failureCallback?(error)
        }
    }
}
