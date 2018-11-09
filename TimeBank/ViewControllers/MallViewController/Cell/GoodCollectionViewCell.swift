//
//  GoodCollectionViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import Kingfisher

class GoodCollectionViewCell: UICollectionViewCell, Reusable {
    
    lazy public var cover: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
    
    lazy private var priceLabel: UILabel = {
        let label = UILabel()
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 251.0), for: .horizontal)
        label.font = MainFont.bold.with(size: 10)
        return label
    }()
    
    lazy private var commissionPriceLabel: UILabelPadding = {
        let label = UILabelPadding()
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 252.0), for: .horizontal)
        label.font = MainFont.medium.with(size: 12)
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.paddingBottom = 4
        label.paddingTop = 4
        label.paddingLeft = 4
        label.paddingRight = 4
        label.textColor = .white
        label.backgroundColor = UIColor.pinky
        label.layer.cornerRadius = 5
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
        contentView.addSubview(cover)
        cover.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.top.leading.trailing.equalToSuperview()
            guard let weakSelf = self else { return }
            maker.height.equalTo(weakSelf.contentView.snp.width)
        }
        contentView.addSubview(titleLabel)
        
        titleLabel.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.leading.equalToSuperview().offset(4)
            maker.trailing.equalToSuperview().offset(-4)
            guard let weakSelf = self else { return }
            maker.top.equalTo(weakSelf.cover.snp.bottom).offset(8)
        }
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        stackView.addArrangedSubview(priceLabel)
        stackView.addArrangedSubview(commissionPriceLabel)
        contentView.addSubview(stackView)
        stackView.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.leading.equalToSuperview().offset(4)
            maker.trailing.equalToSuperview().offset(-4)
            maker.bottom.equalToSuperview().offset(-8)
            guard let weakSelf = self else { return }
            maker.top.equalTo(weakSelf.titleLabel.snp.bottom).offset(8)
        }
        let screenWidth = UIScreen.main.bounds.width
        let w = (screenWidth-12)*0.5
        contentView.snp.remakeConstraints { (maker) -> Void in
            maker.top.leading.trailing.bottom.equalToSuperview()
            maker.width.equalTo(w)
        }
    }
    
    func fill(_ good:APIGood) {
        if let img = good.pic {
            cover.kf.setImage(with: URL(string: img))
        }
        titleLabel.text = good.name
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let price = good.price - good.purchaseWithdraw
        let priceStr = "¥\(formatter.string(from: price)!)"
        let oriPriceStr = "\(formatter.string(from: good.oriPrice)!)"
        let priceAttributes = [NSAttributedString.Key.font:MainFont.medium.with(size: 16), NSAttributedString.Key.foregroundColor:UIColor.darkText]
        let oriPriceAttributes = [NSAttributedString.Key.font:MainFont.light.with(size: 14),
                                  NSAttributedString.Key.foregroundColor: UIColor.darkSubText,
                                  NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attString = NSMutableAttributedString(string: "\(priceStr) \(oriPriceStr)")
        attString.addAttributes(priceAttributes, range:NSRange.init(location: 0, length: priceStr.count + 1))
        attString.addAttributes(oriPriceAttributes, range: NSRange.init(location: priceStr.count + 1, length: oriPriceStr.count))
        priceLabel.attributedText = attString
        commissionPriceLabel.text = "赚 ¥\(formatter.string(from: good.commissionPrice)!)"
    }
}
