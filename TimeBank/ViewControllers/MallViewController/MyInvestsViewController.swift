//
//  MyInvestsViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/13.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import SwiftyUserDefaults
import Pastel
import Moya
import Hydra
import ZHRefresh
import SkeletonView
import ViewAnimator
import Presentr
import SwipeCellKit

fileprivate let DefaultPageSize: UInt = 10
class MyInvestsViewController: UIViewController {
    
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
    
    @IBOutlet private weak var summaryView: PastelView!
    @IBOutlet private weak var withdrawButton: TransitionButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var investLabel: UILabel!
    @IBOutlet private weak var incomeLabel: UILabel!
    
    private let alertPresenter: Presentr = {
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
        let image = UIImage(named: "Logo")
        let shareLink = URL(string: TMMConfigs.WeChat.authLink)
        let title = "打开完成微信支付授权"
        let desc = "打开后点击完成微信支付授权"
        let thumbnail = image?.kf.resize(to: CGSize(width: 300, height: 300))
        let params = NSMutableDictionary()
        params.ssdkSetupWeChatParams(byText: desc, title: title, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatSession)
        params.ssdkSetupWeChatParams(byText: desc, title: title, url: shareLink, thumbImage: thumbnail, image: image, musicFileURL: nil, extInfo: nil, fileData: nil, emoticonData: nil, sourceFileExtension: nil, sourceFileData: nil, type: .webPage, forPlatformSubType: .subTypeWechatTimeline)
        return params
    }()
    
    private var currentPage: UInt = 1
    private var invests: [APIGoodInvest] = []
    private var loadingInvests = false
    private var loadingSummary = false
    private var withdrawing = false
    private var bindingWechat = false
    private var redeeming = false
    
    private var redeemIds: [UInt64]?
    private var redeemCell: MyGoodInvestTableViewCell?
    
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var goodServiceProvider = MoyaProvider<TMMGoodService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
            navigationItem.title = I18n.myInvest.description
        }
        setupSummaryView()
        setupTableView()
        if userInfo != nil {
            refresh()
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
        MTA.trackPageViewBegin(TMMConfigs.PageName.myInvests)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.myInvests)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if userInfo == nil {
            let vc = LoginViewController.instantiate()
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> MyInvestsViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MyInvestsViewController") as! MyInvestsViewController
    }
    
    private func setupSummaryView() {
        summaryView.layer.cornerRadius = 15.0
        summaryView.layer.borderWidth = 0
        summaryView.layer.rasterizationScale = UIScreen.main.scale
        summaryView.layer.contentsScale =  UIScreen.main.scale
        summaryView.clipsToBounds = true
        
        summaryView.startPastelPoint = .bottomLeft
        summaryView.endPastelPoint = .topRight
        summaryView.animationDuration = 3.0
        summaryView.setColors([UIColor(red: 156/255, green: 39/255, blue: 176/255, alpha: 1.0),
                               UIColor(red: 255/255, green: 64/255, blue: 129/255, alpha: 1.0),
                               UIColor(red: 123/255, green: 31/255, blue: 162/255, alpha: 1.0),
                               UIColor(red: 32/255, green: 76/255, blue: 255/255, alpha: 1.0),
                               UIColor(red: 32/255, green: 158/255, blue: 255/255, alpha: 1.0),
                               UIColor(red: 90/255, green: 120/255, blue: 127/255, alpha: 1.0),
                               UIColor(red: 58/255, green: 255/255, blue: 217/255, alpha: 1.0)])
        
        summaryView.startAnimation()
        withdrawButton.setTitle(I18n.withdraw.description, for: .normal)
    }
    
    private func setupTableView() {
        tableView.register(cellType: MyGoodInvestTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
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
        
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    private func updateSummary(_ summary: APIGoodInvestSummary) {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        investLabel.text = formatter.string(from: summary.invest)
        incomeLabel.text = "¥\(formatter.string(from: summary.income)!)"
    }
    
    public func refresh() {
        getInvestSummary()
        getInvests(true)
    }
}

extension MyInvestsViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension MyInvestsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.invests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as MyGoodInvestTableViewCell
        cell.delegate = self
        let invest = self.invests[indexPath.row]
        cell.fill(invest)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let invest = self.invests[indexPath.row]
        let vc = GoodViewController.instantiate()
        vc.setGood(good: invest.toGood()!)
        if let cell = tableView.cellForRow(at: indexPath) as? MyGoodInvestTableViewCell {
            vc.shareImage = cell.imgView.image
            cell.isSelected = false
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingInvests
    }
}

extension MyInvestsViewController: SkeletonTableViewDataSource {
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return LoadingTableViewCell.self.reuseIdentifier
    }
}

extension MyInvestsViewController {
    private func getInvestSummary() {
        if self.loadingSummary { return }
        self.loadingSummary = true
        
        TMMGoodService.getInvestSummary(
            provider: self.goodServiceProvider)
            .then(in: .main, {[weak self] summary in
                guard let weakSelf = self else { return }
                weakSelf.updateSummary(summary)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingSummary = false
            }
        )
    }
    
    private func getInvests(_ refresh: Bool) {
        if self.loadingInvests { return }
        self.loadingInvests = true
        
        if refresh {
            currentPage = 1
        }
        TMMGoodService.getMyInvests(
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
                weakSelf.tableView.hideSkeleton()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
                if refresh {
                    let zoomAnimation = AnimationType.zoom(scale: 0.2)
                    UIView.animate(views: weakSelf.tableView.visibleCells, animations: [zoomAnimation], completion:nil)
                }
            }
        )
    }
    
    @IBAction private func showRedeemAlert() {
        let alertController = AlertViewController(title: I18n.alert.description, body: "确定要提现吗？")
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
        let okAction = AlertAction(title: I18n.withdraw.description, style: .destructive) {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.tryRedeem()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.customPresentViewController(self.alertPresenter, viewController: alertController, animated: true)
    }
    
    private func tryRedeem() {
        if self.redeemCell != nil {
            self.redeemCell?.redeemButton.startAnimation()
        } else {
            withdrawButton.startAnimation()
        }
        async({ _ in
            if !ShareSDK.hasAuthorized(.typeWechat) {
                let user = try ..self.authWechat()
                let _ = try ..self.doBindWechat(user: user)
            }
            let _ = try ..self.doRedeem()
        }).then(in: .main, {[weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.redeemIds = nil
            if weakSelf.redeemCell != nil {
                weakSelf.redeemCell?.redeemButton.stopAnimation(animationStyle: .normal, completion: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.redeemCell = nil
                })
            } else {
                weakSelf.withdrawButton.stopAnimation(animationStyle: .normal, completion: nil)
            }
        }).catch(in: .main, {[weak self] error in
            guard let weakSelf = self else { return }
            if let err = error as? TMMAPIError {
                switch err {
                case .ignore:
                    if weakSelf.redeemCell != nil {
                        weakSelf.redeemCell?.redeemButton.stopAnimation(animationStyle: .shake, completion: nil)
                    } else {
                        weakSelf.withdrawButton.stopAnimation(animationStyle: .shake, completion: nil)
                    }
                    return
                case .wechatOpenIdError:
                    if weakSelf.redeemCell != nil {
                        weakSelf.redeemCell?.redeemButton.stopAnimation(animationStyle: .normal, completion: nil)
                    } else {
                        weakSelf.withdrawButton.stopAnimation(animationStyle: .normal, completion: nil)
                    }
                    let alertController = AlertViewController(title: I18n.alert.description, body: "请在微信内打开页面完成微信授权，以便打款。")
                    let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) {[weak weakSelf] in
                        guard let weakSelf2 = weakSelf else { return }
                        weakSelf2.redeemIds = nil
                        weakSelf2.redeemCell = nil
                    }
                    let okAction = AlertAction(title: "分享页面至微信", style: .destructive) {[weak self] in
                        guard let weakSelf = self else { return }
                        weakSelf.showShareSheet()
                    }
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
                    return
                default: break
                }
            }
            weakSelf.redeemIds = nil
            if weakSelf.redeemCell != nil {
                weakSelf.redeemCell?.redeemButton.stopAnimation(animationStyle: .shake, completion: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.redeemCell = nil
                })
            } else {
                weakSelf.withdrawButton.stopAnimation(animationStyle: .shake, completion: nil)
            }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.bindingWechat = false
            weakSelf.redeeming = false
        })
    }
    
    private func doBindWechat(user: SSDKUser) -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.bindingWechat {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.bindingWechat = true
            guard let rawInfo = user.rawData else { return }
            guard let openId = rawInfo["openid"] as? String else { return }
            guard let unionId = rawInfo["unionid"] as? String else { return }
            TMMUserService.bindWechatInfo(
                unionId: unionId,
                openId: openId,
                nick: user.nickname,
                avatar: user.icon,
                gender: user.gender,
                accessToken: user.credential.token,
                expires: user.credential.expired,
                provider: weakSelf.userServiceProvider)
                .then(in: .background, { _ in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
    
    private func authWechat() -> Promise<SSDKUser> {
        return Promise<SSDKUser> (in: .background, { resolve, reject, _ in
            ShareSDK.authorize(.typeWechat, settings: nil) { (state: SSDKResponseState, user: SSDKUser?, error: Error?) in
                switch state {
                case .success:
                    guard let userInfo = user else {
                        reject(TMMAPIError.ignore)
                        return
                    }
                    resolve(userInfo)
                case .fail:
                    guard let err = error else {
                        reject(TMMAPIError.ignore)
                        return
                    }
                    reject(err)
                default:
                    reject(TMMAPIError.ignore)
                }
            }
        })
    }
    
    private func doRedeem() -> Promise<APIResponse> {
        return Promise<APIResponse> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.redeeming {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.redeeming = true
            TMMGoodService.redeemInvest(
                ids: weakSelf.redeemIds,
                provider: weakSelf.goodServiceProvider)
                .then(in: .background, { resp  in
                    resolve(resp)
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
}

extension MyInvestsViewController {
    private func showShareSheet() {
        ShareSDK.showShareActionSheet(self.view, customItems: shareSheetItems as [Any], shareParams: shareParams, sheetConfiguration: nil){[weak self] (state, platformType, userData, contentEntity, error, end) in
            guard let weakSelf = self else { return }
            switch (state) {
            case SSDKResponseState.success:
                weakSelf.tryRedeem()
                //UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: "", closeBtn: I18n.close.description, viewController: weakSelf)
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
                    weakSelf.tryRedeem()
                    //UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: I18n.shareSuccess.description, closeBtn: I18n.close.description, viewController: weakSelf)
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

extension MyInvestsViewController: MyGoodInvestTableViewCellDelegate {
    func investWithdraw(invest: APIGoodInvest, cell: UITableViewCell) {
        guard let currentCell = cell as? MyGoodInvestTableViewCell else { return }
        if invest.redeemStatus == .redeemed {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已提现", closeBtn: I18n.close.description)
            return
        } else if invest.redeemStatus == .withdraw {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已撤回", closeBtn: I18n.close.description)
            return
        }
        let alertController = AlertViewController(title: I18n.alert.description, body: "撤回投资后该投资收益将被清空，确定撤回投资？")
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
        let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.doWithdraw(goodId: invest.goodId!, cell: currentCell)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.customPresentViewController(self.alertPresenter, viewController: alertController, animated: true)
    }
    
    private func doWithdraw(goodId: UInt64, cell: MyGoodInvestTableViewCell) {
        if self.withdrawing { return }
        self.withdrawing = true
        cell.withdrawButton.startAnimation()
        TMMGoodService.withdrawInvest(
            id: goodId,
            provider: self.goodServiceProvider)
            .then(in: .main, {[weak self] _ in
                guard let weakSelf = self else { return }
                cell.withdrawButton.stopAnimation(animationStyle: .normal, completion: nil)
                weakSelf.refresh()
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                weakSelf.withdrawButton.stopAnimation(animationStyle: .shake, completion: nil)
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.withdrawing = false
            }
        )
    }
    
    func investRedeem(invest: APIGoodInvest, cell: UITableViewCell) {
        if invest.redeemStatus == .redeemed {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已提现", closeBtn: I18n.close.description)
            return
        } else if invest.redeemStatus == .withdraw {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资已撤回", closeBtn: I18n.close.description)
            return
        } else if invest.income <= 0 {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: "该投资还没有收益", closeBtn: I18n.close.description)
            return
        }
        guard let goodId = invest.goodId else { return }
        self.redeemIds = [goodId]
        self.redeemCell = cell as? MyGoodInvestTableViewCell
        self.showRedeemAlert()
    }
}

extension MyInvestsViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
