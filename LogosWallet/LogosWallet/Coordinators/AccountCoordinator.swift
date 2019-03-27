//
//  AccountCoordinator.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/31/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

class AccountCoordinator: RootViewCoordinator {
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController
    private(set) var navController: UINavigationController
    fileprivate var accountVC: AccountViewController?
    var onDismiss: ((AccountCoordinator) -> Void)?
    let account: LogosAccount
    
    init(in navController: UINavigationController, account: LogosAccount) {
        self.rootViewController = navController
        self.account = account
        self.navController = navController
    }

    deinit {
        LogosDelegateService.account = nil
    }

    func start() {
        accountVC = AccountViewController(account: self.account)
        self.accountVC?.delegate = self
        if let accountVC = accountVC {
            navController.pushViewController(accountVC, animated: true)
            LogosDelegateService.account = self.account
        }
    }
}

extension AccountCoordinator: AccountViewControllerDelegate {
    func sendTapped(account: LogosAccount) {
        Lincoln.log()
        let sendCoordinator = SendCoordinator(root: rootViewController, account: account)
        sendCoordinator.delegate = self
        childCoordinators.append(sendCoordinator)
        sendCoordinator.start()
    }
    
    func receiveTapped(account: LogosAccount) {
        Lincoln.log()
        let receiveCoordinator = ReceiveCoordinator(root: rootViewController, account: account)
        childCoordinators.append(receiveCoordinator)
        receiveCoordinator.onDismiss = { [weak self] (coordinator) in
            self?.removeChildCoordinator(coordinator)
        }
        receiveCoordinator.start()
    }
    
    func transactionTapped(txInfo: TransactionRequest) {
        Lincoln.log()
        // TODO
        let blockInfoVC = BlockInfoViewController(viewModel: BlockInfoViewModel(with: txInfo), account: self.account)
        self.navController.pushViewController(blockInfoVC, animated: true)
    }
    
    func editRepTapped(account: LogosAccount) {
        Lincoln.log()
        // TODO
        let viewModel = EnterAddressEntryViewModel(title: .localize("edit-representative"), address: "", isEditing: true, addressOnly: true)
        let editRepVC = EnterAddressEntryViewController(with: viewModel)
        editRepVC.onAddressSaved = { [weak self] (address) in
            self?.accountVC?.initiateChangeBlock(newRep: address)
        }
        rootViewController.present(UINavigationController(rootViewController: editRepVC), animated: true)
    }

    func backTapped() {
        self.accountVC?.pollingTimer?.invalidate()
        self.accountVC?.pollingTimer = nil
        self.onDismiss?(self)
    }
}

extension AccountCoordinator: SendCoordinatorDelegate {
    func sendComplete(coordinator: Coordinator) {
        accountVC?.onNewBlockBroadcasted()
        removeChildCoordinator(coordinator)
    }
    
    func sendBlockGenerated(coordinator: Coordinator) {
        accountVC?.updateView()
        removeChildCoordinator(coordinator)
    }
    
    func closeTapped(coordinator: Coordinator) {
        removeChildCoordinator(coordinator)
    }
}
