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
import FTPopOverMenu_Swift
import BTNavigationDropdownMenu

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
        ShareTasksTableViewController.instantiate(),
        AppTasksTableViewController.instantiate()
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
            navigationItem.title = I18n.earnPointsTasks.description
            let recordButtonItem = UIBarButtonItem(image: UIImage(named: "Records")?.kf.resize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(showTaskRecords))
            navigationItem.leftBarButtonItem = recordButtonItem
            let submitTaskButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTaskAction))
            navigationItem.rightBarButtonItem = submitTaskButtonItem
            
            let menuItems = [I18n.earnPointsTasks.description, I18n.publishedByMe.description]
            let menuView = BTNavigationDropdownMenu(title: BTTitle.index(0), items: menuItems)
            menuView.cellSelectionColor = UIColor(white: 0.91, alpha: 1)
            menuView.cellTextLabelFont = MainFont.light.with(size: 15)
            menuView.cellTextLabelColor = UIColor.darkText
            menuView.navigationBarTitleFont = MainFont.medium.with(size: 17)
            menuView.checkMarkImage = nil
            menuView.arrowTintColor = UIColor.darkText
            
            navigationItem.titleView = menuView
            menuView.didSelectItemAtIndexHandler = {[weak self] (indexPath: Int) -> () in
                guard let weakSelf = self else { return }
                let mineOnly = indexPath == 1
                for vc in weakSelf.viewControllers {
                    if vc.isMember(of: AppTasksTableViewController.self) {
                        (vc as? AppTasksTableViewController)?.mineOnly = mineOnly
                    } else if vc.isMember(of: ShareTasksTableViewController.self) {
                        (vc as? ShareTasksTableViewController)?.mineOnly = mineOnly
                    }
                }
            }
        }
        
        let configuration = FTConfiguration.shared
        configuration.menuWidth = 150.0
        
        // configure the bar
        self.bar.items = [
            Item(title: I18n.shareTasks.description),
            Item(title: I18n.appTasks.description)
        ]
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
    
    @objc func addTaskAction(_ sender: UIBarButtonItem, event: UIEvent) {
        FTPopOverMenu.showForEvent(event: event,
                                   with: [I18n.submitNewShareTask.description, I18n.submitNewAppTask.description],
                                   done: { [weak self] (selectedIndex) -> () in
                                    guard let weakSelf = self else { return }
                                    if selectedIndex == 0 {
                                        let vc = SubmitShareTaskTableViewController.instantiate()
                                        vc.delegate = weakSelf
                                        weakSelf.navigationController?.pushViewController(vc, animated: true)
                                    } else if selectedIndex == 1 {
                                        let vc = SubmitAppTaskTableViewController.instantiate()
                                        vc.delegate = weakSelf
                                        weakSelf.navigationController?.pushViewController(vc, animated: true)
                                    }
        }) {
            
        }
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

extension TasksViewController: ViewUpdateDelegate {
    func shouldRefresh() {
        if let vc = self.currentViewController {
            if vc.isMember(of: AppTasksTableViewController.self) {
                (vc as? AppTasksTableViewController)?.refresh()
            } else if vc.isMember(of: ShareTaskTableViewCell.self) {
                (vc as? ShareTasksTableViewController)?.refresh()
            }
        }
    }
}
