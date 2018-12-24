//
//  MallViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import Tabman
import Pageboy
import Presentr

class MallViewController: TabmanViewController {
    
    let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var viewControllers: [UIViewController] = []
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
            if !isValidatingBuild() {
                let myInvestBarItem = UIBarButtonItem(title: I18n.myInvest.description, style: .plain, target: self, action: #selector(self.showMyInvestView))
                navigationItem.rightBarButtonItem = myInvestBarItem
            }
        }
        
        if isValidatingBuild() {
            self.viewControllers = [
                GoodsViewController.instantiate(collectionType: .cdp)
            ]
            self.bar.items = [
                Item(title: I18n.redeemMobileData.description)
            ]
        } else {
            self.viewControllers = [
                GoodsViewController.instantiate(collectionType: .invest),
                GoodsViewController.instantiate(collectionType: .cdp)
            ]
            self.bar.items = [
                Item(title: I18n.investGoods.description),
                Item(title: I18n.redeemMobileData.description)
            ]
        }
        self.bar.style = .buttonBar
        self.automaticallyAdjustsChildViewInsets = true
        self.dataSource = self
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
    
    @objc func showMyInvestView() {
        let vc = MyInvestsViewController.instantiate()
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

extension MallViewController: PageboyViewControllerDataSource {
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return viewControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController,
                        at index: PageboyViewController.PageIndex) -> UIViewController? {
        return viewControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
}
