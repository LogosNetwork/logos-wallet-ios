//
//  ReceiveCoordinator.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/28/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

class ReceiveCoordinator: RootViewCoordinator {
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController
    fileprivate var receiveViewController: ReceiveViewController?
    let account: AccountInfo
    var onDismiss: ((Coordinator) -> Void)?
    
    init(root: UIViewController, account: AccountInfo) {
        self.rootViewController = root
        self.account = account
    }
    
    func start() {
        receiveViewController = ReceiveViewController(with: account)
        receiveViewController?.onDismiss = { [weak self] in
            if let strongSelf = self {
                strongSelf.onDismiss?(strongSelf)
            }
        }
        receiveViewController?.onRequestAmountTapped = { [weak self] in
            guard let me = self else {
                return
            }
            let requestVC = RequestAmountViewController(with: me.account)
            requestVC.modalTransitionStyle = .crossDissolve
            me.receiveViewController?.present(UINavigationController(rootViewController: requestVC), animated: true)
        }
        receiveViewController?.modalPresentationStyle = .overFullScreen
        guard let receiveVC = receiveViewController else { return }
        rootViewController.present(receiveVC, animated: true)
    }
}
