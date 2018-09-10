//
//  AppTasksTableViewController.swift
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
import TMMSDK
import SwiftWebVC
import Kingfisher
import StoreKit
import EmptyDataSet_Swift

fileprivate let DefaultPageSize: UInt = 10

class AppTasksTableViewController: UITableViewController {
    
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
    
    private var tasks: [APIAppTask] = []
    
    private var loadingTasks = false
    private var presentingAppStore = false
    
    private var taskServiceProvider = MoyaProvider<TMMTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        if userInfo != nil {
            refresh()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> AppTasksTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AppTasksTableViewController") as! AppTasksTableViewController
    }
    
    private func setupTableView() {
        tableView.register(cellType: AppTaskTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        
        tableView.footer = ZHRefreshAutoNormalFooter.footerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.getTasks(false)
        }
        tableView.header?.isHidden = true
        tableView.footer?.isHidden = true
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    func refresh() {
        getTasks(true)
    }
}

// MARK: - Table view data source
extension AppTasksTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as AppTaskTableViewCell
        let task = self.tasks[indexPath.row]
        cell.fill(task, installed: DetectApp.isInstalled(task.bundleId))
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? AppTaskTableViewCell
        cell?.isSelected = false
        if self.tasks.count < indexPath.row + 1 { return }
        let task = self.tasks[indexPath.row]
        showAppStore(task, cell: cell)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let task = self.tasks[indexPath.row]
        guard let _ = task.storeId else {return false}
        if DetectApp.isInstalled(task.bundleId) {
            return false
        }
        return !self.loadingTasks
    }
}

extension AppTasksTableViewController: SkeletonTableViewDataSource {
    
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

extension AppTasksTableViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return self.tasks.count == 0
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyAppTasksTitle.description)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyAppTasksDesc.description)
    }
}

extension AppTasksTableViewController {
    
    private func showAppStore(_ task: APIAppTask, cell: AppTaskTableViewCell?) {
        guard let storeId = task.storeId else {return}
        if self.presentingAppStore { return }
        self.presentingAppStore = true
        cell?.startLoading()
        let storeVC = SKStoreProductViewController.init()
        storeVC.delegate = self
        storeVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: "\(storeId)"], completionBlock: {[weak self, weak cell, weak task] result, error in
            if let weakCell = cell {
                weakCell.endLoading()
            }
            guard let weakSelf = self else {return}
            if result {
                weakSelf.present(storeVC, animated: true, completion: nil)
                guard let weakTask = task else {return}
                weakSelf.preInstall(weakTask)
            } else {
                weakSelf.presentingAppStore = false
                UCAlert.showAlert(imageName: "Error", title: I18n.error.description, desc: (error?.localizedDescription)!, closeBtn: I18n.close.description)
            }
        })
    }
    
    private func preInstall(_ task: APIAppTask) {
        guard let taskId = task.id else {return}
        TMMTaskService.appInstall(
            idfa: TMMBeacon.shareInstance().deviceId(),
            bundleId: task.bundleId,
            taskId: taskId,
            status: 0,
            provider: self.taskServiceProvider)
            .then(in: .background, { task in
                AppTaskChecker.sharedInstance.addTask(task)
            }).catch(in: .main, {error in
                UCAlert.showAlert(imageName: "Error", title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            })
    }
    
    private func getTasks(_ refresh: Bool) {
        if self.loadingTasks {
            return
        }
        self.loadingTasks = true
        
        if refresh {
            currentPage = 1
        }
        
        TMMTaskService.getApps(
            idfa: TMMBeacon.shareInstance().deviceId(),
            page: currentPage,
            pageSize: DefaultPageSize,
            provider: self.taskServiceProvider)
            .then(in: .main, {[weak self] tasks in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.tasks = tasks
                if tasks.count < DefaultPageSize {
                    if weakSelf.tasks.count <= DefaultPageSize {
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
                weakSelf.loadingTasks = false
                weakSelf.tableView.header?.isHidden = false
                weakSelf.tableView.hideSkeleton()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
                let zoomAnimation = AnimationType.zoom(scale: 0.2)
                UIView.animate(views: weakSelf.tableView.visibleCells, animations: [zoomAnimation], completion:nil)
            }
        )
    }
}

extension AppTasksTableViewController: SKStoreProductViewControllerDelegate {
    
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.presentingAppStore = false
        })
    }
    
}

