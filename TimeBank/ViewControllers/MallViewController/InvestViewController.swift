//
//  InvestViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/9.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Moya
import Hydra
import TMMSDK
import Presentr

class InvestViewController: UIViewController {
    
    public weak var delegate: ViewUpdateDelegate?
    
    @IBOutlet private weak var invest100Btn: UIButton!
    @IBOutlet private weak var invest200Btn: UIButton!
    @IBOutlet private weak var invest500Btn: UIButton!
    @IBOutlet private weak var investField: UITextField!
    @IBOutlet private weak var investBtn: TransitionButton!
    
    private var invest: NSDecimalNumber = 0
    private var goodId: UInt64?
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var investing: Bool = false
    
    private var goodServiceProvider = MoyaProvider<TMMGoodService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    convenience init(goodId: UInt64) {
        self.init()
        self.goodId = goodId
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInvestButton(invest100Btn)
        setupInvestButton(invest200Btn)
        setupInvestButton(invest500Btn)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupInvestButton(_ btn: UIButton) {
        btn.layer.cornerRadius = 10
        btn.layer.borderColor = UIColor(white: 0.94, alpha: 1).cgColor
        btn.layer.borderWidth = 1.0
        btn.clipsToBounds = true
        btn.setTitleColor(UIColor.darkGray, for: .normal)
        btn.setTitleColor(UIColor.white, for: .highlighted)
        btn.setTitleColor(UIColor.white, for: .selected)
        btn.setBackgroundImage(UIImage(color: .clear), for: .normal)
        btn.setBackgroundImage(UIImage(color: .pinky), for: .highlighted)
        btn.setBackgroundImage(UIImage(color: .pinky), for: .selected)
    }
    
    @IBAction func selectInvest(sender: UIButton) {
        clearInvestSelect()
        invest = NSDecimalNumber(integerLiteral: sender.tag)
        sender.isSelected = true
        investField.text = invest.stringValue
        investField.resignFirstResponder()
    }
    
    private func clearInvestSelect() {
        invest100Btn.isSelected = false
        invest200Btn.isSelected = false
        invest500Btn.isSelected = false
        invest = 0
    }
}

extension InvestViewController: UITextFieldDelegate {
    public func textFieldDidEndEditing(_ textField: UITextField) {
        let points = NSDecimalNumber.init(string: textField.text)
        if points.isNaN() {
            textField.resignFirstResponder()
            return
        }
        clearInvestSelect()
        invest = points
        textField.resignFirstResponder()
    }
}

extension InvestViewController {
    @IBAction private func investItem() {
        investField.resignFirstResponder()
        if self.investing { return }
        self.investing = true
        guard let itemId = self.goodId else { return }
        guard let idfa = TMMBeacon.shareInstance()?.deviceId() else { return }
        if invest <= 0 { return }
        investBtn.startAnimation()
        TMMGoodService.investItem(
            goodId: itemId,
            idfa: idfa,
            points: invest,
            provider: self.goodServiceProvider)
            .then(in: .main, {[weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.investBtn.stopAnimation(animationStyle: .normal, completion: nil)
                weakSelf.delegate?.shouldRefresh()
                weakSelf.dismiss(animated: true, completion: nil)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                weakSelf.investBtn.stopAnimation(animationStyle: .shake, completion: nil)
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.investing = false
            }
        )
    }
}
