//
//  VideoDetailViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/28.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import MMPlayerView
import Presentr
import Kingfisher

class VideoDetailViewController: UIViewController {

    var data: APIShareTask?
    var cover: UIImage?
    private var orientation: UIInterfaceOrientationMask = .portrait
    fileprivate var playerLayer: MMPlayerLayer?
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rotateButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    @IBAction private func tranformView() {
        var rotateImage: UIImage?
        if self.orientation == .landscape {
            self.orientation = .portrait
            rotateImage = UIImage(named: "FullScreen")
        }else{
            self.orientation = .landscape;
            rotateImage = UIImage(named: "Shrink")
        }
        self.rotateButton.setImage(rotateImage?.withRenderingMode(.alwaysTemplate), for: .normal)
        if orientation == .landscape {
            self.isStatusBarHidden = true
            UIView.animate(withDuration: 0.3, animations: {
                
                self.view.transform = CGAffineTransform.init(rotationAngle: CGFloat(Double.pi / 2))
                self.view.bounds = CGRect(x:0,y:0,width:UIScreen.main.bounds.size.height, height:UIScreen.main.bounds.size.width);
                self.viewWillLayoutSubviews();
                self.view.layoutIfNeeded();
            }) { (isFinish) in
                
            }
        } else {
            self.isStatusBarHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                
                self.view.transform = CGAffineTransform.init(rotationAngle: CGFloat(0))
                self.view.bounds = CGRect(x:0,y:0,width:UIScreen.main.bounds.size.width, height:UIScreen.main.bounds.size.height);
                self.viewWillLayoutSubviews();
                self.view.layoutIfNeeded();
            }) { (isFinish) in
                
            }
        }
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
        
        items.append(SSUIPlatformItem(platformType: SSDKPlatformType.typeCopy))
        let moreItem = SSUIPlatformItem(platformType: SSDKPlatformType.typeAny)
        moreItem?.iconNormal = UIImage(named: "More")
        moreItem?.iconSimple = UIImage(named: "More")
        moreItem?.platformName = I18n.more.description
        items.append(moreItem!)
        for item in items {
            item.addTarget(self, action: #selector(shareItemClicked))
        }
        return items
        }()
    
    lazy var shareParams: NSMutableDictionary = {
        var image: UIImage?
        if let img = self.cover {
            image = img
        } else {
            image = UIImage(named: "Logo")
        }
        let thumbnail = image?.kf.resize(to: CGSize(width: 300, height: 300))
        let shareLink = URL(string: data?.shareLink ?? "")
        let params = NSMutableDictionary()
        params.ssdkSetupShareParams(byText: data?.summary, images: image, url: shareLink, title: data?.title, type: .webPage)
        params.ssdkSetupCopyParams(byText: data?.title, images: image, url: shareLink, type: .webPage)
        params.ssdkSetupWeChatParams(byText: data?.summary, title: data?.title, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatSession)
        params.ssdkSetupWeChatParams(byText: data?.summary, title: data?.title, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatTimeline)
        params.ssdkSetupSinaWeiboShareParams(byText: data?.summary, title: data?.title, images: image, video: nil, url: shareLink, latitude: 0, longitude: 0, objectID: nil, isShareToStory: true, type: .webPage)
        params.ssdkSetupFacebookParams(byText: data?.summary, image: image, url: shareLink, urlTitle: data?.title, urlName: TMMConfigs.Facebook.displayName, attachementUrl: nil, hashtag: "UCoin", quote: nil, type: .webPage)
        params.ssdkSetupTwitterParams(byText: data?.title, images: image, video: nil, latitude: 0, longitude: 0, type: .webPage)
        params.ssdkSetupQQParams(byText: data?.summary, title: data?.title, url: shareLink, audioFlash: nil, videoFlash: nil, thumbImage: thumbnail, images: image, type: .webPage, forPlatformSubType: .subTypeQZone)
        params.ssdkSetupQQParams(byText: data?.summary, title: data?.title, url: shareLink, audioFlash: nil, videoFlash: nil, thumbImage: thumbnail, images: image, type: .webPage, forPlatformSubType: .subTypeQQFriend)
        params.ssdkSetupTelegramParams(byText: data?.title, image: image, audio: nil, video: nil, file: nil, menuDisplay: CGPoint.zero, type: .auto)
        return params
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.mmPlayerTransition.present.pass { (config) in
            config.duration = 0.3
        }
    }
    
    var isStatusBarHidden = false {
        didSet {
            /// 这里包装动画使得 preferredStatusBarUpdateAnimation 能体现效果
            UIView.animate(withDuration: 0.3) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let rotateImage = UIImage(named:"FullScreen")?.withRenderingMode(.alwaysTemplate)
        rotateButton.setImage(rotateImage, for: .normal)
        rotateButton.tintColor = .white
        let shareImage = UIImage(named:"Share")?.withRenderingMode(.alwaysTemplate)
        shareButton.setImage(shareImage, for: .normal)
        shareButton.tintColor = .white
        if let d = data {
            self.titleLabel.text = d.title
            if let imgLink = d.image {
                KingfisherManager.shared.retrieveImage(with: URL(string: imgLink)!, options: nil, progressBlock: nil, completionHandler:{[weak self](_ image: UIImage?, _ error: NSError?, _ cacheType: CacheType?, _ url: URL?) in
                    guard let weakSelf = self else {return}
                    if image != nil {
                        weakSelf.cover = image
                    }
                })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.video)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.video)
    }
    
    static func instantiate() -> VideoDetailViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoDetailViewController") as! VideoDetailViewController
    }
    
    @IBAction func shrinkVideoAction() {
        (self.presentationController as? MMPlayerPassViewPresentatinController)?.shrinkView()
    }
    
    @IBAction func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showShare() {
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
        case I18n.more.description:
            platform = .typeAny
        case SSUIPlatformItem(platformType: .typeCopy)?.platformName:
            break
        default:
            break
        }
        if let platformType = platform {
            if platformType == .typeAny {
                var activityItems: [Any] = []
                if let task = self.data {
                    activityItems.append(task.title)
                    if let image = task.image {
                        activityItems.append(image)
                    }
                    if let link = URL(string: task.shareLink) {
                        activityItems.append(link)
                    }
                }
                
                let activityController: UIActivityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                activityController.excludedActivityTypes = [
                    UIActivity.ActivityType.print,
                    UIActivity.ActivityType.copyToPasteboard,
                    UIActivity.ActivityType.assignToContact,
                    UIActivity.ActivityType.saveToCameraRoll,
                    UIActivity.ActivityType.addToReadingList
                ]
                present(activityController, animated: true, completion: nil)
                return
            }
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
            }
        } else if let link = data?.link {
            let paste = UIPasteboard.general
            paste.string = "\(link)"
        }
    }
    
    deinit {
        print("VideoDetailViewController deinit")
    }

}

extension VideoDetailViewController: MMPlayerToProtocol {
    
    func transitionCompleted(player: MMPlayerLayer) {
        self.playerLayer = player
    }
    
    var containerView: UIView {
        get {
            return playerContainer
        }
    }
}
