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
import Haptica

enum RedeemType {
    case tmm
    case point
}

class TMMRedeemViewController: UIViewController {
    weak public var delegate: RedeemDelegate?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var exchangeRateLabel: UILabel!
    @IBOutlet private weak var amountTextField: TweeAttributedTextField!
    @IBOutlet private weak var changeButton: TransitionButton!
    
    private var isChanging = false
    private var changeRate: APIExchangeRate?
    public var deviceId: String = ""
    
    public var redeemType :RedeemType = .tmm
    
    lazy private var shareSheetItems: [SSUIPlatformItem] = {[weak self] in
        var items:[SSUIPlatformItem] = []
        for scheme in TMMConfigs.WeChat.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .subTypeWechatTimeline))
                items.append(SSUIPlatformItem(platformType: .subTypeWechatSession))
                break
            }
        }
        for item in items {
            item.addTarget(self, action: #selector(shareItemClicked))
        }
        return items
        }()
    
    lazy var shareParams: NSMutableDictionary = {
        let image = UIImage(named: "Logo")
        let shareLink = URL(string: TMMConfigs.WeChat.authLink)
        let title = "打开完成微信支付授权"
        let desc = "打开后点击完成微信支付授权"
        let thumbnail = image?.kf.resize(to: CGSize(width: 300, height: 300))
        let params = NSMutableDictionary()
        params.ssdkSetupWeChatParams(byText: desc, title: title, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatSession)
        params.ssdkSetupWeChatParams(byText: desc, title: title, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatTimeline)
        return params
    }()
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private let currency = Defaults[.currency] ?? Currency.USD.rawValue
    
    private var redeemServiceProvider = MoyaProvider<TMMRedeemService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if redeemType == .tmm {
            MTA.trackPageViewBegin(TMMConfigs.PageName.tmmWithdraw)
        } else {
            MTA.trackPageViewBegin(TMMConfigs.PageName.pointWithdraw)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if redeemType == .tmm {
            MTA.trackPageViewEnd(TMMConfigs.PageName.tmmWithdraw)
        } else {
            MTA.trackPageViewEnd(TMMConfigs.PageName.pointWithdraw)
        }
    }
    
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
        if redeemType == .tmm {
            titleLabel.text = "UC \(I18n.withdraw.description)"
        } else {
            titleLabel.text = "积分 \(I18n.withdraw.description)"
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = .floor
        let rateStr = formatter.string(from: rate)!
        if redeemType == .tmm {
            exchangeRateLabel.text = String(format: I18n.currentTMMRedeemRate.description, rateStr, currency)
            amountTextField.tweePlaceholder = I18n.TMMAmount.description
        } else {
            exchangeRateLabel.text = String(format: I18n.currentPointRedeemPrice.description, rateStr, currency)
            amountTextField.tweePlaceholder = I18n.pointsAmount.description
        }
        
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
        
        let cashAmount = changePoints * (changeRate?.rate ?? 0)
        
        if redeemType == .tmm {
            MTA.trackCustomKeyValueEventBegin(TMMConfigs.EventName.tokenWithdraw, props: ["token": changePoints, "cash": cashAmount])
            TMMRedeemService.withdrawTMM(
                tmm: changePoints,
                currency: currency,
                provider: self.redeemServiceProvider)
                .then(in: .main, {[weak self] resp in
                    guard let weakSelf = self else { return }
                    weakSelf.changeButton.stopAnimation(animationStyle: .normal, completion: nil)
                    MTA.trackCustomKeyValueEventEnd(TMMConfigs.EventName.tokenWithdraw, props: ["token": changePoints, "cash": cashAmount])
                    weakSelf.dismiss(animated: true, completion: {[weak weakSelf] in
                        guard let weakSelf2 = weakSelf else { return }
                        weakSelf2.delegate?.redeemSuccess(resp: resp)
                    })
                }).catch(in: .main, {[weak self] error in
                    guard let weakSelf = self else { return }
                    weakSelf.amountTextField.resignFirstResponder()
                    if let err = error as? TMMAPIError {
                        switch err {
                        case .wechatOpenIdError:
                            let _ = Haptic.notification(.warning)
                            weakSelf.changeButton.stopAnimation(animationStyle: .shake, completion: nil)
                            let alertController = AlertViewController(title: I18n.alert.description, body: "请在微信内打开页面完成微信授权，以便打款。")
                            let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
                            let okAction = AlertAction(title: "分享页面至微信", style: .destructive) {[weak self] in
                                guard let weakSelf = self else { return }
                                weakSelf.showShareSheet()
                            }
                            alertController.addAction(cancelAction)
                            alertController.addAction(okAction)
                            weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
                            return
                        default: break
                        }
                    }
                    weakSelf.changeButton.stopAnimation(animationStyle: .shake, completion: nil)
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                }).always(in: .main, body: {[weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.isChanging = false
                }
            )
        } else {
            MTA.trackCustomKeyValueEventBegin(TMMConfigs.EventName.pointWithdraw, props: ["points": changePoints, "cash": cashAmount])
            TMMRedeemService.withdrawPoints(
                deviceId: self.deviceId,
                points: changePoints,
                currency: currency,
                provider: self.redeemServiceProvider)
                .then(in: .main, {[weak self] resp in
                    guard let weakSelf = self else { return }
                    weakSelf.changeButton.stopAnimation(animationStyle: .normal, completion: nil)
                    MTA.trackCustomKeyValueEventEnd(TMMConfigs.EventName.pointWithdraw, props: ["points": changePoints, "cash": cashAmount])
                    weakSelf.dismiss(animated: true, completion: {[weak weakSelf] in
                        guard let weakSelf2 = weakSelf else { return }
                        weakSelf2.delegate?.redeemSuccess(resp: resp)
                    })
                }).catch(in: .main, {[weak self] error in
                    guard let weakSelf = self else { return }
                    weakSelf.amountTextField.resignFirstResponder()
                    if let err = error as? TMMAPIError {
                        switch err {
                        case .wechatOpenIdError:
                            let _ = Haptic.notification(.warning)
                            weakSelf.changeButton.stopAnimation(animationStyle: .shake, completion: nil)
                            let alertController = AlertViewController(title: I18n.alert.description, body: "请在微信内打开页面完成微信授权，以便打款。")
                            let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
                            let okAction = AlertAction(title: "分享页面至微信", style: .destructive) {[weak self] in
                                guard let weakSelf = self else { return }
                                weakSelf.showShareSheet()
                            }
                            alertController.addAction(cancelAction)
                            alertController.addAction(okAction)
                            weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
                            return
                        default: break
                        }
                    }
                    weakSelf.changeButton.stopAnimation(animationStyle: .shake, completion: nil)
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                }).always(in: .main, body: {[weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.isChanging = false
                }
            )
        }
    }
}

extension TMMRedeemViewController {
    private func showShareSheet() {
        ShareSDK.showShareActionSheet(self.view, customItems: shareSheetItems as [Any], shareParams: shareParams, sheetConfiguration: nil){[weak self] (state, platformType, userData, contentEntity, error, end) in
            guard let weakSelf = self else { return }
            switch (state) {
            case SSDKResponseState.success:
                weakSelf.changeTMM()
            //UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: "", closeBtn: I18n.close.description, viewController: weakSelf)
            case SSDKResponseState.fail:
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error?.localizedDescription ?? "", closeBtn: I18n.close.description, viewController: weakSelf)
                break
            default:
                break
            }
        }
    }
    
    @objc func shareItemClicked(_ item: SSUIPlatformItem) {
        var platform: SSDKPlatformType?
        switch item.platformName {
        case SSUIPlatformItem(platformType: .subTypeWechatTimeline)?.platformName:
            platform = .subTypeWechatTimeline
            break
        case SSUIPlatformItem(platformType: .subTypeWechatSession)?.platformName:
            platform = .subTypeWechatSession
            break
        default:
            break
        }
        if let platformType = platform {
            ShareSDK.share(platformType, parameters: shareParams) {[weak self] (state, userData, contentEntity, error) in
                guard let weakSelf = self else { return }
                switch (state) {
                case SSDKResponseState.success:
                    weakSelf.changeTMM()
                //UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: I18n.shareSuccess.description, closeBtn: I18n.close.description, viewController: weakSelf)
                case SSDKResponseState.fail:
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error?.localizedDescription ?? "", closeBtn: I18n.close.description, viewController: weakSelf)
                    break
                default:
                    break
                }
            }
        }
    }
}

extension TMMRedeemViewController {
    private func verifyPoints() -> Bool {
        let changePoints = NSDecimalNumber.init(string: amountTextField.text)
        if changePoints <= 0 {
            if redeemType == .tmm {
                self.amountTextField.showInfo(I18n.emptyWithdrawTMM.description)
            } else {
                self.amountTextField.showInfo(I18n.emptyWithdrawPoints.description)
            }
            return false
        }
        guard let minPoints = self.changeRate?.minPoints else { return false }
        if changePoints < minPoints {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            formatter.roundingMode = .floor
            let minPointsStr = formatter.string(from: minPoints)!
            if redeemType == .tmm {
                let message = String(format: I18n.invalidMinTMMError.description, minPointsStr)
                self.amountTextField.showInfo(message)
            } else {
                let message = String(format: I18n.invalidMinPointsError.description, minPointsStr)
                self.amountTextField.showInfo(message)
            }
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
        formatter.roundingMode = .floor
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
        formatter.roundingMode = .floor
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
