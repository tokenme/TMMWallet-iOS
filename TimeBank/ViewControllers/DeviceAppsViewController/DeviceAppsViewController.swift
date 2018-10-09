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
    
    private var tmm: APIToken?
    
    @IBOutlet private weak var summaryView: PastelView!
    @IBOutlet private weak var exchangeTMMButton: TransitionButton!
    @IBOutlet private weak var exchangePointButton: TransitionButton!
    @IBOutlet private weak var miningAppsLabel: UILabel!
    @IBOutlet private weak var moreAppsButton: UIButton!
    @IBOutlet private weak var redeemTitleLabel: UILabel!
    @IBOutlet private weak var redeemLoader: UIActivityIndicatorView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var tsLabel: UILabel!
    @IBOutlet private weak var growthFactorLabel: UILabel!
    @IBOutlet private weak var tsImageView: UIImageView!
    @IBOutlet private weak var growthFactorImageView: UIImageView!
    
    let exchangePresenter: Presentr = {
        let width = ModalSize.full
        let height = ModalSize.fluid(percentage: 0.70)
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
    
    let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var apps: [APIApp] = []
    
    private var cdps: [APIRedeemCdp] = []
    
    private var loadingApps = false
    private var gettingTmmExchangeRate = false
    private var loadingBalance = false
    private var loadingDevice = false
    private var loadingRedeemCdps = false
    private var makingCdpOfferId: UInt64 = 0
    
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var exchangeServiceProvider = MoyaProvider<TMMExchangeService>(plugins: [networkActivityPlugin])
    private var tokenServiceProvider = MoyaProvider<TMMTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var redeemServiceProvider = MoyaProvider<TMMRedeemService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
            let exchangeRecordsBarItem = UIBarButtonItem(title: I18n.exchangeRecords.description, style: .plain, target: self, action: #selector(self.showExchangeRecordsView))
            navigationItem.rightBarButtonItem = exchangeRecordsBarItem
        }
        exchangeTMMButton.setTitle(I18n.exchangeTMM.description, for: .normal)
        exchangePointButton.setTitle(I18n.exchangePoint.description, for: .normal)
        miningAppsLabel.text = I18n.miningApps.description
        moreAppsButton.setTitle(I18n.moreApps.description, for: .normal)
        redeemTitleLabel.text = I18n.redeemCdp.description
        guard let _ = self.device else { return }
        setupSummaryView()
        SkeletonAppearance.default.multilineHeight = 10
        
        setupCollectionView()
        setupTableView()
        if userInfo != nil {
            refresh(false)
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
        if userInfo != nil {
            getRedeemCdps()
        }
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
    
    public func setTMM(_ token: APIToken?) {
        self.tmm = token
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
        balanceLabel.text = formatter.string(from: tmm?.balance ?? 0)
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
    
    private func setupCollectionView() {
        collectionView.register(cellType: RedeemCdpCollectionViewCell.self)
        collectionView.backgroundColor = UIColor.white
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
    
    @IBAction func showExchangeTMM() {
        exchangeTMMButton.startAnimation()
        getTmmExchangeRate(direction: .TMMIn)
    }
    
    @IBAction func showExchangePoint() {
        exchangePointButton.startAnimation()
        getTmmExchangeRate(direction: .TMMOut)
    }
    
    @IBAction func showSDKApps() {
        let vc = SDKAppsTableViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func showExchangeRecordsView() {
        let vc = ExchangeRecordsViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
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

extension DeviceAppsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.cdps.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath) as RedeemCdpCollectionViewCell
        let cdp = self.cdps[indexPath.row]
        cell.fill(cdp)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cdp = self.cdps[indexPath.row]
        guard let offerId = cdp.offerId else { return }
        let cell = collectionView.dequeueReusableCell(for: indexPath) as RedeemCdpCollectionViewCell
        cell.isSelected = false
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let msg = String(format: I18n.confirmRedeemPointsCdp.description, arguments: [formatter.string(from: cdp.points)!, cdp.grade!])
        let alertController = Presentr.alertViewController(title: I18n.alert.description, body: msg)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
            //
        }
        let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak self] alert in
            guard let weakSelf = self else { return }
            weakSelf.cdpOrderAdd(offerId: offerId)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.customPresentViewController(self.alertPresenter, viewController: alertController, animated: true)
    }
    
}


extension DeviceAppsViewController {
    
    private func getApps() {
        if self.loadingApps {
            return
        }
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
    
    private func getTmmExchangeRate(direction: APIExchangeDirection) {
        if self.gettingTmmExchangeRate {
            return
        }
        self.gettingTmmExchangeRate = true
        TMMExchangeService.getTMMRate(
            provider: self.exchangeServiceProvider)
            .then(in: .main, {[weak self] rate in
                guard let weakSelf = self else { return }
                guard let points = weakSelf.device?.points else { return }
                weakSelf.showExchangeForm(rate, points, direction)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingTmmExchangeRate = false
                if direction == .TMMIn {
                    weakSelf.exchangeTMMButton.stopAnimation(animationStyle: .normal, completion: nil)
                } else {
                    weakSelf.exchangePointButton.stopAnimation(animationStyle: .normal, completion: nil)
                }
            }
        )
    }
    
    private func showExchangeForm(_ rate: APIExchangeRate, _ points: NSDecimalNumber, _ direction: APIExchangeDirection) {
        guard let device = self.device else { return }
        let vc = PointsTMMExchangeViewController(changeRate: rate, device: device, direction: direction)
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
                    weakSelf2.tmm = token
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
    
    private func getRedeemCdps() {
        if self.loadingRedeemCdps {
            return
        }
        self.loadingRedeemCdps = true
        
        TMMRedeemService.getCdps(
            provider: self.redeemServiceProvider)
            .then(in: .main, {[weak self] cdps in
                guard let weakSelf = self else { return }
                weakSelf.cdps = cdps
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingRedeemCdps = false
                weakSelf.redeemLoader.isHidden = true
                weakSelf.collectionView.reloadData()
                weakSelf.collectionView.header?.endRefreshing()
                let fromAnimation = AnimationType.from(direction: .bottom, offset: 30.0)
                UIView.animate(views: weakSelf.collectionView.visibleCells, animations: [fromAnimation], completion:nil)
            }
        )
    }
    
    private func cdpOrderAdd(offerId: UInt64) {
        guard let deviceId = self.device?.id else { return }
        if self.makingCdpOfferId > 0 {
            return
        }
        self.makingCdpOfferId = offerId
        TMMRedeemService.addCdpOrder(
            offerId: offerId,
            deviceId: deviceId,
            provider: self.redeemServiceProvider)
            .then(in: .main, {[weak self] resp in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: "Redeem Success", closeBtn: I18n.close.description)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.makingCdpOfferId = 0
            }
        )
    }
}

extension DeviceAppsViewController: TransactionDelegate {
    func newTransaction(tx: APITransaction) {
        guard let receipt = tx.receipt else { return }
        self.delegate?.shouldRefresh()
        let message = I18n.newTransactionDesc.description.replacingOccurrences(of: "#receipt#", with: receipt)
        let alertController = Presentr.alertViewController(title: I18n.newTransactionTitle.description, body: message)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
            //
        }
        let okAction = AlertAction(title: I18n.viewTransaction.description, style: .destructive) {[weak self] alert in
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

extension DeviceAppsViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh(true)
        self.getRedeemCdps()
    }
}
