//
//  MarketTopTableViewHeader.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class MarketTopTableViewHeader: UIView, NibOwnerLoadable {

    static let height: CGFloat = 44
    
    @IBOutlet private weak var askAmountLabel: UILabel!
    @IBOutlet private weak var askPriceLabel: UILabel!
    @IBOutlet private weak var bidAmountLabel: UILabel!
    @IBOutlet private weak var bidPriceLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        askAmountLabel.text = I18n.amount.description
        bidAmountLabel.text = I18n.amount.description
        askPriceLabel.text = I18n.price.description
        bidPriceLabel.text = I18n.price.description
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
