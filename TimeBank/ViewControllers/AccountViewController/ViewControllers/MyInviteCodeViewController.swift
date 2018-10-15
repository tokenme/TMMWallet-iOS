//
//  MyInviteCodeViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/19.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import swiftScan

fileprivate let DefaultQrcodeWidth = 200.0

class MyInviteCodeViewController: UIViewController {
    
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
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var codeLabel: UILabel!
    @IBOutlet private weak var qrcodeView: UIImageView!
    @IBOutlet private weak var copyButton: UIButton!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = I18n.myInviteCode.description
        copyButton.setTitle(I18n.copyInviteCode.description, for: .normal)
        guard let userInfo = self.userInfo else { return }
        codeLabel.text = userInfo.inviteCode
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString: userInfo.inviteCode ?? "", size:
            CGSize(width: DefaultQrcodeWidth, height: DefaultQrcodeWidth), qrColor: UIColor.black, bkColor: UIColor.white)
        
        qrcodeView.image = qrImg
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> MyInviteCodeViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MyInviteCodeViewController") as! MyInviteCodeViewController
    }
    
    @IBAction func copyCode() {
        guard let userInfo = self.userInfo else { return }
        let paste = UIPasteboard.general
        paste.string = userInfo.inviteCode
    }

}
