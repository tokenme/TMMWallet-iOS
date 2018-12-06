//
//  InviteIntroTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/6.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

class InviteIntroTableViewCell: UITableViewCell, Reusable {
    
    lazy private var titleLabel: UILabel = {[weak self] in
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        self?.contentView.addSubview(label)
        label.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.lessThanOrEqualToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        self?.backgroundColor = UIColor.redish
        return label
    }()
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ inviteSummary: APIInviteSummary?) {
        guard let summary = inviteSummary else { return }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedRate = String(format: "%@%%", formatter.string(from: summary.inviteBonusRate)!)
        let formattedBonus = String(format: "%@", formatter.string(from: summary.inviterCashBonus)!)
        titleLabel.text = String(format: I18n.inviteSimpleInto.description, formattedBonus, formattedRate)
    }

}
