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
import MMPlayerView
import AVFoundation

fileprivate let DefaultPageSize: UInt = 10

class ShareTasksTableViewController: UITableViewController {
    
    var offsetObservation: NSKeyValueObservation?
    lazy var mmPlayerLayer: MMPlayerLayer = {
        let l = MMPlayerLayer()
        
        l.cacheType = .memory(count: 5)
        l.coverFitType = .fitToPlayerView
        l.videoGravity = AVLayerVideoGravity.resizeAspect
        l.replace(cover: CoverA.instantiateFromNib())
        return l
    }()
    
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
    
    public var mineOnly: Bool = false
    
    private var cid: UInt = 0
    private var isVideo: Bool = false
    private var currentPage: UInt = 1
    
    private var tasks: [APIShareTask] = []
    
    private var loadingTasks = false
    
    private var taskServiceProvider = MoyaProvider<TMMTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("ViewController deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*self.navigationController?.mmPlayerTransition.push.pass(setting: { (_) in
            
        })*/
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.updateByContentOffset()
            //self?.startLoading()
        }
        
        mmPlayerLayer.getStatusBlock { [weak self] (status) in
            guard let weakSelf = self else { return }
            switch status {
            case .failed(let err):
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: err.description, closeBtn: I18n.close.description)
                weakSelf.mmPlayerLayer.player?.pause()
            case .ready:
                #if DEBUG
                print("Ready to Play")
                #endif
            case .playing:
                #if DEBUG
                print("Playing")
                #endif
            case .pause:
                #if DEBUG
                print("Pause")
                #endif
            case .end:
                #if DEBUG
                print("End")
                #endif
            default: break
            }
        }
        setupTableView()
        if userInfo != nil {
            refresh()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        offsetObservation = tableView.observe(\.contentOffset, options: [.new]) { [weak self] (_, value) in
            guard let self = self, self.presentedViewController == nil else {return}
            self.updateByContentOffset()
            //self.perform(#selector(self.startLoading), with: nil, afterDelay: 0.3)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.mmPlayerLayer.player?.pause()
        offsetObservation?.invalidate()
        offsetObservation = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> ShareTasksTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShareTasksTableViewController") as! ShareTasksTableViewController
    }
    
    static func instantiate(cid: UInt, isVideo: Bool) -> ShareTasksTableViewController
    {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ShareTasksTableViewController") as! ShareTasksTableViewController
        vc.cid = cid
        vc.isVideo = isVideo
        return vc
    }
    
    private func setupTableView() {
        tableView.register(cellType: ShareTaskTableViewCell.self)
        tableView.register(cellType: ShareTaskSwipableTableViewCell.self)
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

extension ShareTasksTableViewController: MMPlayerFromProtocol {
    // when second controller pop or dismiss, this help to put player back to where you want
    // original was player last view ex. it will be nil because of this view on reuse view
    func backReplaceSuperView(original: UIView?) -> UIView? {
        return original
    }
    
    // add layer to temp view and pass to another controller
    var passPlayer: MMPlayerLayer {
        return self.mmPlayerLayer
    }
    // current playview is cell.image hide prevent ui error
    func transitionWillStart() {
        self.mmPlayerLayer.playView?.isHidden = true
    }
    // show cell.image
    func transitionCompleted() {
        self.mmPlayerLayer.playView?.isHidden = false
    }
    
    func dismissViewFromGesture() {
        mmPlayerLayer.thumbImageView.image = nil
        self.updateByContentOffset()
        //self.startLoading()
    }
    
    func presentedView(isShrinkVideo: Bool) {
        self.tableView.visibleCells.forEach {
            if let vc = $0 as? ShareTaskTableViewCell {
                if vc.coverView.isHidden == true && isShrinkVideo {
                    vc.coverView.isHidden = false
                }
            }
        }
    }
    
    fileprivate func updateByContentOffset() {
        let p = CGPoint(x: tableView.frame.width/2, y: tableView.contentOffset.y + tableView.frame.width/2)
        guard let path = tableView.indexPathForRow(at: p) else { return }
        if tasks.count <= path.row { return }
        let task = tasks[path.row]
        if task.isVideo == 1,
            self.presentedViewController == nil {
            self.updateCell(at: path)
            NSObject.cancelPreviousPerformRequests(withTarget: self)
            self.perform(#selector(self.startLoading), with: nil, afterDelay: 0.3)
        } else if task.isVideo == 0 {
            self.mmPlayerLayer.player?.pause()
        }
    }
    
    fileprivate func updateVideoDetail(at indexPath: IndexPath) {
        let task = tasks[indexPath.row]
        guard let detail = self.presentedViewController as? VideoDetailViewController,
            let videoLink = URL(string:task.videoLink) else { return }
        detail.data = task
        if let img = task.image {
            KingfisherManager.shared.retrieveImage(with: URL(string: img)!, options: nil, progressBlock: nil, completionHandler:{[weak self](_ image: UIImage?, _ error: NSError?, _ cacheType: CacheType?, _ url: URL?) in
                guard let weakSelf = self else {return}
                if image != nil {
                    weakSelf.mmPlayerLayer.thumbImageView.image = image
                }
            })
        }
        self.mmPlayerLayer.set(url: videoLink)
        self.mmPlayerLayer.resume()
    }
    
    fileprivate func presentVideoDetail(at indexPath: IndexPath) {
        self.updateCell(at: indexPath)
        let vc = VideoDetailViewController.instantiate()
        vc.data = tasks[indexPath.row]
        vc.modalPresentationCapturesStatusBarAppearance = true
        self.present(vc, animated: true, completion: {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.mmPlayerLayer.resume()
        })
    }
    
    fileprivate func updateCell(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ShareTaskTableViewCell else { return }
        if tasks.count <= indexPath.row { return }
        let task = tasks[indexPath.row]
        if task.isVideo == 1 {
            // this thumb use when transition start and your video dosent start
            mmPlayerLayer.thumbImageView.image = cell.coverView.image
            // set video where to play
            if !MMLandscapeWindow.shared.isKeyWindow {
                mmPlayerLayer.playView = cell.coverView
            }
            mmPlayerLayer.set(url: URL(string: task.videoLink))
        } else {
            mmPlayerLayer.player?.pause()
        }
    }
    
    @objc fileprivate func startLoading() {
        if self.presentedViewController != nil {
            return
        }
        // start loading video
        mmPlayerLayer.resume()
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
        var showStats: Bool = false
        if mineOnly, let _ = task.creator {
            showStats = true
        }
        
        if mineOnly {
            let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskSwipableTableViewCell
            cell.delegate = self
            cell.fill(task, showStats: showStats)
            return cell
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as ShareTaskTableViewCell
        cell.fill(task, showStats: showStats)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.tasks.count < indexPath.row + 1 { return }
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        let task = tasks[indexPath.row]
        if task.isVideo == 1 {
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else { return }
                if weakSelf.presentedViewController != nil {
                    tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: true)
                    weakSelf.updateVideoDetail(at: indexPath)
                } else {
                    weakSelf.presentVideoDetail(at: indexPath)
                }
            }
            return
        }
        if let imageURL = task.image {
            KingfisherManager.shared.retrieveImage(with: URL(string: imageURL)!, options: nil, progressBlock: nil, completionHandler:{[weak self](_ image: UIImage?, _ error: NSError?, _ cacheType: CacheType?, _ url: URL?) in
                guard let weakSelf = self else {return}
                var shareItem: TMMShareItem?
                if image != nil {
                    let img = image?.kf.resize(to: CGSize(width: 500, height: 500), for: .aspectFit)
                    shareItem = TMMShareItem(id: task.id, title: task.title, description: task.summary, image: img, link: URL(string:task.shareLink), task: task)
                } else {
                    shareItem = TMMShareItem(id: task.id, title: task.title, description: task.summary, image: nil, link: URL(string:task.shareLink), task: task)
                }
                weakSelf.presentWebVC(task.link, shareItem)
            })
        } else {
            let shareItem = TMMShareItem(id: task.id, title: task.title, description: task.summary, image: nil, link: URL(string:task.shareLink), task: task)
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
            let alertController = AlertViewController(title: I18n.alert.description, body: I18n.confirmCancelTask.description)
            let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler:nil)
            let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] in
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
                let alertController = AlertViewController(title: I18n.alert.description, body: I18n.confirmStopTask.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler:nil)
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] in
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
                let alertController = AlertViewController(title: I18n.alert.description, body: I18n.confirmStartTask.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] in
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
            cid: cid,
            isVideo: isVideo,
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
