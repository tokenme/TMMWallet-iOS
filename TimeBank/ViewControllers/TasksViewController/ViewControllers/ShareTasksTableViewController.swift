//
//  ShareTasksTableViewController.swift
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
import Kingfisher
import EmptyDataSet_Swift
import Presentr
import SwipeCellKit

fileprivate let DefaultPageSize: UInt = 10

class ShareTasksTableViewController: UITableViewController {
    
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
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    public var mineOnly: Bool = false {
        didSet {
            self.refresh()
        }
    }
    
    private var currentPage: UInt = 1
    
    private var tasks: [APIShareTask] = []
    
    private var loadingTasks = false
    
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
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> ShareTasksTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShareTasksTableViewController") as! ShareTasksTableViewController
    }
    
    private func setupTableView() {
        tableView.register(cellType: ShareTaskTableViewCell.self)
        tableView.register(cellType: ShareTaskStatsTableViewCell.self)
        tableView.register(cellType: ShareTaskNoImageTableViewCell.self)
        tableView.register(cellType: ShareTaskNoImageStatsTableViewCell.self)
        tableView.register(cellType: LoadingShareTaskTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 88.0
        tableView.rowHeight = UITableView.automaticDimension
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
    
    public func refresh() {
        getTasks(true)
    }
}

// MARK: - Table view data source
extension ShareTasksTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = self.tasks[indexPath.row]
        if task.image != nil {
            if let creator = task.creator {
                if creator > 0 && creator == userInfo?.id {
                    let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskStatsTableViewCell
                    cell.delegate = self
                    cell.fill(task)
                    return cell
                }
            }
            let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskTableViewCell
            cell.delegate = self
            cell.fill(task)
            return cell
        }
        if let creator = task.creator {
            if creator > 0 && creator == userInfo?.id {
                let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskNoImageStatsTableViewCell
                cell.delegate = self
                cell.fill(task)
                return cell
            }
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskNoImageTableViewCell
        cell.delegate = self
        cell.fill(task)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.tasks.count < indexPath.row + 1 { return }
        let cell = tableView.cellForRow(at: indexPath) as? ShareTaskTableViewCell
        cell?.isSelected = false
        let task = tasks[indexPath.row]
        if let imageURL = task.image {
            KingfisherManager.shared.retrieveImage(with: URL(string: imageURL)!, options: nil, progressBlock: nil, completionHandler:{[weak self](_ image: UIImage?, _ error: NSError?, _ cacheType: CacheType?, _ url: URL?) in
                guard let weakSelf = self else {return}
                var shareItem: TMMShareItem?
                if image != nil {
                    let img = image?.kf.resize(to: CGSize(width: 500, height: 500), for: .aspectFit)
                    shareItem = TMMShareItem(title: task.title, description: task.summary, image: img, link: URL(string:task.shareLink))
                } else {
                    shareItem = TMMShareItem(title: task.title, description: task.summary, image: nil, link: URL(string:task.shareLink))
                }
                weakSelf.presentWebVC(task.link, shareItem)
            })
        } else {
            let shareItem = TMMShareItem(title: task.title, description: task.summary, image: nil, link: URL(string:task.shareLink))
            presentWebVC(task.link, shareItem)
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingTasks
    }
    
    private func presentWebVC(_ urlString: String, _ shareItem: TMMShareItem?) {
        guard let url = URL(string: urlString) else { return }
        let vc = TMMWebViewController.instantiate()
        vc.request = URLRequest(url: url)
        vc.shareItem = shareItem
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension ShareTasksTableViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let task = self.tasks[indexPath.row]
        guard let taskId = task.id else { return nil }
        guard let creator = task.creator else { return nil }
        guard let userId = self.userInfo?.id else { return nil }
        if userId != creator {
            return nil
        }
        if task.onlineStatus == .canceled {
            return nil
        }
        
        if orientation == .right {
            let editAction = SwipeAction(style: .default, title: I18n.edit.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                let vc = SubmitShareTaskTableViewController.instantiate()
                vc.task = task
                vc.delegate = weakSelf
                weakSelf.navigationController?.pushViewController(vc, animated: true)
            }
            editAction.backgroundColor = UIColor.primaryBlue
            
            return [editAction]
        }
        
        let cancelAction = SwipeAction(style: .default, title: I18n.cancel.description) {[weak self] action, indexPath in
            guard let weakSelf = self else { return }
            let alertController = Presentr.alertViewController(title: I18n.alert.description, body: I18n.confirmCancelTask.description)
            let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
                //
            }
            let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] alert in
                guard let weakSelf2 = weakSelf else { return }
                weakSelf2.runUpdateTaskStatus(taskId, .canceled)
            }
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
        }
        cancelAction.backgroundColor = UIColor.red
        var actions: [SwipeAction] = [cancelAction]
        if task.onlineStatus == .running {
            let stopAction = SwipeAction(style: .default, title: I18n.stop.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                let alertController = Presentr.alertViewController(title: I18n.alert.description, body: I18n.confirmStopTask.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
                    //
                }
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] alert in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.runUpdateTaskStatus(taskId, .stopped)
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
            }
            stopAction.backgroundColor = UIColor.orange
            actions.append(stopAction)
        } else {
            let startAction = SwipeAction(style: .default, title: I18n.start.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                let alertController = Presentr.alertViewController(title: I18n.alert.description, body: I18n.confirmStartTask.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
                    //
                }
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] alert in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.runUpdateTaskStatus(taskId, .running)
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
            }
            startAction.backgroundColor = UIColor.greenGrass
            actions.append(startAction)
        }
        return actions
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        return options
    }
}

extension ShareTasksTableViewController: SkeletonTableViewDataSource {
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return LoadingShareTaskTableViewCell.self.reuseIdentifier
    }
}

extension ShareTasksTableViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return self.tasks.count == 0
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.refresh()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyShareTasksTitle.description)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyShareTasksDesc.description)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return NSAttributedString(string: I18n.refresh.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:17), NSAttributedString.Key.foregroundColor:UIColor.primaryBlue])
    }
}

extension ShareTasksTableViewController {
    
    private func runUpdateTaskStatus(_ taskId: UInt64, _ onlineStatus: APITaskOnlineStatus) {
        TMMTaskService.updateShareTask(
            id: taskId,
            link: "",
            title: "",
            summary: "",
            image: "",
            points: 0,
            bonus: 0,
            maxViewers: 0,
            onlineStatus: onlineStatus,
            provider: self.taskServiceProvider)
        .then(in: .main, {[weak self] task in
            guard let weakSelf = self else { return }
            for task in weakSelf.tasks {
                if task.id == taskId {
                    task.onlineStatus = onlineStatus
                    break
                }
            }
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        }).catch(in: .main, {[weak self] error in
            guard let weakSelf = self else { return }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
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
        
        TMMTaskService.getShares(
            idfa: TMMBeacon.shareInstance().deviceId(),
            page: currentPage,
            pageSize: DefaultPageSize,
            mineOnly: self.mineOnly,
            provider: self.taskServiceProvider)
            .then(in: .main, {[weak self] tasks in
                guard let weakSelf = self else { return }
                if refresh {
                    weakSelf.tasks = tasks
                } else {
                    weakSelf.tasks.append(contentsOf: tasks)
                }
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
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                weakSelf.tableView.footer?.isHidden = false
                weakSelf.tableView.footer?.endRefreshing()
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingTasks = false
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
}

extension ShareTasksTableViewController: ViewUpdateDelegate {
    func shouldRefresh() {
        self.refresh()
    }
}
