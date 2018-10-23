//
//  FeedbackHeaderView.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/23.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import Kingfisher
import SnapKit

final class FeedbackHeaderView: UIView, Reusable {
    
    private let msgLabel = UILabel()
    private let imgView = UIImageView()
    private let dateLabel = UILabel()
    
    private lazy var containerView: UIView = {
        self.backgroundColor = .white
        let containerView = UIView()
        dateLabel.font = UIFont.systemFont(ofSize: 12)
        dateLabel.textColor = UIColor.lightGray
        containerView.addSubview(dateLabel)
        dateLabel.snp.remakeConstraints { (maker) in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
        }
        msgLabel.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 0)
        msgLabel.font = UIFont.systemFont(ofSize: 14)
        msgLabel.numberOfLines = 0
        containerView.addSubview(msgLabel)
        imgView.contentMode = .scaleAspectFit
        containerView.addSubview(imgView)
        self.addSubview(containerView)
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
            maker.leading.equalToSuperview().offset(16)
        }
        return containerView
    }()
    
    func fill(_ feedback: APIFeedback) {
        self.containerView.needsUpdateConstraints()
        let timestamp = NSDecimalNumber(string: feedback.ts)
        let publishedDate = Date(timeIntervalSince1970: timestamp.doubleValue)
        let timeZone = NSTimeZone.local
        let fomatterDate = DateFormatter()
        fomatterDate.timeZone = timeZone
        fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateLabel.text = fomatterDate.string(from: publishedDate)
        
        msgLabel.text = feedback.msg
        let size: CGSize = msgLabel.sizeThatFits(CGSize(width: msgLabel.frame.size.width, height: CGFloat(MAXFLOAT)))
        if let img = feedback.image {
            msgLabel.snp.remakeConstraints { (maker) in
                maker.leading.equalToSuperview()
                maker.trailing.equalToSuperview()
                maker.top.equalTo(dateLabel.snp.bottom).offset(8)
                maker.height.equalTo(size.height)
            }
            imgView.isHidden = false
            imgView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview()
                maker.top.equalTo(msgLabel.snp.bottom).offset(8)
                maker.width.equalTo(80)
                maker.height.equalTo(80)
                maker.bottom.equalToSuperview()
            }
            imgView.kf.setImage(with: URL(string:img))
        } else {
            msgLabel.snp.remakeConstraints { (maker) in
                maker.leading.equalToSuperview()
                maker.trailing.equalToSuperview()
                maker.top.equalTo(dateLabel.snp.bottom).offset(8)
                maker.bottom.equalToSuperview()
                maker.height.equalTo(size.height)
            }
            imgView.isHidden = true
            imgView.snp.removeConstraints()
        }
        self.containerView.needsUpdateConstraints()
        self.containerView.layoutIfNeeded()
    }
    
    public func viewHeight() -> CGFloat {
        return self.containerView.frame.height + 16
    }

}
