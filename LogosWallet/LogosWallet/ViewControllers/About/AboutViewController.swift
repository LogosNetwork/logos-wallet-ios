//
//  AboutViewController.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/10/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

class AboutViewController: TitleTableViewController {
    enum Rows: Int, CaseCountable {
        static var caseCount: Int = Rows.countCases()
        case disclaimer
    }
    
    lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppStyle.Color.offBlack
        label.font = .systemFont(ofSize: 12.0, weight: .light)
        if let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            label.text = "Logos Wallet - v\(versionNumber) (\(buildNumber))"
        }
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        view.addSubview(self.versionLabel)
        self.versionLabel.snp.makeConstraints { (make) in
            make.bottomMargin.equalToSuperview().offset(-AppStyle.Size.padding)
            make.leading.equalToSuperview().offset(AppStyle.Size.padding)
        }
    }
    
    // MARK: - Setup
    
    fileprivate func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SettingsTableViewCell.self)
    }
}

extension AboutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = Rows(rawValue: indexPath.row) else { return }
        switch row {
        case .disclaimer:
            navigationController?.pushViewController(DisclaimerViewController(showButtons: false), animated: true)
        }
    }
}

extension AboutViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Rows.caseCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = Rows(rawValue: indexPath.row) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(SettingsTableViewCell.self, for: indexPath)
        switch row {
        case .disclaimer:
            cell.settingsTitleLabel?.text = "Disclaimer"
        }
        
        return cell
    }
}
