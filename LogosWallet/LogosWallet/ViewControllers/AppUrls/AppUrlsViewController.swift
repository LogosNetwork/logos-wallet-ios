//
//  AppUrlsViewController.swift
//  LogosWallet
//
//  Created by Ben Kray on 9/26/18.
//  Copyright © 2018 Planar Form. All rights reserved.
//

import UIKit

class AppUrlsViewController: TransparentNavViewController {

    private let urls = PersistentStore.getAppUrls()

    lazy var nodeIpTextField: UITextField = {
        let textField = UITextField()
        textField.font = AppStyle.Font.body
        textField.textColor = AppStyle.Color.offBlack
        textField.text = urls.nodeUrl
        return textField
    }()

    lazy var walletServerTextField: UITextField = {
        let textField = UITextField()
        textField.font = AppStyle.Font.body
        textField.textColor = AppStyle.Color.offBlack
        textField.text = urls.walletServerUrl
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupViews()
    }

    override func setupNavBar() {
        super.setupNavBar()
        let save = UIBarButtonItem(title: .localize("save"), style: .done, target: self, action: #selector(self.saveUrls))
        save.tintColor = .black
        self.navigationItem.rightBarButtonItem = save
    }

    private func setupViews() {
        let titleLabel = UILabel()
        titleLabel.text = "Server URLs"
        titleLabel.font = AppStyle.Font.title
        self.view.backgroundColor = .white
        self.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            if #available(iOS 11.0, *) {
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.topMargin).offset(AppStyle.Size.smallPadding)
            } else {
                make.top.equalToSuperview().offset(AppStyle.Size.padding)
            }
            make.left.equalTo(view.snp.left).offset(AppStyle.Size.padding)
            make.right.equalTo(view.snp.right)
        }

        let nodeIpLabel = UILabel()
        nodeIpLabel.font = AppStyle.Font.subtitle
        nodeIpLabel.text = "NODE IP ADDRESS"
        nodeIpLabel.textColor = AppStyle.Color.lightGrey
        self.view.addSubview(nodeIpLabel)

        nodeIpLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppStyle.Size.padding)
            make.left.equalTo(view.snp.left).offset(AppStyle.Size.padding)
            make.right.equalTo(view.snp.right).offset(-AppStyle.Size.padding)
        }

        self.view.addSubview(self.nodeIpTextField)
        self.nodeIpTextField.snp.makeConstraints { (make) in
            make.top.equalTo(nodeIpLabel.snp.bottom).offset(AppStyle.Size.smallPadding)
            make.left.equalTo(view.snp.left).offset(AppStyle.Size.padding)
            make.right.equalTo(view.snp.right).offset(-AppStyle.Size.padding)
        }

        let divider = UIView.line()
        self.view.addSubview(divider)
        divider.snp.makeConstraints { (make) in
            make.top.equalTo(self.nodeIpTextField.snp.bottom).offset(4.0)
            make.left.equalTo(self.nodeIpTextField.snp.left)
            make.right.equalTo(self.nodeIpTextField.snp.right)
        }

        let walletServerLabel = UILabel()
        walletServerLabel.font = AppStyle.Font.subtitle
        walletServerLabel.text = "WALLET SERVER ADDRESS"
        walletServerLabel.textColor = AppStyle.Color.lightGrey
        self.view.addSubview(walletServerLabel)
        walletServerLabel.snp.makeConstraints { (make) in
            make.top.equalTo(divider.snp.bottom).offset(AppStyle.Size.padding)
            make.left.equalTo(nodeIpLabel.snp.left)
            make.right.equalTo(nodeIpLabel.snp.right)
        }

        self.view.addSubview(self.walletServerTextField)
        self.walletServerTextField.snp.makeConstraints { (make) in
            make.top.equalTo(walletServerLabel.snp.bottom).offset(AppStyle.Size.smallPadding)
            make.left.equalTo(walletServerLabel.snp.left)
            make.right.equalTo(walletServerLabel.snp.right)
        }

        let divider2 = UIView.line()
        self.view.addSubview(divider2)
        divider2.snp.makeConstraints { (make) in
            make.top.equalTo(self.walletServerTextField.snp.bottom).offset(4.0)
            make.left.equalTo(self.walletServerTextField.snp.left)
            make.right.equalTo(self.walletServerTextField.snp.right)
        }
    }

    // MARK: - Actions

    @objc func saveUrls() {
        guard
            let walletUrlString = self.walletServerTextField.text,
            let _ = URL(string: walletUrlString),
            let nodeUrlString = self.nodeIpTextField.text,
            let _ = URL(string: nodeUrlString)
        else {
            return
        }

        SocketManager.shared.changeSocketUrl(to: walletUrlString)
        PersistentStore.updateNodeUrl(to: nodeUrlString)
        self.navigationController?.popViewController(animated: true)
    }

}
