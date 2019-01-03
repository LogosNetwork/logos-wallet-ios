//
//  AppCoordinator.swift
//
//  Created by Ben Kray on 6/1/17.
//  Copyright © 2017 Promethean Labs. All rights reserved.
//

import UIKit
import LocalAuthentication

class AppCoordinator: NSObject, RootViewCoordinator {
    static let shared: AppCoordinator = AppCoordinator()
    var childCoordinators: [Coordinator] = []
    var rootViewController: UIViewController {
        return navController
    }
    private(set) var navController: UINavigationController
    
    // MARK: - Initializers 
    
    override init() {
        self.navController = UINavigationController()
        super.init()
        navController.view.backgroundColor = AppStyle.Color.logosBlue

    }
    
    func start() {
        guard !WalletManager.shared.isLocked else {
            navController.pushViewController(LockViewController(), animated: true)
            return
        }

        defer {
            self.fetchDelegates()
        }
        if WalletManager.shared.accounts.count < 1 {
            showStart()
        } else {
            if UserSettings.requireBiometricseOnLaunch {
                handleBiometrics()
            } else {
                handlePassword()
            }
        }
    }

    fileprivate func fetchDelegates() {
        NetworkAdapter.networkDelegates { delegates, _ in
            if let networkDelegates = delegates {
                WalletManager.shared.networkDelegates = networkDelegates

                if WalletManager.shared.accounts.count > 0 {
                    // default to using first account's info to generate load balanced URL
                    LogosDelegateService.accountInfo = WalletManager.shared.accounts[0]
                    let loadBalancedUrl = LogosDelegateService.loadBalancedUrl()
                    NetworkAdapter.baseNodeUrl = loadBalancedUrl
                }

            }
        }
    }
    
    fileprivate func handlePassword() {
        let passwordVC = PasswordViewController(action: .authenticate, style: .blue, hideNav: true)
        passwordVC.onAuthenticated = { [weak self] (_) in
            self?.navController.popViewController(animated: true)
            self?.showWallet()
        }
        navController.pushViewController(passwordVC, animated: true)
    }
    
    fileprivate func handleBiometrics() {
        let context = LAContext()
        var error: NSError? = NSError()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authorization is required to proceed", reply: { (success, err) in
                guard success else {
                    DispatchQueue.main.async {
                        self.handlePassword()
                    }
                    return
                }
                guard WalletManager.shared.unlockWalletBiometrics() else { return }
                DispatchQueue.main.async {
                    self.showWallet()
                }
            })
        }
    }
    
    fileprivate func showDisclaimer() {
        let vc = DisclaimerViewController()
        vc.modalPresentationStyle = .overCurrentContext
        vc.onDecision = { [weak self] didAccept in
            if didAccept {
                UserDefaults.standard.set(true, forKey: "disclaimer-accepted")
                UserDefaults.standard.synchronize()
                vc.dismiss(animated: true)
                self?.showWallet()
            } else {
                exit(1)
            }
        }
        navController.present(vc, animated: true)
    }
    
    fileprivate func showWallet() {
        navController.viewControllers = []
        guard UserDefaults.standard.bool(forKey: "disclaimer-accepted") else {
            showDisclaimer()
            return
        }
        
        let accountsCoordinator = AccountsCoordinator(root: rootViewController)
        accountsCoordinator.delegate = self
        addChildCoordinator(accountsCoordinator)
        accountsCoordinator.start()
    }
    
    fileprivate func showStart() {
        navController.viewControllers = []
        let createWalletCoordinator = CreateWalletCoordinator(root: rootViewController)
        createWalletCoordinator.delegate = self
        addChildCoordinator(createWalletCoordinator)
        createWalletCoordinator.start()
    }
}

extension AppCoordinator: AccountsCoordinatorDelegate {
    func walletCleared(coordinator: AccountsCoordinator) {
        removeChildCoordinator(coordinator)
        showStart()
    }
}

extension AppCoordinator: CreateWalletCoordinatorDelegate {
    func closeTapped(coordinator: CreateWalletCoordinator) {
        removeChildCoordinator(coordinator)
    }
    
    func walletCreated(coordinator: CreateWalletCoordinator) {
        removeChildCoordinator(coordinator)
        showWallet()
    }
}
