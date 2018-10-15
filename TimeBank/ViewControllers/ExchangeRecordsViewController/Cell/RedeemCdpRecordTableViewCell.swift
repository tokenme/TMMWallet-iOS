//
//  RedeemCdpRecordTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class RedeemCdpRecordTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var fromLabel: UILabel!
    @IBOutlet private weak var toLabel: UILabel!
    @IBOutlet private weak var changeLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        changeLabel.text = I18n.exchange.description
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ record: APIRedeemCdpRecord) {
        toLabel.text = record.grade
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedPoints = formatter.string(from: record.points)!
        let pointsTxt = "\(formattedPoints) \(I18n.points.description)"
        fromLabel.text = pointsTxt
        
        if let insertedAt = record.insertedAt {
            let timeZone = NSTimeZone.local
            let fomatterDate = DateFormatter()
            fomatterDate.timeZone = timeZone
            fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = fomatterDate.string(from: insertedAt)
        }
    }
    
}
