//
//  MarketNavHeaderView.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class MarketNavHeaderView: UIView, NibOwnerLoadable {
    
    static let height: CGFloat = 44
    
    @IBOutlet private weak var priceLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func fill(_ rate: APIOrderBookRate?) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 5
        formatter.minimumFractionDigits = 5
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        
        let changeRate: NSDecimalNumber = rate?.changeRate ?? 0
        var rateColor: UIColor = UIColor.lightGray
        if changeRate > 0 {
            rateColor = UIColor.greenGrass
        } else if changeRate < 0 {
            rateColor = UIColor.red
        }
        
        let rateAttributes = [NSAttributedString.Key.font:UIFont.systemFont(ofSize:14), NSAttributedString.Key.foregroundColor:rateColor]
        let normalAttributes = [NSAttributedString.Key.font:UIFont.systemFont(ofSize:14), NSAttributedString.Key.foregroundColor:UIColor.lightGray]
        
        let rateStr = "\(formatter.string(from: changeRate)!)%"
        
        let price : NSDecimalNumber = rate?.price ?? 0
        
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 6
        
        let priceStr = " | \(formatter.string(from: price)!)"
        
        let attString = NSMutableAttributedString(string: "\(rateStr)\(priceStr)")
        attString.addAttributes(rateAttributes, range:NSRange.init(location: 0, length: rateStr.count))
        attString.addAttributes(normalAttributes, range: NSRange.init(location: rateStr.count, length: priceStr.count))
        
        priceLabel.attributedText = attString
        
    }
    
}
