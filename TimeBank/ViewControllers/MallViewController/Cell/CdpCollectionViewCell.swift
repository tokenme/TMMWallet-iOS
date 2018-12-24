//
//  CdpCollectionViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/24.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

class CdpCollectionViewCell: UICollectionViewCell, Reusable {
    
    lazy private var pointsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    lazy private var titleLabel: UILabelPadding = {
        let label = UILabelPadding()
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 252.0), for: .horizontal)
        label.font = MainFont.bold.with(size: 24)
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.textColor = .white
        label.paddingBottom = 8
        label.paddingTop = 8
        label.paddingLeft = 16
        label.paddingRight = 16
        label.backgroundColor = UIColor.init(rgbHex: 0xFF9300)
        label.layer.cornerRadius = 8
        label.layer.borderWidth = 0
        label.clipsToBounds = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }
    
    private func setup() {
        contentView.backgroundColor = UIColor.white
        contentView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints {(maker) -> Void in
            maker.top.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
        }
        contentView.addSubview(pointsLabel)
        pointsLabel.snp.remakeConstraints {[weak self ](maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.bottom.trailing.equalToSuperview().offset(-16)
            guard let weakSelf = self else { return }
            maker.top.equalTo(weakSelf.titleLabel.snp.bottom).offset(16)
        }
        let screenWidth = UIScreen.main.bounds.width
        let w = (screenWidth-12)*0.5
        contentView.snp.remakeConstraints { (maker) -> Void in
            maker.top.leading.trailing.bottom.equalToSuperview()
            maker.width.equalTo(w)
        }
    }
    
    func fill(_ cdp:APIRedeemCdp) {
        titleLabel.text = cdp.grade
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        pointsLabel.text = "\(formatter.string(from: cdp.points)!) \(I18n.points.description)"
    }
}
