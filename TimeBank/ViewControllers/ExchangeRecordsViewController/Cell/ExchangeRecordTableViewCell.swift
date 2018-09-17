//
//  ExchangeRecordTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/17.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class ExchangeRecordTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var fromLabel: UILabel!
    @IBOutlet private weak var toLabel: UILabel!
    @IBOutlet private weak var changeLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabelPadding!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        changeLabel.text = I18n.exchange.description
        statusLabel.layer.cornerRadius = 5
        statusLabel.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ record: APIExchangeRecord) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedTmm = formatter.string(from: record.tmm)!
        let formattedPoints = formatter.string(from: record.points)!
        let tmmTxt = "\(formattedTmm) TBC"
        let pointsTxt = "\(formattedPoints) \(I18n.points.description)"
        if record.direction == APIExchangeDirection.TMMIn {
            fromLabel.text = pointsTxt
            toLabel.text = tmmTxt
        } else {
            fromLabel.text = tmmTxt
            toLabel.text = pointsTxt
        }
        
        if let insertedAt = record.insertedAt {
            let timeZone = NSTimeZone.local
            let fomatterDate = DateFormatter()
            fomatterDate.timeZone = timeZone
            fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = fomatterDate.string(from: insertedAt)
        }
        var statusBackgroundColor: UIColor = .lightGray
        var statusText: String = I18n.txPending.description
        switch record.status {
        case .success:
            statusBackgroundColor = UIColor.greenGrass
            statusText = I18n.txSuccess.description
        case .failed:
            statusBackgroundColor = UIColor.red
            statusText = I18n.txFailed.description
        case .pending:
            statusBackgroundColor = .lightGray
            statusText = I18n.txPending.description
        }
        (statusLabel as UILabel).backgroundColor = statusBackgroundColor
        (statusLabel as UILabel).text = statusText
    }
}
