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
import SwiftWebVC
import Kingfisher
import EmptyDataSet_Swift
import Presentr

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
        tableView.register(cellType: LoadingShareTaskTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.estimatedRowHeight = 125.0
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
        let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskTableViewCell
        let task = self.tasks[indexPath.row]
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
                var shareItem: SwiftWebVCShareItem?
                if image != nil {
                    let img = image?.kf.resize(to: CGSize(width: 500, height: 500), for: .aspectFit)
                    shareItem = SwiftWebVCShareItem(title: task.title, image: img, link: URL(string:task.shareLink))
                } else {
                    shareItem = SwiftWebVCShareItem(title: task.title, image: nil, link: URL(string:task.shareLink))
                }
                weakSelf.presentWebVC(task.link, shareItem)
            })
        } else {
            let shareItem = SwiftWebVCShareItem(title: task.title, image: nil, link: URL(string:task.shareLink))
            presentWebVC(task.link, shareItem)
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingTasks
    }
    
    private func presentWebVC(_ urlString: String, _ shareItem: SwiftWebVCShareItem?) {
        let webVC = SwiftModalWebVC(urlString: urlString, shareItem: shareItem)
        self.present(webVC, animated: true, completion: nil)
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
        return false
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyShareTasksTitle.description)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyShareTasksDesc.description)
    }
}

extension ShareTasksTableViewController {
    
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
