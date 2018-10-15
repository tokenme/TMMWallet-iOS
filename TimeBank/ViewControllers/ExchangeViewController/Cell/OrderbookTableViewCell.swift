//
//  OrderbookTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SwipeCellKit

class OrderbookTableViewCell: SwipeTableViewCell, NibReusable {
    
    @IBOutlet private weak var idLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var dealAmountLabel: UILabel!
    @IBOutlet private weak var dealETHLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabelPadding!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        statusLabel.layer.cornerRadius = 5
        statusLabel.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ order: APIOrderBook) {
        if let tradeId = order.id {
            idLabel.text = "\(tradeId)"
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        amountLabel.text = "\(I18n.amount.description): \(formatter.string(from: order.quantity)!)"
        priceLabel.text = "\(I18n.price.description): \(formatter.string(from: order.price)!)"
        dealAmountLabel.text = "\(I18n.dealAmount.description): \(formatter.string(from: order.dealQuantity)!)"
        dealETHLabel.text = "\(I18n.dealETH.description): \(formatter.string(from: order.dealETH)!)"
        
        if let insertedAt = order.insertedAt {
            let timeZone = NSTimeZone.local
            let fomatterDate = DateFormatter()
            fomatterDate.timeZone = timeZone
            fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = fomatterDate.string(from: insertedAt)
        }
        
        var statusBackgroundColor: UIColor = .lightGray
        var statusText: String = I18n.txPending.description
        switch order.onlineStatus {
        case .completed:
            statusBackgroundColor = UIColor.greenGrass
            statusText = I18n.orderbookCompleted.description
        case .canceled:
            statusBackgroundColor = UIColor.red
            statusText = I18n.orderbookCanceled.description
        case .pending:
            statusBackgroundColor = .lightGray
            statusText = I18n.orderbookPending.description
        }
        (statusLabel as UILabel).backgroundColor = statusBackgroundColor
        (statusLabel as UILabel).text = statusText
    }
}
