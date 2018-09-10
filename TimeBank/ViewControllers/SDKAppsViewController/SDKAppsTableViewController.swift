//
//  SDKAppsTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import ZHRefresh
import SkeletonView
import ViewAnimator
import StoreKit

fileprivate let DefaultPageSize: UInt = 10

class SDKAppsTableViewController: UITableViewController {
    
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
    
    private var currentPage: UInt = 1
    
    private var apps: [APIApp] = []
    
    private var loadingApps = false
    private var presentingAppStore = false
    
    private var appServiceProvider = MoyaProvider<TMMAppService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
            //navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            //navigationController.navigationBar.shadowImage = UIImage()
            navigationItem.title = I18n.sdkApps.description
        }
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
    }
    
    private func setupTableView() {
        tableView.register(cellType: SDKAppTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        tableView.footer = ZHRefreshAutoNormalFooter.footerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.getApps(false)
        }
        tableView.footer?.isHidden = true
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    private func refresh() {
        getApps(true)
    }
}

extension SDKAppsTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension SDKAppsTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apps.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as SDKAppTableViewCell
        let app = self.apps[indexPath.row]
        cell.fill(app, installed: DetectApp.isInstalled(app.bundleId))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? SDKAppTableViewCell
        cell?.isSelected = false
        if self.apps.count < indexPath.row + 1 { return }
        let app = self.apps[indexPath.row]
        guard let storeId = app.storeId else {return}
        if DetectApp.isInstalled(app.bundleId) {
            return
        }
        showAppStore(storeId, cell: cell)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let app = self.apps[indexPath.row]
        guard let _ = app.storeId else {return false}
        if DetectApp.isInstalled(app.bundleId) {
            return false
        }
        return !self.loadingApps
    }
}

extension SDKAppsTableViewController: SkeletonTableViewDataSource {
    
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

extension SDKAppsTableViewController {
    
    private func showAppStore(_ storeId: UInt64, cell: SDKAppTableViewCell?) {
        if self.presentingAppStore { return }
        self.presentingAppStore = true
        cell?.startLoading()
        let storeVC = SKStoreProductViewController.init()
        storeVC.delegate = self
        storeVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: "\(storeId)"], completionBlock: {[weak self, weak cell] result, error in
            if let weakCell = cell {
                weakCell.endLoading()
            }
            guard let weakSelf = self else {return}
            if result {
                weakSelf.present(storeVC, animated: true, completion: nil)
            } else {
                weakSelf.presentingAppStore = false
                UCAlert.showAlert(imageName: "Error", title: I18n.error.description, desc: (error?.localizedDescription)!, closeBtn: I18n.close.description)
            }
        })
    }
    
    private func getApps(_ refresh: Bool) {
        if self.loadingApps {
            return
        }
        self.loadingApps = true
        
        if refresh {
            currentPage = 1
        }
        
        TMMAppService.getSdks(
            page: currentPage,
            pageSize: DefaultPageSize,
            provider: self.appServiceProvider)
            .then(in: .main, {[weak self] apps in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.apps = apps
                if apps.count < DefaultPageSize {
                    if weakSelf.apps.count <= DefaultPageSize {
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
                UCAlert.showAlert(imageName: "Error", title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                guard let weakSelf = self else { return }
                weakSelf.tableView.footer?.isHidden = false
                weakSelf.tableView.footer?.endRefreshing()
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
}

extension SDKAppsTableViewController: SKStoreProductViewControllerDelegate {
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.presentingAppStore = false
        })
    }
    
}

extension SDKAppsTableViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
