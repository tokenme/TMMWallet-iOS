//
//  ScanViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import swiftScan
import Moya
import SwiftyUserDefaults

class ScanViewController: LBXScanViewController {
    weak public var scanDelegate: ScanViewDelegate?
    
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
    
    private var isParsingCode: Bool = false
    
    private var bundle: Bundle? {
        get {
            if let bundlePath = Bundle.init(for: LBXScanViewController.self).path(forResource: "CodeScan", ofType: "bundle") {
                return Bundle.init(path: bundlePath)
            }
            return nil
        }
    }
    /**
     @brief  扫码区域上方提示文字
     */
    var topTitle:UILabel?
    
    /**
     @brief  闪关灯开启状态
     */
    var isOpenedFlash:Bool = false
    
    // MARK: - 底部几个功能：开启闪光灯、相册、我的二维码
    
    //底部显示的功能项
    var bottomItemsView:UIView?
    
    //相册
    var btnPhoto:UIButton = UIButton()
    
    //闪光灯
    var btnFlash:UIButton = UIButton()
    
    var btnClose:UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //需要识别后的图像
        setNeedCodeImage(needCodeImg: true)
        
        //框向上移动10个像素
        scanStyle?.centerUpOffset += 10
        scanStyle?.anmiationStyle = LBXScanViewAnimationStyle.NetGrid
        scanStyle?.animationImage = UIImage(named: "qrcode_scan_part_net", in: self.bundle, compatibleWith: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.scan)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawBottomItems()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.scan)
    }
    
    override func handleCodeResult(arrayResult: [LBXScanResult]) {
        
        for result:LBXScanResult in arrayResult
        {
            if let str = result.strScanned {
                print(str)
            }
        }
        
        let result:LBXScanResult = arrayResult[0]
        self.parseCode(result.strScanned ?? "")
    }
    
    func drawBottomItems()
    {
        if (bottomItemsView != nil) {
            
            return;
        }
        
        let yMax = self.view.frame.maxY - self.view.frame.minY
        
        bottomItemsView = UIView(frame:CGRect(x: 0.0, y: yMax-100,width: self.view.frame.size.width, height: 100 ) )
        
        
        bottomItemsView!.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.6)
        
        self.view.addSubview(bottomItemsView!)
        
        
        let size = CGSize(width: 65, height: 87);
        
        self.btnClose = UIButton()
        btnClose.bounds = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        btnClose.center = CGPoint(x: bottomItemsView!.frame.width / 2, y: bottomItemsView!.frame.height/2)
        let closeImg = UIImage(named: "Cancel")?.withRenderingMode(.alwaysTemplate)
        btnClose.contentMode = .scaleAspectFill
        btnClose.clipsToBounds = true
        btnClose.setImage(closeImg, for: UIControl.State.normal)
        btnClose.tintColor = UIColor.white
        btnClose.addTarget(self, action: #selector(ScanViewController.close), for: UIControl.Event.touchUpInside)
        
        self.btnFlash = UIButton()
        btnFlash.bounds = btnClose.bounds
        btnFlash.center = CGPoint(x: bottomItemsView!.frame.width / 4, y: bottomItemsView!.frame.height/2)
        btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_nor", in: self.bundle, compatibleWith: nil), for:UIControl.State.normal)
        btnFlash.addTarget(self, action: #selector(ScanViewController.openOrCloseFlash), for: UIControl.Event.touchUpInside)
        
        
        self.btnPhoto = UIButton()
        btnPhoto.bounds = btnClose.bounds
        btnPhoto.center = CGPoint(x: bottomItemsView!.frame.width * 3/4, y: bottomItemsView!.frame.height/2)
        btnPhoto.setImage(UIImage(named: "qrcode_scan_btn_photo_nor", in: self.bundle, compatibleWith: nil), for: UIControl.State.normal)
        btnPhoto.setImage(UIImage(named: "qrcode_scan_btn_photo_down", in: self.bundle, compatibleWith: nil), for: UIControl.State.highlighted)
        btnPhoto.addTarget(self, action: #selector(ScanViewController.showPhotoAlbum), for: UIControl.Event.touchUpInside)
        
        bottomItemsView?.addSubview(btnFlash)
        bottomItemsView?.addSubview(btnPhoto)
        bottomItemsView?.addSubview(btnClose)
        
        self.view .addSubview(bottomItemsView!)
        
    }
    
    
    //开关闪光灯
    @objc func openOrCloseFlash()
    {
        scanObj?.changeTorch();
        
        isOpenedFlash = !isOpenedFlash
        
        if isOpenedFlash
        {
            btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_down", in: self.bundle, compatibleWith: nil), for:UIControl.State.normal)
        }
        else
        {
            btnFlash.setImage(UIImage(named: "qrcode_scan_btn_flash_nor", in: self.bundle, compatibleWith: nil), for:UIControl.State.normal)
        }
    }
    
    @objc func showPhotoAlbum() {
        self.openPhotoAlbum()
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ScanViewController {
    private func parseCode(_ result: String) {
        guard let delegate = self.scanDelegate else { return }
        self.dismiss(animated: true, completion: {
            delegate.collectHandler(result)
        })
    }
}

protocol ScanViewDelegate: NSObjectProtocol {
    func collectHandler(_ qrcode: String)
}
