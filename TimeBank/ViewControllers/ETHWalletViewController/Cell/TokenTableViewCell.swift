//
//  TokenTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/11.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Kingfisher
import Reusable
import SwipeCellKit

class TokenTableViewCell: SwipeTableViewCell, NibReusable {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconImageView.layer.cornerRadius = 5.0
        iconImageView.layer.borderWidth = 0.0
        iconImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ token: APIToken) {
        if let icon = token.icon {
            iconImageView.kf.setImage(with: URL(string: icon))
        }
        nameLabel.text = token.symbol
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        balanceLabel.text = formatter.string(from: token.balance)
        if token.price > 0 {
            let totalPrice = token.balance * token.price
            let priceStr = "\(formatter.string(from: totalPrice)!)"
            priceLabel.text = priceStr
        } else {
            priceLabel.text = "~"
        }
    }
    
}
