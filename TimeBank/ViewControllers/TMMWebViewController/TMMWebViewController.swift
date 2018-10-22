//
//  TMMWebViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import WebKit
import ZHRefresh
import Presentr

class TMMWebViewController: UIViewController {
    
    lazy private var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let tmpWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        tmpWebView.uiDelegate = self
        tmpWebView.navigationDelegate = self
        self.view = tmpWebView
        return tmpWebView
    }()
    
    lazy private var shareSheetItems: [SSUIPlatformItem] = {
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
        if let img = shareItem?.image {
            image = img
        } else {
            image = UIImage(named: "Logo")
        }
        let thumbnail = image?.kf.resize(to: CGSize(width: 300, height: 300))
        let params = NSMutableDictionary()
        params.ssdkSetupShareParams(byText: shareItem?.description, images: image, url: shareItem?.link, title: shareItem?.title, type: .webPage)
        params.ssdkSetupCopyParams(byText: shareItem?.description, images: image, url: shareItem?.link, type: .webPage)
        params.ssdkSetupWeChatParams(byText: shareItem?.description, title: shareItem?.title, url: shareItem?.link, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatSession)
        params.ssdkSetupWeChatParams(byText: shareItem?.description, title: shareItem?.title, url: shareItem?.link, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatTimeline)
        params.ssdkSetupSinaWeiboShareParams(byText: shareItem?.description, title: shareItem?.title, images: image, video: nil, url: shareItem?.link, latitude: 0, longitude: 0, objectID: nil, isShareToStory: true, type: .webPage)
        params.ssdkSetupFacebookParams(byText: shareItem?.description, image: image, url: shareItem?.link, urlTitle: shareItem?.title, urlName: TMMConfigs.Facebook.displayName, attachementUrl: nil, hashtag: "UCoin", quote: nil, type: .webPage)
        params.ssdkSetupTwitterParams(byText: shareItem?.description, images: image, video: nil, latitude: 0, longitude: 0, type: .webPage)
        params.ssdkSetupQQParams(byText: shareItem?.description, title: shareItem?.title, url: shareItem?.link, audioFlash: nil, videoFlash: nil, thumbImage: thumbnail, images: image, type: .webPage, forPlatformSubType: .subTypeQZone)
        params.ssdkSetupQQParams(byText: shareItem?.description, title: shareItem?.title, url: shareItem?.link, audioFlash: nil, videoFlash: nil, thumbImage: thumbnail, images: image, type: .webPage, forPlatformSubType: .subTypeQQFriend)
        params.ssdkSetupTelegramParams(byText: shareItem?.description, image: image, audio: nil, video: nil, file: nil, menuDisplay: CGPoint.zero, type: .auto)
        return params
    }()
    
    public var request: URLRequest?
    public var shareItem: TMMShareItem?
    
    fileprivate var progressView: UIProgressView!
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
            if self.shareItem != nil {
                let shareBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "Share")?.kf.resize(to: CGSize(width: 24, height: 24), for: .aspectFit), style: .plain, target: self, action: #selector(showShareSheet))
                navigationItem.rightBarButtonItem = shareBtn
                navigationItem.title = shareItem?.title
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
        
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.scrollView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.webView.reload()
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {return}
        switch keyPath {
        case "estimatedProgress":
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                progressChanged(newValue)
            }
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    fileprivate func progressChanged(_ newValue: NSNumber) {
        if progressView == nil {
            progressView = UIProgressView()
            progressView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(progressView)
            
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[progressView]-0-|", options: [], metrics: nil, views: ["progressView": progressView]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topGuide]-0-[progressView(2)]", options: [], metrics: nil, views: ["progressView": progressView, "topGuide": self.topLayoutGuide]))
        }
        
        progressView.progress = newValue.floatValue
        if progressView.progress == 1 {
            progressView.progress = 0
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.progressView.alpha = 0
            })
        } else if progressView.alpha == 0 {
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.progressView.alpha = 1
            })
        }
    }
    
    private func loadRequest(_ request: URLRequest) {
        webView.load(request)
    }
    
    override public func loadView() {
        guard let req = request else { return }
        loadRequest(req)
    }
    
    static func instantiate() -> TMMWebViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TMMWebViewController") as! TMMWebViewController
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        webView.stopLoading()
        webView.uiDelegate = nil;
        webView.navigationDelegate = nil;
    }
    
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
                if let shareItem = self.shareItem {
                    if let title = shareItem.title {
                        activityItems.append(title)
                    }
                    if let image = shareItem.image {
                        activityItems.append(image)
                    }
                    if let link = shareItem.link {
                        activityItems.append(link)
                    }
                }
                if activityItems.count == 0 {
                    if let url: URL = ((webView.url != nil) ? webView.url : request?.url) {
                        activityItems.append(url)
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
        } else if let link = shareItem?.link {
            let paste = UIPasteboard.general
            paste.string = "\(link)"
        }
    }
}

extension TMMWebViewController: WKUIDelegate {
    
    // Add any desired WKUIDelegate methods here: https://developer.apple.com/reference/webkit/wkuidelegate
    
}

extension TMMWebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        webView.scrollView.header?.endRefreshing()
        
        webView.evaluateJavaScript("document.title", completionHandler: {[weak self] (response, error) in
            guard let weakSelf = self else { return }
            weakSelf.navigationItem.title = response as! String?
        })
        
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        webView.scrollView.header?.endRefreshing()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let url = navigationAction.request.url
        
        let hostAddress = navigationAction.request.url?.host
        
        if (navigationAction.targetFrame == nil) {
            if UIApplication.shared.canOpenURL(url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
            }
        }
        
        // To connnect app store
        if hostAddress == "itunes.apple.com" {
            if UIApplication.shared.canOpenURL(navigationAction.request.url!) {
                UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }
        
        let url_elements = url!.absoluteString.components(separatedBy: ":")
        
        switch url_elements[0] {
        case "tel":
            openCustomApp(urlScheme: "telprompt://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "sms":
            openCustomApp(urlScheme: "sms://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        case "mailto":
            openCustomApp(urlScheme: "mailto://", additional_info: url_elements[1])
            decisionHandler(.cancel)
            
        default:
            //print("Default")
            break
        }
        
        decisionHandler(.allow)
        
    }
    
    func openCustomApp(urlScheme: String, additional_info:String){
        
        if let requestUrl: URL = URL(string:"\(urlScheme)"+"\(additional_info)") {
            let application:UIApplication = UIApplication.shared
            if application.canOpenURL(requestUrl) {
                application.open(requestUrl, options: [:], completionHandler: nil)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if challenge.previousFailureCount == 0 {
                let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
                completionHandler(.useCredential, credential)
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
