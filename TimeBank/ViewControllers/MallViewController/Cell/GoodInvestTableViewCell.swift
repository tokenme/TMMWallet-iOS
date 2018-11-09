//
//  GoodInvestTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import Kingfisher

class GoodInvestTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var avatarView: UIImageView!
    @IBOutlet private weak var nickLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarView.layer.cornerRadius = 22
        avatarView.layer.borderWidth = 0
        avatarView.clipsToBounds = true
        pointsLabel.minimumScaleFactor = 0.5
        pointsLabel.adjustsFontSizeToFitWidth = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ good: APIGoodInvest) {
        if let avatar = good.avatar {
            avatarView.kf.setImage(with: URL(string: avatar))
        }
        nickLabel.text = good.userName
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        
        let afterFix = "积分"
        let pointsStr = "\(formatter.string(from: good.points)!)"
        let afterFixAttributes = [NSAttributedString.Key.font:MainFont.light.with(size: 12), NSAttributedString.Key.foregroundColor:UIColor.darkSubText]
        let pointsAttributes = [NSAttributedString.Key.font:MainFont.medium.with(size: 17), NSAttributedString.Key.foregroundColor:UIColor.darkText]
        let attString = NSMutableAttributedString(string: "\(pointsStr) \(afterFix)")
        attString.addAttributes(pointsAttributes, range:NSRange.init(location: 0, length: pointsStr.count))
        attString.addAttributes(afterFixAttributes, range: NSRange.init(location: pointsStr.count + 1, length: afterFix.count))
        pointsLabel.attributedText = attString
    }
}
