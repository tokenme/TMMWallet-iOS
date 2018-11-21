//
//  GoodLoadingCollectionViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/21.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import SkeletonView

class GoodLoadingCollectionViewCell: UICollectionViewCell, Reusable {
    
    lazy public var cover: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.isSkeletonable = true
        imgView.backgroundColor = UIColor.dimmedLightBackground
        return imgView
    }()
    
    lazy private var textView: UITextView = {
        let textView = UITextView()
        textView.isSkeletonable = true
        return textView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isSkeletonable = true
        self.contentView.isSkeletonable = true
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
        contentView.addSubview(textView)
        textView.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.leading.equalToSuperview().offset(4)
            maker.trailing.equalToSuperview().offset(-4)
            maker.bottom.equalToSuperview().offset(-8)
            guard let weakSelf = self else { return }
            maker.top.equalTo(weakSelf.cover.snp.bottom).offset(8)
            maker.height.equalTo(weakSelf.cover.snp.height).multipliedBy(0.3)
        }
        let screenWidth = UIScreen.main.bounds.width
        let w = (screenWidth-12)*0.5
        contentView.snp.remakeConstraints { (maker) -> Void in
            maker.top.leading.trailing.bottom.equalToSuperview()
            maker.width.equalTo(w)
        }
    }
}
