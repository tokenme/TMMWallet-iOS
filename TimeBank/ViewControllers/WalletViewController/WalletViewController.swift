//
//  WalletViewController.swift
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
import TMMSDK
import SwipeCellKit
import SwiftRater
import FlexibleSteppedProgressBar

fileprivate enum SectionType {
    case tools
    case devices
}

class WalletViewController: UIViewController {
    
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
    
    private var todayRewarded: Bool {
        get {
            if let lastRewardDate: Date = Defaults[.lastDailyBonus] {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                return dateFormatter.string(from: lastRewardDate) == dateFormatter.string(from: Date())
            }
            return false
        }
    }
    
    private var todayInviteSumaryAlerted: Bool {
        get {
            if let lastDate: Date = Defaults[.lastDailyInviteSummary] {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                return dateFormatter.string(from: lastDate) == dateFormatter.string(from: Date())
            }
            return false
        }
    }
    
    @IBOutlet private weak var summaryView: PastelView!
    @IBOutlet private weak var dailyBonusProgressBar: FlexibleSteppedProgressBar!
    @IBOutlet private weak var dailyBonusButton: TransitionButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var chestButton: UIButton!
    
    private let dailyInviteSummaryAlertViewController = DailyInviteSummaryAlertViewController()
    
    private var devices: [APIDevice] = [] {
        didSet {
            var totalPoints: NSDecimalNumber = 0
            for device in devices {
                totalPoints += device.points
            }
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            pointsLabel.text = formatter.string(from: totalPoints)
        }
    }
    
    private var tmm: APIToken? {
        didSet {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            balanceLabel.text = formatter.string(from: tmm?.balance ?? 0)
        }
    }
    
    private var currentDeviceIsBinded: Bool {
        get {
            if self.loadingDevices {
                return true
            }
            guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else {
                return false
            }
            for device in self.devices {
                if device.idfa == deviceId {
                    return true
                }
            }
            return false
        }
    }
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private let inviteSummaryPresenter: Presentr = {
        let presenter = Presentr(presentationType: .fullScreen)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var loadingDevices = false
    private var loadingBalance = false
    private var unbindingDevice = false
    private var gettingDailyBonusStatus = false
    private var committingDailyBonus = false
    private var gettingDailyInviteSummary = false
    
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var tokenServiceProvider = MoyaProvider<TMMTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var bonusServiceProvider = MoyaProvider<TMMBonusService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
            if !isValidatingBuild() {
                let ethWalletBarItem = UIBarButtonItem(title: I18n.ethWallet.description, style: .plain, target: self, action: #selector(self.showETHWalletView))
                navigationItem.rightBarButtonItem = ethWalletBarItem
            } else {
                chestButton.isHidden = true
            }
            let scanBarItem = UIBarButtonItem(image: UIImage(named: "Scan"), style: .plain, target: self, action: #selector(self.showScanView))
            navigationItem.leftBarButtonItem = scanBarItem
        }
        setupSummaryView()
        setupTableView()
        if userInfo != nil {
            refresh()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.wallet)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if userInfo == nil {
            let vc = LoginViewController.instantiate()
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        } else if !todayInviteSumaryAlerted {
            getDailyInviteSummary()
        }
        SwiftRater.check()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.wallet)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        if todayRewarded {
            dailyBonusButton.setTitle(I18n.dailyRewarded.description, for: .normal)
        } else {
            dailyBonusButton.setTitle(I18n.dailyReward.description, for: .normal)
        }
        dailyBonusProgressBar.numberOfPoints = 7
        dailyBonusProgressBar.radius = 5
        dailyBonusProgressBar.lineHeight = 3
        dailyBonusProgressBar.progressRadius = 5
        dailyBonusProgressBar.progressLineHeight = 3
        dailyBonusProgressBar.currentSelectedCenterColor = UIColor.primaryBlue
        dailyBonusProgressBar.selectedBackgoundColor = UIColor.greenGrass
        dailyBonusProgressBar.selectedOuterCircleStrokeColor = UIColor.white
        dailyBonusProgressBar.textDistance = 6.0
        dailyBonusProgressBar.stepTextFont = UIFont.systemFont(ofSize: 10)
        dailyBonusProgressBar.stepTextColor = UIColor.lightGray
        dailyBonusProgressBar.currentSelectedTextColor = UIColor.darkGray
        dailyBonusProgressBar.delegate = self
    }
    
    private func setupTableView() {
        tableView.register(cellType: IndexToolsTableViewCell.self)
        tableView.register(cellType: DeviceTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        tableView.register(cellType: AdTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    public func refresh() {
        getDailyBonusStatus()
        getDevices()
        getBalance()
    }
    
    @IBAction func showETHWalletView() {
        let vc = ETHWalletViewController.instantiate()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func showScanView() {
        let vc = ScanViewController()
        vc.scanDelegate = self
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func showChestView() {
        let vc = ChestTableViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension WalletViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension WalletViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if !isValidatingBuild() && indexPath.section == 0 {
            return nil
        }
        let device = self.devices[indexPath.row]
        if device.creative != nil {
            return nil
        }
        if orientation == .right {
            let sendAction = SwipeAction(style: .default, title: I18n.unbind.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                guard let deviceId = weakSelf.devices[indexPath.row].id else { return }
                let alertController = AlertViewController(title: I18n.alert.description, body: I18n.confirmUnbind.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.runUnbindDevice(deviceId)
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
                
            }
            sendAction.backgroundColor = UIColor.red
            sendAction.textColor = UIColor.white
            
            return [sendAction]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        return options
    }
}

extension WalletViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if !isValidatingBuild() && section == 0 || self.currentDeviceIsBinded {
            return 0
        }
        return UnbindDeviceHeaderView.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !isValidatingBuild() && section == 0 || self.currentDeviceIsBinded {
            return nil
        }
        let view = UnbindDeviceHeaderView()
        view.delegate = self
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return isValidatingBuild() ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isValidatingBuild() && section == 0 {
            return 1
        }
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !isValidatingBuild() && indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(for: indexPath) as IndexToolsTableViewCell
            cell.delegate = self
            cell.show()
            return cell
        }
        let device = self.devices[indexPath.row]
        if let creative = device.creative {
            let cell = tableView.dequeueReusableCell(for: indexPath) as AdTableViewCell
            cell.fill(creative, fullFill: true)
            return cell
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as DeviceTableViewCell
        cell.delegate = self
        cell.fill(device)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if !isValidatingBuild() && indexPath.section == 0 { return }
        if self.devices.count < indexPath.row + 1 { return }
        let device = self.devices[indexPath.row]
        
        if let creative = device.creative {
            if let link = URL(string:creative.link) {
                let vc = TMMWebViewController.instantiate()
                vc.request = URLRequest(url: link)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return
        }
        
        let vc = DeviceAppsViewController.instantiate()
        vc.setDevice(device)
        vc.setTMM(self.tmm)
        vc.delegate = self
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: device.name, style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let isValidating = isValidatingBuild()
        return (isValidating || !isValidating && indexPath.section == 1) && !self.loadingDevices
    }
}

extension WalletViewController: SkeletonTableViewDataSource {
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return isValidatingBuild() ? 1 : 2
    }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !isValidatingBuild() && section == 0 { return 0 }
        return 5
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return LoadingTableViewCell.self.reuseIdentifier
    }
}

extension WalletViewController {
    
    private func runUnbindDevice(_ deviceId: String) {
        self.unbindDevice(id: deviceId).then(in: .main, {[weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }).catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return  }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.unbindingDevice = false
        })
    }
    
    private func getDevices() {
        if self.loadingDevices {
            return
        }
        self.loadingDevices = true
        TMMDeviceService.getDevices(
            provider: self.deviceServiceProvider)
            .then(in: .main, {[weak self] devices in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.devices = devices
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.loadingDevices = false
                weakSelf.tableView.hideSkeleton()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
                let fromAnimation = AnimationType.from(direction: .right, offset: 30.0)
                UIView.animate(views: weakSelf.tableView.visibleCells, animations: [fromAnimation], completion:nil)
            }
        )
    }
    
    private func getBalance() {
        if self.loadingBalance {
            return
        }
        self.loadingBalance = true
        TMMTokenService.getTMMBalance(
            provider: self.tokenServiceProvider)
            .then(in: .main, {[weak self] token in
                guard let weakSelf = self else { return }
                weakSelf.tmm = token
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingBalance = false
            }
        )
    }
    
    private func unbindDevice(id: String) -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.unbindingDevice {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.unbindingDevice = true
            TMMDeviceService.unbindUser(
                id: id,
                provider: weakSelf.deviceServiceProvider)
                .then(in: .background, {user in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
    
    private func getDailyBonusStatus() {
        if self.gettingDailyBonusStatus {
            return
        }
        self.gettingDailyBonusStatus = true
        TMMBonusService.getDailyStatus(
            provider: self.bonusServiceProvider)
            .then(in: .main, {[weak self] status in
                guard let weakSelf = self else { return }
                var days: Int = 0
                if status.days > 0 {
                    days = status.days-1
                }
                weakSelf.dailyBonusProgressBar.currentIndex = days
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingDailyBonusStatus = false
            }
        )
    }
    
    private func getDailyInviteSummary() {
        if self.gettingDailyInviteSummary { return }
        self.gettingDailyInviteSummary = true
        TMMUserService.getDailyInviteSummary(
            currency: Defaults[.currency] ?? Currency.USD.rawValue,
            provider: self.userServiceProvider)
            .then(in: .main, {[weak self] summary in
                guard let weakSelf = self else { return }
                Defaults[.lastDailyInviteSummary] = Date()
                if summary.contribute == 0 {
                    return
                }
                weakSelf.dailyInviteSummaryAlertViewController.summary = summary
                weakSelf.dailyInviteSummaryAlertViewController.delegate = self
                weakSelf.customPresentViewController(weakSelf.inviteSummaryPresenter, viewController: weakSelf.dailyInviteSummaryAlertViewController, animated: true)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingDailyInviteSummary = false
            }
        )
    }
    
    @IBAction private func commitDailyBonus() {
        guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else { return }
        if self.committingDailyBonus {
            return
        }
        self.committingDailyBonus = true
        dailyBonusButton.startAnimation()
        TMMBonusService.commitDailyBonus(
            deviceId: deviceId,
            provider: self.bonusServiceProvider)
            .then(in: .main, {[weak self] status in
                guard let weakSelf = self else { return }
                if status.days > 0 {
                    weakSelf.dailyBonusProgressBar.currentIndex = status.days - 1
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 4
                    formatter.groupingSeparator = "";
                    formatter.numberStyle = NumberFormatter.Style.decimal
                    let pointsStr = formatter.string(from: status.points)!
                    let interestsStr = formatter.string(from: status.interests)!
                    let msg: String = String(format: I18n.dailyBonusSuccessMsg.description, pointsStr, interestsStr)
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: msg, closeBtn: I18n.close.description)
                }
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.committingDailyBonus = false
                weakSelf.dailyBonusButton.stopAnimation(animationStyle: .normal, completion: nil)
            }
        )
    }
}

extension WalletViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}

extension WalletViewController: ViewUpdateDelegate {
    func shouldRefresh() {
        self.refresh()
    }
}

extension WalletViewController: ScanViewDelegate {
    func collectHandler(_ qrcode: String) {
        if qrcode.hasPrefix("ethereum:") {
            let data: String = qrcode.replacingOccurrences(of: "ethereum:", with: "")
            let components = data.split(separator: "?")
            let wallet = components[0]
            var result = QRCodeResult(String(wallet))
            if components.count == 2 {
                let args = components[1].split(separator: "&")
                for arg in args {
                    let splitted = arg.split(separator: "=")
                    if splitted.count != 2 {
                        continue
                    }
                    let key = splitted[0]
                    let val = splitted[1]
                    switch key {
                    case "contractAddress":
                        result.setContractAddress(String(val))
                    case "decimals":
                        if let decimals = Int8(val) {
                            result.setDecimals(decimals)
                        }
                    default:
                        continue
                    }
                }
            }
            if result.contractAddress == nil || result.contractAddress == "" {
                result.setContractAddress("0x")
            }
            let vc = TransferTableViewController.instantiate()
            vc.setQrcodeResult(result)
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
        let alertController = AlertViewController(title: I18n.alert.description, body: qrcode)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
        let okAction = AlertAction(title: I18n.copy.description, style: .destructive) {
            let paste = UIPasteboard.general
            paste.string = qrcode
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        customPresentViewController(alertPresenter, viewController: alertController, animated: true)
    }
}

extension WalletViewController: FlexibleSteppedProgressBarDelegate {
    func progressBar(_ progressBar: FlexibleSteppedProgressBar,
                     canSelectItemAtIndex index: Int) -> Bool {
        return false
    }
    
    func progressBar(_ progressBar: FlexibleSteppedProgressBar,
                     textAtIndex index: Int, position: FlexibleSteppedProgressBarTextLocation) -> String {
        if position == FlexibleSteppedProgressBarTextLocation.bottom {
            return String(format: I18n.xDay.description, index + 1)
        }
        return ""
    }
}

extension WalletViewController: IndexToolsDelegate {
    func gotoShareTasksView(_ index: Int) {
        self.tabBarController?.selectedIndex = 1
    }
    
    func gotoInviteView() {
        let vc = InviteViewController.instantiate()
        self.present(vc, animated: true, completion: nil)
    }
    
    func gotoMallView() {
        self.tabBarController?.selectedIndex = 2
    }
    
    func gotoHelpView() {
        let vc = TMMWebViewController.instantiate()
        vc.request = URLRequest(url: URL(string: TMMConfigs.helpLink)!)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func gotoETHWallet() {
        self.showETHWalletView()
    }
    
    func gotoExchangeRecordsView() {
        let vc = ExchangeRecordsViewController.instantiate()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func gotoWithdraw() {
        guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else { return }
        for device in self.devices {
            if device.idfa == deviceId {
                let vc = DeviceAppsViewController.instantiate()
                vc.setDevice(device)
                vc.setTMM(self.tmm)
                vc.delegate = self
                vc.showWithdrawForm = true
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: device.name, style: .plain, target: nil, action: nil)
                self.navigationController?.pushViewController(vc, animated: true)
                break
            }
        }
    }
    
    func gotoMyInvites() {
        let vc = MyInvitesTableViewController.instantiate()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension WalletViewController: DailyInviteSummaryAlertDelegate {
    func gotoInviteSummaryPage() {
        let vc = MyInvitesTableViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

public protocol ViewUpdateDelegate: NSObjectProtocol {
    func shouldRefresh()
}
