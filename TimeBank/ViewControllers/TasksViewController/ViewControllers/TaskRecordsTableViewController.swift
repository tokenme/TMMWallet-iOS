//
//  TaskRecordsTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/6.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import ZHRefresh
import SkeletonView
import ViewAnimator
import Kingfisher
import EmptyDataSet_Swift
import Presentr

fileprivate let DefaultPageSize: UInt = 10

class TaskRecordsTableViewController: UITableViewController {
    
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
    
    private var currentPage: UInt = 1
    
    private var tasks: [APITaskRecord] = []
    
    private var loadingTasks = false
    
    private var taskServiceProvider = MoyaProvider<TMMTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
            navigationItem.title = I18n.taskRecords.description
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
            navigationController.navigationBar.isTranslucent = false
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> TaskRecordsTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TaskRecordsTableViewController") as! TaskRecordsTableViewController
    }
    
    private func setupTableView() {
        tableView.register(cellType: AppTaskRecordTableViewCell.self)
        tableView.register(cellType: ShareTaskRecordTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 66.0
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
    
    func refresh() {
        getTasks(true)
    }
}

extension TaskRecordsTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

// MARK: - Table view data source
extension TaskRecordsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let task = self.tasks[indexPath.row]
        if task.type == .app {
            let cell = tableView.dequeueReusableCell(for: indexPath) as AppTaskRecordTableViewCell
            cell.fill(task)
            return cell
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskRecordTableViewCell
        cell.fill(task)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingTasks
    }
}

extension TaskRecordsTableViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return self.tasks.count == 0
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyTaskRecordsTitle.description)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyTaskRecordsDesc.description)
    }
}

extension TaskRecordsTableViewController: SkeletonTableViewDataSource {
    
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

extension TaskRecordsTableViewController {
    
    private func getTasks(_ refresh: Bool) {
        if self.loadingTasks {
            return
        }
        self.loadingTasks = true
        
        if refresh {
            currentPage = 1
        }
        
        TMMTaskService.getRecords(
            page: currentPage,
            pageSize: DefaultPageSize,
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
