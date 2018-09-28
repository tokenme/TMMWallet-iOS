//
//  ShareTaskNoImageTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/28.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit

import UIKit
import Kingfisher
import Reusable

class ShareTaskNoImageTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var rewardLabel: UILabelPadding!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        rewardLabel.layer.cornerRadius = 5
        rewardLabel.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ task: APIShareTask) {
        titleLabel.text = task.title
        summaryLabel.text = task.summary
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedBonus: String = formatter.string(from: task.bonus)!
        let maxBonus = task.bonus * NSDecimalNumber(value: task.maxViewers)
        let formattedMaxBonus: String = formatter.string(from: maxBonus)!
        let rewardMsg = I18n.shareTaskRewardDesc.description.replacingOccurrences(of: "#points#", with: formattedBonus).replacingOccurrences(of: "#points2#", with: formattedMaxBonus)
        rewardLabel.text = rewardMsg
    }
}
