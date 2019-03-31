//
//  AccountCarouselCollectionViewCell.swift
//  LogosWallet
//
//  Created by Ben Kray on 3/30/19.
//  Copyright © 2019 Planar Form. All rights reserved.
//

import UIKit

class AccountCarouselCollectionViewCell: UICollectionViewCell {

    let nameLabel = with(UILabel()) {
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 10.0, weight: .medium)//AppStyle.Font.subtitle
        $0.textColor = AppStyle.Color.lowAlphaWhite
    }
    let balanceLabel = with(UILabel()) {
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 25.0, weight: .light)//AppStyle.Font.title//
        $0.textColor = .white
        $0.setContentHuggingPriority(.required, for: .horizontal)
    }
    
    let iconImageView = with(UIImageView()) {
        $0.contentMode = .scaleAspectFit
    }

    static let reuseIdentifier = "\(self)"

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        self.layer.cornerRadius = 6.0
        self.addShadow(0.25, radius: 7.0, offset: CGSize(width: 0, height: 2))
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let stackView = with(UIStackView()) {
            $0.axis = .vertical
            $0.alignment = .center
        }
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(AppStyle.Size.smallPadding)
            make.right.equalToSuperview().offset(-AppStyle.Size.smallPadding)
        }
        stackView.addArrangedSubview(self.nameLabel)
        stackView.addArrangedSubview(self.balanceLabel)
        self.nameLabel.text = "LOGOS"

        self.balanceLabel.text = "9494.32"

        let currencyLabel = UILabel()
        currencyLabel.font = .systemFont(ofSize: 8.0, weight: .light)
        currencyLabel.text = "LGS"
        currencyLabel.textColor = .white
        self.addSubview(currencyLabel)
        currencyLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.balanceLabel.snp.top).offset(4.0)
            make.left.equalTo(self.balanceLabel.snp.right)
        }
    }

}