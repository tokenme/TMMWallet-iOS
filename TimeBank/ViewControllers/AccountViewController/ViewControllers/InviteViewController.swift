//
//  InviteViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/6.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Presentr
import SnapKit
import swiftScan
import Kingfisher
import SwiftyUserDefaults
import Moya
import Hydra

class InviteViewController: UIViewController {
    
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
    
    public var inviteSummary: APIInviteSummary?
    
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var subTitle: UILabel!
    @IBOutlet private weak var avatarView: UIImageView!
    @IBOutlet private weak var inviteCodeLabel: UILabel!
    @IBOutlet private weak var copyButton: UIButton!
    @IBOutlet private weak var inviteCodeSubTitle: UILabel!
    @IBOutlet private weak var qrcodeView: UIImageView!
    @IBOutlet private weak var inviteButton: UIButton!
    
    let invitePresenter: Presentr = {
        let customPresenter = Presentr(presentationType: .topHalf)
        customPresenter.transitionType = .coverVertical
        customPresenter.dismissTransitionType = .crossDissolve
        customPresenter.roundCorners = false
        //customPresenter.blurBackground = true
        customPresenter.blurStyle = UIBlurEffect.Style.light
        //customPresenter.keyboardTranslationType = .moveUp
        //customPresenter.backgroundColor = .green
        customPresenter.backgroundOpacity = 0.5
        customPresenter.dismissOnSwipe = true
        customPresenter.dismissOnSwipeDirection = .top
        return customPresenter
    }()
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private let inviteImagePresentr = InviteImagePresentrViewController()
    
    lazy private var shareImage: UIImage? = {[weak self] in
        let bgImage = UIImage(named: "InviteImage")!
        let logoImage = UIImage(named: "Logo")!.kf.image(withRoundRadius: 22.0, fit: CGSize(width: 44.0, height: 44.0), roundingCorners: .all, backgroundColor: UIColor.clear)
        
        let qrcodeWidth = bgImage.size.width * 0.25
        let qrcodeCenterX = (bgImage.size.width - qrcodeWidth) / 2 + 8
        let qrcodeCenterY = bgImage.size.height - qrcodeWidth - 28
        let qrcodeLink = String(format: "https://tmm.tokenmama.io/invite/%@", self?.userInfo?.inviteCode ?? "emptycode")
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString: qrcodeLink, size:
            CGSize(width: qrcodeWidth, height: qrcodeWidth), qrColor: UIColor.black, bkColor: UIColor.white)!
        UIGraphicsBeginImageContext(bgImage.size)
        bgImage.draw(in: CGRect(origin: CGPoint.zero, size: bgImage.size))
        logoImage.draw(in: CGRect(origin: CGPoint(x: 36.0, y: 36.0), size: logoImage.size))
        qrImg.draw(in: CGRect(origin: CGPoint(x: qrcodeCenterX, y: qrcodeCenterY), size: qrImg.size))
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.kf.scaled(to: 5.0)
    }()
    
    private var loadingInviteSummary = false
    
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
            //self.title = I18n.inviteFriends.description
        }
        if inviteSummary == nil {
            getInviteSummary()
        }
        avatarView.layer.cornerRadius = 20
        avatarView.layer.borderWidth = 0.0
        avatarView.clipsToBounds = true
        
        closeButton.layer.cornerRadius = 5
        closeButton.layer.borderWidth = 0
        closeButton.clipsToBounds = true
        
        copyButton.layer.cornerRadius = 10
        copyButton.layer.borderWidth = 1.0
        copyButton.layer.borderColor = UIColor.orange.cgColor
        copyButton.clipsToBounds = true
        
        inviteButton.layer.cornerRadius = 18
        inviteButton.layer.borderWidth = 0
        inviteButton.layer.shadowOffset =  CGSize(width: 0, height: 0)
        inviteButton.layer.shadowOpacity = 0.42
        inviteButton.layer.shadowRadius = 6
        inviteButton.layer.shadowColor = UIColor.white.cgColor
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
        MTA.trackPageViewBegin(TMMConfigs.PageName.invite)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.invite)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> InviteViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "InviteViewController") as! InviteViewController
    }
    
    private func setupView() {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        subTitle.text = String(format: "邀请1位好友奖励%@元现金", formatter.string(from: inviteSummary?.inviterCashBonus ?? 0)!)
        
        if let avatar = URL(string: userInfo?.avatar ?? "") {
            avatarView.kf.setImage(with: avatar)
        }
        
        inviteCodeLabel.text = userInfo?.inviteCode
        inviteCodeSubTitle.text = String(format: "已邀请%d位好友", inviteSummary?.invites ?? 0)
        
        let qrcodeLink = String(format: "https://tmm.tokenmama.io/invite/%@", userInfo?.inviteCode ?? "emptycode")
        let qrImg = LBXScanWrapper.createCode(codeType: "CIQRCodeGenerator",codeString: qrcodeLink, size:
            CGSize(width: 200, height: 200), qrColor: UIColor.black, bkColor: UIColor.white)!
        qrcodeView.image = qrImg
    }
    
    @IBAction func copyCode() {
        guard let userInfo = self.userInfo else { return }
        let paste = UIPasteboard.general
        paste.string = userInfo.inviteCode
    }
    
    @IBAction func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func showShareImage() {
        guard let img = shareImage else { return }
        self.inviteImagePresentr.setImage(img: img)
        customPresentViewController(invitePresenter, viewController: inviteImagePresentr, animated: true, completion: {[weak self] in
            self?.showShareSheet()
        })
    }
    
    lazy private var shareSheetItems: [SSUIPlatformItem] = {[weak self] in
        var items:[SSUIPlatformItem] = []
        for scheme in TMMConfigs.WeChat.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .subTypeWechatTimeline))
                items.append(SSUIPlatformItem(platformType: .subTypeWechatSession))
                break
            }
        }
        
        for scheme in TMMConfigs.QQ.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .subTypeQQFriend))
                items.append(SSUIPlatformItem(platformType: .subTypeQZone))
                break
            }
        }
        
        for scheme in TMMConfigs.Weibo.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .typeSinaWeibo))
                break
            }
        }
        
        for scheme in TMMConfigs.Line.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .typeLine))
                break
            }
        }
        
        for scheme in TMMConfigs.Facebook.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .typeFacebook))
                break
            }
        }
        
        for scheme in TMMConfigs.Twitter.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .typeTwitter))
                break
            }
        }
        for scheme in TMMConfigs.Telegram.schemes {
            guard let url = URL(string: "\(scheme)://") else { continue}
            if UIApplication.shared.canOpenURL(url) {
                items.append(SSUIPlatformItem(platformType: .typeTelegram))
                break
            }
        }
        for item in items {
            item.addTarget(self, action: #selector(shareItemClicked))
        }
        return items
    }()
    
    lazy var shareParams: NSMutableDictionary = {
        let params = NSMutableDictionary()
        guard let img = self.shareImage?.kf.resize(to: CGSize(width: 500, height: 500), for: .aspectFit) else { return params }
        params.ssdkSetupShareParams(byText: nil, images: img, url: nil, title: nil, type: .image)
        params.ssdkSetupWeChatParams(byText: nil, title: nil, url: nil, thumbImage: img, image: img, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .image, forPlatformSubType: .subTypeWechatSession)
        params.ssdkSetupWeChatParams(byText: nil, title: nil, url: nil, thumbImage: img, image: img, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .image, forPlatformSubType: .subTypeWechatTimeline)
        params.ssdkSetupSinaWeiboShareParams(byText: nil, title: nil, images: img, video: nil, url: nil, latitude: 0, longitude: 0, objectID: nil, isShareToStory: true, type: .image)
        params.ssdkSetupFacebookParams(byText: nil, image: img, url: nil, urlTitle: nil, urlName: TMMConfigs.Facebook.displayName, attachementUrl: nil, hashtag: "UCoin", quote: nil, type: .image)
        params.ssdkSetupTwitterParams(byText: nil, images: img, video: nil, latitude: 0, longitude: 0, type: .image)
        params.ssdkSetupQQParams(byText: nil, title: nil, url: nil, audioFlash: nil, videoFlash: nil, thumbImage: img, images: img, type: .image, forPlatformSubType: .subTypeQZone)
        params.ssdkSetupQQParams(byText: nil, title: nil, url: nil, audioFlash: nil, videoFlash: nil, thumbImage: img, images: img, type: .image, forPlatformSubType: .subTypeQQFriend)
        params.ssdkSetupTelegramParams(byText: nil, image: img, audio: nil, video: nil, file: nil, menuDisplay: CGPoint.zero, type: .image)
        return params
    }()
}

extension InviteViewController {
    @objc func showShareSheet() {
        ShareSDK.showShareActionSheet(self.view, customItems: shareSheetItems as [Any], shareParams: shareParams, sheetConfiguration: nil){[weak self] (state, platformType, userData, contentEntity, error, end) in
            guard let weakSelf = self else { return }
            switch (state) {
            case SSDKResponseState.success:
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: "", closeBtn: I18n.close.description, viewController: weakSelf)
            case SSDKResponseState.fail:
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error?.localizedDescription ?? "", closeBtn: I18n.close.description, viewController: weakSelf)
                break
            default:
                break
            }
            weakSelf.inviteImagePresentr.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func shareItemClicked(_ item: SSUIPlatformItem) {
        var platform: SSDKPlatformType?
        switch item.platformName {
        case SSUIPlatformItem(platformType: .subTypeWechatTimeline)?.platformName:
            platform = .subTypeWechatTimeline
            break
        case SSUIPlatformItem(platformType: .subTypeWechatSession)?.platformName:
            platform = .subTypeWechatSession
            break
        case SSUIPlatformItem(platformType: .subTypeQQFriend)?.platformName:
            platform = .subTypeQQFriend
            break
        case SSUIPlatformItem(platformType: .subTypeQZone)?.platformName:
            platform = .subTypeQZone
            break
        case SSUIPlatformItem(platformType: .typeSinaWeibo)?.platformName:
            platform = .typeSinaWeibo
            break
        case SSUIPlatformItem(platformType: .typeLine)?.platformName:
            platform = .typeLine
            break
        case SSUIPlatformItem(platformType: .typeFacebook)?.platformName:
            platform = .typeFacebook
            break
        case SSUIPlatformItem(platformType: .typeTwitter)?.platformName:
            platform = .typeTwitter
            break
        case SSUIPlatformItem(platformType: .typeTelegram)?.platformName:
            platform = .typeTelegram
            break
        default:
            break
        }
        if let platformType = platform {
            ShareSDK.share(platformType, parameters: shareParams) {[weak self] (state, userData, contentEntity, error) in
                guard let weakSelf = self else { return }
                switch (state) {
                case SSDKResponseState.success:
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: I18n.shareSuccess.description, closeBtn: I18n.close.description, viewController: weakSelf)
                case SSDKResponseState.fail:
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error?.localizedDescription ?? "", closeBtn: I18n.close.description, viewController: weakSelf)
                    break
                default:
                    break
                }
                weakSelf.inviteImagePresentr.dismiss(animated: true, completion: nil)
            }
        }
    }
}

extension InviteViewController {
    
    private func getInviteSummary() {
        if self.loadingInviteSummary {
            return
        }
        self.loadingInviteSummary = true
        
        TMMUserService.getInviteSummary(
            withUserList: false,
            provider: self.userServiceProvider)
            .then(in: .background, {[weak self] summary in
                guard let weakSelf = self else { return }
                weakSelf.inviteSummary = summary
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingInviteSummary = false
                weakSelf.setupView()
            }
        )
    }
}
