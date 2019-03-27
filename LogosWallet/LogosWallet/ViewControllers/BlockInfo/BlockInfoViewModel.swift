//
//  BlockInfoViewModel.swift
//  LogosWallet
//
//  Created by Ben Kray on 4/23/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import Foundation

class BlockInfoViewModel {
    let info: TransactionRequest
    private(set) var model: TransactionRequest?
    var localizedDate: String? {
        guard
            let timestamp = model?.timestamp,
            let epoch = Float(timestamp)
        else {
            return nil
        }
        let date = Date(timeIntervalSince1970: TimeInterval(epoch / 1000.0))
        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
    }
    var isMultiTx: Bool {
        return self.model?.transactions != nil
    }

    init(with info: TransactionRequest) {
        self.info = info
    }
    
    func fetch(_ completion: @escaping () -> Void) {
        NetworkAdapter.blockInfo(hash: self.info.hash) { [weak self] (info, error) in
            guard error == nil else {
                Banner.show(error?.localizedDescription ?? "Fetch error", style: .danger)
                completion()
                return
            }
            self?.model = info
            completion()
        }
    }
}
