//
//  AppTaskTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/5.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Kingfisher
import Reusable

class AppTaskTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var bonusLabel: UILabel!
    @IBOutlet private weak var installButton: TransitionButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        iconImageView.layer.cornerRadius = 5.0
        iconImageView.layer.borderWidth = 0.0
        iconImageView.clipsToBounds = true
        
        installButton.setTitle(I18n.install.description, for: UIControlState.normal)
        installButton.setTitle(I18n.installed.description, for: UIControlState.disabled)
        installButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        installButton.setTitleColor(UIColor.darkGray, for: UIControlState.disabled)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ app: APIAppTask, installed: Bool) {
        if let icon = app.icon {
            iconImageView.kf.setImage(with: URL(string: icon))
        }
        nameLabel.text = app.name
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedBonus = formatter.string(from: app.bonus)!
        bonusLabel.text = "\(I18n.earn.description) \(formattedBonus) \(I18n.pointsPerInstall.description)"
        installButton.isEnabled = !installed
    }
    
    func startLoading() {
        installButton.startAnimation()
    }
    
    func endLoading() {
        installButton.stopAnimation(animationStyle: .normal, completion: nil)
    }
}