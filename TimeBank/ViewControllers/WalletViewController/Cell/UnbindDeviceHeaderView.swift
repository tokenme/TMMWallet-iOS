//
//  UnbindDeviceHeaderView.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/20.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import Reusable
import Moya
import Hydra
import Presentr
import TMMSDK

class UnbindDeviceHeaderView: UIView, NibOwnerLoadable {

    static let height: CGFloat = 44
    
    weak public var delegate: ViewUpdateDelegate?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var bindButton: TransitionButton!
    
    private var bindingDevice = false
    
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadNibContent()
        titleLabel.text = I18n.unbindDeviceExplain.description
        bindButton.setTitle(I18n.bind.description, for: .normal)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction private func bind() {
        if self.bindingDevice { return }
        self.bindingDevice = true
        bindButton.startAnimation()
        TMMDeviceService.bindUser(
            idfa: TMMBeacon.shareInstance().deviceId(),
            provider: self.deviceServiceProvider)
            .then(in: .main, {[weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.shouldRefresh()
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.bindingDevice = false
                weakSelf.bindButton.stopAnimation(animationStyle: .normal, completion: {})
            }
        )
    }
}
