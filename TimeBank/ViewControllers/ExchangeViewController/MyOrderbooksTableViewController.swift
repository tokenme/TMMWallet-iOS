//
//  MyOrderbooksTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import ZHRefresh
import SkeletonView
import ViewAnimator
import EmptyDataSet_Swift
import Presentr
import SwipeCellKit

fileprivate let DefaultPageSize: UInt = 10

class MyOrderbooksTableViewController: UITableViewController {
    
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
    
    public var side: APIOrderBookSide = .ask
    
    private var currentPage: UInt = 1
    
    private var orders: [APIOrderBook] = []
    
    private var loadingOrders = false
    
    private var cancellingOrder = false
    
    private var orderbookServiceProvider = MoyaProvider<TMMOrderBookService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
            navigationItem.title = I18n.myOrderbooks.description
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.header?.removeObservers()
        tableView.footer?.removeObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> MyOrderbooksTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MyOrderbooksTableViewController") as! MyOrderbooksTableViewController
    }
    
    private func setupTableView() {
        tableView.register(cellType: OrderbookTableViewCell.self)
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
            weakSelf.getOrders(false)
        }
        tableView.header?.isHidden = true
        tableView.footer?.isHidden = true
        
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    func refresh() {
        getOrders(true)
    }
    
}

extension MyOrderbooksTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

// MARK: - Table view data source
extension MyOrderbooksTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let order = self.orders[indexPath.row]
        let cell = tableView.dequeueReusableCell(for: indexPath) as OrderbookTableViewCell
        cell.delegate = self
        cell.fill(order)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension MyOrderbooksTableViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return self.orders.count == 0
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.refresh()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyOrderbookTitle.description)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyOrderbookDesc.description)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return NSAttributedString(string: I18n.refresh.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:17), NSAttributedString.Key.foregroundColor:UIColor.primaryBlue])
    }
}

extension MyOrderbooksTableViewController: SkeletonTableViewDataSource {
    
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

extension MyOrderbooksTableViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let order = self.orders[indexPath.row]
        if order.onlineStatus != .pending {
            return nil
        }
        if orientation == .right {
            let sendAction = SwipeAction(style: .default, title: I18n.cancel.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                guard let tradeId = weakSelf.orders[indexPath.row].id else { return }
                let alertController = AlertViewController(title: I18n.alert.description, body: I18n.confirmCancelOrder.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.runCancelOrder(tradeId)
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

extension MyOrderbooksTableViewController {
    
    private func runCancelOrder(_ tradeId: UInt64) {
        self.cancelOrder(id: tradeId).then(in: .main, {[weak self] _ in
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
            weakSelf.cancellingOrder = false
        })
    }
    
    private func getOrders(_ refresh: Bool) {
        if self.loadingOrders {
            return
        }
        self.loadingOrders = true
        
        if refresh {
            currentPage = 1
        }
        
        TMMOrderBookService.getOrders(
            page: currentPage,
            pageSize: DefaultPageSize,
            side: side,
            provider: self.orderbookServiceProvider)
            .then(in: .main, {[weak self] orders in
                guard let weakSelf = self else {
                    return
                }
                if refresh {
                    weakSelf.orders = orders
                } else {
                    weakSelf.orders.append(contentsOf: orders)
                }
                if orders.count < DefaultPageSize {
                    if weakSelf.orders.count <= DefaultPageSize {
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
                weakSelf.loadingOrders = false
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
    
    private func cancelOrder(id: UInt64) -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.cancellingOrder {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.cancellingOrder = true
            TMMOrderBookService.cancelOrder(
                id: id,
                provider: weakSelf.orderbookServiceProvider)
                .then(in: .background, {_ in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
}
