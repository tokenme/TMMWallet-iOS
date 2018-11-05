//
//  ShareTaskSwipableTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/5.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import SwipeCellKit

class ShareTaskSwipableTableViewCell: SwipeTableViewCell, Reusable {
    private let imgView = UIImageView()
    private let titleLabel = UILabel()
    private let summaryTextView = UITextView()
    private let rewardLabel = UILabelPadding()
    
    private let viewersLabel = UILabel()
    private let bonusLabel = UILabel()
    private let pointsLeftLabel = UILabel()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.clipsToBounds = true
        containerView.addSubview(imgView)
        imgView.snp.remakeConstraints { (maker) -> Void in
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
            maker.width.equalTo(80)
            maker.height.equalTo(80)
        }
        imgView.contentMode = .scaleAspectFit
        
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.darkText
        containerView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.top.equalTo(imgView.snp.top)
            maker.trailing.equalTo(imgView.snp.leading).offset(-8)
        }
        
        summaryTextView.textContainer.lineFragmentPadding = 0
        summaryTextView.textContainerInset = UIEdgeInsets.zero
        summaryTextView.font = UIFont.systemFont(ofSize: 13)
        summaryTextView.textColor = UIColor.lightGray
        summaryTextView.isScrollEnabled = false
        summaryTextView.isSelectable = false
        summaryTextView.isUserInteractionEnabled = false
        containerView.addSubview(summaryTextView)
        summaryTextView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(8)
            maker.trailing.equalTo(titleLabel.snp.trailing)
            maker.bottom.equalTo(imgView.snp.bottom)
        }
        
        rewardLabel.layer.cornerRadius = 5
        rewardLabel.clipsToBounds = true
        rewardLabel.paddingBottom = 4
        rewardLabel.paddingTop = 4
        rewardLabel.paddingLeft = 16
        rewardLabel.paddingRight = 16
        rewardLabel.textColor = UIColor.darkGray
        rewardLabel.backgroundColor = #colorLiteral(red: 0.801612651, green: 0.9045636618, blue: 0.941994863, alpha: 1)
        rewardLabel.font = UIFont.systemFont(ofSize: 12)
        containerView.addSubview(rewardLabel)
        rewardLabel.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.top.equalTo(summaryTextView.snp.bottom).offset(8)
            maker.trailing.equalToSuperview()
            maker.bottom.equalToSuperview()
        }
        
        self.contentView.addSubview(containerView)
        
        containerView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        
        return containerView
    }()
    
    private lazy var statsStackView: UIStackView = {
        let statsStackView = UIStackView()
        statsStackView.spacing = 16.0
        statsStackView.axis = .horizontal
        statsStackView.alignment = .fill
        statsStackView.distribution = .fillEqually
        
        let viewersStack = UIStackView()
        viewersStack.spacing = 4.0
        viewersStack.axis = .vertical
        viewersStack.alignment = .fill
        viewersStack.distribution = .fillProportionally
        viewersLabel.font = MainFont.medium.with(size: 17)
        viewersLabel.textColor = .darkText
        viewersLabel.textAlignment = .center
        viewersLabel.minimumScaleFactor = 0.5
        let viewersTitleLabel = UILabel()
        viewersTitleLabel.font = UIFont.systemFont(ofSize: 12)
        viewersTitleLabel.textAlignment = .center
        viewersTitleLabel.textColor = UIColor.lightGray
        viewersTitleLabel.text = I18n.viewers.description
        viewersStack.addArrangedSubview(viewersLabel)
        viewersStack.addArrangedSubview(viewersTitleLabel)
        
        let bonusStack = UIStackView()
        bonusStack.spacing = 4.0
        bonusStack.axis = .vertical
        bonusStack.alignment = .fill
        bonusStack.distribution = .fillProportionally
        bonusLabel.font = MainFont.medium.with(size: 17)
        bonusLabel.textColor = .darkText
        bonusLabel.textAlignment = .center
        bonusLabel.minimumScaleFactor = 0.5
        let bonusTitleLabel = UILabel()
        bonusTitleLabel.font = UIFont.systemFont(ofSize: 12)
        bonusTitleLabel.textAlignment = .center
        bonusTitleLabel.textColor = UIColor.lightGray
        bonusTitleLabel.text = I18n.bonusPoint.description
        bonusStack.addArrangedSubview(bonusLabel)
        bonusStack.addArrangedSubview(bonusTitleLabel)
        
        let pointsLeftStack = UIStackView()
        pointsLeftStack.spacing = 4.0
        pointsLeftStack.axis = .vertical
        pointsLeftStack.alignment = .fill
        pointsLeftStack.distribution = .fillProportionally
        pointsLeftLabel.font = MainFont.medium.with(size: 17)
        pointsLeftLabel.textColor = .darkText
        pointsLeftLabel.textAlignment = .center
        pointsLeftLabel.minimumScaleFactor = 0.5
        let pointsLeftTitleLabel = UILabel()
        pointsLeftTitleLabel.font = UIFont.systemFont(ofSize: 12)
        pointsLeftTitleLabel.textAlignment = .center
        pointsLeftTitleLabel.textColor = UIColor.lightGray
        pointsLeftTitleLabel.text = I18n.pointsLeft.description
        pointsLeftStack.addArrangedSubview(pointsLeftLabel)
        pointsLeftStack.addArrangedSubview(pointsLeftTitleLabel)
        
        statsStackView.addArrangedSubview(viewersStack)
        statsStackView.addArrangedSubview(bonusStack)
        statsStackView.addArrangedSubview(pointsLeftStack)
        
        self.contentView.addSubview(statsStackView)
        
        return statsStackView
    }()
    
    public func fill(_ task: APIShareTask, showStats: Bool) {
        self.containerView.needsUpdateConstraints()
        if let image = task.image {
            imgView.kf.setImage(with: URL(string: image))
            imgView.isHidden = false
            if !task.showBonusHint {
                rewardLabel.isHidden = true
                rewardLabel.snp.removeConstraints()
                imgView.snp.remakeConstraints { (maker) -> Void in
                    maker.trailing.equalToSuperview()
                    maker.top.equalToSuperview()
                    maker.bottom.equalToSuperview()
                    maker.width.equalTo(80)
                    maker.height.equalTo(80)
                }
                titleLabel.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(imgView.snp.top)
                    maker.trailing.equalTo(imgView.snp.leading).offset(-8)
                }
                summaryTextView.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(titleLabel.snp.bottom).offset(8)
                    maker.trailing.equalTo(titleLabel.snp.trailing)
                    maker.height.equalTo(40)
                }
            } else {
                rewardLabel.isHidden = false
                imgView.snp.remakeConstraints { (maker) -> Void in
                    maker.trailing.equalToSuperview()
                    maker.top.equalToSuperview()
                    maker.width.equalTo(80)
                    maker.height.equalTo(80)
                }
                titleLabel.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(imgView.snp.top)
                    maker.trailing.equalTo(imgView.snp.leading).offset(-8)
                }
                summaryTextView.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(titleLabel.snp.bottom).offset(8)
                    maker.trailing.equalTo(titleLabel.snp.trailing)
                    maker.bottom.lessThanOrEqualTo(imgView.snp.bottom)
                }
                rewardLabel.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(imgView.snp.bottom).offset(8)
                    maker.trailing.equalToSuperview()
                    maker.bottom.equalToSuperview()
                }
            }
        } else {
            self.imgView.isHidden = true
            titleLabel.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview()
                maker.top.equalToSuperview()
                maker.trailing.equalToSuperview()
            }
            if !task.showBonusHint {
                rewardLabel.isHidden = true
                rewardLabel.snp.removeConstraints()
                summaryTextView.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(titleLabel.snp.bottom).offset(8)
                    maker.trailing.equalTo(titleLabel.snp.trailing)
                    maker.height.lessThanOrEqualTo(40)
                    maker.bottom.equalToSuperview()
                }
            } else {
                rewardLabel.isHidden = false
                summaryTextView.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(titleLabel.snp.bottom).offset(8)
                    maker.trailing.equalTo(titleLabel.snp.trailing)
                    maker.height.lessThanOrEqualTo(40)
                }
                rewardLabel.snp.remakeConstraints { (maker) -> Void in
                    maker.leading.equalToSuperview()
                    maker.top.equalTo(summaryTextView.snp.bottom).offset(8)
                    maker.trailing.equalToSuperview()
                    maker.bottom.equalToSuperview()
                }
            }
        }
        
        titleLabel.text = task.title
        titleLabel.sizeToFit()
        summaryTextView.text = task.summary
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedBonus: String = formatter.string(from: task.bonus)!
        let maxBonus = task.bonus * NSDecimalNumber(value: task.maxViewers)
        let formattedMaxBonus: String = formatter.string(from: maxBonus)!
        let rewardMsg = String(format: I18n.shareTaskRewardDesc.description, formattedBonus, formattedMaxBonus)
        rewardLabel.text = rewardMsg
        
        formatter.maximumFractionDigits = 4
        viewersLabel.text = "\(task.viewers)"
        bonusLabel.text = formatter.string(from: task.points - task.pointsLeft)
        pointsLeftLabel.text = formatter.string(from: task.pointsLeft)
        
        if showStats {
            containerView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(16)
                maker.trailing.equalToSuperview().offset(-16)
                maker.top.equalToSuperview().offset(8)
            }
            statsStackView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(16)
                maker.trailing.equalToSuperview().offset(-16)
                maker.top.equalTo(self.containerView.snp.bottom).offset(8)
                maker.bottom.equalToSuperview().offset(-8)
            }
            statsStackView.isHidden = false
        } else {
            containerView.snp.remakeConstraints { (maker) -> Void in
                maker.leading.equalToSuperview().offset(16)
                maker.trailing.equalToSuperview().offset(-16)
                maker.top.equalToSuperview().offset(8)
                maker.bottom.equalToSuperview().offset(-8)
            }
            statsStackView.snp.removeConstraints()
            statsStackView.isHidden = true
        }
        
        self.containerView.needsUpdateConstraints()
    }
}
