//
//  TMMWebViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import WebKit
import Moya
import Hydra
import ZHRefresh
import Presentr
import SnapKit
import DynamicBlurView
import Schedule
import MKRingProgressView
import TMMSDK

fileprivate let DefaultSleepTime: Double = 15

class TMMWebViewController: UIViewController {
    
    lazy private var webView: WKWebView = {[weak self] in
        let wkController = WKUserContentController()
        wkController.add(TMMWebViewLeakAvoider(delegate: self!), name: "TMMWordCounter")
        wkController.addUserScript(self!.injectJS())
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = wkController
        let tmpWebView = WKWebView(frame: .zero, configuration: webConfiguration)
        tmpWebView.uiDelegate = self
        tmpWebView.navigationDelegate = self
        tmpWebView.scrollView.delegate = self
        self?.view = tmpWebView
        return tmpWebView
    }()
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    lazy private var toolbarView: DynamicBlurView = {[weak self] in
        let blurOverlay = DynamicBlurView()
        blurOverlay.blurRatio = 0.5
        blurOverlay.trackingMode = .common
        blurOverlay.isUserInteractionEnabled = true
        self?.view.addSubview(blurOverlay)
        blurOverlay.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.trailing.equalToSuperview()
            maker.leading.equalToSuperview()
            maker.bottom.equalTo(bottomLayoutGuide.snp.top).offset(-8)
        }
        approximatePointsLabel.font = UIFont.systemFont(ofSize: 12)
        approximatePointsLabel.backgroundColor = UIColor(white: 0.98, alpha: 1)
        approximatePointsLabel.paddingTop = 4
        approximatePointsLabel.paddingBottom = 4
        approximatePointsLabel.paddingLeft = 16
        approximatePointsLabel.paddingRight = 16
        approximatePointsLabel.layer.cornerRadius = 5
        approximatePointsLabel.layer.borderWidth = 0
        approximatePointsLabel.clipsToBounds = true
        approximatePointsLabel.adjustsFontSizeToFitWidth = true
        approximatePointsLabel.minimumScaleFactor = 0.5
        blurOverlay.addSubview(approximatePointsLabel)
        approximatePointsLabel.snp.remakeConstraints { (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.leading.equalToSuperview().offset(16)
            maker.top.equalToSuperview().offset(8)
        }
        let stackView = UIStackView()
        stackView.alignment = UIStackView.Alignment.center
        stackView.axis = .horizontal
        stackView.distribution = .fillProportionally
        stackView.spacing = 16.0
        blurOverlay.addSubview(stackView)
        stackView.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.trailing.equalToSuperview().offset(-16)
            maker.leading.equalToSuperview().offset(16)
            maker.top.equalTo(approximatePointsLabel.snp.bottom).offset(8)
            maker.bottom.equalToSuperview().offset(-8)
        }
        let shareButton = UIButton(type: .custom)
        shareButton.backgroundColor = .greenGrass
        shareButton.layer.cornerRadius = 10.0
        shareButton.layer.borderWidth = 0.0
        shareButton.layer.shadowOffset =  CGSize(width: 0, height: 0)
        shareButton.layer.shadowOpacity = 0.42
        shareButton.layer.shadowRadius = 2
        shareButton.layer.shadowColor = UIColor.black.cgColor
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.setTitle(I18n.shareEarnPoints.description, for: .normal)
        shareButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        shareButton.addTarget(self, action: #selector(showShareSheetAlert), for: .touchUpInside)
        shareButton.titleLabel?.adjustsFontSizeToFitWidth = true
        shareButton.titleLabel?.minimumScaleFactor = 0.5
        stackView.addArrangedSubview(shareButton)
        
        timerProgressView.startColor = .red
        timerProgressView.endColor = .magenta
        timerProgressView.ringWidth = 10
        timerProgressView.progress = 0.0
        stackView.addArrangedSubview(timerProgressView)
        timerProgressView.snp.remakeConstraints { (maker) -> Void in
            maker.width.equalTo(40)
            maker.height.equalTo(40)
        }
        
        pointsLabel.font = MainFont.bold.with(size: 14)
        pointsLabel.textColor = .white
        pointsLabel.backgroundColor = UIColor.redish
        pointsLabel.textAlignment = .center
        pointsLabel.adjustsFontSizeToFitWidth = true
        pointsLabel.minimumScaleFactor = 0.5
        pointsLabel.paddingTop = 4
        pointsLabel.paddingBottom = 4
        pointsLabel.paddingLeft = 16
        pointsLabel.paddingRight = 16
        pointsLabel.layer.cornerRadius = 10
        pointsLabel.layer.borderWidth = 0
        pointsLabel.clipsToBounds = true
        stackView.addArrangedSubview(pointsLabel)
        return blurOverlay
    }()
    
    private let approximatePointsLabel: UILabelPadding = UILabelPadding()
    private let pointsLabel: UILabelPadding = UILabelPadding()
    private var pointsRate: APIExchangeRate? {
        didSet {
            if let rate = pointsRate?.rate {
                let points = NSDecimalNumber(integerLiteral: self.readTime) * rate
                self.updateApproximatePointsLabel(points)
            }
        }
    }
    
    private var readTime: Int = 0 {
        didSet {
            var pointsRate = TMMConfigs.defaultPointsPerTs
            if let rate = self.pointsRate {
                pointsRate = rate.rate
            }
            let points = NSDecimalNumber(integerLiteral: self.readTime) * pointsRate
            self.updateApproximatePointsLabel(points)
        }
    }
    
    private var timer: Schedule.Task?
    private let timerProgressView: RingProgressView = RingProgressView(frame: CGRect.zero)
    
    private var lastTime: Date = Date()
    private var lastScrollTime: Date = Date()
    private var duration: Double = 0 {
        didSet {
            var pointsRate = TMMConfigs.defaultPointsPerTs
            if let rate = self.pointsRate {
                pointsRate = rate.rate
            }
            let points = NSDecimalNumber(decimal: Decimal(duration)) * pointsRate
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.minimumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            let formattedPoints = formatter.string(from: points)!
            DispatchQueue.main.async {[weak self] in
                self?.pointsLabel.text = String(format: I18n.getPointsReward.description, formattedPoints)
                UIView.animate(withDuration: 0.5) {[weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.timerProgressView.progress = weakSelf.duration / Double(weakSelf.readTime)
                }
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
    
    private var bonusServiceProvider = MoyaProvider<TMMBonusService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var exchangeServiceProvider = MoyaProvider<TMMExchangeService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
            if self.shareItem != nil {
                let shareBtn: UIBarButtonItem = UIBarButtonItem(image: UIImage(named: "Share")?.kf.resize(to: CGSize(width: 24, height: 24), for: .aspectFit), style: .plain, target: self, action: #selector(showShareSheet))
                navigationItem.rightBarButtonItem = shareBtn
                navigationItem.title = shareItem?.title
                if isValidatingBuild() {
                    toolbarView.isHidden = true
                }
                toolbarView.setNeedsDisplay()
                self.updateTimer()
                self.timer = Plan.every(0.5.seconds).do(queue: .global()) {[weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.updateTimer()
                }
            }
        }
        getPointsRate()
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.scrollView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.webView.reload()
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
        self.tabBarController?.tabBar.isHidden = true
        if self.shareItem != nil {
            MTA.trackPageViewBegin(TMMConfigs.PageName.article)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.savePoints()
        self.tabBarController?.tabBar.isHidden = false
        MTA.trackPageViewEnd(TMMConfigs.PageName.article)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        timer?.cancel()
        webView.stopLoading()
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
        webView.scrollView.delegate = nil
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.configuration.userContentController.removeAllUserScripts()
    }
    
    override func currentViewControllerShouldPop() -> Bool {
        if webView.canGoBack {
            webView.goBack()
            return false
        }
        return true
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
    
    private func injectJS() -> WKUserScript {
        let jsDomParser = try! String(contentsOfFile: (Bundle.main.path(forResource: "JSDOMParser", ofType: "js"))!)
        let readability = try! String(contentsOfFile: (Bundle.main.path(forResource: "Readability", ofType: "js"))!)
        let wordCounter = try! String(contentsOfFile: (Bundle.main.path(forResource: "WordCounter", ofType: "js"))!)
        return WKUserScript(source: "\(jsDomParser)\n\(readability)\n\(wordCounter)", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
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
    
    @objc func showShareSheetAlert() {
        if let task = self.shareItem?.task {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            let maxBonus = task.bonus * NSDecimalNumber(value: task.maxViewers)
            let formattedMaxBonus: String = formatter.string(from: maxBonus)!
            let msg = String(format: I18n.toShareAlert.description, formatter.string(from: task.bonus)!, formattedMaxBonus)
            let alertController = AlertViewController(title: I18n.alert.description, body: msg)
            let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
            let okAction = AlertAction(title: I18n.toShare.description, style: .destructive) {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.showShareSheet()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            self.customPresentViewController(self.alertPresenter, viewController: alertController, animated: true)
            return
        }
        self.showShareSheet()
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
    
    private func updateApproximatePointsLabel(_ points: NSDecimalNumber) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let formattedPoints = formatter.string(from: points)!
        DispatchQueue.main.async {[weak self] in
            self!.approximatePointsLabel.text = String(format: I18n.approximateTime.description, self!.readTime.timeSpan(), formattedPoints)
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

extension TMMWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let msg = message.body as? [AnyHashable: Any] {
            var totalTs: Int = 0
            if let imageTs = msg["imgTS"] as? Int {
                totalTs += imageTs
            }
            if let length = msg["length"] as? Int {
                totalTs += length * 60 / TMMConfigs.defaultReadSpeed
            }
            self.readTime = totalTs
        }
    }
}

extension TMMWebViewController: UIScrollViewDelegate {
    private func updateTimer() {
        let now = Date()
        let du = now.timeIntervalSince1970 - self.lastTime.timeIntervalSince1970
        if du >= DefaultSleepTime {
            self.duration += DefaultSleepTime
        } else {
            self.duration += du
        }
        self.lastTime = now
        
        let scrollDu = now.timeIntervalSince1970 - self.lastScrollTime.timeIntervalSince1970
        if scrollDu < DefaultSleepTime {
            self.timer?.resume()
        } else {
            self.timer?.suspend()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.lastScrollTime = Date()
        if let suspensions = self.timer?.suspensions, suspensions > 0 {
            self.lastTime = Date()
        }
        self.timer?.resume()
    }
    
    private func savePoints() {
        guard let bonus = APIReadBonus(),
            let taskId = self.shareItem?.id,
            let idfa = TMMBeacon.shareInstance()?.deviceId()
        else { return }
        bonus.taskId = taskId
        var pointsRate = TMMConfigs.defaultPointsPerTs
        if let rate = self.pointsRate {
            pointsRate = rate.rate
        }
        bonus.points = NSDecimalNumber(decimal: Decimal(duration)) * pointsRate
        bonus.duration = Int64(duration.rounded())
        bonus.ts = Int64(Date().timeIntervalSince1970)
        guard let payload = bonus.toJSONString()?.desEncrypt(withKey: TMMConfigs.TMMBeacon.secret) else { return }
        TMMBonusService.saveReadingBonus(idfa: idfa, appKey: TMMConfigs.TMMBeacon.key, payload: payload, provider: self.bonusServiceProvider).catch { error in
            #if DEBUG
            print(error.localizedDescription)
            #endif
        }
    }
    
    private func getPointsRate() {
        TMMExchangeService.getPointsRate(
            provider: self.exchangeServiceProvider)
            .then(in: .main, {[weak self] rate in
                guard let weakSelf = self else { return }
                weakSelf.pointsRate = rate
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            })
    }
}
