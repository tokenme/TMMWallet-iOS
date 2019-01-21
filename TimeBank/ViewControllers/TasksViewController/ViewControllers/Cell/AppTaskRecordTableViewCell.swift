//
//  AppTaskRecordTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/6.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class AppTaskRecordTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgView.layer.cornerRadius = 5.0
        imgView.layer.borderWidth = 0.0
        imgView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ task: APITaskRecord) {
        if let icon = task.image {
            imgView.kf.setImage(with: URL(string: icon))
        } else {
            imgView.image = nil
        }
        titleLabel.text = task.title
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = .floor
        let formattedBonus = formatter.string(from: task.points)!
        pointsLabel.text = "+\(formattedBonus)"
        if let updatedAt = task.updatedAt {
            let timeZone = NSTimeZone.local
            let fomatterDate = DateFormatter()
            fomatterDate.timeZone = timeZone
            fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = fomatterDate.string(from: updatedAt)
        }
    }
}
