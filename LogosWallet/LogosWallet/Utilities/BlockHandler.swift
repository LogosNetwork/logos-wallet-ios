//
//  BlockHandler.swift
//  LogosWallet
//
//  Created by Ben Kray on 5/10/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation
import RxSwift

class BlockHandler {

    static let shared = BlockHandler()
    let incomingBlockSubject = PublishSubject<TransactionBlock>()

    enum BlockHandlerError: Error {
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
                    return "Something happened when processing the block"
                }
            case .unknown: return "Unknown"
            case .alreadyInProgress: return "Broadcast already in progress"
            }
        }
    }
    enum Result {
        case success(String)
        case failure(BlockHandlerError)
    }
    
    fileprivate static var processing: Set<String> = []
    
    static func handle(_ block: StateBlock, for account: String, completion: @escaping (BlockHandler.Result) -> Void) {
        var block = block
        guard let accountPublic = WalletUtil.derivePublic(from: account) else {
            completion(.failure(.unknown))
            return
        }
        let workInput = block.previous
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
            block.work = work
            NetworkAdapter.process(block: block) { (blockHash, error) in
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


    func handleIncoming(blockData: Data, for address: String) {
        guard
            let transactionBlock = Decoda.decode(TransactionBlock.self, strategy: .useDefaultKeys, from: blockData),
            let account = WalletManager.shared.accounts.first(where: { $0.address == address })
        else {
            return
        }

        if WalletManager.shared.accounts.filter({ $0.address == transactionBlock.account }).isEmpty {
            // play receive sound for when sender address is not from this wallet
            SoundManager.shared.play(.receive)
        }
        NetworkAdapter.accountInfo(for: address) { [weak self] (info, error) in
            guard let accountInfo = info else { return }
            let blockCount = Int(accountInfo.blockCount) ?? 0
            PersistentStore.write {
                account.balance = accountInfo.balance
                account.frontier = accountInfo.frontier
                account.blockCount = blockCount
            }
            NetworkAdapter.getAccountHistory(account: address, count: blockCount) { chain, _ in
                PersistentStore.updateBlockHistory(for: account, history: chain.compactMap({ $0.simpleBlock(account: address) }))
                WalletManager.shared.updateAccounts()
                self?.incomingBlockSubject.onNext(transactionBlock)
            }
        }
    }
}
