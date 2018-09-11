//
//  SimpleHeaderView.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/11.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

final class SimpleHeaderView: UIView, NibOwnerLoadable {
    
    static let height: CGFloat = 50
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func fill(_ text: String) {
        titleLabel.text = text
    }
}
