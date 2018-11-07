//
//  TokenTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/11.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
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
        iconImageView.layer.cornerRadius = 20.0
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
            let currency = Defaults[.currency] ?? Currency.USD.rawValue
            let totalPrice = token.balance * token.price
            let priceStr = "\(formatter.string(from: totalPrice)!)"
            
            let priceAttributes = [NSAttributedString.Key.font:MainFont.light.with(size: 14), NSAttributedString.Key.foregroundColor:UIColor.lightGray]
            let currencyAttributes = [NSAttributedString.Key.font:MainFont.light.with(size: 10), NSAttributedString.Key.foregroundColor:UIColor.lightGray]
            
            let attString = NSMutableAttributedString(string: "\(priceStr) \(currency)")
            attString.addAttributes(priceAttributes, range:NSRange.init(location: 0, length: priceStr.count))
            attString.addAttributes(currencyAttributes, range: NSRange.init(location: priceStr.count, length: currency.count + 1))
            
            priceLabel.attributedText = attString
        } else {
            priceLabel.text = "~"
        }
    }
    
}
