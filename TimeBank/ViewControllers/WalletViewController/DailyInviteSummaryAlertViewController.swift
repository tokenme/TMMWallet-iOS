//
//  DailyInviteSummaryAlertViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/18.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit

class DailyInviteSummaryAlertViewController: UIViewController {
    
    public weak var delegate: DailyInviteSummaryAlertDelegate?
    public var summary: APIDailyInviteSummary?
    
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var cashLabel: UILabel!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let summary = self.summary else { return }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = .floor
        let pointsStr = "\(formatter.string(from: summary.contribute)!)"
        let cashStr = "\(formatter.string(from: summary.cny)!)"
        
        let pointAttributes = [NSAttributedString.Key.font:MainFont.condensedBold.with(size: 21), NSAttributedString.Key.foregroundColor:UIColor.red, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.red ] as [NSAttributedString.Key : Any]
        let pointAfterFixAttributes = [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor:UIColor.red]
        
        let pointAttrString = NSMutableAttributedString(string: "\(pointsStr) 积分")
        pointAttrString.addAttributes(pointAttributes, range:NSRange.init(location: 0, length: pointsStr.count))
        pointAttrString.addAttributes(pointAfterFixAttributes, range: NSRange.init(location: pointsStr.count+1, length: 2))
        pointsLabel.attributedText = pointAttrString
        
        let cashAttributes = [NSAttributedString.Key.font:MainFont.condensedBold.with(size: 21), NSAttributedString.Key.foregroundColor:UIColor.red, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue, NSAttributedString.Key.underlineColor: UIColor.red ] as [NSAttributedString.Key : Any]
        let cashPrefixAttributes = [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor:UIColor.init(rgbHex: 0xB55836)]
        let cashAfterfixAttributes = [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 17), NSAttributedString.Key.foregroundColor:UIColor.red]
        
        let cashAttrString = NSMutableAttributedString(string: "价值约 \(cashStr) 元")
        cashAttrString.addAttributes(cashPrefixAttributes, range:NSRange.init(location: 0, length: 3))
        cashAttrString.addAttributes(cashAttributes, range: NSRange.init(location: 4, length: cashStr.count))
        cashAttrString.addAttributes(cashAfterfixAttributes, range: NSRange.init(location: 4 + cashStr.count + 1, length: 1))
        cashLabel.attributedText = cashAttrString
    }
    
    @IBAction func gotoInviteSummaryPage() {
        self.dismiss(animated: true, completion: {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.delegate?.gotoInviteSummaryPage()
        })
    }
}

public protocol DailyInviteSummaryAlertDelegate: NSObjectProtocol {
    func gotoInviteSummaryPage()
}
