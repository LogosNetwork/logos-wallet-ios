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
        balanceLabel?.text = "-- \(CURRENCY_NAME)"
        amountLabel?.text = "\(txInfo.amount.formattedAmount) \(CURRENCY_NAME)"
        let secondaryAmount = Currency.secondary.convert(txInfo.amount.decimalNumber, isRaw: false)
        secondaryAmountLabel?.text = "\(secondaryAmount) \(Currency.secondary.rawValue.uppercased())"
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
            let keyPair = WalletManager.shared.keyPair(at: self.txInfo.accountInfo.index),
            let _ = keyPair.lgsAccount,
            let _ = WalletUtil.derivePublic(from: self.txInfo.recipientAddress)
        else {
            return
        }

        var block = StateBlock(type: .send)
        block.work = "0000000000000000"
        block.previous = self.txInfo.accountInfo.frontier.uppercased()
        block.sequence = NSDecimalNumber(integerLiteral: self.txInfo.accountInfo.sequence)
        block.transactionFee = NSDecimalNumber(string: "10000000000000000000000")
        block.transactions = [
            MultiSendTransaction(target: self.txInfo.recipientAddress, amount: self.txInfo.amount.decimalNumber.rawValue),
        ]

        guard
            block.build(with: keyPair)
        else {
            Lincoln.log("Problem building block: \(block.json)")
            return
        }
        
        Lincoln.log("Sending \(txInfo.amount) \(CURRENCY_NAME) to '\(txInfo.recipientAddress)'", inConsole: true)
        UIView.animate(withDuration: 0.3) {
            self.contentView?.alpha = 0.0
        }
        LoadingView.startAnimating(in: self.navigationController)
        NetworkAdapter.process(block: block) { [weak self] (hash, error) in
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
}
