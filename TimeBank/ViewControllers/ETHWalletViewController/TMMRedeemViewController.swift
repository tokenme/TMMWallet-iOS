//
//  TMMRedeemViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/12.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import TMMSDK
import Presentr

class TMMRedeemViewController: UIViewController {
    weak public var delegate: RedeemDelegate?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var exchangeRateLabel: UILabel!
    @IBOutlet private weak var amountTextField: TweeAttributedTextField!
    @IBOutlet private weak var changeButton: TransitionButton!
    
    private var isChanging = false
    private var changeRate: APIExchangeRate?
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private let currency = Defaults[.currency] ?? Currency.USD.rawValue
    
    private var redeemServiceProvider = MoyaProvider<TMMRedeemService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    convenience init(changeRate: APIExchangeRate) {
        self.init()
        self.changeRate = changeRate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let rate = changeRate?.rate else { return }
        titleLabel.text = "UC \(I18n.withdraw.description)"
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let rateStr = formatter.string(from: rate)!
        exchangeRateLabel.text = String(format: I18n.currentTMMRedeemRate.description, rateStr, currency)
        amountTextField.tweePlaceholder = I18n.TMMAmount.description
        changeButton.setTitle(I18n.withdraw.description, for: .normal)
        amountTextField.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


extension TMMRedeemViewController {
    @IBAction func changeTMM() {
        if self.isChanging {
            return
        }
        if !self.verifyPoints() { return }
        let changePoints = NSDecimalNumber.init(string: amountTextField.text)
        if changePoints.isNaN() { return }
        
        self.isChanging = true
        changeButton.startAnimation()
        TMMRedeemService.withdrawTMM(
            tmm: changePoints,
            currency: currency,
            provider: self.redeemServiceProvider)
            .then(in: .main, {[weak self] resp in
                guard let weakSelf = self else { return }
                weakSelf.dismiss(animated: true, completion: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.delegate?.redeemSuccess(resp: resp)
                })
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isChanging = false
                weakSelf.changeButton.stopAnimation(animationStyle: .normal, completion: nil)
                }
        )
    }
}

extension TMMRedeemViewController {
    private func verifyPoints() -> Bool {
        let changePoints = NSDecimalNumber.init(string: amountTextField.text)
        if changePoints <= 0 {
            self.amountTextField.showInfo(I18n.emptyWithdrawTMM.description)
            return false
        }
        guard let minPoints = self.changeRate?.minPoints else { return false }
        if changePoints < minPoints {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            let minPointsStr = formatter.string(from: minPoints)!
            let message = String(format: I18n.invalidMinTMMError.description, minPointsStr)
            self.amountTextField.showInfo(message)
            return false
        }
        return true
    }
}

extension TMMRedeemViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.amountTextField.hideInfo()
    }
    
    @IBAction func textFieldDidChange(_ textField:UITextField) {
        guard let rate = changeRate?.rate else { return }
        let changePoints = NSDecimalNumber.init(string: textField.text)
        if changePoints.isNaN() { return }
        let cashAmount = changePoints * rate
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let cashAmountStr = formatter.string(from: cashAmount)
        let msg = String(format: I18n.TMMWithdrawAmount.description, cashAmountStr ?? "-", currency)
        self.amountTextField.showInfo(msg)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let rate = changeRate?.rate else { return }
        let changePoints = NSDecimalNumber.init(string: amountTextField.text)
        if changePoints.isNaN() { return }
        let cashAmount = changePoints.multiplying(by: rate)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let cashAmountStr = formatter.string(from: cashAmount)!
        let msg = String(format: I18n.TMMWithdrawAmount.description, cashAmountStr, currency)
        self.amountTextField.showInfo(msg)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = self.verifyPoints()
        return true
    }
}


public protocol RedeemDelegate: NSObjectProtocol {
    func redeemSuccess(resp: APITMMWithdraw)
}
