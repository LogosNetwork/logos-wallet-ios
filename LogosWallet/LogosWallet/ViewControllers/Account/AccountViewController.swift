//
//  AccountViewController.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/11/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit
import RxSwift

protocol AccountViewControllerDelegate: class {
    func transactionTapped(txInfo: SimpleBlockBridge)
    func editRepTapped(account: AccountInfo)
    func sendTapped(account: AccountInfo)
    func receiveTapped(account: AccountInfo)
    func backTapped()
}

class AccountViewController: UIViewController {

    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var currencyTapBox: UIView?
    @IBOutlet weak var receiveButton: UIButton?
    @IBOutlet weak var sendButton: UIButton?
    @IBOutlet weak var sortButton: UIButton?
    @IBOutlet weak var totalBalanceTitleLabel: UILabel?
    @IBOutlet weak var totalBalanceLabel: UILabel?
    @IBOutlet weak var unitsLabel: UILabel?
    fileprivate var refreshControl: UIRefreshControl?
    @IBOutlet weak var tableView: UITableView!
    fileprivate var previousOffset: CGFloat = 0.0
    fileprivate var balanceToSortOffset: CGFloat?
    weak var delegate: AccountViewControllerDelegate?
    private(set) var viewModel: AccountViewModel
    private let disposeBag = DisposeBag()
    var pollingTimer: Timer?
    private let feedbackGenerator = UINotificationFeedbackGenerator()

    // MARK: - Object lifecycle

    init(account: AccountInfo) {
        self.viewModel = AccountViewModel(with: account)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: - View lifecycle

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if balanceToSortOffset == nil {
            balanceToSortOffset = totalBalanceLabel?.convert(totalBalanceLabel!.center, to: sortButton!).y ?? 1.0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupView()
        self.setupTableView()
        self.setupNavBar()
        self.setupViewModel()
        self.totalBalanceLabel?.text = self.viewModel.balanceValue

        self.viewModel.getAccountInfo { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.totalBalanceLabel?.text = strongSelf.viewModel.balanceValue
            strongSelf.viewModel.getHistory { error in
                if let _ = error {
                    strongSelf.showWalletResetDialogue()
                } else {
                    strongSelf.tableView.reloadData()
                }
            }
        }

        BlockHandler.shared
            .incomingBlockSubject
            .subscribe(onNext: { [weak self] (incomingBlock) in
                guard let strongSelf = self else { return }
                strongSelf.viewModel = AccountViewModel(with: strongSelf.viewModel.account)
                strongSelf.setupViewModel()
                strongSelf.updateView()
            }).disposed(by: self.disposeBag)
    }

    // MARK: - Setup

    // TEMP
    func showWalletResetDialogue() {
        let alertController = UIAlertController(title: "TestNet Reset Detected", message: "This account returned with an 'Account not found' error despite previously having an account history. Reset all wallet accounts?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            WalletManager.shared.resetAllAccounts()
            self.navigationController?.popViewController(animated: true)
        }))
        alertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alertController, animated: true)
    }

    func setupViewModel() {
        self.viewModel.onNewBlockBroadcasted = { [weak self] in
            self?.onNewBlockBroadcasted()
        }

        self.viewModel.updateView = { [weak self] in
            self?.updateView()
        }
    }

    func setupNavBar() {
        view.viewWithTag(1337)?.removeFromSuperview()
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.tag = 1337
        stackView.axis = .vertical
        
        let accountNameLabel = UILabel()
        accountNameLabel.text = viewModel.account.name
        accountNameLabel.textColor = .white
        accountNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        
        let keyPair = WalletManager.shared.keyPair(at: viewModel.account.index)
        let accountAddressLabel = UILabel()
        accountAddressLabel.text = keyPair?.lgsAccount
        accountAddressLabel.lineBreakMode = .byTruncatingMiddle
        accountAddressLabel.textColor = UIColor.white.withAlphaComponent(0.4)
        accountAddressLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        
        [accountNameLabel, accountAddressLabel].forEach {
            $0.textAlignment = .center
            $0.sizeToFit()
            $0.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview($0)
        }
        stackView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        stackView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        stackView.sizeToFit()
        navigationItem.titleView = stackView
        
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "back2"), style: .plain, target: self, action: #selector(backTapped))
        backButton.tintColor = .white
        navigationItem.leftBarButtonItem = backButton
        
        let rightBarItem = UIBarButtonItem(image: #imageLiteral(resourceName: "passphrase"), style: .plain, target: self, action: #selector(overflowPressed))
        rightBarItem.tintColor = .white
        navigationItem.rightBarButtonItem = rightBarItem
    }
    
    fileprivate func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.register(TransactionTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
    }
    
    fileprivate func setupView() {
        let buttonImg = #imageLiteral(resourceName: "down").withRenderingMode(.alwaysTemplate)
        sortButton?.imageView?.tintColor = .white
        sortButton?.setImage(buttonImg, for: .normal)
        
        let currencyTap = UITapGestureRecognizer(target: self, action: #selector(currencySwitch))
        currencyTapBox?.addGestureRecognizer(currencyTap)
        totalBalanceTitleLabel?.text = String.localize("total-balance").uppercased()
        sortButton?.setTitle(viewModel.refineType.title, for: .normal)
        sendButton?.setTitle(.localize("send"), for: .normal)
        receiveButton?.setTitle(.localize("receive"), for: .normal)
        unitsLabel?.text = self.viewModel.currencyValue
    }
    
    // MARK: - Actions

    @objc fileprivate func backTapped() {
        self.navigationController?.popViewController(animated: true)
        self.delegate?.backTapped()
    }

    @IBAction func refineTapped(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let latestAction = UIAlertAction(title: .localize("latest-sort"), style: .default) { [weak self] _ in
            self?.viewModel.refine(.latestFirst)
        }
        let oldestAction = UIAlertAction(title: .localize("oldest-sort"), style: .default) { [weak self] _ in
            self?.viewModel.refine(.oldestFirst)
        }
        let smallestAction = UIAlertAction(title: .localize("smallest-sort"), style: .default) { [weak self] _ in
            self?.viewModel.refine(.smallestFirst)
        }
        let largestAction = UIAlertAction(title: .localize("largest-sort"), style: .default) { [weak self] _ in
            self?.viewModel.refine(.largestFirst)
        }
        let sendAction = UIAlertAction(title: .localize("sent-filter"), style: .default) { [weak self] _ in
            self?.viewModel.refine(.sent)
        }
        let receiveAction = UIAlertAction(title: .localize("received-filter"), style: .default) { [weak self] _ in
            self?.viewModel.refine(.received)
        }
        let cancelAction = UIAlertAction(title: .localize("cancel"), style: .cancel, handler: nil)
        [latestAction, oldestAction, smallestAction, largestAction, sendAction, receiveAction, cancelAction].forEach { alertController.addAction($0) }
        present(alertController, animated: true)
    }
    
    @objc fileprivate func currencySwitch() {
        viewModel.toggleCurrency()
        tableView?.reloadData()
        totalBalanceLabel?.text = viewModel.balanceValue
        unitsLabel?.text = viewModel.currencyValue
    }
    
    @objc fileprivate func overflowPressed() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: .localize("cancel"), style: .cancel, handler: nil)
        let editName = UIAlertAction(title: .localize("edit-name"), style: .default) { [weak self] _ in
            self?.showTextDialogue(.localize("edit-name"), placeholder: "Account name", keyboard: .default, completion: { (textField) in
                guard let text = textField.text, !text.isEmpty else {
                    Banner.show("No account name provided", style: .warning)
                    return
                }
                PersistentStore.write {
                    self?.viewModel.account.name = text
                }
                if let address = self?.viewModel.account.address {
                    PersistentStore.updateAddressEntry(address: address, name: text, originalAddress: address)
                }
                self?.setupNavBar()
            })
        }
        let editRepresentative = UIAlertAction(title: .localize("edit-representative"), style: .default) { [unowned self] _ in
            self.delegate?.editRepTapped(account: self.viewModel.account)
        }
        let repair = UIAlertAction(title: .localize("repair-account"), style: .default) { [unowned self] _ in
            LoadingView.startAnimating(in: self, dimView: true)
            self.viewModel.repair { [weak self] in
                LoadingView.stopAnimating()
                self?.updateView()

            }
        }
        alertController.addAction(editName)
        alertController.addAction(editRepresentative)
        alertController.addAction(repair)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func sendTapped(_ sender: Any) {
        delegate?.sendTapped(account: viewModel.account)
    }
    
    @IBAction func receiveTapped(_ sender: Any) {
        delegate?.receiveTapped(account: viewModel.account)
    }
    
    func onNewBlockBroadcasted() {
        self.viewModel.getAccountInfo { [weak self] in
            self?.totalBalanceLabel?.text = self?.viewModel.balanceValue.trimTrailingZeros()
        }
    }
    
    func updateView() {
        self.totalBalanceLabel?.text = self.viewModel.balanceValue
        self.sortButton?.setTitle(self.viewModel.refineType.title, for: .normal)
        self.tableView.reloadData()
    }
    
    func initiateChangeBlock(newRep: String?) {
        guard let rep = newRep,
            let keyPair = WalletManager.shared.keyPair(at: viewModel.account.index),
            let account = keyPair.lgsAccount else { return }
        if rep == viewModel.account.representative {
            Banner.show(.localize("no-rep-change"), style: .warning)
            return
        }
        guard viewModel.account.frontier != ZERO_AMT else {
            // No blocks have been made yet, store the rep for later
            PersistentStore.write { [weak self] in
                self?.viewModel.account.representative = rep
            }
            Banner.show(.localize("rep-changed"), style: .success)
            return
        }

        // TEMP
        var block = StateBlock(type: .change)
        block.sequence = NSDecimalNumber(integerLiteral: self.viewModel.account.blockCount)
        block.previous = viewModel.account.frontier
        block.transactions = [
            MultiSendTransaction.init(target: rep, amount: NSDecimalNumber(string: ZERO_AMT))
        ]
        guard block.build(with: keyPair) else { return }
        Banner.show("Waiting for work on change block...", style: .success)
        BlockHandler.handle(block, for: account) { [weak self] (result) in
            switch result {
            case .success(_):
                Banner.show(.localize("rep-changed"), style: .success)
                self?.viewModel.getAccountInfo() {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                Banner.show(.localize("change-rep-error-arg", arg: error.description), style: .danger)
            }
        }
    }
}

extension AccountViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let balanceToSortOffset = balanceToSortOffset else { return }
        let currentOffset = min(max(scrollView.contentOffset.y, 0), scrollView.contentSize.height - scrollView.bounds.size.height)
        let balanceY = totalBalanceLabel?.convert(totalBalanceLabel!.center, to: sortButton!).y ?? 1.0
        currencyTapBox?.alpha = CGFloat(balanceY / balanceToSortOffset)
        if currencyTapBox?.alpha ?? 0.0 < 0 { currencyTapBox?.alpha = 0 }
        if currencyTapBox?.alpha ?? 0.0 > 1 { currencyTapBox?.alpha = 1 }
        
        if currentOffset > 0 {
            let delta = previousOffset - currentOffset
            topConstraint.constant += delta
            if topConstraint.constant <= 0 {
                topConstraint.constant = 0
            } else if topConstraint.constant > 200 {
                topConstraint.constant = 200
            }
            previousOffset = currentOffset
        } else {
            topConstraint.constant = 200
            previousOffset = 0.0
        }
    }
}

extension AccountViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let tx = viewModel[indexPath.section] else { return }
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let copyAddress = UIAlertAction(title: "Copy Address", style: .default) { _ in
            UIPasteboard.general.string = tx.account
            Banner.show("Address copied to clipboard", style: .success)
        }
        let viewDetails = UIAlertAction(title: "View Details", style: .default) { [weak self] _ in
            self?.delegate?.transactionTapped(txInfo: tx)
        }
        let saveAddress = UIAlertAction(title: "Save Address", style: .default) { [weak self] _ in
            self?.showTextDialogue(.localize("enter-name"), placeholder: .localize("name"), keyboard: .default, completion: { (textField) in
                guard let text = textField.text, !text.isEmpty else {
                    Banner.show(.localize("no-name-provided"), style: .warning)
                    return
                }
                PersistentStore.addAddressEntry(text, address: tx.account)
                Banner.show(.localize("arg-entry-saved", arg: text), style: .success)
            })
        }
        let cancel = UIAlertAction(title: .localize("cancel"), style: .cancel, handler: nil)
        actionSheet.addAction(viewDetails)
        actionSheet.addAction(copyAddress)
        if !PersistentStore.getAddressEntries().contains(where: { $0.address == tx.account }) {
            actionSheet.addAction(saveAddress)
        }
        actionSheet.addAction(cancel)
        DispatchQueue.main.async {
            self.present(actionSheet, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
}

extension AccountViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(TransactionTableViewCell.self, for: indexPath)
        cell.prepare(with: viewModel[indexPath.section], useSecondaryCurrency: viewModel.isShowingSecondary)
        return cell
    }
}
