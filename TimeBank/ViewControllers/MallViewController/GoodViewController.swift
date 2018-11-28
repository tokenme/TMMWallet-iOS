//
//  GoodViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import ZHRefresh
import Presentr

fileprivate let DefaultPageSize: UInt = 10
class GoodViewController: UIViewController {
    
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
    
    let investPresenter: Presentr = {
        let customPresenter = Presentr(presentationType: .bottomHalf)
        customPresenter.keyboardTranslationType = .moveUp
        customPresenter.transitionType = .coverVertical
        customPresenter.dismissTransitionType = .crossDissolve
        customPresenter.roundCorners = false
        //customPresenter.blurBackground = true
        customPresenter.blurStyle = UIBlurEffect.Style.light
        customPresenter.backgroundOpacity = 0.5
        customPresenter.dismissOnSwipe = true
        customPresenter.dismissOnSwipeDirection = .bottom
        return customPresenter
    }()
    
    let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
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
        for item in items {
            item.addTarget(self, action: #selector(shareItemClicked))
        }
        return items
    }()
    
    lazy var shareParams: NSMutableDictionary = {
        var image: UIImage?
        let shareLink = URL(string: good?.shareLink ?? "")
        if let img = shareImage {
            image = img
        } else {
            image = UIImage(named: "Logo")
        }
        let desc = good?.name
        let thumbnail = image?.kf.resize(to: CGSize(width: 300, height: 300))
        let params = NSMutableDictionary()
        params.ssdkSetupWeChatParams(byText: desc, title: good?.name, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatSession)
        params.ssdkSetupWeChatParams(byText: desc, title: good?.name, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatTimeline)
        return params
    }()
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var investButton: UIButton!
    
    private var good: APIGood?
    public var shareImage: UIImage?
    private var invests: [APIGoodInvest] = []
    private var loadingGood = false
    private var loadingInvests = false
    private var currentPage: UInt = 0
    
    private var goodServiceProvider = MoyaProvider<TMMGoodService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    
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
            navigationItem.title = good?.name
        }
        setupTableView()
        refresh()
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> GoodViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GoodViewController") as! GoodViewController
    }
    
    public func setGood(good: APIGood) {
        self.good = good
    }
    
    private func setupTableView() {
        tableView.register(cellType: GoodInfoTableViewCell.self)
        tableView.register(cellType: GoodInvestTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableView.automaticDimension
        //tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        
        tableView.footer = ZHRefreshAutoNormalFooter.footerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.getInvests(false)
        }
        tableView.header?.isHidden = true
        tableView.footer?.isHidden = true
    }
    
    func updateView() {
        guard let item = good else { return }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let prefix = "分享赚\n"
        let priceStr = "¥\(formatter.string(from: item.commissionPrice)!)"
        let pointsStr = "\(formatter.string(from: item.commissionPoints)!)积分"
        let reward = "\(priceStr)+\(pointsStr)"
        let prefixAttributes = [NSAttributedString.Key.font:MainFont.medium.with(size: 12), NSAttributedString.Key.foregroundColor:UIColor.white]
        let rewardAttributes = [NSAttributedString.Key.font:MainFont.medium.with(size: 15), NSAttributedString.Key.foregroundColor:UIColor.white]
        let attString = NSMutableAttributedString(string: "\(prefix)\(reward)")
        attString.addAttributes(prefixAttributes, range:NSRange.init(location: 0, length: prefix.count))
        attString.addAttributes(rewardAttributes, range: NSRange.init(location: prefix.count, length: reward.count))
        shareButton.titleLabel?.numberOfLines = 0
        shareButton.titleLabel?.textAlignment = .center
        shareButton.titleLabel?.adjustsFontSizeToFitWidth = true
        shareButton.titleLabel?.minimumScaleFactor = 0.5
        shareButton.setAttributedTitle(attString, for: .normal)
        shareButton.backgroundColor = UIColor.pinky
        if item.investPoints > 0 {
            let prefix = "已投资\n"
            let pointsStr = "\(formatter.string(from: item.investPoints)!)积分, 点击追加"
            let prefixAttributes = [NSAttributedString.Key.font:MainFont.medium.with(size: 12), NSAttributedString.Key.foregroundColor:UIColor.white]
            let investAttributes = [NSAttributedString.Key.font:MainFont.medium.with(size: 15), NSAttributedString.Key.foregroundColor:UIColor.white]
            let attString = NSMutableAttributedString(string: "\(prefix)\(pointsStr)")
            attString.addAttributes(prefixAttributes, range:NSRange.init(location: 0, length: prefix.count))
            attString.addAttributes(investAttributes, range: NSRange.init(location: prefix.count, length: pointsStr.count))
            investButton.titleLabel?.numberOfLines = 0
            investButton.titleLabel?.textAlignment = .center
            investButton.titleLabel?.adjustsFontSizeToFitWidth = true
            investButton .titleLabel?.minimumScaleFactor = 0.5
            investButton.setAttributedTitle(attString, for: .normal)
        } else {
            investButton.titleLabel?.numberOfLines = 1
            investButton.setTitle("投资赚现金", for: .normal)
        }
    }
    
    func refresh() {
        getGood()
        getInvests(true)
    }
}

extension GoodViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && good != nil {
            return GoodInvestTableHeaderView.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 && good != nil {
            let view = GoodInvestTableHeaderView()
            view.fill(good!)
            return view
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return invests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(for: indexPath) as GoodInfoTableViewCell
            cell.fill(good)
            return cell
        }
        let invest = self.invests[indexPath.row]
        let cell = tableView.dequeueReusableCell(for: indexPath) as GoodInvestTableViewCell
        cell.fill(invest)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension GoodViewController {
    
    @IBAction func showInvestForm() {
        guard let goodId = good?.id else { return }
        let vc = InvestViewController(goodId: goodId)
        vc.delegate = self
        customPresentViewController(investPresenter, viewController: vc, animated: true, completion: nil)
    }
    
    @IBAction func showShareSheet() {
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
            }
        }
    }
}

extension GoodViewController {
    private func getGood() {
        if self.loadingGood { return }
        self.loadingGood = true
        guard let itemId = good?.id else { return }
        TMMGoodService.getItem(
            id: itemId,
            provider: self.goodServiceProvider)
            .then(in: .main, {[weak self] good in
                guard let weakSelf = self else { return }
                weakSelf.good = good
                weakSelf.updateView()
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingGood = false
                weakSelf.tableView.header?.isHidden = false
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
            }
        )
    }
    
    private func getInvests(_ refresh: Bool) {
        if self.loadingInvests { return }
        self.loadingInvests = true
        
        if refresh {
            currentPage = 1
        }
        guard let goodId = good?.id else { return }
        TMMGoodService.getInvests(
            goodId: goodId,
            page: currentPage,
            pageSize: DefaultPageSize,
            provider: self.goodServiceProvider)
            .then(in: .main, {[weak self] invests in
                guard let weakSelf = self else { return }
                if refresh {
                    weakSelf.invests = invests
                } else {
                    weakSelf.invests.append(contentsOf: invests)
                }
                if invests.count < DefaultPageSize {
                    if weakSelf.invests.count <= DefaultPageSize {
                        weakSelf.tableView.footer?.isHidden = true
                    } else {
                        weakSelf.tableView.footer?.isHidden = false
                        weakSelf.tableView.footer?.endRefreshingWithNoMoreData()
                    }
                } else {
                    weakSelf.tableView.footer?.isHidden = false
                    weakSelf.tableView.footer?.endRefreshing()
                    weakSelf.currentPage += 1
                }
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                weakSelf.tableView.footer?.isHidden = false
                weakSelf.tableView.footer?.endRefreshing()
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingInvests = false
                weakSelf.tableView.header?.isHidden = false
                weakSelf.tableView.header?.endRefreshing()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
}

extension GoodViewController: ViewUpdateDelegate {
    func shouldRefresh() {
        self.refresh()
    }
}
