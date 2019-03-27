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
    private(set) var chain = [TransactionRequest]()
    private(set) var refinedChain = [TransactionRequest]()
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
    var updateView: (() -> Void)?
    
    var count: Int {
        return self.refinedChain.count
    }
    
    init(with account: LogosAccount) {
        self.account = account
        self.chain = LogosStore.getHistory(for: self.account.address)?.history ?? []
        self.refinedChain = self.chain
    }
    
    subscript(index: Int) -> TransactionRequest? {
        guard index < self.refinedChain.count else { return nil }
        return self.refinedChain[index]
    }
    
    func toggleCurrency() {
        Currency.setSecondary(!self.isShowingSecondary)
    }

    func getAccountInfo(completion: (() -> Void)? = nil) {
        guard let address = self.account.address else {
            return
        }
        NetworkAdapter.accountInfo2(for: address) { [weak self] (accountInfo, _) in
            guard let info = accountInfo else {
                completion?()
                return
            }
            self?.account.info = info
            LogosStore.update(account: address, info: info)
            completion?()
        }
    }
    
    func getHistory(completion: @escaping (Error?) -> Void) {
        guard let address = self.account.address else {
            return
        }
        NetworkAdapter.getAccountHistory2(account: address, count: self.account.requestCount + 1) { (history, error) in
            if let error = error {
                // TEMP: ignore error if no previous block history exists, otherwise assume that the testnet has been reset
                if self.account.requestCount > 0, (error as NSError).code == 1337, history?.history.isEmpty ?? true {
                    completion(error)
                } else {
                    completion(nil)
                }
            } else if let history = history {
                self.chain = history.history
                self.refinedChain = history.history
                LogosStore.updateHistory(for: address, history: history)
                completion(nil)
            }
        }
    }

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
            self.refinedChain = self.chain.filter { $0.isReceive(of: address) }
        case .sent:
            self.refinedChain = self.chain.filter { !$0.isReceive(of: address) }
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
