//
//  FeedbackReplyTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/23.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class FeedbackReplyTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var msgLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func fill(_ feedback: APIFeedback, username: String?) {
        let timestamp = NSDecimalNumber(string: feedback.ts)
        let publishedDate = Date(timeIntervalSince1970: timestamp.doubleValue)
        let timeZone = NSTimeZone.local
        let fomatterDate = DateFormatter()
        fomatterDate.timeZone = timeZone
        fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateLabel.text = fomatterDate.string(from: publishedDate)
        if feedback.bot {
            nameLabel.text = username
        } else {
            nameLabel.text = I18n.operatorName.description
        }
        msgLabel.text = feedback.msg
    }
}
