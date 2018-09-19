//
//  SubmitAppTaskTableViewController.swift
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
import TMMSDK

class SubmitAppTaskTableViewController: UITableViewController {

    weak public var delegate: ViewUpdateDelegate?
    
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
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var bundleIdTextField: UITextField!
    @IBOutlet private weak var rewardLabel: UILabel!
    @IBOutlet private weak var rewardTextField: UITextField!
    @IBOutlet private weak var totalPointsLabel: UILabel!
    @IBOutlet private weak var totalPointsTextField: UITextField!
    
    private var submitButton: TransitionButton = TransitionButton(type: .custom)
    
    private var isSubmitting: Bool = false
    
    private var taskServiceProvider = MoyaProvider<TMMTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = true
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
            navigationItem.title = I18n.submitNewAppTask.description
        }
        setupTableView()
        nameLabel.text = I18n.appName.description
        rewardLabel.text = I18n.rewardPerInstall.description
        totalPointsLabel.text = I18n.totalReward.description
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
    
    static func instantiate() -> SubmitAppTaskTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SubmitAppTaskTableViewController") as! SubmitAppTaskTableViewController
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupTableView() {
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        
        submitButton.setTitle(I18n.submitTask.description, for: .normal)
        submitButton.backgroundColor = UIColor.primaryBlue
        submitButton.disabledBackgroundColor = UIColor.lightGray
        submitButton.spinnerColor = UIColor.white
        submitButton.tintColor = UIColor.white
        submitButton.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 40)
        
        submitButton.addTarget(self, action: #selector(submit), for: .touchUpInside)
        tableView.tableFooterView = submitButton
    }
    
}

extension SubmitAppTaskTableViewController {
    @objc func submit() {
        if isSubmitting {
            return
        }
        isSubmitting = true
        guard let name = nameTextField.text else {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing name", closeBtn: I18n.close.description)
            return
        }
        guard let bundleId = bundleIdTextField.text else {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing bundleId", closeBtn: I18n.close.description)
            return
        }
        let points = NSDecimalNumber(string: totalPointsTextField.text)
        if points < 0 {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing points", closeBtn: I18n.close.description)
            return
        }
        let bonus = NSDecimalNumber(string: rewardTextField.text)
        if bonus < 0 {
            UCAlert.showAlert(alertPresenter, title: I18n.error.description, desc: "missing bonus", closeBtn: I18n.close.description)
            return
        }
        submitButton.startAnimation()
        TMMTaskService.addAppTask(
            name: name,
            bundleId: bundleId,
            points: points,
            bonus: bonus,
            provider: self.taskServiceProvider)
            .then(in: .main, {[weak self] task in
                guard let weakSelf = self else { return }
                weakSelf.submitButton.stopAnimation(animationStyle: .expand, completion: {
                    weakSelf.delegate?.shouldRefresh()
                    weakSelf.navigationController?.popViewController(animated: true)
                })
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                weakSelf.submitButton.stopAnimation(animationStyle: .shake, completion: {
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                })
            }).always(in: .main,  body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isSubmitting = false
            })
    }
}
