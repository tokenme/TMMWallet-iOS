//
//  BlowupBidTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/19.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class BlowupBidTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var nickLabel: UILabel!
    @IBOutlet private weak var bidLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ bid: APIBlowupBid) {
        var textColor: UIColor = .greenGrass
        var prefix = "+"
        if bid.rate == 0 {
            textColor = .red
            prefix = "-"
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let points = formatter.string(from: bid.value * (bid.rate + 1))
        nickLabel.text = bid.nick
        nickLabel.textColor = textColor
        bidLabel.text = formatter.string(from: bid.value)
        bidLabel.textColor = textColor
        pointsLabel.text = "\(prefix)\(points!)"
        pointsLabel.textColor = textColor
    }
}
