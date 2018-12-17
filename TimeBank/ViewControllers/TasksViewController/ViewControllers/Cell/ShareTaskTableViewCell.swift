//
//  ShareTaskTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/19.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import Kingfisher

class ShareTaskTableViewCell: UITableViewCell, Reusable {
    public let coverView = UIImageView()
    private let imgView = UIImageView()
    private let playButton = UIButton(type: UIButton.ButtonType.custom)
    private let titleLabel = UILabel()
    private let summaryTextView = UITextView()
    private let rewardLabel = UILabelPadding()
    private let zhuanLabel = UILabelPadding()
    
    private let viewersLabel = UILabel()
    private let bonusLabel = UILabel()
    private let pointsLeftLabel = UILabel()
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.clipsToBounds = true
        coverView.backgroundColor = .black
        containerView.addSubview(coverView)
        coverView.contentMode = .scaleAspectFit
        
        imgView.backgroundColor = .clear
        containerView.addSubview(imgView)
        imgView.contentMode = .scaleAspectFit
        
        zhuanLabel.layer.cornerRadius = 5
        zhuanLabel.clipsToBounds = true
        zhuanLabel.paddingBottom = 4
        zhuanLabel.paddingTop = 4
        zhuanLabel.paddingLeft = 4
        zhuanLabel.paddingRight = 4
        zhuanLabel.textColor = UIColor.white
        zhuanLabel.backgroundColor = UIColor.red
        zhuanLabel.font = UIFont.systemFont(ofSize: 12)
        zhuanLabel.text = "赚"
        containerView.addSubview(zhuanLabel)
        
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.darkText
        containerView.addSubview(titleLabel)
        
        summaryTextView.textContainer.lineFragmentPadding = 0
        summaryTextView.textContainerInset = UIEdgeInsets.zero
        summaryTextView.font = UIFont.systemFont(ofSize: 13)
        summaryTextView.textColor = UIColor.lightGray
        summaryTextView.isScrollEnabled = false
        summaryTextView.isSelectable = false
        summaryTextView.isUserInteractionEnabled = false
        containerView.addSubview(summaryTextView)
        
        rewardLabel.layer.cornerRadius = 5
        rewardLabel.clipsToBounds = true
        rewardLabel.paddingBottom = 4
        rewardLabel.paddingTop = 4
        rewardLabel.paddingLeft = 16
        rewardLabel.paddingRight = 16
        rewardLabel.textColor = UIColor.darkGray
        rewardLabel.backgroundColor = UIColor.init(rgbHex: 0xf8f8f6)
        rewardLabel.font = UIFont.systemFont(ofSize: 12)
        containerView.addSubview(rewardLabel)
        
        self.contentView.addSubview(containerView)
        
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
    
    private func updateTitelConstraints(_ isTask: Bool, haveImage: Bool) {
        if haveImage {
            imgView.isHidden = false
            imgView.snp.remakeConstraints { (maker) -> Void in
                maker.trailing.top.equalToSuperview()
                maker.width.height.equalTo(80)
            }
            imgView.setContentHuggingPriority(UILayoutPriority(rawValue: 2000), for: .horizontal)
            imgView.setContentHuggingPriority(UILayoutPriority(rawValue: 2000), for: .vertical)
            imgView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 2000), for: .horizontal)
            imgView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 2000), for: .vertical)
            if isTask {
                zhuanLabel.isHidden = false
                zhuanLabel.snp.remakeConstraints { (maker) -> Void in
                    maker.top.leading.equalToSuperview()
                }
                zhuanLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 2000), for: .horizontal)
                zhuanLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 2000), for: .horizontal)
                titleLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
                    maker.top.equalToSuperview()
                    guard let weakSelf = self else { return }
                    maker.leading.equalTo(weakSelf.zhuanLabel.snp.trailing).offset(8)
                    maker.trailing.equalTo(weakSelf.imgView.snp.leading).offset(-8)
                }
                titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
            } else {
                zhuanLabel.isHidden = true
                zhuanLabel.snp.removeConstraints()
                titleLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
                    maker.leading.top.equalToSuperview()
                    guard let weakSelf = self else { return }
                    maker.trailing.equalTo(weakSelf.imgView.snp.leading).offset(-8)
                }
            }
            return
        }
        self.imgView.isHidden = true
        self.imgView.snp.removeConstraints()
        if isTask {
            zhuanLabel.isHidden = false
            zhuanLabel.snp.remakeConstraints { (maker) -> Void in
                maker.top.leading.equalToSuperview()
            }
            zhuanLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 2000), for: .horizontal)
            zhuanLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 2000), for: .horizontal)
            titleLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.top.trailing.equalToSuperview()
                guard let weakSelf=self else { return }
                maker.leading.equalTo(weakSelf.zhuanLabel.snp.trailing).offset(8)
            }
            titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 750), for: .horizontal)
        } else {
            zhuanLabel.isHidden = true
            zhuanLabel.snp.removeConstraints()
            titleLabel.snp.remakeConstraints { (maker) -> Void in
                maker.top.leading.trailing.equalToSuperview()
            }
        }
    }
    
    private func updateSummaryViewConstraints(_ showRewardHint: Bool, haveImage: Bool) {
        if haveImage {
            if showRewardHint {
                rewardLabel.isHidden = false
                summaryTextView.snp.remakeConstraints {[weak self] (maker) -> Void in
                    maker.leading.equalToSuperview()
                    guard let weakSelf = self else { return }
                    maker.top.equalTo(weakSelf.titleLabel.snp.bottom).offset(8)
                    maker.trailing.equalTo(weakSelf.imgView.snp.leading).offset(-8)
                    maker.bottom.lessThanOrEqualTo(weakSelf.imgView.snp.bottom)
                }
                rewardLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
                    maker.trailing.leading.bottom.equalToSuperview()
                    guard let weakSelf = self else { return }
                    maker.top.equalTo(weakSelf.imgView.snp.bottom).offset(8)
                }
            } else {
                rewardLabel.isHidden = true
                rewardLabel.snp.removeConstraints()
                summaryTextView.snp.remakeConstraints {[weak self] (maker) -> Void in
                    maker.leading.equalToSuperview()
                    //maker.height.equalTo(40).priority(ConstraintPriority.low)
                    guard let weakSelf = self else { return }
                    maker.top.equalTo(weakSelf.titleLabel.snp.bottom).offset(8)
                    maker.trailing.equalTo(weakSelf.imgView.snp.leading).offset(-8)
                    maker.bottom.lessThanOrEqualTo(weakSelf.imgView.snp.bottom)
                }
            }
            return
        }
        if showRewardHint {
            rewardLabel.isHidden = false
            summaryTextView.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.trailing.equalToSuperview()
                maker.height.lessThanOrEqualTo(40)
                guard let weakSelf = self else { return }
                maker.top.equalTo(weakSelf.titleLabel.snp.bottom).offset(8)
            }
            rewardLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.trailing.bottom.equalToSuperview()
                guard let weakSelf = self else { return }
                maker.top.equalTo(weakSelf.summaryTextView.snp.bottom).offset(8)
            }
        } else {
            rewardLabel.isHidden = true
            rewardLabel.snp.removeConstraints()
            summaryTextView.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.bottom.trailing.equalToSuperview()
                maker.height.lessThanOrEqualTo(40)
                guard let weakSelf = self else { return }
                maker.top.equalTo(weakSelf.titleLabel.snp.bottom).offset(8)
            }
        }
    }
    
    private func updateCoverViewConstraint(_ showRewardHint: Bool) {
        if showRewardHint {
            rewardLabel.isHidden = false
            coverView.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.trailing.equalToSuperview()
                maker.top.equalTo(titleLabel.snp.bottom).offset(8)
                guard let weakSelf = self else { return }
                maker.height.equalTo(weakSelf.coverView.snp.width).multipliedBy(9.0/16.0).priority(750)
            }
            rewardLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.trailing.bottom.equalToSuperview()
                guard let weakSelf = self else { return }
                maker.top.equalTo(weakSelf.coverView.snp.bottom).offset(8)
            }
        } else {
            rewardLabel.isHidden = true
            rewardLabel.snp.removeConstraints()
            coverView.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.trailing.bottom.equalToSuperview()
                guard let weakSelf = self else { return }
                maker.top.equalTo(weakSelf.titleLabel.snp.bottom).offset(8)
                maker.height.equalTo(weakSelf.coverView.snp.width).multipliedBy(9.0/16.0).priority(750)
            }
        }
    }
    
    public func fill(_ task: APIShareTask, showStats: Bool) {
        self.containerView.needsUpdateConstraints()
        if task.isVideo == 1 {
            self.imgView.isHidden = true
            self.imgView.snp.removeConstraints()
            if let img = task.image {
                coverView.kf.setImage(with: URL(string: img))
            } else {
                coverView.image = nil
            }
            coverView.isHidden = false
            updateTitelConstraints(task.isTask, haveImage: false)
            summaryTextView.isHidden = true
            summaryTextView.snp.removeConstraints()
            updateCoverViewConstraint(task.showBonusHint && !isValidatingBuild())
        } else {
            self.coverView.isHidden = true
            self.coverView.snp.removeConstraints()
            summaryTextView.isHidden = false
            if let image = task.image {
                imgView.kf.setImage(with: URL(string: image))
                updateTitelConstraints(task.isTask, haveImage: true)
                updateSummaryViewConstraints(task.showBonusHint && !isValidatingBuild(), haveImage: true)
            } else {
                updateTitelConstraints(task.isTask, haveImage: false)
                updateSummaryViewConstraints(task.showBonusHint && !isValidatingBuild(), haveImage: false)
            }
        }
        
        titleLabel.text = task.title
        
        if task.isTask {
            rewardLabel.backgroundColor = UIColor.init(rgbHex: 0xfffae3)
        } else {
            rewardLabel.backgroundColor = UIColor.init(rgbHex: 0xf8f8f6)
        }
        
        titleLabel.sizeToFit()
        summaryTextView.text = task.summary
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        //let formattedBonus: String = formatter.string(from: task.bonus)!
        let maxBonus = task.bonus * NSDecimalNumber(value: task.maxViewers)
        let formattedMaxBonus: String = formatter.string(from: maxBonus)!
        let rewardMsg = String(format: I18n.shareTaskRewardDescSimple.description, formattedMaxBonus)
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
            statsStackView.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.equalToSuperview().offset(16)
                maker.trailing.equalToSuperview().offset(-16)
                maker.bottom.equalToSuperview().offset(-8)
                guard let weakSelf = self else { return }
                maker.top.equalTo(weakSelf.containerView.snp.bottom).offset(8)
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
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
}
