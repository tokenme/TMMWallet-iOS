//
//  ShareTaskRecordTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/6.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class ShareTaskRecordTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var viewersLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ task: APITaskRecord) {
        titleLabel.text = task.title
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedBonus = formatter.string(from: task.points)!
        pointsLabel.text = "+\(formattedBonus)"
        viewersLabel.text = "\(I18n.view.description) \(task.viewers) \(I18n.times.description)"
        if let updatedAt = task.updatedAt {
            let timeZone = NSTimeZone.local
            let fomatterDate = DateFormatter()
            fomatterDate.timeZone = timeZone
            fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = fomatterDate.string(from: updatedAt)
        }
    }
}
