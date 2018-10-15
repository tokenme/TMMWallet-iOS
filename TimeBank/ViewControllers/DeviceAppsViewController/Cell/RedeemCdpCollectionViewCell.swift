//
//  RedeemCdpCollectionViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class RedeemCdpCollectionViewCell: UICollectionViewCell, NibReusable {
    
    @IBOutlet private weak var gradeLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var pointsImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let pointsImage = UIImage(named: "Points")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        pointsImageView.image = pointsImage
    }
    
    func fill(_ cdp:APIRedeemCdp) {
        gradeLabel.text = cdp.grade
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        priceLabel.text = "¥\(formatter.string(from: cdp.price)!)"
        formatter.maximumFractionDigits = 4
        pointsLabel.text = formatter.string(from: cdp.points)
    }

}
