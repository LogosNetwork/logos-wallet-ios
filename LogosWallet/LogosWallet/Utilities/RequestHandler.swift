//
//  BlockHandler.swift
//  LogosWallet
//
//  Created by Ben Kray on 5/10/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import RxSwift

class RequestHandler {

    static let shared = RequestHandler()
    let incomingRequestSubject = PublishSubject<TransactionRequest>()

    enum RequestHandlerError: Error {
        case proofOfWork
        case process(String?)
        case unknown
        case alreadyInProgress
        
        var description: String {
            switch self {
            case .proofOfWork: return "Proof of Work"
            case .process(let msg):
                if let msg = msg {
                    return "Process (\(msg))"
                } else {
                    return "Something happened when processing the request"
                }
            case .unknown: return "Unknown"
            case .alreadyInProgress: return "Broadcast already in progress"
            }
        }
    }
    enum Result {
        case success(String)
        case failure(RequestHandlerError)
    }
    
    fileprivate static var processing: Set<String> = []
    
    static func handle(_ request: SendRequest, for account: String, completion: @escaping (RequestHandler.Result) -> Void) {
        var request = request
        guard let accountPublic = WalletUtil.derivePublic(from: account) else {
            completion(.failure(.unknown))
            return
        }
        let workInput = request.previous
        guard !processing.contains(workInput) else {
            completion(.failure(.alreadyInProgress))
            return
        }
        processing.insert(workInput)
        NetworkAdapter.getWork(hash: workInput) { (work) in
            guard let work = work else {
                processing.remove(workInput)
                completion(.failure(.proofOfWork))
                return
            }
            request.work = work
            NetworkAdapter.process(request: request) { (blockHash, error) in
                defer {
                    processing.remove(workInput)
                }
                guard let blockHash = blockHash else {
                    completion(.failure(.process(error?.localizedDescription)))
                    return
                }
                completion(.success(blockHash))
            }
        }
    }


    func handleIncoming(requestData: Data, for address: String) {
        guard
            let transactionRequest = Decoda.decode(TransactionRequest.self, strategy: .useDefaultKeys, from: requestData),
            let _ = WalletManager.shared.accounts.first(where: { $0.address == address })
        else {
            return
        }

        if WalletManager.shared.accounts.filter({ $0.address == transactionRequest.origin }).isEmpty {
            // play receive sound for when sender address is not from this wallet
            SoundManager.shared.play(.receive)
        }
        NetworkAdapter.accountInfo2(for: address) { [weak self] (info, error) in
            guard let accountInfo = info else { return }
            LogosStore.update(account: address, info: accountInfo)
            NetworkAdapter.getAccountHistory2(account: address, count: 10) { history, _ in
                if let history = history {
                    LogosStore.updateHistory(for: address, history: history)
                }
                WalletManager.shared.updateAccounts()
                self?.incomingRequestSubject.onNext(transactionRequest)
            }
        }
    }
}
