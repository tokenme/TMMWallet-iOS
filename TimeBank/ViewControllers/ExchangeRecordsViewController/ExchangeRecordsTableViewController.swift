//
//  ExchangeRecordsTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/17.
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
import EmptyDataSet_Swift
import Presentr

fileprivate let DefaultPageSize: UInt = 10

class ExchangeRecordsTableViewController: UITableViewController {
    
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
    public var direction: APIExchangeDirection = .TMMIn
    public var recordType: UInt8 = 0
    
    private var records: [APIExchangeRecord] = []
    private var cdpRecords: [APIRedeemCdpRecord] = []
    
    private var loadingRecords = false
    
    private var exchangeServiceProvider = MoyaProvider<TMMExchangeService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        tableView?.header?.removeObservers()
        tableView?.footer?.removeObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        if userInfo != nil {
            refresh()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.exchangeRecords)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.exchangeRecords)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> ExchangeRecordsTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ExchangeRecordsTableViewController") as! ExchangeRecordsTableViewController
    }
    
    private func setupTableView() {
        tableView.register(cellType: ExchangeRecordTableViewCell.self)
        tableView.register(cellType: RedeemCdpRecordTableViewCell.self)
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
            weakSelf.getRecords(false)
        }
        tableView.header?.isHidden = true
        tableView.footer?.isHidden = true
        
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    func refresh() {
        if recordType == 1 {
            getRedeemCdpRecords(true)
            return
        }
        getRecords(true)
    }
}

// MARK: - Table view data source
extension ExchangeRecordsTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if recordType == 1 {
            return self.cdpRecords.count
        }
        return records.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if recordType == 1 {
            let cell = tableView.dequeueReusableCell(for: indexPath) as RedeemCdpRecordTableViewCell
            let record = self.cdpRecords[indexPath.row]
            cell.fill(record)
            return cell
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as ExchangeRecordTableViewCell
        let record = self.records[indexPath.row]
        cell.fill(record)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if recordType == 1 { return }
        if self.records.count < indexPath.row + 1 { return }
        let record = self.records[indexPath.row]
        guard let receipt = record.tx else { return }
        let urlString = "https://etherscan.io/tx/\(receipt)"
        guard let url = URL(string: urlString) else { return }
        let vc = TMMWebViewController.instantiate()
        vc.request = URLRequest(url: url)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingRecords && recordType != 1
    }
}

extension ExchangeRecordsTableViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return self.records.count == 0
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.refresh()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyExchangeRecordsTitle.description)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyExchangeRecordsDesc.description)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return NSAttributedString(string: I18n.refresh.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:17), NSAttributedString.Key.foregroundColor:UIColor.primaryBlue])
    }
}

extension ExchangeRecordsTableViewController: SkeletonTableViewDataSource {
    
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

extension ExchangeRecordsTableViewController {
    
    private func getRecords(_ refresh: Bool) {
        if self.loadingRecords {
            return
        }
        self.loadingRecords = true
        
        if refresh {
            currentPage = 1
        }
        TMMExchangeService.getRecords(
            page: currentPage,
            pageSize: DefaultPageSize,
            direction: direction,
            provider: self.exchangeServiceProvider)
            .then(in: .main, {[weak self] records in
                guard let weakSelf = self else { return }
                if refresh {
                    weakSelf.records = records
                } else {
                    weakSelf.records.append(contentsOf: records)
                }
                if records.count < DefaultPageSize {
                    if weakSelf.records.count <= DefaultPageSize {
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
                weakSelf.loadingRecords = false
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
    
    private func getRedeemCdpRecords(_ refresh: Bool) {
        if self.loadingRecords {
            return
        }
        self.loadingRecords = true
        
        if refresh {
            currentPage = 1
        }
        TMMExchangeService.getRedeemCdpRecords(
            page: currentPage,
            pageSize: DefaultPageSize,
            provider: self.exchangeServiceProvider)
            .then(in: .main, {[weak self] records in
                guard let weakSelf = self else { return }
                if refresh {
                    weakSelf.cdpRecords = records
                } else {
                    weakSelf.cdpRecords.append(contentsOf: records)
                }
                if records.count < DefaultPageSize {
                    if weakSelf.cdpRecords.count <= DefaultPageSize {
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
                weakSelf.loadingRecords = false
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
