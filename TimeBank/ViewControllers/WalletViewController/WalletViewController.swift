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
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var loadingDevices = false
    private var loadingBalance = false
    
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
}

extension WalletViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension WalletViewController: UITableViewDelegate, UITableViewDataSource {
    
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
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as DeviceTableViewCell
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

public protocol ViewUpdateDelegate: NSObjectProtocol {
    func shouldRefresh()
}
