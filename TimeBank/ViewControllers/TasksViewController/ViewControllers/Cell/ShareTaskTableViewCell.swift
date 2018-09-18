//
//  ShareTaskTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Kingfisher
import Reusable

class ShareTaskTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var bonusLabel: UILabel!
    @IBOutlet private weak var maxViewersLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ task: APIShareTask) {
        if let image = task.image {
            imgView.kf.setImage(with: URL(string: image))
        }
        titleLabel.text = task.title
        summaryLabel.text = task.summary
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedBonus: String = formatter.string(from: task.bonus)!
        let bonusText = I18n.pointsPerViewer.description.replacingOccurrences(of: "#points#", with: formattedBonus)
        bonusLabel.text = bonusText
        let maxBonus = task.bonus * NSDecimalNumber(value: task.maxViewers)
        let formattedMaxBonus: String = formatter.string(from: maxBonus)!
        maxViewersLabel.text = "\(I18n.maxBonus.description) \(formattedMaxBonus) \(I18n.points.description)"
    }
}
