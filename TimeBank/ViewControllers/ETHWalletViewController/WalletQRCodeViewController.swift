//
//  WalletQRCodeViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/12.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import swiftScan

fileprivate let DefaultQrcodeWidth = 200.0

class WalletQRCodeViewController: UIViewController {
    
    @IBOutlet private weak var qrcodeView: UIImageView!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet private weak var receiveLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    
    public var address: String?
    public var token: APIToken?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addressLabel.text = address
        if let symbol = self.token?.symbol {
            receiveLabel.text = "\(symbol) \(I18n.receiveQRCode.description)"
        } else {
            receiveLabel.text = I18n.receiveQRCode.description
        }
        copyButton.setTitle(I18n.copyWalletAddress.description, for: .normal)
        guard let address = self.address else { return }
        var codeString = address
        if let token = self.token {
            if let tokenAddress = token.address {
                codeString = "ethereum:\(address)?contractAddress=\(tokenAddress)&decimal=\(token.decimals)"
            } else {
                codeString = "ethereum:\(address)?decimal=\(token.decimals)"
            }
        }
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString:codeString, size:
            CGSize(width: DefaultQrcodeWidth, height: DefaultQrcodeWidth), qrColor: UIColor.black, bkColor: UIColor.white)
        
        qrcodeView.image = qrImg
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> WalletQRCodeViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WalletQRCodeViewController") as! WalletQRCodeViewController
    }
    
    @IBAction func copyAddress() {
        let paste = UIPasteboard.general
        paste.string = self.address
    }
}
