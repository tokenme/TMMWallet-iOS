//
//  ReceiveQRCodeViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/13.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit

import UIKit
import swiftScan

fileprivate let DefaultQrcodeWidth = 200.0

class ReceiveQRCodeViewController: UIViewController {
    
    @IBOutlet private weak var qrcodeView: UIImageView!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var receiveLabel: UILabel!
    
    public var address: String?
    public var token: APIToken?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addressLabel.text = address
        receiveLabel.text = "\(I18n.receive.description) \(token?.symbol ?? "")"
        copyButton.setTitle(I18n.copyWalletAddress.description, for: .normal)
        guard let address = self.address else { return }
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString:address, size:
            CGSize(width: DefaultQrcodeWidth, height: DefaultQrcodeWidth), qrColor: UIColor.black, bkColor: UIColor.white)
        
        qrcodeView.image = qrImg
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> ReceiveQRCodeViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ReceiveQRCodeViewController") as! ReceiveQRCodeViewController
    }
    
    @IBAction func copyAddress() {
        let paste = UIPasteboard.general
        paste.string = self.address
    }
}
