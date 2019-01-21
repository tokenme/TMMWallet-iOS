//
//  GoodsViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/19.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import EmptyDataSet_Swift
import Moya
import Hydra
import ZHRefresh
import Presentr
import SkeletonView
import SnapKit

fileprivate let DefaultPageSize: UInt = 10

public enum GoodType {
    case invest
    case cdp
}

class GoodsViewController: UIViewController {
    
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
    
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 4.0
        layout.minimumInteritemSpacing = 2.0
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        let screenWidth = UIScreen.main.bounds.width
        layout.itemSize = CGSize(width: (screenWidth-12)*0.5, height: (screenWidth-12)*0.5)
        return layout
    }()
    
    public var collectionType: GoodType = .invest
    
    private var collectionView: UICollectionView!
    
    let deviceSelectorPresenter: Presentr = {
        let customPresenter = Presentr(presentationType: .bottomHalf)
        customPresenter.transitionType = .coverVertical
        customPresenter.dismissTransitionType = .crossDissolve
        customPresenter.roundCorners = false
        //customPresenter.blurBackground = true
        customPresenter.blurStyle = UIBlurEffect.Style.light
        //customPresenter.keyboardTranslationType = .moveUp
        //customPresenter.backgroundColor = .green
        customPresenter.backgroundOpacity = 0.5
        customPresenter.dismissOnSwipe = true
        customPresenter.dismissOnSwipeDirection = .bottom
        return customPresenter
    }()
    
    let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var currentPage: UInt = 1
    
    private var devices: [APIDevice] = []
    private var goods: [APIGood] = []
    private var cdps: [APIRedeemCdp] = []
    
    private var loadingDevices = false
    private var loadingItems = false
    private var loadingRedeemCdps = false
    private var selectedCdpOffer: APIRedeemCdp?
    
    private var goodServiceProvider = MoyaProvider<TMMGoodService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var redeemServiceProvider = MoyaProvider<TMMRedeemService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.mall)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.mall)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> GoodsViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GoodsViewController") as! GoodsViewController
    }
    
    static func instantiate(collectionType: GoodType) -> GoodsViewController
    {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GoodsViewController") as! GoodsViewController
        vc.collectionType = collectionType
        return vc
    }
    
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: GoodCollectionViewCell.self)
        collectionView.register(cellType: CdpCollectionViewCell.self)
        collectionView.register(cellType: GoodLoadingCollectionViewCell.self)
        collectionView.backgroundColor = UIColor(white: 0.98, alpha: 1)
        collectionView.contentInset = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        
        collectionView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        
        if collectionType != .cdp {
            collectionView.footer = ZHRefreshAutoNormalFooter.footerWithRefreshing { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.getGoods(false)
            }
        }
        collectionView.header?.isHidden = true
        collectionView.footer?.isHidden = true
        
        self.view.addSubview(collectionView)
        collectionView.snp.remakeConstraints { (maker) -> Void in
            maker.leading.equalToSuperview()
            maker.trailing.equalToSuperview()
            maker.top.equalTo(topLayoutGuide.snp.bottom)
            maker.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        SkeletonAppearance.default.multilineHeight = 10
        collectionView.prepareSkeleton { [weak self] (done) in
            if let visibleCells = self?.collectionView.visibleCells {
                for cell in visibleCells {
                    cell.contentView.showAnimatedSkeleton()
                }
            }
        }
        collectionView.showAnimatedSkeleton()
    }
    
    func refresh() {
        if collectionType == .cdp {
            getRedeemCdps()
        } else {
            getGoods(true)
        }
    }
    
    @objc func showMyInvestView() {
        let vc = MyInvestsViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func showRedeemCdpSelector() {
        if self.devices.count == 1 {
            showDeviceRedeemCdp(device: self.devices[0])
        }
        let vc = DevicesViewController()
        vc.selectorDelegate = self
        vc.selectAction = .redeemCdp
        vc.devices = self.devices
        customPresentViewController(deviceSelectorPresenter, viewController: vc, animated: true)
    }
}

extension GoodsViewController: SkeletonCollectionViewDataSource {
    
    func numSections(in collectionSkeletonView: UICollectionView) -> Int {
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return GoodLoadingCollectionViewCell.self.reuseIdentifier
    }
}

extension GoodsViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionType == .cdp {
            return self.cdps.count
        }
        return self.goods.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.collectionType == GoodType.cdp {
            let cell = collectionView.dequeueReusableCell(for: indexPath) as CdpCollectionViewCell
            let cdp = self.cdps[indexPath.row]
            cell.fill(cdp)
            return cell
        }
        let cell = collectionView.dequeueReusableCell(for: indexPath) as GoodCollectionViewCell
        let good = self.goods[indexPath.row]
        cell.fill(good)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionType == .cdp {
            self.selectedCdpOffer = self.cdps[indexPath.row]
            showRedeemCdpSelector()
            return
        }
        let good = self.goods[indexPath.row]
        let vc = GoodViewController.instantiate()
        vc.setGood(good: good)
        if let cell = collectionView.cellForItem(at: indexPath) as? GoodCollectionViewCell {
            vc.shareImage = cell.cover.image
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension GoodsViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        if collectionType == .cdp {
            return self.cdps.count == 0
        }
        return self.goods.count == 0
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.refresh()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "怎么没有商品？")
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "稍后刷新试试吧！")
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return NSAttributedString(string: I18n.refresh.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:17), NSAttributedString.Key.foregroundColor:UIColor.primaryBlue])
    }
}

extension GoodsViewController {
    private func getGoods(_ refresh: Bool) {
        if self.loadingItems { return }
        self.loadingItems = true
        
        if refresh {
            currentPage = 1
        }
        TMMGoodService.getList(
            page: currentPage,
            pageSize: DefaultPageSize,
            provider: self.goodServiceProvider)
            .then(in: .main, {[weak self] goods in
                guard let weakSelf = self else { return }
                if refresh {
                    weakSelf.goods = goods
                } else {
                    weakSelf.goods.append(contentsOf: goods)
                }
                if goods.count < DefaultPageSize {
                    if weakSelf.goods.count <= DefaultPageSize {
                        weakSelf.collectionView.footer?.isHidden = true
                    } else {
                        weakSelf.collectionView.footer?.isHidden = false
                        weakSelf.collectionView.footer?.endRefreshingWithNoMoreData()
                    }
                } else {
                    weakSelf.collectionView.footer?.isHidden = false
                    weakSelf.collectionView.footer?.endRefreshing()
                    weakSelf.currentPage += 1
                }
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                weakSelf.collectionView.footer?.isHidden = false
                weakSelf.collectionView.footer?.endRefreshing()
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingItems = false
                weakSelf.collectionView.header?.isHidden = false
                weakSelf.collectionView.header?.endRefreshing()
                weakSelf.collectionView.hideSkeleton()
                weakSelf.collectionView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
    
    private func getRedeemCdps() {
        if self.loadingRedeemCdps { return }
        self.loadingRedeemCdps = true
        
        TMMRedeemService.getCdps(
            provider: self.redeemServiceProvider)
            .then(in: .main, {[weak self] cdps in
                guard let weakSelf = self else { return }
                weakSelf.cdps = cdps
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingRedeemCdps = false
                weakSelf.collectionView.header?.isHidden = false
                weakSelf.collectionView.header?.endRefreshing()
                weakSelf.collectionView.hideSkeleton()
                weakSelf.collectionView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
    
    private func cdpOrderAdd(deviceId: String, offer: APIRedeemCdp) {
        TMMRedeemService.addCdpOrder(
            offerId: offer.offerId ?? 0,
            deviceId: deviceId,
            provider: self.redeemServiceProvider)
            .then(in: .main, {[weak self] resp in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: "Redeem Success", closeBtn: I18n.close.description)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.selectedCdpOffer = nil
            }
        )
    }
}

extension GoodsViewController: DeviceSelectorDelegate {
    func selected(device: APIDevice, selectAction: DeviceSelectAction) {
        if selectAction == .redeemCdp {
            self.showDeviceRedeemCdp(device: device)
        }
    }
    
    private func showDeviceRedeemCdp(device: APIDevice) {
        guard let deviceId = device.id else { return }
        guard let cdpOffer = selectedCdpOffer else { return }
        if device.points < cdpOffer.points {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.notEnoughPointsError.description, closeBtn: I18n.close.description)
            return
        }
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = .floor
        let msg = String(format: I18n.confirmRedeemPointsCdp.description, arguments: [formatter.string(from: cdpOffer.points)!, cdpOffer.grade!])
        let alertController = AlertViewController(title: I18n.alert.description, body: msg)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
        let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.cdpOrderAdd(deviceId: deviceId, offer: cdpOffer)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.customPresentViewController(self.alertPresenter, viewController: alertController, animated: true)
    }
}

