//
//  TasksViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/3.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Tabman
import Pageboy

class TasksViewController: TabmanViewController {
    
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
        AppTasksTableViewController.instantiate(),
        ShareTasksTableViewController.instantiate()
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
            navigationController.navigationBar.isTranslucent = true
            //navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            //navigationController.navigationBar.shadowImage = UIImage()
            navigationItem.title = I18n.earnPointsTasks.description
            let recordButtonItem = UIBarButtonItem(title: I18n.taskRecords.description, style: .plain, target: self, action: #selector(showTaskRecords))
            navigationItem.rightBarButtonItem = recordButtonItem
        }
        
        // configure the bar
        self.bar.items = [Item(title: I18n.appTasks.description),
                          Item(title: I18n.shareTasks.description)]
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
            navigationController.navigationBar.isTranslucent = true
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func showTaskRecords() {
        let vc = TaskRecordsTableViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

extension TasksViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension TasksViewController: PageboyViewControllerDataSource {
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

extension TasksViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        if let vc = self.currentViewController {
            if vc.isMember(of: AppTasksTableViewController.self) {
                (vc as? AppTasksTableViewController)?.refresh()
            } else if vc.isMember(of: ShareTaskTableViewCell.self) {
                (vc as? ShareTasksTableViewController)?.refresh()
            }
        }
    }
}
