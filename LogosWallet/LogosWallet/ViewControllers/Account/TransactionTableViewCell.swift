//
//  TransactionTableViewCell.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/11/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var sourceDestLabel: UILabel?
    @IBOutlet weak var typeIndicatorLabel: UILabel?
    @IBOutlet weak var typeLabel: UILabel?
    @IBOutlet weak var amountLabel: UILabel?
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        self.alpha = highlighted ? 0.3 : 1.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        self.alpha = selected ? 0.3 : 1.0
    }
    
    func prepare(with tx: TransactionRequest?, owner: String, useSecondaryCurrency: Bool) {
        guard let tx = tx else {
            return
        }
        backgroundColor = UIColor.white.withAlphaComponent(0.04)
        contentView.backgroundColor = .clear
        layer.cornerRadius = 10.0

        let sourceDestination: String
        if tx.isReceive(of: owner) {
            // receive
            self.typeIndicatorLabel?.text = "+"
            self.typeLabel?.text = .localize("received-filter")
            sourceDestination = tx.origin
        } else {
            // send
            self.typeIndicatorLabel?.text = "-"
            self.typeLabel?.text = .localize("sent-filter")
            // TODO: handle multiple
            sourceDestination = tx.transactions?.first?.destination ?? ""
        }
        let secondary = Currency.secondary
        let stringValue: String
        if useSecondaryCurrency {
            let converted = secondary.convert(tx.amountTotal(for: owner))
            stringValue = "\(converted) " + secondary.rawValue.uppercased()
        } else {
            stringValue = "\(tx.amountTotal(for: owner).mlgsString.formattedAmount) \(CURRENCY_NAME)"
        }
        amountLabel?.text = stringValue
        let alias = PersistentStore.getAddressEntries().first(where: { $0.address == sourceDestination })?.name
        sourceDestLabel?.text = alias ?? sourceDestination
    }
    
}
