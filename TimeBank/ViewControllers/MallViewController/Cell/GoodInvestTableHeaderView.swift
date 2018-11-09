//
//  GoodInvestTableHeaderView.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/9.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class GoodInvestTableHeaderView: UIView, NibOwnerLoadable {
    
    static let height: CGFloat = 44
    
    @IBOutlet private weak var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func fill(_ good: APIGood) {
        if good.totalInvestors == 0 && good.investIncome == 0 {
            titleLabel.text = "还没人投资"
            return
        } else if good.investIncome == 0 {
            titleLabel.text = "还没有投资收益"
            return
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let income = formatter.string(from: good.investIncome)
        titleLabel.text = "\(good.totalInvestors)个人瓜分 ¥\(income!) 投资收益"
    }

}
