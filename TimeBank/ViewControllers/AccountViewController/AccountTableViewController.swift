//
//  AccountTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/18.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import Kingfisher
import Presentr

class AccountTableViewController: UITableViewController {

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
    
    @IBOutlet private weak var avatarImageView : UIImageView!
    @IBOutlet private weak var mobileLabel: UILabel!
    
    @IBOutlet private weak var myInviteCodeLabel: UILabel!
    @IBOutlet private weak var inviteCodeLabel: UILabel!
    @IBOutlet private weak var inviteCodeTextField: UITextField!
    @IBOutlet private weak var telegramGroupLabel: UILabel!
    @IBOutlet private weak var wechatGroupLabel: UILabel!
    @IBOutlet private weak var feedbackLabel: UILabel!
    @IBOutlet private weak var signOutLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationItem.title = I18n.account.description
        }
        setupTableView()
        guard let userInfo = self.userInfo else { return }
        mobileLabel.text = "+\(userInfo.countryCode!)\(userInfo.mobile!)"
        if let avatar = userInfo.avatar {
            avatarImageView.layer.cornerRadius = 20.0
            avatarImageView.layer.borderWidth = 0.0
            avatarImageView.clipsToBounds = true
            avatarImageView.kf.setImage(with: URL(string: avatar))
        }
        myInviteCodeLabel.text = I18n.myInviteCode.description
        inviteCodeLabel.text = I18n.inviteCode.description
        inviteCodeTextField.placeholder = I18n.inviteCodePlaceholder.description
        telegramGroupLabel.text = I18n.telegramGroup.description
        wechatGroupLabel.text = I18n.wechatGroup.description
        feedbackLabel.text = I18n.feedback.description
        signOutLabel.text = I18n.signout.description
        
        let versionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30))
        let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionLabel.text = "\(I18n.currentVersion.description): \(currentVersion)"
        versionLabel.textAlignment = .center
        versionLabel.textColor = UIColor.lightGray
        versionLabel.font = MainFont.light.with(size: 12)
        tableView.tableFooterView = versionLabel
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupTableView() {
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: CGFloat.leastNormalMagnitude))
    }
    
    public func refresh() {
        self.tableView.reloadDataWithAutoSizingCellWorkAround()
    }
    
}

extension AccountTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension AccountTableViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
