//
//  TransactionTableViewCell.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/12.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable

class TransactionTableViewCell: UITableViewCell, NibReusable {
    
    @IBOutlet private weak var imgView: UIImageView!
    @IBOutlet private weak var receiptLabel: UILabel!
    @IBOutlet private weak var valueLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgView.layer.cornerRadius = 5.0
        imgView.layer.borderWidth = 0.0
        imgView.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fill(_ tx: APITransaction, wallet: String) {
        var suffix: String = "+"
        if tx.from.lowercased() == wallet.lowercased() {
            imgView.image = UIImage(named: "TransferOut")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            imgView.tintColor = UIColor.primaryBlue
            suffix = "-"
        } else {
            imgView.image = UIImage(named: "TransferIn")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            imgView.tintColor = UIColor.greenGrass
        }
        receiptLabel.text = tx.receipt
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = .floor
        let formattedValue = formatter.string(from: tx.value)!
        valueLabel.text = "\(suffix)\(formattedValue)"
        if let insertedAt = tx.insertedAt {
            let timeZone = NSTimeZone.local
            let fomatterDate = DateFormatter()
            fomatterDate.timeZone = timeZone
            fomatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateLabel.text = fomatterDate.string(from: insertedAt)
        }
    }
}
