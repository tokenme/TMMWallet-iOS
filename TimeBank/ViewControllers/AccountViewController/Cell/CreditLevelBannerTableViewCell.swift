//
//  CreditLevelBannerTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/6.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class CreditLevelBannerTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    @IBOutlet private weak var button: UIButton!
    @IBOutlet private weak var currentLevelView: UIView!
    @IBOutlet private weak var nextLevelView: UIView!
    @IBOutlet private weak var currentLevelName: UILabel!
    @IBOutlet private weak var nextLevelName: UILabel!
    @IBOutlet private weak var currentLevelSubTitleLabel: UILabel!
    @IBOutlet private weak var nextLevelSubTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 0
        button.clipsToBounds = true
        currentLevelView.layer.cornerRadius = 5
        currentLevelView.layer.borderWidth = 0
        currentLevelView.layer.shadowOffset =  CGSize(width: 0, height: 0)
        currentLevelView.layer.shadowOpacity = 0.42
        currentLevelView.layer.shadowRadius = 6
        currentLevelView.layer.shadowColor = UIColor.black.cgColor
        currentLevelView.clipsToBounds = true
        
        nextLevelView.layer.cornerRadius = 5
        nextLevelView.layer.borderWidth = 0
        nextLevelView.layer.shadowOffset =  CGSize(width: 0, height: 0)
        nextLevelView.layer.shadowOpacity = 0.42
        nextLevelView.layer.shadowRadius = 6
        nextLevelView.layer.shadowColor = UIColor.black.cgColor
        nextLevelView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ userLevel: UInt8, inviteSummary: APIInviteSummary?, levels: [APICreditLevel]) {
        var currentLevel: APICreditLevel?
        var nextLevel: APICreditLevel?
        for level in levels {
            if level.id == userLevel {
                currentLevel = level
            }
            if nextLevel == nil && currentLevel != nil && level.id > (currentLevel?.id)! {
                nextLevel = level
                break
            }
        }
        guard let cLevel = currentLevel,
            let nLevel = nextLevel,
            let summary = inviteSummary
        else {
                self.isHidden = true
                return
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let bonusRate = formatter.string(from: cLevel.taskBonusRate/100)
        let nextBonusRate = formatter.string(from: nLevel.taskBonusRate/100)
        titleLabel.text = String(format: "升级为%@会员, 可以拿%@倍积分", nLevel.showName(false), nextBonusRate!)
        currentLevelName.text = cLevel.showName(false)
        currentLevelSubTitleLabel.text = String(format: "%@倍积分", bonusRate!)
        currentLevelView.backgroundColor = cLevel.color()
        nextLevelName.text = nLevel.showName(false)
        nextLevelSubTitleLabel.text = String(format: "%@倍积分", nextBonusRate!)
        nextLevelView.backgroundColor = nLevel.color()
        subTitleLabel.text = String(format:"邀请%d人可升级", summary.nextLevelInvites)
    }
}
