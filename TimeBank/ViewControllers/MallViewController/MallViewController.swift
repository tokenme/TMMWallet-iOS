//
//  MallViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import ZHRefresh
import Presentr
import SnapKit

fileprivate let DefaultPageSize: UInt = 10

class MallViewController: UIViewController {
    
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
    
    private var collectionView: UICollectionView!
    
    let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var currentPage: UInt = 1
    
    private var goods: [APIGood] = []
    
    private var loadingItems = false
    
    private var goodServiceProvider = MoyaProvider<TMMGoodService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    
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
            navigationItem.title = I18n.mall.description
            let myInvestBarItem = UIBarButtonItem(title: I18n.myInvest.description, style: .plain, target: self, action: #selector(self.showMyInvestView))
            navigationItem.rightBarButtonItem = myInvestBarItem
        }
        setupCollectionView()
        refresh()
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
        // Dispose of any resources that can be recreated.
    }
    
    static func instantiate() -> MallViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MallViewController") as! MallViewController
    }
    
    private func setupCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(cellType: GoodCollectionViewCell.self)
        collectionView.backgroundColor = UIColor(white: 0.98, alpha: 1)
        collectionView.contentInset = UIEdgeInsets(top: 4.0, left: 4.0, bottom: 4.0, right: 4.0)
        
        collectionView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        
        collectionView.footer = ZHRefreshAutoNormalFooter.footerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.getGoods(false)
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
    }
    
    func refresh() {
        getGoods(true)
    }
    
    @objc func showMyInvestView() {
        let vc = SDKAppsTableViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension MallViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension MallViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.goods.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
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
        let good = self.goods[indexPath.row]
        let vc = GoodViewController.instantiate()
        vc.setGood(good: good)
        if let cell = collectionView.cellForItem(at: indexPath) as? GoodCollectionViewCell {
            vc.shareImage = cell.cover.image
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension MallViewController {
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
                weakSelf.collectionView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
}
