//
//  ShareTaskNoImageTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/28.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Kingfisher
import Reusable
import SwipeCellKit

class ShareTaskNoImageTableViewCell: SwipeTableViewCell, NibReusable {
    
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var summaryTextView: UITextView!
    @IBOutlet private weak var rewardLabel: UILabelPadding!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        rewardLabel.layer.cornerRadius = 5
        rewardLabel.clipsToBounds = true
        rewardLabel.paddingBottom = 4
        rewardLabel.paddingTop = 4
        rewardLabel.paddingLeft = 16
        rewardLabel.paddingRight = 16
        summaryTextView.textContainer.lineFragmentPadding = 0;
        summaryTextView.textContainerInset = UIEdgeInsets.zero;
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ task: APIShareTask) {
        let progress = (task.points - task.pointsLeft) / task.points
        progressView.setProgress(progress.floatValue, animated: true)
        titleLabel.text = task.title
        summaryTextView.text = task.summary
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedBonus: String = formatter.string(from: task.bonus)!
        let maxBonus = task.bonus * NSDecimalNumber(value: task.maxViewers)
        let formattedMaxBonus: String = formatter.string(from: maxBonus)!
        let rewardMsg = String(format: I18n.shareTaskRewardDesc.description, formattedBonus, formattedMaxBonus)
        rewardLabel.text = rewardMsg
    }
}
