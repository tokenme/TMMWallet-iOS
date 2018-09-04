//
//  LoaderModal.swift
//  ucoin
//
//  Created by Syd on 2018/6/15.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SnapKit

fileprivate let DefaultSpinnerWidth = 30.0

class LoaderModal: UIView {
    private var spinner = NVActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: DefaultSpinnerWidth, height: DefaultSpinnerWidth), type: NVActivityIndicatorType.ballScaleMultiple, color: UIColor.primaryBlue)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.spinner)
        spinner.snp.remakeConstraints { (maker) -> Void in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.width.equalTo(DefaultSpinnerWidth)
            maker.height.equalTo(DefaultSpinnerWidth)
        }
        self.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init?(backgroundColor: UIColor) {
        self.init(frame: CGRect.zero)
        self.backgroundColor = backgroundColor
    }
    
    public func start() {
        self.isHidden = false
        self.spinner.startAnimating()
        self.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.width.equalToSuperview()
            maker.height.equalToSuperview()
        }
    }
    
    public func stop() {
        self.isHidden = true
        self.spinner.stopAnimating()
    }
    
}
