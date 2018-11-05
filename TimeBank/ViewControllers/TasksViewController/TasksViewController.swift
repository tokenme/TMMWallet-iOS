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
import BTNavigationDropdownMenu
import DropDown
import Presentr

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
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private let viewControllers = [
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.suggest.rawValue),
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.sociaty.rawValue),
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.finance.rawValue),
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.funny.rawValue),
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.entertainment.rawValue),
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.technology.rawValue),
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.fashion.rawValue),
        ShareTasksTableViewController.instantiate(cid: APIArticleCategory.blockchain.rawValue),
        BlowupViewController.instantiate()
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
            navigationItem.title = I18n.discover.description
            let recordButtonItem = UIBarButtonItem(image: UIImage(named: "Records")?.kf.resize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), style: .plain, target: self, action: #selector(showTaskRecords))
            navigationItem.leftBarButtonItem = recordButtonItem
            let submitTaskButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTaskAction))
            navigationItem.rightBarButtonItem = submitTaskButtonItem
            
            let menuItems = [I18n.discover.description, I18n.publishedByMe.description]
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
                if mineOnly {
                    let vc = ShareTasksTableViewController.instantiate()
                    vc.mineOnly = mineOnly
                    weakSelf.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        
        // configure the bar
        self.bar.items = [
            Item(title: APIArticleCategory.suggest.description),
            Item(title: APIArticleCategory.sociaty.description),
            Item(title: APIArticleCategory.finance.description),
            Item(title: APIArticleCategory.funny.description),
            Item(title: APIArticleCategory.entertainment.description),
            Item(title: APIArticleCategory.technology.description),
            Item(title: APIArticleCategory.fashion.description),
            Item(title: APIArticleCategory.blockchain.description),
            Item(title: I18n.blowupGame.description)
        ]
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
        let vc = SubmitShareTaskTableViewController.instantiate()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
        return
        let dropDown = DropDown()
        dropDown.anchorView = sender
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.plainView.bounds.height)
        dropDown.dataSource = [I18n.submitNewShareTask.description, I18n.submitNewAppTask.description]
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
            guard let weakSelf = self else { return }
            if index == 0 {
                let vc = SubmitShareTaskTableViewController.instantiate()
                vc.delegate = weakSelf
                weakSelf.navigationController?.pushViewController(vc, animated: true)
            } else if index == 1 {
                /*
                let vc = SubmitAppTaskTableViewController.instantiate()
                vc.delegate = weakSelf
                weakSelf.navigationController?.pushViewController(vc, animated: true)
                */
                let alertController = Presentr.alertViewController(title: I18n.alert.description, body: I18n.submitAppTaskNotAvailable.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
                    //
                }
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] alert in
                    guard let weakSelf2 = weakSelf else { return }
                    let vc = FeedbackTableViewController.instantiate()
                    weakSelf2.navigationController?.pushViewController(vc, animated: true)
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
            }
        }
        dropDown.show()
        DropDown.startListeningToKeyboard()
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
