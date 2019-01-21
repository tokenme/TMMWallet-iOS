//
//  DeviceAppTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Kingfisher
import Reusable

class DeviceAppTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var tsLabel: UILabel!
    @IBOutlet private weak var growthFactorLabel: UILabel!
    @IBOutlet private weak var growthFactorImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let flashImage = UIImage(named:"Flash")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        growthFactorImageView.image = flashImage
        iconImageView.layer.cornerRadius = 5.0
        iconImageView.layer.borderWidth = 0.0
        iconImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(_ app: APIApp) {
        if let icon = app.icon {
            iconImageView.kf.setImage(with: URL(string: icon))
        }
        nameLabel.text = app.name
        versionLabel.text = app.version
        tsLabel.text = app.ts.timeSpan()
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = .floor
        growthFactorLabel.text = formatter.string(from: app.growthFactor)
    }
    
}
