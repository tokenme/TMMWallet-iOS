//
//  ExchangeRecordsViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/16.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Tabman
import Pageboy

class ExchangeRecordsViewController: TabmanViewController {
    
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
    
    private let viewControllers = [
        ExchangeRecordsTableViewController.instantiate(),
        ExchangeRecordsTableViewController.instantiate(),
        ExchangeRecordsTableViewController.instantiate(),
    ]
    
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
            navigationItem.title = I18n.exchangeRecords.description
        }
        viewControllers[0].direction = .TMMIn
        viewControllers[1].direction = .TMMOut
        viewControllers[2].recordType = 1
        
        // configure the bar
        self.bar.items = [Item(title: "\(I18n.changeTo.description) TBC"),
                          Item(title: "\(I18n.changeTo.description) \(I18n.points.description)"),
                          Item(title: "\(I18n.changeTo.description) \(I18n.mobileData.description)")]
        self.bar.style = .scrollingButtonBar
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if userInfo == nil {
            let vc = LoginViewController.instantiate()
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    static func instantiate() -> ExchangeRecordsViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ExchangeRecordsViewController") as! ExchangeRecordsViewController
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension ExchangeRecordsViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension ExchangeRecordsViewController: PageboyViewControllerDataSource {
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

extension ExchangeRecordsViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        if let vc = self.currentViewController {
            if vc.isMember(of: ExchangeRecordsTableViewController.self) {
                (vc as? ExchangeRecordsTableViewController)?.refresh()
            }
        }
    }
}
