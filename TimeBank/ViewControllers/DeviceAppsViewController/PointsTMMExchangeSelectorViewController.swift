//
//  PointsTMMExchangeSelectorViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Moya
import Hydra
import Presentr

class PointsTMMExchangeSelectorViewController: UIViewController {
    
    weak public var delegate: PointsTMMExchangeSelectorDelegate?
    
    @IBOutlet private weak var exchangeTMMButton: TransitionButton!
    @IBOutlet private weak var exchangePointButton: TransitionButton!
    
    let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var gettingTmmExchangeRate = false
    
    private var exchangeServiceProvider = MoyaProvider<TMMExchangeService>(plugins: [networkActivityPlugin, SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        exchangeTMMButton.setTitle(I18n.exchangeTMM.description, for: .normal)
        exchangePointButton.setTitle(I18n.exchangePoint.description, for: .normal)
    }

    @IBAction func showExchangeTMM() {
        exchangeTMMButton.startAnimation()
        getTmmExchangeRate(direction: .TMMIn)
    }
    
    @IBAction func showExchangePoint() {
        exchangePointButton.startAnimation()
        getTmmExchangeRate(direction: .TMMOut)
    }
    
    
    private func getTmmExchangeRate(direction: APIExchangeDirection) {
        if self.gettingTmmExchangeRate {
            return
        }
        self.gettingTmmExchangeRate = true
        TMMExchangeService.getTMMRate(
            provider: self.exchangeServiceProvider)
            .then(in: .main, {[weak self] rate in
                guard let weakSelf = self else { return }
                weakSelf.dismiss(animated: true, completion: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.delegate?.exchangeDirectionSelected(rate: rate, direction: direction)
                })
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingTmmExchangeRate = false
                if direction == .TMMIn {
                    weakSelf.exchangeTMMButton.stopAnimation(animationStyle: .normal, completion: nil)
                } else {
                    weakSelf.exchangePointButton.stopAnimation(animationStyle: .normal, completion: nil)
                }
            }
        )
    }
}


public protocol PointsTMMExchangeSelectorDelegate: NSObjectProtocol {
    func exchangeDirectionSelected(rate: APIExchangeRate, direction: APIExchangeDirection)
}
