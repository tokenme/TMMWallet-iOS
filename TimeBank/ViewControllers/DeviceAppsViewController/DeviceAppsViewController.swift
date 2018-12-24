//
//  DeviceAppsViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Pastel
import Moya
import Hydra
import ZHRefresh
import SkeletonView
import ViewAnimator
import Presentr
import Haptica
import Peep

class DeviceAppsViewController: UIViewController {
    
    weak public var delegate: ViewUpdateDelegate?
    
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
    
    private var device: APIDevice?
    
    private var tmmBalance: NSDecimalNumber = 0
    
    @IBOutlet private weak var summaryView: PastelView!
    @IBOutlet private weak var summaryContainerView: UIStackView!
    @IBOutlet private weak var summarySubContainerView: UIStackView!
    @IBOutlet private weak var withdrawWrapper: UIStackView!
    @IBOutlet private weak var withdrawButton: TransitionButton!
    @IBOutlet private weak var exchangeButton: TransitionButton!
    @IBOutlet private weak var tableHeaderView: UIView!
    @IBOutlet private weak var miningAppsLabel: UILabel!
    @IBOutlet private weak var moreAppsButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var tsLabel: UILabel!
    @IBOutlet private weak var growthFactorLabel: UILabel!
    @IBOutlet private weak var tsImageView: UIImageView!
    @IBOutlet private weak var growthFactorImageView: UIImageView!
    
    let exchangePresenter: Presentr = {
        let width = ModalSize.full
        let height = ModalSize.fluid(percentage: 0.80)
        let center = ModalCenterPosition.bottomCenter
        let customType = PresentationType.custom(width: width, height: height, center: center)
        
        let customPresenter = Presentr(presentationType: customType)
        customPresenter.transitionType = .coverVertical
        customPresenter.dismissTransitionType = .crossDissolve
        customPresenter.roundCorners = false
        //customPresenter.blurBackground = true
        customPresenter.blurStyle = UIBlurEffect.Style.light
        //customPresenter.keyboardTranslationType = .moveUp
        //customPresenter.backgroundColor = .green
        customPresenter.backgroundOpacity = 0.5
        customPresenter.dismissOnSwipe = true
        customPresenter.dismissOnSwipeDirection = .bottom
        return customPresenter
    }()
    
    let exchangeSelectorPresenter: Presentr = {
        let customPresenter = Presentr(presentationType: .bottomHalf)
        customPresenter.transitionType = .coverVertical
        customPresenter.dismissTransitionType = .crossDissolve
        customPresenter.roundCorners = false
        //customPresenter.blurBackground = true
        customPresenter.blurStyle = UIBlurEffect.Style.light
        //customPresenter.keyboardTranslationType = .moveUp
        //customPresenter.backgroundColor = .green
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
    
    private var apps: [APIApp] = []
    
    private var loadingApps = false
    private var loadingBalance = false
    private var loadingDevice = false
    private var gettingPointPrice = false
    private var bindingWechat = false
    
    public var showWithdrawForm = false
    public var showChangeSelector = false
    
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var exchangeServiceProvider = MoyaProvider<TMMExchangeService>(plugins: [networkActivityPlugin, SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var tokenServiceProvider = MoyaProvider<TMMTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var redeemServiceProvider = MoyaProvider<TMMRedeemService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        tableView?.header?.removeObservers()
        tableView?.footer?.removeObservers()
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
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
            if !isValidatingBuild() {
                let exchangeRecordsBarItem = UIBarButtonItem(title: I18n.exchangeRecords.description, style: .plain, target: self, action: #selector(self.showExchangeRecordsView))
                navigationItem.rightBarButtonItem = exchangeRecordsBarItem
            }
        }
        withdrawButton.setTitle(I18n.pointsWithdraw.description, for: .normal)
        exchangeButton.setTitle(I18n.changePoints.description, for: .normal)
        miningAppsLabel.text = I18n.miningApps.description
        moreAppsButton.setTitle(I18n.moreApps.description, for: .normal)
        guard let _ = self.device else { return }
        setupSummaryView()
        SkeletonAppearance.default.multilineHeight = 10
        
        setupTableView()
        if userInfo != nil {
            refresh(false)
        }
        if showWithdrawForm {
            tryWithdraw()
        }
        if showChangeSelector {
            showExchangeSelector()
        }
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
        MTA.trackPageViewBegin(TMMConfigs.PageName.device)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.device)
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
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> DeviceAppsViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DeviceAppsViewController") as! DeviceAppsViewController
    }
    
    public func setDevice(_ device: APIDevice) {
        self.device = device
    }
    
    public func setTMMBalance(_ balance: NSDecimalNumber) {
        self.tmmBalance = balance
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
        
        if isValidatingBuild() {
            summaryContainerView.isHidden = true
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .center
            stackView.distribution = .fillProportionally
            stackView.spacing = 4
            summaryView.addSubview(stackView)
            stackView.snp.makeConstraints {[weak self] (maker) in
                maker.leading.top.equalToSuperview().offset(16)
                maker.trailing.equalToSuperview().offset(-16)
                guard let weakSelf = self else { return }
                maker.bottom.equalTo(weakSelf.summarySubContainerView.snp.top).offset(-8)
            }
            let nameLabel = UILabel()
            nameLabel.text = I18n.points.description
            nameLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light)
            nameLabel.textColor = .white
            stackView.addArrangedSubview(nameLabel)
            stackView.addArrangedSubview(pointsLabel)
            
            withdrawWrapper.isHidden = true
            tableHeaderView.snp.remakeConstraints {[weak self] (maker) in
                maker.leading.equalToSuperview().offset(20)
                maker.trailing.equalToSuperview().offset(-20)
                guard let weakSelf = self else { return }
                maker.top.equalTo(weakSelf.summaryView.snp.bottom).offset(16)
                maker.bottom.equalTo(weakSelf.tableView.snp.top).offset(-8)
            }
            miningAppsLabel.text = I18n.myApps.description
            moreAppsButton.isHidden = true
        }
        
        let tsImage = UIImage(named:"Timer")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        tsImageView.image = tsImage
        
        let flashImage = UIImage(named:"Flash")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        growthFactorImageView.image = flashImage
        
        updateSummaryView()
    }
    
    private func updateSummaryView() {
        guard let device = self.device else { return }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        pointsLabel.text = formatter.string(from: device.points)
        balanceLabel.text = formatter.string(from: self.tmmBalance)
        tsLabel.text = device.totalTs.timeSpan()
        
        let formatterGs = NumberFormatter()
        formatterGs.maximumFractionDigits = 2
        formatterGs.groupingSeparator = "";
        formatterGs.numberStyle = NumberFormatter.Style.decimal
        growthFactorLabel.text = formatterGs.string(from: device.growthFactor)
    }
    
    private func setupTableView() {
        tableView.register(cellType: DeviceAppTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh(true)
        }
        tableView.showAnimatedSkeleton()
    }
    
    private func refresh(_ refresh: Bool=false) {
        getApps()
        if refresh {
            refreshSummary()
        }
    }
    
    private func refreshSummary() {
        all(getBalance(), getDevice()).catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.updateSummaryView()
        })
    }
    
    @IBAction func showSDKApps() {
        let vc = SDKAppsTableViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func showExchangeRecordsView() {
        let vc = ExchangeRecordsViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func showExchangeSelector() {
        let vc = PointsTMMExchangeSelectorViewController()
        vc.delegate = self
        customPresentViewController(exchangeSelectorPresenter, viewController: vc, animated: true, completion: nil)
    }
}

extension DeviceAppsViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension DeviceAppsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.apps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DeviceAppTableViewCell
        let app = self.apps[indexPath.row]
        cell.fill(app)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingApps
    }
}

extension DeviceAppsViewController: SkeletonTableViewDataSource {
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return LoadingTableViewCell.self.reuseIdentifier
    }
}


extension DeviceAppsViewController {
    
    private func getApps() {
        if self.loadingApps { return }
        self.loadingApps = true
        
        guard let deviceId = self.device?.id else {return}
        
        TMMDeviceService.getApps(
            deviceId: deviceId,
            provider: self.deviceServiceProvider)
            .then(in: .main, {[weak self] apps in
                guard let weakSelf = self else { return }
                weakSelf.apps = apps
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingApps = false
                weakSelf.tableView.hideSkeleton()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
                let fromAnimation = AnimationType.from(direction: .right, offset: 30.0)
                UIView.animate(views: weakSelf.tableView.visibleCells, animations: [fromAnimation], completion:nil)
            }
        )
    }
    
    private func showExchangeForm(_ rate: APIExchangeRate, _ points: NSDecimalNumber, _ direction: APIExchangeDirection) {
        guard let device = self.device else { return }
        let vc = PointsTMMExchangeViewController(changeRate: rate, device: device, tmmBalance: self.tmmBalance, direction: direction)
        vc.delegate = self
        customPresentViewController(exchangePresenter, viewController: vc, animated: true, completion: nil)
    }
    
    private func getBalance() -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.loadingBalance {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.loadingBalance = true
            TMMTokenService.getTMMBalance(
                provider: weakSelf.tokenServiceProvider)
                .then(in: .main, {[weak weakSelf] token in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.tmmBalance = token.balance
                    resolve(())
                }).catch(in: .main, { error in
                    reject(error)
                }).always(in: .background, body: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.loadingBalance = false
                }
            )
        })
    }
    
    private func getDevice() -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.loadingDevice {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.loadingDevice = true
            guard let deviceId = weakSelf.device?.id else {
                reject(TMMAPIError.ignore)
                return
            }
            TMMDeviceService.getInfo(
                deviceId: deviceId,
                provider: weakSelf.deviceServiceProvider)
                .then(in: .background, {[weak weakSelf] device in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.device = device
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                }).always(in: .background, body: {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.loadingDevice = false
                }
            )
        })
    }
    
    @IBAction private func tryWithdraw() {
        withdrawButton.startAnimation()
        async({ _ -> APIExchangeRate in
            if !ShareSDK.hasAuthorized(.typeWechat) {
                let user = try ..self.authWechat()
                let _ = try ..self.doBindWechat(user: user)
            }
            let exchangeRate = try ..self.getPointPrice()
            return exchangeRate
        }).then(in: .main, {[weak self] exchangeRate in
            guard let weakSelf = self else { return }
            weakSelf.withdrawButton.stopAnimation(animationStyle: .normal, completion: {[weak weakSelf] in
                guard let weakSelf2 = weakSelf else { return }
                guard let deviceId = weakSelf2.device?.id else { return }
                let vc = TMMRedeemViewController(changeRate: exchangeRate)
                vc.redeemType = .point
                vc.deviceId = deviceId
                vc.delegate = weakSelf2
                weakSelf2.customPresentViewController(weakSelf2.exchangePresenter, viewController: vc, animated: true, completion: nil)
            })
        }).catch(in: .main, {[weak self] error in
            guard let weakSelf = self else { return }
            if let err = error as? TMMAPIError {
                switch err {
                case .ignore:
                    weakSelf.withdrawButton.stopAnimation(animationStyle: .shake, completion: nil)
                    return
                default: break
                }
            }
            weakSelf.withdrawButton.stopAnimation(animationStyle: .shake, completion: nil)
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.bindingWechat = false
            weakSelf.gettingPointPrice = false
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
    
    private func getPointPrice() -> Promise<APIExchangeRate> {
        return Promise<APIExchangeRate> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.gettingPointPrice {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.gettingPointPrice = true
            
            TMMRedeemService.getPointPrice(
                currency: Defaults[.currency] ?? Currency.USD.rawValue,
                provider: weakSelf.redeemServiceProvider)
                .then(in: .background, { rate  in
                    resolve(rate)
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
}

extension DeviceAppsViewController: TransactionDelegate {
    func newTransaction(tx: APITransaction) {
        guard let receipt = tx.receipt else { return }
        let _ = Haptic.notification(.success)
        Peep.play(sound: AlertTone.complete)
        self.delegate?.shouldRefresh()
        let message = String(format: I18n.newTransactionDesc.description, receipt)
        let alertController = AlertViewController(title: I18n.newTransactionTitle.description, body: message)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
        let okAction = AlertAction(title: I18n.viewTransaction.description, style: .destructive) {[weak self] in
            guard let weakSelf = self else { return }
            let urlString = "https://etherscan.io/tx/\(receipt)"
            guard let url = URL(string: urlString) else { return }
            let vc = TMMWebViewController.instantiate()
            vc.request = URLRequest(url: url)
            weakSelf.navigationController?.pushViewController(vc, animated: true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        customPresentViewController(alertPresenter, viewController: alertController, animated: true)
        self.refreshSummary()
    }
}

extension DeviceAppsViewController: RedeemDelegate {
    func redeemSuccess(resp: APITMMWithdraw) {
        let _ = Haptic.notification(.success)
        Peep.play(sound: AlertTone.complete)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let message = String(format: I18n.withdrawSuccessMsg.description, formatter.string(from: resp.tmm)!, I18n.points.description, formatter.string(from: resp.cash)!, resp.currency)
        let alertController = AlertViewController(title: I18n.newTransactionTitle.description, body: message)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        customPresentViewController(alertPresenter, viewController: alertController, animated: true)
    }
}

extension DeviceAppsViewController: PointsTMMExchangeSelectorDelegate {
    func exchangeDirectionSelected(rate: APIExchangeRate, direction: APIExchangeDirection) {
        guard let points = self.device?.points else { return }
        self.showExchangeForm(rate, points, direction)
    }
}

extension DeviceAppsViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh(true)
    }
}
