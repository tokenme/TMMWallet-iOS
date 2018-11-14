//
//  MyGoodInvestTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/13.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import Kingfisher

class MyGoodInvestTableViewCell: UITableViewCell, NibReusable {
    
    public weak var delegate: MyGoodInvestTableViewCellDelegate?
    private var invest: APIGoodInvest?
    
    @IBOutlet public weak var imgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var investLabel: UILabel!
    @IBOutlet private weak var incomeLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet public weak var redeemButton: TransitionButton!
    @IBOutlet public weak var withdrawButton: TransitionButton!
    @IBOutlet private weak var statusLabel: UILabelPadding!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        statusLabel.layer.cornerRadius = 10.0
        statusLabel.layer.borderWidth = 0.0
        statusLabel.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ invest: APIGoodInvest) {
        self.invest = invest
        if let img = invest.goodPic {
            imgView.kf.setImage(with: URL(string: img))
        }
        titleLabel.text = invest.goodName
        
        if let insertedAt = invest.investedAt {
            let timeZone = NSTimeZone.local
            let fomatterDate = DateFormatter()
            fomatterDate.timeZone = timeZone
            fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = fomatterDate.string(from: insertedAt)
        }
        var strikethrough = false
        switch(invest.redeemStatus) {
        case .redeemed:
            statusLabel.backgroundColor = UIColor.greenGrass
            statusLabel.textColor = UIColor.white
            statusLabel.text = "已提现"
            strikethrough = true
        case .withdraw:
            statusLabel.backgroundColor = UIColor.pinky
            statusLabel.textColor = UIColor.white
            statusLabel.text = "已撤资"
            strikethrough = true
        case .unknown:
            statusLabel.backgroundColor = UIColor(white: 0.94, alpha: 1)
            statusLabel.textColor = UIColor.darkGray
            statusLabel.text = "已投资"
        }
        investLabel.attributedText = numberLabelAttribute("投资积分: ", invest.points, 4, strikethrough)
        incomeLabel.attributedText = numberLabelAttribute("投资收益: ", invest.income, 4, strikethrough)
        contentView.updateConstraints()
    }
    
    private func numberLabelAttribute(_ prefix: String, _ value: NSDecimalNumber, _ decimals: Int, _ strikethrough: Bool) -> NSMutableAttributedString {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = decimals
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        
        let prefixAttributes = [NSAttributedString.Key.font:MainFont.light.with(size: 12),
                                NSAttributedString.Key.foregroundColor:UIColor.darkSubText]
        var valueAttributes = [NSAttributedString.Key.font:MainFont.medium.with(size: 15),
                               NSAttributedString.Key.foregroundColor: UIColor.darkText]
        if strikethrough {
            valueAttributes[NSAttributedString.Key.strikethroughStyle] = NSUnderlineStyle.single.rawValue as NSObject
        }
        let valueStr = formatter.string(from: value)!
        let attString = NSMutableAttributedString(string: "\(prefix)\(valueStr)")
        attString.addAttributes(prefixAttributes, range:NSRange.init(location: 0, length: prefix.count))
        attString.addAttributes(valueAttributes, range: NSRange.init(location: prefix.count, length: valueStr.count))
        
        return attString
    }
}

extension MyGoodInvestTableViewCell {
    @IBAction func redeem() {
        guard let invest = self.invest else { return }
        self.delegate?.investRedeem(invest: invest, cell: self)
    }
    
    @IBAction func withdraw() {
        guard let invest = self.invest else { return }
        self.delegate?.investWithdraw(invest: invest, cell: self)
    }
}

public protocol MyGoodInvestTableViewCellDelegate: NSObjectProtocol {
    func investWithdraw(invest: APIGoodInvest, cell: UITableViewCell)
    func investRedeem(invest: APIGoodInvest, cell: UITableViewCell)
}
