//
//  AddressItemTableViewCell.swift
//  LogosWallet
//
//  Created by Ben Kray on 1/23/18.
//  Copyright © 2018 Promethean Labs. All rights reserved.
//

import UIKit

class AddressItemTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var addressLabel: UILabel?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
