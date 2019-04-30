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
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
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

    let contentStackView = with(UIStackView()) {
        $0.axis = .vertical
        $0.spacing = AppStyle.Size.extraSmallPadding
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
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear

        let content = with(UIView()) {
            $0.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            $0.layer.cornerRadius = 10.0
            $0.addShadow(0.2, radius: 3.0)
        }
        self.addSubview(content)
        content.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(AppStyle.Size.smallPadding)
            make.right.equalToSuperview().offset(-AppStyle.Size.smallPadding)
            make.top.bottom.equalToSuperview()
        }

        let baseContentView = UIView()
        content.addSubview(baseContentView)
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

        content.addSubview(self.contentStackView)
        self.contentStackView.snp.makeConstraints { make in
            make.top.equalTo(baseContentView.snp.bottom).offset(AppStyle.Size.padding)
            make.left.right.equalTo(baseContentView)
            make.bottom.equalToSuperview()
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
        self.typeImageView.image = nil
        self.contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
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

        self.requestTypeLabel.text = tx.typeText
        self.timeLabel.text = tx.formattedTimestamp
        self.originLabel.text = tx.origin

        switch tx.type {
        case .send:
            self.layoutSend(tx: tx, owner: owner)
        case .distribute, .withdrawFee, .withdrawLogos, .revoke, .tokenSend:
            self.layoutTokenRequest(tx: tx, owner: owner)
        case .issuance:
            self.layoutTokenIssuance(tx: tx)
        default:
            break
        }
        if self.contentStackView.arrangedSubviews.count > 0 {
            let padding = UIView()
            padding.snp.makeConstraints { make in make.height.equalTo(AppStyle.Size.padding).priority(999) }
            self.contentStackView.addArrangedSubview(padding)
        }
    }

    private func layoutTokenRequest(tx: TransactionRequest, owner: String) {
        guard
            let tokenId = tx.tokenID,
            let tokenInfo = LogosTokenManager.shared.tokenAccounts[tokenId]
        else {
            return
        }

        if let transactions = tx.transactions {
            self.subtitleLabel.text = "\(tx.amountTotal(for: owner).stringValue) \(tokenInfo.symbol)"
            if transactions.count > 1 {
                transactions.forEach {
                    let stack = self.createHorizontalStack(header: $0.amount.formattedAmount + " \(tokenInfo.symbol)", value: "received by \($0.destination)")
                    self.contentStackView.addArrangedSubview(stack)
                }
            }
        } else if let transaction = tx.transaction {
            let amount: String
            let symbol: String
            if tx.type == .withdrawLogos {
                amount = transaction.amount.decimalNumber.mlgsString.formattedAmount
                symbol = CURRENCY_NAME
            } else if let decimals = tokenInfo.decimals {
                amount = transaction.amount.decimalNumber.formattedValue(decimals).stringValue
                symbol = tokenInfo.symbol
            } else {
                amount = transaction.amount
                symbol = tokenInfo.symbol
            }
            self.subtitleLabel.text = "\(amount) \(symbol)"
        } else {
            self.subtitleLabel.text = "\(tx.name ?? "") \(tokenInfo.symbol)"
        }
        self.typeImageView.image = #imageLiteral(resourceName: "token").withRenderingMode(.alwaysTemplate)
    }

    private func layoutSend(tx: TransactionRequest, owner: String) {
        self.typeImageView.image = #imageLiteral(resourceName: "lambda").withRenderingMode(.alwaysTemplate)
        self.subtitleLabel.text = "\(tx.amountTotal(for: owner).mlgsString.formattedAmount) \(CURRENCY_NAME)"

        if let transactions = tx.transactions, transactions.count > 1 {
            transactions.forEach {
                let stack = self.createHorizontalStack(header: $0.amount.decimalNumber.mlgsString.formattedAmount + " \(CURRENCY_NAME)", value: "received by \($0.destination)")
                self.contentStackView.addArrangedSubview(stack)
            }
        }
    }

    private func layoutTokenIssuance(tx: TransactionRequest) {
        self.subtitleLabel.text = "\(tx.name ?? "") \(tx.symbol ?? "")"
        self.typeImageView.image = #imageLiteral(resourceName: "token").withRenderingMode(.alwaysTemplate)

        guard
            let tokenAccount = tx.tokenID,
            let encodedAccount = try? WalletUtil.deriveLGSAccount(from: tokenAccount.hexData!)
        else {
            return
        }

        let tokenAccountStack = self.createHorizontalStack(header: "Token account:", value: encodedAccount)
        let issuedByStack = self.createHorizontalStack(header: "Issued by:", value: tx.origin)
        let nameStack = self.createHorizontalStack(header: "Name:", value: "\(tx.name ?? "") (\(tx.symbol ?? ""))")
        let supplyStack = self.createHorizontalStack(header: "Total supply:", value: "\(tx.totalSupply ?? "") \(tx.symbol ?? "")")
        let feeRateStack = self.createHorizontalStack(header: "Fee rate:", value: tx.feeRate)
        [tokenAccountStack, issuedByStack, nameStack, supplyStack, feeRateStack].forEach {
            self.contentStackView.addArrangedSubview($0)
        }
    }

    private func createHorizontalStack(header: String, value: String?) -> UIStackView {
        let stackView = with(UIStackView()) {
            $0.axis = .horizontal
            $0.spacing = AppStyle.Size.extraSmallPadding
        }
        let headerLabel = with(UILabel()) {
            $0.textColor = .white
            $0.font = AppStyle.Font.subtitle
            $0.text = header
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.numberOfLines = 1
        }
        let valueLabel = with(UILabel()) {
            $0.textColor = AppStyle.Color.lowAlphaWhite
            $0.font = AppStyle.Font.lightSubtitle
            $0.text = value
            $0.numberOfLines = 1
            $0.textAlignment = .left
            $0.lineBreakMode = .byTruncatingMiddle
        }
        stackView.addArrangedSubview(headerLabel)
        stackView.addArrangedSubview(valueLabel)

        return stackView
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
        case .send:
            result = "Send"
        case .distribute:
            result = "Token Distribute"
        case .tokenSend:
            result = "Token Send"
        case .issuance:
            result = "Token Issuance"
        case .revoke:
            result = "Token Revoke"
        case .adjustFee:
            result = "Token Adjust Fee"
        case .adjustUserStatus:
            result = "Token Adjust User Status"
        case .burn:
            result = "Token Burn"
        case .change:
            result = "Change"
        case .changeSetting:
            result = "Token Change Setting"
        case .immuteSetting:
            result = "Token Immute Setting"
        case .withdrawFee:
            result = "Token Withdraw Fee"
        case .withdrawLogos:
            result = "Withdraw Logos"
        case .issuanceAdditional:
            result = "Token Issuance Additional"
        case .updateController:
            result = "Token Update Controller"
        case .updateIssuerInfo:
            result = "Token Update Issuer"
        case .withdraw:
            result = "Withdraw"
        }
        return result
    }

}
