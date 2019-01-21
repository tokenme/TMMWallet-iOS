//
//  InviteStatsTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/5.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class InviteStatsTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var inviteUsersLabel: UILabel!
    @IBOutlet private weak var inviteIncomeLabel: UILabel!
    @IBOutlet private weak var inviteFriendsContributeLabel: UILabel!
    @IBOutlet private weak var inviteUsersTitleLabel: UILabel!
    @IBOutlet private weak var inviteIncomeTitleLabel: UILabel!
    @IBOutlet private weak var inviteFriendsContributeTitleLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        inviteUsersTitleLabel.text = I18n.inviteUsers.description
        inviteIncomeTitleLabel.text = I18n.inviteIncome.description
        inviteFriendsContributeTitleLabel.text = I18n.inviteFriendsContribute.description
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ inviteSummary: APIInviteSummary?) {
        if let summary = inviteSummary {
            inviteUsersLabel.text = String(summary.invites)
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            formatter.roundingMode = .floor
            inviteIncomeLabel.text = formatter.string(from: summary.points)
            inviteFriendsContributeLabel.text = formatter.string(from: summary.friendsContribute)
        }
    }
}
