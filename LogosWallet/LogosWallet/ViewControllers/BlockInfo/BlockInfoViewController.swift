//
//  BlockInfoViewController.swift
//  LogosWallet
//
//  Created by Ben Kray on 4/22/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit
import SnapKit

class BlockInfoViewController: TransparentNavViewController {

    let viewModel: BlockInfoViewModel
    let account: LogosAccount

    lazy var mainStack: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12.0
        stackView.distribution = .fill
        return stackView
    }()

    lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = AppStyle.Font.body
        label.textColor = AppStyle.Color.lowAlphaWhite
        return label
    }()

    lazy var scrollView: UIScrollView = UIScrollView()
    private var isSend: Bool {
        return self.account.address == self.viewModel.info.origin
    }
    
    init(viewModel: BlockInfoViewModel, account: LogosAccount) {
        self.viewModel = viewModel
        self.account = account
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LoadingView.stopAnimating()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavBar()
        self.buildView()
        LoadingView.startAnimating(in: self.navigationController, dimView: true)
        self.viewModel.fetch { [weak self] in
            self?.buildStackView()
            LoadingView.stopAnimating()
        }
    }

    override func viewWillAppear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, AppStyle.Size.padding, 0)
    }

    // MARK: - Setup
    
    fileprivate func buildView() {
        let typeLabel = UILabel()
        typeLabel.font = AppStyle.Font.title
        typeLabel.textColor = .white

        let type: String
        if self.viewModel.isMultiTx {
            type = self.isSend ? "MultiSend" : "Receive"
        } else {
            type = self.isSend ? "Send" : "Receive"
        }

        typeLabel.text = type
        view.addSubview(typeLabel)
        view.addSubview(dateLabel)
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.addSubview(mainStack)
        scrollView.addSubview(contentView)

        let blockStack = buildSubStack("BLOCK", value: viewModel.info.hash)
        mainStack.addArrangedSubview(blockStack)

        typeLabel.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.topMargin).offset(AppStyle.Size.padding)
            make.height.equalTo(25.0)
            make.leading.equalToSuperview().offset(AppStyle.Size.padding)
            make.trailing.equalToSuperview().offset(-AppStyle.Size.padding)
        }
        dateLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(typeLabel.snp.centerY)
            make.trailing.equalToSuperview().offset(-AppStyle.Size.padding)
        }
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(typeLabel.snp.bottom).offset(AppStyle.Size.padding)
            make.bottom.leading.trailing.equalToSuperview()
        }
        contentView.snp.makeConstraints { (make) in
            make.width.top.bottom.leading.trailing.equalToSuperview()

        }
        mainStack.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(AppStyle.Size.padding)
            make.trailing.equalToSuperview().offset(-AppStyle.Size.padding)
        }
    }
    
    fileprivate func buildStackView() {
        guard let model = self.viewModel.model else {
            return
        }

        if self.isSend == false {
            let originStack = self.buildSubStack("ORIGIN", value: self.viewModel.model?.origin ?? "")
            self.mainStack.addArrangedSubview(originStack)
        }
        
        dateLabel.text = viewModel.localizedDate

        mainStack.addArrangedSubview(buildSubStack("PREVIOUS", value: self.viewModel.model?.previous))
        mainStack.addArrangedSubview(buildSubStack("SIGNATURE", value: self.viewModel.model?.signature))
        if self.viewModel.isMultiTx {
            model.transactions?.enumerated().forEach { (index, tx) in
                let targetStack = self.buildSubStack("RECIPIENT \(index + 1)", value: tx.destination)
                self.mainStack.addArrangedSubview(targetStack)
                let amountStack = self.buildSubStack("AMOUNT \(index + 1)", value: tx.amount.decimalNumber.mlgsString.formattedAmount)
                self.mainStack.addArrangedSubview(amountStack)
            }
        } else {
            let targetStack = buildSubStack("RECIPIENT", value: model.transaction?.destination ?? "")
            mainStack.addArrangedSubview(targetStack)

            let amount = viewModel.info.amountTotal(for: self.account.address!).mlgsString.formattedAmount
            let amountStack = buildSubStack("AMOUNT", value: amount + " \(CURRENCY_NAME)")
            mainStack.addArrangedSubview(amountStack)
        }
    }
    
    override func setupNavBar() {
        super.setupNavBar()
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "back2"), style: .plain, target: self, action: #selector(backTapped))
        backButton.tintColor = .white
        navigationItem.leftBarButtonItem = backButton
        
        let externalButton = UIBarButtonItem(image: #imageLiteral(resourceName: "external"), style: .plain, target: self, action: #selector(externalTapped))
        externalButton.tintColor = .white
        navigationItem.rightBarButtonItem = externalButton
    }
    
    // MARK: - Actions
    
    @objc func externalTapped() {
        guard let url = URL(string: BLOCK_EXPLORER_URL + viewModel.info.hash) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helpers

    fileprivate func buildSubStack(_ title: String, value: String?) -> UIStackView {
        let value = value ?? "---"
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4.0
        stack.distribution = .fill
        let titleLabel = buildStackLabel(title, isTitle: true)
        let valueLabel = buildStackLabel(value, isTitle: false)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)
        return stack
    }
    
    fileprivate func buildStackLabel(_ value: String, isTitle: Bool) -> UILabel {
        let label = UILabel()
        label.font = isTitle ? .systemFont(ofSize: 14) : .systemFont(ofSize: 14, weight: .light)
        label.textColor = isTitle ? .white : AppStyle.Color.lowAlphaWhite
        label.text = isTitle ? value.uppercased() : value
        label.numberOfLines = 0
        label.alpha = 0
        UIView.animate(withDuration: 0.3) {
            label.alpha = 1.0
        }
        return label
    }
}
