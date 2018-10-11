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
import ZHRefresh
import Kingfisher
import Presentr

enum AccountTableSectionType {
    case account
    case invite
    case contact
    case signout
}

enum AccountTableCellType {
    case accountInfo
    case inviteSummary
    case myInviteCode
    case inviteCode
    case bindWechatAccount
    case currency
    case telegramGroup
    case wechatGroup
    case feedback
    case signout
}

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
    
    let myInviteCodePresenter: Presentr = {
        let presentationType = PresentationType.dynamic(center: .center)
        let presenter = Presentr(presentationType: presentationType)
        presenter.roundCorners = true
        presenter.transitionType = nil
        presenter.dismissTransitionType = .coverVerticalFromTop
        presenter.dismissAnimated = true
        presenter.dismissOnSwipe = true
        presenter.dismissOnSwipeDirection = .top
        return presenter
    }()
    
    let wechatCodePresenter: Presentr = {
        let presentationType = PresentationType.dynamic(center: .center)
        let presenter = Presentr(presentationType: presentationType)
        presenter.roundCorners = true
        presenter.transitionType = nil
        presenter.dismissTransitionType = .coverVerticalFromTop
        presenter.dismissAnimated = true
        presenter.dismissOnSwipe = true
        presenter.dismissOnSwipeDirection = .top
        return presenter
    }()
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    private var inviteSummary: APIInviteSummary?
    
    private var contacts:[String:String] = [:]
    
    private let sections: [[AccountTableCellType]] = [[.accountInfo], [.inviteSummary, .myInviteCode, .inviteCode], [.bindWechatAccount, .currency, .telegramGroup, .wechatGroup, .feedback], [.signout]]
    
    @IBOutlet private weak var avatarImageView : UIImageView!
    @IBOutlet private weak var mobileLabel: UILabel!
    
    @IBOutlet private weak var myInviteCodeLabel: UILabel!
    @IBOutlet private weak var inviteUsersLabel: UILabel!
    @IBOutlet private weak var inviteIncomeLabel: UILabel!
    @IBOutlet private weak var inviteUsersTitleLabel: UILabel!
    @IBOutlet private weak var inviteIncomeTitleLabel: UILabel!
    @IBOutlet private weak var inviteCodeLabel: UILabel!
    @IBOutlet private weak var inviteCodeTextField: UITextField!
    @IBOutlet private weak var bindWechatAccountLabel: UILabel!
    @IBOutlet private weak var bindWechatStatusLabel: UILabelPadding!
    @IBOutlet private weak var currencyTitleLabel: UILabel!
    @IBOutlet private weak var currentCurrencyLabel: UILabel!
    @IBOutlet private weak var telegramGroupLabel: UILabel!
    @IBOutlet private weak var wechatGroupLabel: UILabel!
    @IBOutlet private weak var feedbackLabel: UILabel!
    @IBOutlet private weak var signOutLabel: UILabel!
    @IBOutlet private weak var contactActivityIndicatorTelegram: UIActivityIndicatorView!
    @IBOutlet private weak var contactActivityIndicatorWechat: UIActivityIndicatorView!
    
    private var isUpdating: Bool = false
    private var loadingUserInfo: Bool = false
    private var loadingInviteSummary: Bool = false
    private var gettingContacts: Bool = false
    private var bindingWechat: Bool = false
    
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    private var contactServiceProvider = MoyaProvider<TMMContactService>(plugins: [networkActivityPlugin])
    
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
        
        avatarImageView.layer.cornerRadius = 20.0
        avatarImageView.layer.borderWidth = 0.0
        avatarImageView.clipsToBounds = true
        inviteUsersTitleLabel.text = I18n.inviteUsers.description
        inviteIncomeTitleLabel.text = I18n.inviteIncome.description
        myInviteCodeLabel.text = I18n.myInviteCode.description
        inviteCodeLabel.text = I18n.inviteCode.description
        inviteCodeTextField.attributedPlaceholder = NSAttributedString(string: I18n.inviteCodePlaceholder.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:15), NSAttributedString.Key.foregroundColor:UIColor.lightGray])
        bindWechatAccountLabel.text = I18n.bindWechatAccount.description
        bindWechatStatusLabel.layer.cornerRadius = 5;
        bindWechatStatusLabel.clipsToBounds = true
        bindWechatStatusLabel.paddingTop = 2
        bindWechatStatusLabel.paddingBottom = 2
        bindWechatStatusLabel.paddingLeft = 4
        bindWechatStatusLabel.paddingRight = 4
        
        currencyTitleLabel.text = I18n.currency.description
        currentCurrencyLabel.text = Defaults[.currency] ?? Currency.USD.rawValue
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
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getContacts()
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
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
    }
    
    public func refresh() {
        self.getUserInfo().catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return  }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
        }).always(in: .background, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.loadingUserInfo = false
        })
        self.getInviteSummary()
    }
    
    private func updateView() {
        guard let userInfo = self.userInfo else { return }
        if let showName = userInfo.showName {
            mobileLabel.text = showName
        } else {
            mobileLabel.text = "+\(userInfo.countryCode!)\(userInfo.mobile!)"
        }
        if let avatar = userInfo.avatar {
            avatarImageView.kf.setImage(with: URL(string: avatar))
        }
        if let summary = self.inviteSummary {
            inviteUsersLabel.text = String(summary.invites)
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            inviteIncomeLabel.text = formatter.string(from: summary.points)
        }
        let inviterCode = userInfo.inviterCode ?? ""
        inviteCodeTextField.text = inviterCode
        if !inviterCode.isEmpty {
            inviteCodeTextField.isEnabled = false
        } else {
            inviteCodeTextField.isEnabled = true
        }
        
        if ShareSDK.hasAuthorized(.typeWechat) {
            bindWechatStatusLabel.backgroundColor = UIColor.greenGrass
            bindWechatStatusLabel.text = I18n.binded.description
            bindWechatStatusLabel.textColor = .white
        } else {
            bindWechatStatusLabel.backgroundColor = UIColor(white: 0.9, alpha: 1)
            bindWechatStatusLabel.text = I18n.notbinded.description
            bindWechatStatusLabel.textColor = .darkGray
        }
    }
    
    private func showMyInviteCode() {
        let vc = MyInviteCodeViewController.instantiate()
        customPresentViewController(myInviteCodePresenter, viewController: vc, animated: true)
    }
    
    private func showWechatCode() {
        guard let wechatGroup = self.contacts["wechat"] else { return }
        let vc = WechatQRCodeViewController.instantiate()
        vc.wechatGroup = wechatGroup
        customPresentViewController(wechatCodePresenter, viewController: vc, animated: true)
    }
    
    private func showChooseCurrency() {
        let sheet = UIAlertController(title: "Choose Currency", message: nil, preferredStyle: .actionSheet)
        let usdAction = UIAlertAction(title: Currency.USD.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.USD.rawValue
            weakSelf.currentCurrencyLabel.text = Currency.USD.rawValue
        })
        let cnyAction = UIAlertAction(title: Currency.CNY.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.CNY.rawValue
            weakSelf.currentCurrencyLabel.text = Currency.CNY.rawValue
        })
        let eurAction = UIAlertAction(title: Currency.EUR.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.EUR.rawValue
            weakSelf.currentCurrencyLabel.text = Currency.EUR.rawValue
        })
        let krwAction = UIAlertAction(title: Currency.KRW.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.KRW.rawValue
            weakSelf.currentCurrencyLabel.text = Currency.KRW.rawValue
        })
        let jpyAction = UIAlertAction(title: Currency.JPY.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.JPY.rawValue
            weakSelf.currentCurrencyLabel.text = Currency.JPY.rawValue
        })
        let cancelAction = UIAlertAction(title: I18n.cancel.description, style: UIAlertAction.Style.cancel, handler: nil)
        sheet.addAction(usdAction)
        sheet.addAction(cnyAction)
        sheet.addAction(eurAction)
        sheet.addAction(krwAction)
        sheet.addAction(jpyAction)
        sheet.addAction(cancelAction)
        self.present(sheet, animated: true, completion: nil)
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

// MARK: - Table view data source
extension AccountTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if self.sections.count < indexPath.section + 1 { return }
        if self.sections[indexPath.section].count < indexPath.row + 1 { return }
        switch self.sections[indexPath.section][indexPath.row] {
        case .myInviteCode:
            self.showMyInviteCode()
        case .bindWechatAccount:
            if ShareSDK.hasAuthorized(.typeWechat) {
                self.getWechatInfo()
                return
            }
            self.bindWechat()
        case .currency:
            self.showChooseCurrency()
        case .telegramGroup:
            guard let telegramGroup = self.contacts["telegram"] else { return }
            guard let link = URL(string: telegramGroup) else { return }
            UIApplication.shared.open(link, options: [:], completionHandler: nil)
        case .wechatGroup:
            self.showWechatCode()
        case .feedback:
            let vc = FeedbackTableViewController.instantiate()
            self.navigationController?.pushViewController(vc, animated: true)
        case .signout:
            Defaults.removeAll()
            Defaults.synchronize()
            let vc = LoginViewController.instantiate()
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
            return
        default:
            return
        }
    }
}

extension AccountTableViewController {
    
    private func setInviterCode(_ code: String) {
        guard let userInfo = self.userInfo else { return }
        userInfo.inviterCode = code
        async({[weak self] _ in
            guard let weakSelf = self else { return }
            let _ = try ..weakSelf.updateUserInfo(userInfo)
            let _ = try ..weakSelf.getUserInfo()
        }).then(in: .main, {[weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.updateView()
        }).catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return  }
            weakSelf.inviteCodeTextField.text = ""
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
        }).always(in: .background, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.isUpdating = false
            weakSelf.loadingUserInfo = false
        })
    }
    
    private func getUserInfo() -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.loadingUserInfo {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.loadingUserInfo = true
            TMMUserService.getUserInfo(
                true,
                provider: weakSelf.userServiceProvider)
                .then(in: .background, {user in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
    
    private func updateUserInfo(_ user: APIUser) -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.isUpdating {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.isUpdating = true
            TMMUserService.updateUserInfo(
                user,
                provider: weakSelf.userServiceProvider)
                .then(in: .background, {user in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
    
    private func getInviteSummary() {
        if self.loadingInviteSummary {
            return
        }
        self.loadingInviteSummary = true
        
        TMMUserService.getInviteSummary(
            provider: self.userServiceProvider)
            .then(in: .main, {[weak self] summary in
                guard let weakSelf = self else { return }
                weakSelf.inviteSummary = summary
                weakSelf.updateView()
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingInviteSummary = false
                weakSelf.tableView.header?.endRefreshing()
            }
        )
    }
    
    private func getContacts() {
        if self.gettingContacts {
            return
        }
        self.gettingContacts = true
        
        TMMContactService.getContacts(
            provider: self.contactServiceProvider)
            .then(in: .main, {[weak self] contacts in
                guard let weakSelf = self else { return }
                for contact in contacts {
                    weakSelf.contacts[contact.name] = contact.value
                }
                weakSelf.contactActivityIndicatorTelegram.isHidden = true
                weakSelf.contactActivityIndicatorWechat.isHidden = true
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingContacts = false
                weakSelf.tableView.header?.endRefreshing()
                }
        )
    }
    
    private func doBindWechat(unionId: String, nick: String, avatar: String, gender: Int, accessToken: String, expires: TimeInterval) {
        if self.bindingWechat {
            return
        }
        self.bindingWechat = true
        
        TMMUserService.bindWechatInfo(
            unionId: unionId,
            nick: nick,
            avatar: avatar,
            gender: gender,
            accessToken: accessToken,
            expires: expires,
            provider: self.userServiceProvider)
            .then(in: .main, {[weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.getUserInfo().catch(in: .main, {[weak weakSelf] error in
                    switch error as! TMMAPIError {
                    case .ignore:
                        return
                    default: break
                    }
                    guard let weakSelf2 = weakSelf else { return  }
                    UCAlert.showAlert(weakSelf2.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                }).always(in: .background, body: {[weak weakSelf]  in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.loadingUserInfo = false
                })
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.bindingWechat = false
                }
        )
    }
    
    private func bindWechat() {
        ShareSDK.authorize(.typeWechat, settings: nil) { [weak self] (state: SSDKResponseState, user: SSDKUser?, error: Error?) in
            guard let weakSelf = self else { return }
            switch state {
            case .success:
                guard let userInfo = user else { return }
                weakSelf.doBindWechat(unionId: userInfo.uid, nick: userInfo.nickname, avatar: userInfo.icon, gender: userInfo.gender, accessToken: userInfo.credential.token, expires: userInfo.credential.expired)
            case .fail:
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error?.localizedDescription ?? "failed", closeBtn: I18n.close.description)
            default:
                print("not catched auth state")
            }
        }
    }
    
    private func getWechatInfo() {
        ShareSDK.getUserInfo(SSDKPlatformType.typeWechat) {[weak self] (state: SSDKResponseState, user: SSDKUser?, error: Error?) in
            guard let weakSelf = self else { return }
            switch state {
            case .success:
                guard let userInfo = user else { return }
                weakSelf.doBindWechat(unionId: userInfo.uid, nick: userInfo.nickname, avatar: userInfo.icon, gender: userInfo.gender, accessToken: userInfo.credential.token, expires: userInfo.credential.expired)
            case .fail:
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: error?.localizedDescription ?? "failed", closeBtn: I18n.close.description)
            default:
                print("not catched auth state")
            }
        }
    }
}

extension AccountTableViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.inviteCodeTextField {
            let inviteCode = textField.text ?? ""
            if !inviteCode.isEmpty {
                self.setInviterCode(inviteCode)
            }
        }
        textField.resignFirstResponder()
        return true
    }
}

extension AccountTableViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
