//
//  AccountViewModel.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/12/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

class AccountViewModel {
    
    enum RefineType {
        case latestFirst
        case oldestFirst
        case largestFirst
        case smallestFirst
        case sent
        case received
        
        var title: String {
            switch self {
            case .latestFirst: return String.localize("latest-sort").uppercased()
            case .oldestFirst: return String.localize("oldest-sort").uppercased()
            case .smallestFirst: return String.localize("smallest-sort").uppercased()
            case .largestFirst: return String.localize("largest-sort").uppercased()
            case .received: return String.localize("received-filter").uppercased()
            case .sent: return String.localize("sent-filter").uppercased()
            }
        }
    }
    
    private(set) var isFetching = false
    private(set) var account: LogosAccount
    private(set) var accountHistory: LogosAccountHistory?
    private(set) var chain = [HistoryTransactionBlock]()
    private(set) var refinedChain = [HistoryTransactionBlock]()
    private(set) var blockCheck: Set<String> = []
    private(set) var balance: AccountBalance?
    var isShowingSecondary: Bool {
        return Currency.isSecondarySelected
    }
    var balanceValue: String {
        guard let info = self.account.info else {
            return self.isShowingSecondary ? "0".formattedBalance : Currency.secondary.convert(0)
        }
        if self.isShowingSecondary {
            return Currency.secondary.convert(info.balance.decimalNumber)
        } else {
            return info.formattedBalance
        }
    }
    // TODO: clean up currency stuff
    var currencyValue: String {
        if self.isShowingSecondary {
            return Currency.secondary.denomination
        } else {
            return CURRENCY_NAME
        }
    }
    private(set) var refineType: RefineType = .latestFirst
    var onNewBlockBroadcasted: (() -> Void)?
    var updateView: (() -> Void)?
    
    var count: Int {
        return self.refinedChain.count
    }
    
    init(with account: LogosAccount) {
        self.account = account
        self.chain = LogosStore.getHistory(for: self.account.address)?.history ?? []
        self.refinedChain = self.chain
    }
    
    subscript(index: Int) -> HistoryTransactionBlock? {
        guard index < self.refinedChain.count else { return nil }
        return self.refinedChain[index]
    }
    
    func toggleCurrency() {
        Currency.setSecondary(!self.isShowingSecondary)
    }
    
    /// Recursively handle pending
//    func handlePending(_ pending: [String], previous: String, shouldOpen: Bool) {
//        guard !pending.isEmpty,
//            let keyPair = WalletManager.shared.keyPair(at: account.index),
//            let account = keyPair.lgnAccount else { return }
//        var remaining = pending
//        // Pending block order in array is newest -> oldest
//        let source = remaining.removeLast()
//        isFetching = true
//        NetworkAdapter.blockInfo(hashes: [source]) { [weak self] (info, error) in
//            self?.isFetching = false
//            guard let me = self,
//                let amount = info.first?.amount,
//                let balance = BInt(me.account.balance),
//                let amt = BInt(amount) else { return }
//            var block = shouldOpen ? StateBlock(intent: .open) : StateBlock(intent: .receive)
//            let randomRep = WalletManager.shared.getRandomRep()?.account ?? account
//            block.previous = previous
//            block.targetAddresses = [source]
//            block.transactionAmounts = [amount]
//            if me.account.representative.isEmpty {
//                block.representative = randomRep
//            } else {
//                block.representative = me.account.representative
//            }
//            guard me.account.balance.bNumber + amount.bNumber >= me.account.balance.bNumber else {
//                Banner.show("Account balance should be greater than previous balance", style: .danger)
//                return
//            }
//            guard block.build(with: keyPair) else { return }
//            if shouldOpen {
//                Banner.show(.localize("opening-account"), style: .success)
//            }
//            me.isFetching = true
//            BlockHandler.handle(block, for: account) { (result) in
//                me.isFetching = false
//                switch result {
//                case .success(let newHash):
//                    // Balance must be updated otherwise consecutive recieves can be seen as sends due to a negative balance
//                    PersistentStore.write {
//                        // TODO: come back to this
//                        me.account.balance = (me.account.balance.bNumber + amount.bNumber).toMlgn
//                    }
//                    me.handlePending(remaining, previous: newHash, shouldOpen: false)
//                    me.onNewBlockBroadcasted?()
//                case .failure(let error):
//                    Banner.show(.localize("receive-error-arg", arg: error.description), style: .danger)
//                }
//            }
//        }
//    }

    func getAccountInfo(completion: (() -> Void)? = nil) {
        guard let address = self.account.address else {
            return
        }

        NetworkAdapter.accountInfo2(for: address) { [weak self] (accountInfo, _) in
            defer { completion?() }
            guard let info = accountInfo else {
                return
            }
            self?.account.info = info
            LogosStore.update(account: address, info: info)
        }
    }
    
    func getHistory(completion: @escaping (Error?) -> Void) {
        guard let acc: String = WalletManager.shared.keyPair(at: account.index)?.lgsAccount else { return }
        NetworkAdapter.getAccountHistory(account: acc, count: account.blockCount + 1) { (chain, error) in
//            let transformed = chain.compactMap { $0.simpleBlock(account: acc) }
//            for var item in transformed {
//                item.owner = acc
//            }
//            self.history = transformed
//            self.refined = transformed
//            PersistentStore.updateBlockHistory(for: self.account, history: transformed)
            if let error = error {
                // TEMP: ignore error if no previous block history exists, otherwise assume that the testnet has been reset
                if self.account.blockCount > 0, (error as NSError).code == 1337, chain.isEmpty {
                    completion(error)
                } else {
                    completion(nil)
                }
            } else {
//                self.updateSequenceIfNeeded(chain)
                completion(nil)
            }
        }
    }

//    private func updateSequenceIfNeeded(_ chain: [TransactionBlock]) {
//        if self.account.blockCount > 0 && self.account.sequence == 0 {
//            PersistentStore.write {
//                self.account.sequence = chain.filter { $0.account == self.account.address }.count
//            }
//        }
//    }

    func repair(_ completion: @escaping () -> Void) {
//        PersistentStore.removeBlockHistory(for: account.address)
//        refined = []
//        history = []
//        blockCheck.removeAll()
//
//        PersistentStore.write {
//            self.account.repair()
//        }
//        getHistory { _ in
//            if !self.history.isEmpty {
//                self.getAccountInfo {
//                    completion()
//                }
//            } else {
//                completion()
//            }
//        }
    }
    
    func refine(_ type: RefineType) {
        guard let address = self.account.address else {
            return
        }
        switch type {
        case .latestFirst:
            self.refinedChain = self.chain
        case .oldestFirst:
            self.refinedChain = self.chain.reversed()
        case .received:
            self.refinedChain = self.chain.filter { $0.type == "receive" }
        case .sent:
            self.refinedChain = self.chain.filter { $0.type == StateBlock.RequestType.send.string }
        case .largestFirst:
            self.refinedChain = self.chain.sorted(by: { (blockA, blockB) -> Bool in
                return blockA.amountTotal(for: address).compare(blockB.amountTotal(for: address)) == .orderedDescending
            })
        case .smallestFirst:
            self.refinedChain = self.chain.sorted(by: { (blockA, blockB) -> Bool in
                return blockA.amountTotal(for: address).compare(blockB.amountTotal(for: address)) == .orderedAscending
            })
        }
        refineType = type
        updateView?()
    }
}
