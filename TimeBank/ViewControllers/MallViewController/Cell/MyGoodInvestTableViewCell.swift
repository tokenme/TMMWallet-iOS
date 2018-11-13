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
import Moya
import Hydra
import Presentr

class MyGoodInvestTableViewCell: UITableViewCell, NibReusable {
    
    public weak var delegate: ViewUpdateDelegate?
    
    private var withdrawing: Bool = false
    private var invest: APIGoodInvest?
    
    private var goodServiceProvider = MoyaProvider<TMMGoodService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    @IBOutlet public weak var imgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var investLabel: UILabel!
    @IBOutlet private weak var incomeLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var redeemButton: TransitionButton!
    @IBOutlet private weak var withdrawButton: TransitionButton!
    @IBOutlet private weak var statusLabel: UILabelPadding!
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
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
        incomeLabel.attributedText = numberLabelAttribute("投资收益: ", invest.income, 2, strikethrough)
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
        if invest.redeemStatus == .redeemed {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已提现", closeBtn: I18n.close.description)
            return
        } else if invest.redeemStatus == .withdraw {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已撤回", closeBtn: I18n.close.description)
            return
        } else if invest.income <= 0 {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资还没有收益", closeBtn: I18n.close.description)
            return
        }
    }
    
    @IBAction func withdraw() {
        guard let invest = self.invest else { return }
        if invest.redeemStatus == .redeemed {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已提现", closeBtn: I18n.close.description)
            return
        } else if invest.redeemStatus == .withdraw {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已撤回", closeBtn: I18n.close.description)
            return
        }
        if let vc = UIViewController.currentViewController() {
            let alertController = Presentr.alertViewController(title: I18n.alert.description, body: "撤回投资后该投资收益将被清空，确定撤回投资？")
            let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
                //
            }
            let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak self] alert in
                guard let weakSelf = self else { return }
                weakSelf.doWithdraw(goodId: invest.goodId!)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            vc.customPresentViewController(self.alertPresenter, viewController: alertController, animated: true)
        }
    }
    
    private func doWithdraw(goodId: UInt64) {
        if self.withdrawing { return }
        self.withdrawing = true
        withdrawButton.startAnimation()
        TMMGoodService.withdrawInvest(
            id: goodId,
            provider: self.goodServiceProvider)
            .then(in: .main, {[weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.withdrawButton.stopAnimation(animationStyle: .normal, completion: nil)
                weakSelf.delegate?.shouldRefresh()
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                weakSelf.withdrawButton.stopAnimation(animationStyle: .shake, completion: nil)
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.withdrawing = false
            }
        )
    }
}
