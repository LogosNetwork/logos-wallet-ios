//
//  AppUrlsViewController.swift
//  LogosWallet
//
//  Created by Ben Kray on 9/26/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

class AppUrlsViewController: TransparentNavViewController {

    lazy var nodeIpTextField: UITextField = {
        let textField = UITextField()
        textField.font = AppStyle.Font.body
        textField.textColor = AppStyle.Color.offBlack
        textField.text = NetworkAdapter.baseNodeUrl.absoluteString
        return textField
    }()

    lazy var walletServerTextField: UITextField = {
        let textField = UITextField()
        textField.font = AppStyle.Font.body
        textField.textColor = AppStyle.Color.offBlack
        textField.text = LogosMQTT.shared.url.absoluteString
        return textField
    }()

    lazy var statusView: UIView = {
        let view = UIView()
        view.backgroundColor = LogosMQTT.shared.status == .connected ? .green : .red
        view.layer.cornerRadius = AppStyle.Size.extraSmallControl / 2
        return view
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
        nodeIpLabel.text = "NODE URL"
        nodeIpLabel.textColor = AppStyle.Color.lightGrey
        self.view.addSubview(nodeIpLabel)

        nodeIpLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(AppStyle.Size.padding)
            make.left.equalTo(view.snp.left).offset(AppStyle.Size.padding)
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
            make.right.equalTo(view.snp.right).offset(-AppStyle.Size.padding)

        }

        let walletServerLabel = UILabel()
        walletServerLabel.font = AppStyle.Font.subtitle
        walletServerLabel.text = "MQTT URL"
        walletServerLabel.textColor = AppStyle.Color.lightGrey
        self.view.addSubview(walletServerLabel)
        walletServerLabel.snp.makeConstraints { (make) in
            make.top.equalTo(divider.snp.bottom).offset(AppStyle.Size.padding)
            make.left.equalTo(nodeIpLabel.snp.left)
        }

        self.view.addSubview(self.statusView)
        statusView.snp.makeConstraints { (make) in
            make.height.width.equalTo(AppStyle.Size.extraSmallControl)
            make.left.equalTo(walletServerLabel.snp.right).offset(AppStyle.Size.extraSmallPadding)
            make.centerY.equalTo(walletServerLabel.snp.centerY)
        }

        self.view.addSubview(self.walletServerTextField)
        self.walletServerTextField.snp.makeConstraints { (make) in
            make.top.equalTo(walletServerLabel.snp.bottom).offset(AppStyle.Size.smallPadding)
            make.left.equalTo(walletServerLabel.snp.left)
            make.right.equalTo(divider.snp.right)
        }

        let divider2 = UIView.line()
        self.view.addSubview(divider2)
        divider2.snp.makeConstraints { (make) in
            make.top.equalTo(self.walletServerTextField.snp.bottom).offset(4.0)
            make.left.equalTo(self.walletServerTextField.snp.left)
            make.right.equalTo(divider.snp.right)
        }
    }

    // MARK: - Actions

    @objc func saveUrls() {
        self.view.endEditing(true)

        guard
            let nodeUrlString = self.nodeIpTextField.text,
            let nodeUrl = URL(string: nodeUrlString)
        else {
            Banner.show("Could not save Node URL", style: .danger)
            return
        }
        NetworkAdapter.baseNodeUrl = nodeUrl

        guard
            let walletUrlString = self.walletServerTextField.text,
            let _ = URL(string: walletUrlString)
        else {
            Banner.show("Could not save MQTT URL", style: .danger)
            return
        }

        LoadingView.startAnimating(in: self.navigationController, dimView: true)
        self.view.isUserInteractionEnabled = false
        LogosMQTT.shared.changeMQTTUrl(to: walletUrlString) { [weak self] success in
            self?.view.isUserInteractionEnabled = true
            LoadingView.stopAnimating()
            if success {
                self?.navigationController?.popViewController(animated: true)
            } else {
                Banner.show("Could not establish MQTT connection", style: .danger)
            }
            self?.statusView.backgroundColor = success ? .green : .red
        }

    }

}
