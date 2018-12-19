//
//  ChestTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/18.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class ChestTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(title: String, subTitle: String, icon: UIImage?, buttonTitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subTitle
        iconView.image = icon
        button.setTitle(buttonTitle, for: .normal)
    }
}
