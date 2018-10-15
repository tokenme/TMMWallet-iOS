//
//  WechatQRCodeViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/4.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import swiftScan

fileprivate let DefaultQrcodeWidth = 200.0

class WechatQRCodeViewController: UIViewController {
    
    public var wechatGroup: String?
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var qrcodeView: UIImageView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = I18n.wechatGroup.description
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString: wechatGroup ?? "", size:
            CGSize(width: DefaultQrcodeWidth, height: DefaultQrcodeWidth), qrColor: UIColor.black, bkColor: UIColor.white)
        
        qrcodeView.image = qrImg
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> WechatQRCodeViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WechatQRCodeViewController") as! WechatQRCodeViewController
    }
    
}
