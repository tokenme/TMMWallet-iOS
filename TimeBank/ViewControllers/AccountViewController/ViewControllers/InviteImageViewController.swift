//
//  InviteImageViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/6.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import swiftScan

class InviteImageViewController: UIViewController {
    
    private var userInfo: APIUser? {
        get {
            if let userInfo: DefaultsUser = Defaults[.user] {
                if CheckValidAccessToken() {
                    return APIUser.init(user: userInfo)
                }
                return nil
            }
            return nil
        }
    }
    
    @IBOutlet private weak var qrcodeView: UIImageView!
    @IBOutlet public weak var containerView: UIView!
    @IBOutlet private weak var logoView: UIImageView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logoView.layer.cornerRadius = 22
        logoView.layer.borderWidth = 0
        logoView.clipsToBounds = true
        
        guard let inviteCode = userInfo?.inviteCode else { return }
        let qrcodeLink = String(format: "https://tmm.tokenmama.io/invite/%@", inviteCode)
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString: qrcodeLink, size:
            CGSize(width: qrcodeView.bounds.width, height: qrcodeView.bounds.height), qrColor: UIColor.black, bkColor: UIColor.white)
        qrcodeView.image = qrImg
    }

}
