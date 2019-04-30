//
//  ConfirmTxViewController.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/30/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit
import LocalAuthentication

class ConfirmTxViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView?
    @IBOutlet weak var balanceTitleLabel: UILabel?
    @IBOutlet weak var amountTitleLabel: UILabel?
    @IBOutlet weak var recipientTitleLabel: UILabel?
    @IBOutlet weak var balanceLabel: UILabel?
    @IBOutlet weak var amountLabel: UILabel?
    @IBOutlet weak var secondaryAmountLabel: UILabel?
    @IBOutlet weak var recipientAddressLabel: UILabel?
    @IBOutlet weak var recipientNameLabel: UILabel?
    @IBOutlet weak var contentView: UIView?
    @IBOutlet weak var confirmButton: UIButton?
    var onBlockGenerated: (() -> Void)?
    var onSendComplete: (() -> Void)?
    let txInfo: TxInfo
    var currencyText: String {
        if let tokenID = self.txInfo.tokenID, let tokenInfo = LogosTokenManager.shared.tokenAccounts[tokenID] {
            return tokenInfo.symbol
        } else {
            return CURRENCY_NAME
        }
    }
    
    init(with txInfo: TxInfo) {
        self.txInfo = txInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupView()
    }
    
    // MARK: - Setup
    
    fileprivate func setupNavBar() {
        let leftBarItem = UIBarButtonItem(image: #imageLiteral(resourceName: "close2").withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(closeTapped))
        leftBarItem.tintColor = .white
        navigationItem.leftBarButtonItem = leftBarItem
    }
    
    fileprivate func setupView() {
        contentView?.layer.cornerRadius = 10.0
        contentView?.clipsToBounds = true
        confirmButton?.backgroundColor = AppStyle.Color.logosBlue
        balanceLabel?.text = "\(self.txInfo.remainingBalance) \(self.currencyText)"
        amountLabel?.text = "\(txInfo.amount.formattedAmount) \(self.currencyText)"
        let secondaryAmount = Currency.secondary.convert(txInfo.amount.decimalNumber, isRaw: false)
        secondaryAmountLabel?.text = "\(secondaryAmount) \(Currency.secondary.rawValue.uppercased())"
        if let _ = self.txInfo.tokenID {
            self.secondaryAmountLabel?.text = "--"
        }
        recipientNameLabel?.text = txInfo.recipientName
        recipientAddressLabel?.text = txInfo.recipientAddress
        [recipientTitleLabel, amountTitleLabel, balanceTitleLabel, recipientNameLabel, amountLabel, balanceLabel].forEach {
            $0?.textColor = AppStyle.Color.offBlack
        }
    }
    
    // MARK: - Actions
    
    @IBAction func confirmTapped(_ sender: Any) {
        let context = LAContext()
        var error: NSError? = NSError()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            && UserSettings.requireBiometricsOnSend {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authorization is required to proceed with the transaction.", reply: { (success, error) in
                guard success else { return }
                DispatchQueue.main.async {
                    self.handleSend()
                }
            })
        } else {
            handleSend()
        }
    }
    
    @objc fileprivate func closeTapped() {
        if LoadingView.isAnimating {
            // Send is still in progress. If cancel is pressed before work finishes then we're safe since the callback will fire and self should be nil, however there is an edge case where the process request may already be sent up. 
            Banner.show(.localize("send-cancelled"), style: .warning)
        }
        dismiss(animated: true)
    }
    
    fileprivate func handleSend() {
        guard
            self.txInfo.amount.decimalNumber.decimalValue > 0.0,
            let keyPair = WalletManager.shared.keyPair(at: self.txInfo.account.index),
            let origin = keyPair.lgsAccount,
            let _ = WalletUtil.derivePublic(from: self.txInfo.recipientAddress),
            let info = self.txInfo.account.info
        else {
            return
        }

        let request: SendRequest
        if let tokenID = self.txInfo.tokenID {
            request = self.createTokenSend(info: info, tokenID: tokenID)
        } else {
            request = self.createSend(info: info)
        }
        request.origin = origin
        request.previous = info.frontier.uppercased()
        request.sequence = NSDecimalNumber(string: info.sequence)
        request.fee = NSDecimalNumber(string: "10000000000000000000000")

        guard
            request.sign(with: keyPair)
        else {
            Lincoln.log("Problem building block: \(request.json)")
            return
        }
        
        Lincoln.log("Sending \(txInfo.amount) \(self.currencyText) to '\(txInfo.recipientAddress)'", inConsole: true)
        UIView.animate(withDuration: 0.3) {
            self.contentView?.alpha = 0.0
        }
        LoadingView.startAnimating(in: self.navigationController)
        NetworkAdapter.process(request: request) { [weak self] (hash, error) in
            if let error = error {
                Banner.show("\(error.message)", style: .danger)
                LoadingView.stopAnimating(true) {
                    self?.dismiss(animated: true)
                }
            } else {
                LoadingView.stopAnimating(true) {
                    self?.onSendComplete?()
                    self?.dismiss(animated: true)
                }
            }
        }
    }

    private func createTokenSend(info: LogosAccountInfo, tokenID: String) -> SendRequest {
        let feeRate = LogosTokenManager.shared.tokenAccounts[tokenID]?.feeRate ?? "0"
        let request = TokenSendRequest(tokenID: tokenID, tokenFee: feeRate.decimalNumber)
        request.work = "0"
        request.transactions = [
            Transaction(destination: self.txInfo.recipientAddress, amount: self.txInfo.amount),
        ]
        return request
    }

    private func createSend(info: LogosAccountInfo) -> SendRequest {
        let request = SendRequest()
        request.work = "0000000000000000"
        request.transactions = [
            Transaction(destination: self.txInfo.recipientAddress, amount: self.txInfo.amount.decimalNumber.lgsRawString),
        ]
        return request
    }

}
