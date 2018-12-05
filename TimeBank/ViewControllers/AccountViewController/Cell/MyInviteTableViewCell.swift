//
//  MyInviteTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/5.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import Kingfisher

class MyInviteTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var avatarView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var pointsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarView.layer.cornerRadius = 22
        avatarView.layer.borderWidth = 0.0
        avatarView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ userInfo: APIUser) {
        if let showName = userInfo.showName {
            nameLabel.text = showName
        } else {
            nameLabel.text = "+\(userInfo.countryCode!)\(userInfo.mobile!)"
        }
        
        if let avatar = URL(string: userInfo.avatar ?? "") {
            avatarView.kf.setImage(with: avatar)
        }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedValue = formatter.string(from: userInfo.contribute)!
        pointsLabel.text = "+\(formattedValue) \(I18n.points.description)"
    }
}
