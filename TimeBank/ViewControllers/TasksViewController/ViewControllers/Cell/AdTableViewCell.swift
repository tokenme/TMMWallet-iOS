//
//  AdTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/3.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import SnapKit
import Kingfisher

class AdTableViewCell: UITableViewCell, Reusable {
    
    lazy private var imgView: UIImageView = {
        let imageView = UIImageView()
        self.contentView.addSubview(imageView)
        return imageView
    }()
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ creative: APICreative, fullFill: Bool) {
        imgView.kf.setImage(with: URL(string: creative.image))
        if fullFill {
            imgView.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.trailing.top.bottom.equalToSuperview()
                guard let weakSelf = self else { return }
                maker.height.equalTo(weakSelf.imgView.snp.width).multipliedBy(Float64(creative.height)/Float64(creative.width)).priority(750)
            }
        } else {
            imgView.snp.remakeConstraints {[weak self] (maker) -> Void in
                maker.leading.top.equalToSuperview().offset(16)
                maker.trailing.bottom.equalToSuperview().offset(-16)
                guard let weakSelf = self else { return }
                maker.height.equalTo(weakSelf.imgView.snp.width).multipliedBy(Float64(creative.height)/Float64(creative.width)).priority(750)
            }
        }
    }
}
