//
//  GoodInfoTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import Kingfisher

class GoodInfoTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var cover: UIImageView!
    @IBOutlet private weak var titleLabel: UILabelPadding!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var withdrawLabel: UILabelPadding!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.layer.cornerRadius = 8.0
        titleLabel.layer.borderWidth = 0
        titleLabel.clipsToBounds = true
        withdrawLabel.layer.cornerRadius = 5.0
        withdrawLabel.layer.borderWidth = 0
        withdrawLabel.clipsToBounds = true
        withdrawLabel.backgroundColor = UIColor.pinky
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(_ good: APIGood?) {
        guard let item = good else { return }
        if let img = item.pic {
            cover.kf.setImage(with: URL(string: img))
        }
        titleLabel.text = item.name
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = .floor
        priceLabel.text = "¥\(formatter.string(from: item.price)!)"
        withdrawLabel.text = "成交返现: ¥\(formatter.string(from: item.purchaseWithdraw)!)"
    }
    
}
