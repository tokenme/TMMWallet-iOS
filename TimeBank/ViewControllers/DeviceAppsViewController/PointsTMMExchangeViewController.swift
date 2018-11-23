//
//  PointsTMMExchangeViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/10.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Moya
import Hydra
import TMMSDK
import Haptica
import Presentr

class PointsTMMExchangeViewController: UIViewController {
    
    weak public var delegate: TransactionDelegate?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var exchangeRateLabel: UILabel!
    @IBOutlet private weak var amountTextField: TweeAttributedTextField!
    @IBOutlet private weak var changeButton: TransitionButton!
    
    private var isChanging = false
    private var changeRate: APIExchangeRate?
    private var device: APIDevice?
    private var tmmBalance: NSDecimalNumber?
    private var direction: APIExchangeDirection?
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var exchangeServiceProvider = MoyaProvider<TMMExchangeService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure()), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    convenience init(changeRate: APIExchangeRate, device: APIDevice, tmmBalance: NSDecimalNumber, direction: APIExchangeDirection) {
        self.init()
        self.changeRate = changeRate
        self.device = device
        self.direction = direction
        self.tmmBalance = tmmBalance
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let rate = changeRate?.rate else { return }
        guard let direction = self.direction else { return }
        if direction == .TMMIn {
            titleLabel.text = "\(I18n.points.description) \(I18n.changeTo.description) UC"
        } else {
            titleLabel.text = "UC \(I18n.changeTo.description) \(I18n.points.description)"
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let rateStr = formatter.string(from: rate)!
        exchangeRateLabel.text = String(format: I18n.currentPointsTMMExchangeRate.description, rateStr)
        amountTextField.tweePlaceholder = I18n.pointsAmount.description
        changeButton.setTitle(I18n.exchange.description, for: .normal)
        amountTextField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension PointsTMMExchangeViewController {
    
    private func verifyPoints() -> Bool {
        guard let rate = changeRate?.rate else { return false }
        guard let direction = self.direction else { return false }
        guard let points = self.device?.points else { return false }
        let changePoints = NSDecimalNumber.init(string: amountTextField.text)
        if changePoints <= 0 {
            self.amountTextField.showInfo(I18n.emptyChangePoints.description)
            return false
        }
        let tmmAmount = changePoints.multiplying(by: rate)
        if direction == .TMMIn && changePoints > points {
            self.amountTextField.showInfo(I18n.exceedChangePoints.description)
            return false
        } else if direction == .TMMOut && tmmAmount > tmmBalance ?? 0 {
            return false
        }
        guard let minPoints = self.changeRate?.minPoints else { return false }
        if changePoints < minPoints {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            let minPointsStr = formatter.string(from: minPoints)!
            let message = String(format: I18n.invalidMinPointsError.description, minPointsStr)
            self.amountTextField.showInfo(message)
            return false
        }
        return true
    }
}

extension PointsTMMExchangeViewController {
    @IBAction func changeTMM() {
        if self.isChanging {
            return
        }
        guard let deviceId = device?.id else { return }
        guard let direction = self.direction else { return }
        if !self.verifyPoints() {
            let _ = Haptic.notification(.error)
            return
        }
        let changePoints = NSDecimalNumber.init(string: amountTextField.text)
        if changePoints.isNaN() { return }
        
        self.isChanging = true
        changeButton.startAnimation()
        TMMExchangeService.changeTMM(
            deviceId: deviceId,
            points: changePoints,
            direction: direction,
            provider: self.exchangeServiceProvider)
            .then(in: .main, {[weak self] tx in
                guard let weakSelf = self else { return }
                weakSelf.dismiss(animated: true, completion: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.delegate?.newTransaction(tx: tx)
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

extension PointsTMMExchangeViewController: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.amountTextField.hideInfo()
    }
    
    @IBAction func textFieldDidChange(_ textField:UITextField) {
        guard let rate = changeRate?.rate else { return }
        let changePoints = NSDecimalNumber.init(string: textField.text)
        if changePoints.isNaN() { return }
        let tmmAmount = changePoints * rate
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let tmmAmountStr = formatter.string(from: tmmAmount)
        let msg = String(format: I18n.pointsTMMChangeAmount.description, tmmAmountStr ?? "-")
        self.amountTextField.showInfo(msg)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        guard let rate = changeRate?.rate else { return }
        let changePoints = NSDecimalNumber.init(string: amountTextField.text)
        if changePoints.isNaN() { return }
        let tmmAmount = changePoints.multiplying(by: rate)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let tmmAmountStr = formatter.string(from: tmmAmount)!
        let msg = String(format: I18n.pointsTMMChangeAmount.description, tmmAmountStr)
        self.amountTextField.showInfo(msg)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        _ = self.verifyPoints()
        return true
    }
}

public protocol TransactionDelegate: NSObjectProtocol {
    func newTransaction(tx: APITransaction)
}
