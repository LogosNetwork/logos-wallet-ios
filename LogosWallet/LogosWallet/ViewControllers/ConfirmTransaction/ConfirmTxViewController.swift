//
//  ConfirmTxViewController.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/30/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit
import LocalAuthentication
import AVFoundation

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
        guard let amountValue = BDouble(txInfo.amount) else { return }
        contentView?.layer.cornerRadius = 10.0
        contentView?.clipsToBounds = true
        confirmButton?.backgroundColor = AppStyle.Color.logosBlue
        balanceLabel?.text = "\(txInfo.balance.trimTrailingZeros()) \(CURRENCY_NAME)"
        amountLabel?.text = "\(txInfo.amount.trimTrailingZeros()) \(CURRENCY_NAME)"
        let secondaryAmount = Currency.secondary.convertToFiat(amountValue, isRaw: false)
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
        let replacePrefix: (String?) -> String = { str in
            return str?.replacingOccurrences(of: "lgn_", with: "xrb_") ?? ""
        }

        guard let amountValue = BDouble(txInfo.amount), amountValue > 0.0,
            let privateKey = WalletManager.shared.testAccount?.privateKey,
            let previous = WalletManager.shared.testAccountInfo?.frontier else {
            return
        }

        let account = replacePrefix(WalletManager.shared.testAccount?.address)
        let recipientAccount = replacePrefix(txInfo.recipientAddress)
        Lincoln.log("Sending \(txInfo.amount) \(CURRENCY_NAME) to '\(txInfo.recipientAddress)'", inConsole: true)
        UIView.animate(withDuration: 0.3) {
            self.contentView?.alpha = 0.0
        }
        LoadingView.startAnimating(in: self.navigationController)

        let rep = "0000000000000000000000000000000000000000000000000000000000000000"
        let parameters = BlockCreateParameters(account: account, amount: txInfo.amount, destination: recipientAccount, previous: previous, privateKey: privateKey, representative: rep)
        NetworkAdapter.createBlock(parameters: parameters) { (block, error) in
            guard error == nil, let block = block else {
                Banner.show("Error on block create: \(error?.localizedDescription ?? "")", style: .danger)
                LoadingView.stopAnimating()
                return
            }

            NetworkAdapter.process(block: block) { [weak self] (response, error) in
                guard error == nil else {
                    Banner.show("Error on process: \(error?.localizedDescription ?? "") ", style: .danger)
                    LoadingView.stopAnimating()
                    return
                }
                SoundManager.shared.play(.send)
                LoadingView.stopAnimating(true) {
                    self?.onSendComplete?()
                    self?.dismiss(animated: true)
                }
            }
        }

    }

    fileprivate func legacySend() {
        guard let amountValue = BDouble(txInfo.amount), amountValue > 0.0,
            let keyPair = WalletManager.shared.keyPair(at: txInfo.accountInfo.index),
            let account = keyPair.lgnAccount else { return }

        // Generate block
        var block = StateBlock(intent: .send)
        block.previous = txInfo.accountInfo.frontier.uppercased()
        block.transactionAmounts = [txInfo.amount]
        block.targetAddresses = [txInfo.recipientAddress]
        guard block.build(with: keyPair) else { return }

        Lincoln.log("Sending \(txInfo.amount) \(CURRENCY_NAME) to '\(txInfo.recipientAddress)'", inConsole: true)
        UIView.animate(withDuration: 0.3) {
            self.contentView?.alpha = 0.0
        }
        LoadingView.startAnimating(in: self.navigationController)
        BlockHandler.handle(block, for: account) { [weak self] (result) in
            switch result {
            case .success(_):
                LoadingView.stopAnimating(true) {
                    self?.onSendComplete?()
                    self?.dismiss(animated: true)
                }
            case .failure(let error):
                Banner.show(.localize("send-error-arg", arg: error.description), style: .danger)
                UIView.animate(withDuration: 0.3) {
                    self?.contentView?.alpha = 1.0
                }
            }
        }
    }
}
