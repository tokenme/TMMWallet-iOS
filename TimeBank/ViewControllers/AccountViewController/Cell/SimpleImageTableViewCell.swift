//
//  SimpleImageTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/5.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit

class SimpleImageTableViewCell: UITableViewCell, Reusable {
    lazy private var imgView: UIImageView = {[weak self] in
        let v = UIImageView()
        self?.contentView.addSubview(v)
        return v
    }()
    
    func fill(_ image: UIImage, ratio: Float64) {
        imgView.image = image
        imgView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(4)
            maker.bottom.equalToSuperview().offset(-4)
            maker.height.equalTo(imgView.snp.width).multipliedBy(ratio)
        }
    }
}
