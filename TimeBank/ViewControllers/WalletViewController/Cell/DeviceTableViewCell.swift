//
//  DeviceTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SwipeCellKit
import TMMSDK

class DeviceTableViewCell: SwipeTableViewCell, NibReusable {
    
    @IBOutlet private weak var currentDeviceMark: UIView!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var tsLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var growthFactorLabel: UILabel!
    @IBOutlet private weak var pointsImageView: UIImageView!
    @IBOutlet private weak var growthFactorImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let pointsImage = UIImage(named: "Points")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        let flashImage = UIImage(named:"Flash")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        pointsImageView.image = pointsImage
        growthFactorImageView.image = flashImage
        currentDeviceMark.layer.cornerRadius = currentDeviceMark.frame.width / 2.0
        currentDeviceMark.layer.borderWidth = 0
        currentDeviceMark.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(_ device: APIDevice) {
        var iconImage: UIImage?
        switch device.platform {
        case .iOS: iconImage = UIImage(named: "iOS")
        case .Android: iconImage = UIImage(named: "Android")
        }
        if let img = iconImage {
            iconImageView.image = img
        }
        nameLabel.text = device.name
        tsLabel.text = device.totalTs.timeSpan()
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        pointsLabel.text = formatter.string(from: device.points)
        let formatterGf = NumberFormatter()
        formatterGf.maximumFractionDigits = 2
        formatterGf.groupingSeparator = "";
        formatterGf.numberStyle = NumberFormatter.Style.decimal
        growthFactorLabel.text = formatterGf.string(from: device.growthFactor)
        currentDeviceMark.isHidden = TMMBeacon.shareInstance()?.deviceId() != device.idfa
    }
}
