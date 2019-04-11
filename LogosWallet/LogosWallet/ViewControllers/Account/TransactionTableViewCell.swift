//
//  TransactionTableViewCell.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/11/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {

    static let reuseIdentifier = "\(self)"

    let timeLabel = with(UILabel()) {
        $0.textColor = .white
        $0.font = AppStyle.Font.subhead
        $0.textAlignment = .right
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }

    let originLabel = with(UILabel()) {
        $0.textColor = AppStyle.Color.lowAlphaWhite
        $0.font = AppStyle.Font.lightSubtitle
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.lineBreakMode = .byTruncatingMiddle
    }

    let requestTypeLabel = with(UILabel()) {
        $0.textColor = .white
        $0.font = AppStyle.Font.subhead
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    let subtitleLabel = with(UILabel()) {
        $0.textColor = AppStyle.Color.lowAlphaWhite
        $0.font = AppStyle.Font.lightSubtitle
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

//    let contentStackView = with(UIStackView()) {
//        $0.axis = .vertical
//        $0.spacing = AppStyle.Size.smallPadding
//    }

    let expandedStackView = with(UIStackView()) {
        $0.axis = .vertical
        $0.spacing = AppStyle.Size.smallPadding
    }

    let typeImageView = with(UIImageView()) {
        $0.contentMode = .scaleAspectFit
        $0.tintColor = .white
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        let baseContentView = UIView()
        self.addSubview(baseContentView)
        baseContentView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppStyle.Size.padding)
            make.right.equalToSuperview().offset(-AppStyle.Size.padding)
            make.left.equalToSuperview().offset(AppStyle.Size.padding)
        }

        baseContentView.addSubview(self.typeImageView)
        self.typeImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.height.width.equalTo(20.0)
        }

        let leftStackView = with(UIStackView()) {
            $0.axis = .vertical
        }
        leftStackView.addArrangedSubview(self.requestTypeLabel)
        leftStackView.addArrangedSubview(self.subtitleLabel)

        baseContentView.addSubview(leftStackView)
        leftStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(self.typeImageView.snp.right).offset(AppStyle.Size.padding)
            make.bottom.equalToSuperview()
        }

        let rightStackView = with(UIStackView()) {
            $0.axis = .vertical
        }
        rightStackView.addArrangedSubview(self.timeLabel)
        rightStackView.addArrangedSubview(self.originLabel)

        baseContentView.addSubview(rightStackView)
        rightStackView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalTo(rightStackView)
            make.left.equalTo(leftStackView.snp.right).offset(AppStyle.Size.extraSmallPadding)
            make.bottom.equalToSuperview()
        }

        self.addSubview(self.expandedStackView)
        self.expandedStackView.snp.makeConstraints { make in
            make.top.equalTo(baseContentView.snp.bottom)
            make.left.right.equalTo(baseContentView)
            make.bottom.equalToSuperview().offset(-AppStyle.Size.padding)
        }

        self.originLabel.snp.makeConstraints { make in
            make.width.equalTo(self.timeLabel.snp.width).priority(.required)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.requestTypeLabel.text = ""
        self.timeLabel.text = ""
        self.subtitleLabel.text = ""
        self.originLabel.text = ""
//        self.contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }

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

        self.requestTypeLabel.text = tx.typeText
        self.timeLabel.text = tx.formattedTimestamp
        self.originLabel.text = tx.origin

        switch tx.type {
        case "send":
            self.layoutSend(tx: tx, owner: owner)
        case "distribute":
            self.layoutDistribute(tx: tx)
        case "token_send":
            self.layoutTokenSend(tx: tx, owner: owner)
        default:
            break
        }
//        let sourceDestination: String
//        if tx.isReceive(of: owner) {
//            // receive
//            self.typeIndicatorLabel?.text = "+"
//            self.typeLabel?.text = .localize("received-filter")
//            sourceDestination = tx.origin
//        } else {
//            // send
//            self.typeIndicatorLabel?.text = "-"
//            self.typeLabel?.text = .localize("sent-filter")
//            // TODO: handle multiple
//            sourceDestination = tx.transactions?.first?.destination ?? ""
//        }
//        let secondary = Currency.secondary
//        let stringValue: String
//        if useSecondaryCurrency {
//            let converted = secondary.convert(tx.amountTotal(for: owner))
//            stringValue = "\(converted) " + secondary.rawValue.uppercased()
//        } else {
//            stringValue = "\(tx.amountTotal(for: owner).mlgsString.formattedAmount) \(CURRENCY_NAME)"
//        }
//        amountLabel?.text = stringValue
//        let alias = PersistentStore.getAddressEntries().first(where: { $0.address == sourceDestination })?.name
//        sourceDestLabel?.text = alias ?? sourceDestination
    }

    private func layoutSend(tx: TransactionRequest, owner: String) {
        if tx.isReceive(of: owner) {
            self.typeImageView.image = #imageLiteral(resourceName: "download-arrow").withRenderingMode(.alwaysTemplate)
        } else {
            self.typeImageView.image = #imageLiteral(resourceName: "paper-plane").withRenderingMode(.alwaysTemplate)
        }
        self.subtitleLabel.text = "\(tx.amountTotal(for: owner).mlgsString.formattedAmount) \(CURRENCY_NAME)"
    }

    private func layoutDistribute(tx: TransactionRequest) {
        guard
            let tokenId = tx.tokenID,
            let tokenInfo = LogosTokenManager.shared.tokenAccounts[tokenId]
        else {
            return
        }

        self.typeImageView.image = #imageLiteral(resourceName: "box").withRenderingMode(.alwaysTemplate)
        if let distributeTransaction = tx.transaction {
            self.subtitleLabel.text = "\(distributeTransaction.amount) \(tokenInfo.symbol)"
        }
    }

    func layoutTokenSend(tx: TransactionRequest, owner: String) {
        guard
            let tokenId = tx.tokenID,
            let tokenInfo = LogosTokenManager.shared.tokenAccounts[tokenId]
        else {
            return
        }

        self.subtitleLabel.text = "\(tx.amountTotal(for: owner).stringValue) \(tokenInfo.symbol)"
    }
    
}

extension TransactionRequest {

    var formattedTimestamp: String {
        // timestamp in milliseconds
        guard let timestampValue = TimeInterval(self.timestamp) else {
            return "--"
        }

        let date = Date(timeIntervalSince1970: timestampValue / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"

        return formatter.string(from: date)
    }

    var typeText: String {
        let result: String
        switch self.type {
        case "send":
            result = "Send"
        case "distribute":
            result = "Token Distribute"
        case "token_send":
            result = "Token Send"
        default:
            result = "Request"
        }
        return result
    }

}
