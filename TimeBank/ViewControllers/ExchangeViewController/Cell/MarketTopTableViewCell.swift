//
//  MarketTopTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/22.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class MarketTopTableViewCell: UITableViewCell, NibReusable {

    @IBOutlet private weak var askPriceLabel: UILabel!
    @IBOutlet private weak var askQuantityLabel: UILabel!
    @IBOutlet private weak var bidPriceLabel: UILabel!
    @IBOutlet private weak var bidQuantityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        askPriceLabel.text = ""
        askQuantityLabel.text = ""
        bidPriceLabel.text = ""
        bidQuantityLabel.text = ""
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(askOrder: APIOrderBook?, bidOrder: APIOrderBook?) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        if let order = askOrder {
            askPriceLabel.text = formatter.string(from: order.price)
            askQuantityLabel.text = formatter.string(from: order.quantity - order.dealQuantity)
        }
        if let order = bidOrder {
            bidPriceLabel.text = formatter.string(from: order.price)
            bidQuantityLabel.text = formatter.string(from: order.quantity - order.dealQuantity)
        }
    }
}
