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
    
    @IBOutlet private weak var summaryView: PastelView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var pointsLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    
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
    
    private var loadingDevices = false
    private var loadingBalance = false
    private var unbindingDevice = false
    
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    private var tokenServiceProvider = MoyaProvider<TMMTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
            let ethWalletBarItem = UIBarButtonItem(title: I18n.ethWallet.description, style: .plain, target: self, action: #selector(self.showETHWalletView))
            navigationItem.rightBarButtonItem = ethWalletBarItem
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
        }
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
    }
    
    private func setupTableView() {
        tableView.register(cellType: DeviceTableViewCell.self)
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
        
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    public func refresh() {
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
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
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
        if orientation == .right {
            let sendAction = SwipeAction(style: .default, title: I18n.unbind.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                guard let deviceId = weakSelf.devices[indexPath.row].id else { return }
                let alertController = Presentr.alertViewController(title: I18n.alert.description, body: I18n.confirmUnbind.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
                    //
                }
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] alert in
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
        if self.currentDeviceIsBinded {
            return 0
        }
        return UnbindDeviceHeaderView.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.currentDeviceIsBinded {
            return nil
        }
        let view = UnbindDeviceHeaderView()
        view.delegate = self
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DeviceTableViewCell
        cell.delegate = self
        let device = self.devices[indexPath.row]
        cell.fill(device)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if self.devices.count < indexPath.row + 1 { return }
        let device = self.devices[indexPath.row]
        let vc = DeviceAppsViewController.instantiate()
        vc.setDevice(device)
        vc.setTMM(self.tmm)
        vc.delegate = self
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: device.name, style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingDevices
    }
}

extension WalletViewController: SkeletonTableViewDataSource {
    
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
        let alertController = Presentr.alertViewController(title: I18n.alert.description, body: qrcode)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
            //
        }
        let okAction = AlertAction(title: I18n.copy.description, style: .destructive) { alert in
            let paste = UIPasteboard.general
            paste.string = qrcode
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        customPresentViewController(alertPresenter, viewController: alertController, animated: true)
    }
}

public protocol ViewUpdateDelegate: NSObjectProtocol {
    func shouldRefresh()
}
