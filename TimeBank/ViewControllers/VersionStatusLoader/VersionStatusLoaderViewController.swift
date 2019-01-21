//
//  VersionStatusLoaderViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2019/1/2.
//  Copyright © 2019 Tokenmama.io. All rights reserved.
//

import UIKit
import Moya

class VersionStatusLoaderViewController: UIViewController {
    
    public weak var delegate: VersionStatusLoaderViewControllerDelegate?
    
    private var appServiceProvider = MoyaProvider<TMMAppService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if CheckVersionStatus() == .unknown {
            getVersionStatus()
        } else {
            self.dismiss(animated: false, completion: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.success()
            })
        }
    }

    private func getVersionStatus() {
        TMMAppService.getSubmitBuild(provider: appServiceProvider).then(in: .main, {[weak self] app in
            if let build = app.submitBuild {
                ValidatingBuild = build
                guard let weakSelf = self else { return }
                weakSelf.dismiss(animated: false, completion: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.delegate?.success()
                })
            }
        }).catch(in: .background, {[weak self] error in
            print(error)
            guard let weakSelf = self else { return }
            weakSelf.getVersionStatus()
        })
    }
    
}

public protocol VersionStatusLoaderViewControllerDelegate: NSObjectProtocol {
    func success()
}
