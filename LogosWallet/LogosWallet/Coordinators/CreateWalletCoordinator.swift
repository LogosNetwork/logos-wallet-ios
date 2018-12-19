//
//  CreateWalletCoordinator.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/4/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

protocol CreateWalletCoordinatorDelegate: class {
    func closeTapped(coordinator: CreateWalletCoordinator)
    func walletCreated(coordinator: CreateWalletCoordinator)
}

class CreateWalletCoordinator: RootViewCoordinator {
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController
    private let navController = UINavigationController()
    weak var delegate: CreateWalletCoordinatorDelegate?
    fileprivate var seed: Data?
    
    init(root: UIViewController) {
        self.rootViewController = root
    }
    
    func start() {
        let startVC = StartViewController()
        startVC.delegate = self
        navController.viewControllers = [startVC]
        navController.modalTransitionStyle = .crossDissolve
        rootViewController.present(navController, animated: true)
    }

}

extension CreateWalletCoordinator: StartViewControllerDelegate {
    func newWalletTapped() {
        seed = NaCl.randomBytes()
        let seedView = SeedViewController(action: .showSeed, style: .blue, seed: seed)
        seedView.delegate = self
        navController.pushViewController(seedView, animated: true)
    }
    
    func importWalletTapped() {
        let importVC = ImportWalletViewController()
        importVC.delegate = self
        navController.pushViewController(importVC, animated: true)
    }
}

extension CreateWalletCoordinator: ImportWalletViewControllerDelegate {
    func passphraseTapped() {
        // TODO: NOT YET IMPLEMENTED
        let alert = UIAlertController(title: nil, message: "Feature not yet implemented", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        navController.present(alert, animated: true)
        
//        let passphraseVC = ImportPassphraseViewController()
//        passphraseVC.delegate = self
//        navController.pushViewController(passphraseVC, animated: true)
    }
    
    func seedTapped() {
        let seedVC = SeedViewController(action: .importSeed, style: .blue)
        seedVC.delegate = self
        navController.pushViewController(seedVC, animated: true)
    }
}

extension CreateWalletCoordinator: ImportPassphraseViewControllerDelegate {
    func imported(passphrase: [String]) {

    }
}

extension CreateWalletCoordinator: SeedViewControllerDelegate {
    func imported(seed: Data) {
        let passwordVC = PasswordViewController(action: .create, style: .blue, hideNav: false)
        passwordVC.onAuthenticated = { [weak self] (pw) in
            guard
                WalletManager.shared.setWalletSeed(seed, password: pw),
                let strongSelf = self
            else {
                Banner.show("An error occurred while setting your wallet's seed", style: .danger)
                return
            }
            WalletManager.shared.createWallet()
            LoadingView.startAnimating(in: passwordVC)
            // Set up MQTT subscription credentials
            if let address = WalletManager.shared.accounts.first?.address {
                LogosMQTT.shared.subscribe(to: [address])
            }

            LoadingView.stopAnimating()
            strongSelf.navController.dismiss(animated: true) {
                strongSelf.delegate?.walletCreated(coordinator: strongSelf)
            }
        }
        navController.pushViewController(passwordVC, animated: true)
    }
}
