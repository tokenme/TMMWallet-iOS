//
//  UserInfoTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/5.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import Kingfisher

class UserInfoTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var avatarImageView : UIImageView!
    @IBOutlet private weak var mobileLabel: UILabel!
    @IBOutlet private weak var levelImageView: UIImageView!
    @IBOutlet private weak var levelNameLabel: UILabel!
    @IBOutlet private weak var nextLevelInvitesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.layer.borderWidth = 0.0
        avatarImageView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ userInfo: APIUser?, inviteSummary: APIInviteSummary?) {
        if let u = userInfo {
            if let showName = u.showName {
                mobileLabel.text = showName
            } else {
                mobileLabel.text = "+\(u.countryCode!)\(u.mobile!)"
            }
            levelImageView.tintColor = u.level?.color() ?? APICreditLevel()!.color()
            levelNameLabel.text = u.level?.showName(true) ?? APICreditLevel()!.showName(true)
            let levelImage = UIImage(named: "CreditLevel")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            levelImageView.image = levelImage
            
            if let avatar = URL(string: u.avatar ?? "") {
                avatarImageView.kf.setImage(with: avatar)
            }
        }
        
        if let summary = inviteSummary {
            nextLevelInvitesLabel.text = String(format: I18n.nextLevelInvitesDesc.description, summary.nextLevelInvites)
        }
    }
}
