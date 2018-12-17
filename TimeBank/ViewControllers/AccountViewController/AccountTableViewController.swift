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

fileprivate enum AccountTableSectionType {
    case account
    case invite
    case contact
    case signout
}

fileprivate enum AccountTableCellType {
    case accountInfo
    case creditLevelBanner
    case inviteSummary
    case myInviteCode
    case inviteCode
    case bindWechatAccount
    case currency
    case telegramGroup
    case wechatGroup
    case feedback
    case help
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
    
    private var creditLevels: [APICreditLevel] = []
    
    private let sections: [[AccountTableCellType]] = [[.accountInfo, .creditLevelBanner], [.inviteSummary, .myInviteCode, .inviteCode], [.bindWechatAccount, .currency, .telegramGroup, .wechatGroup, .help, .feedback], [.signout]]
    
    private var isUpdating: Bool = false
    private var loadingUserInfo: Bool = false
    private var loadingInviteSummary: Bool = false
    private var gettingContacts: Bool = false
    private var bindingWechat: Bool = false
    private var loadingCreditLevels: Bool = false
    
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    private var contactServiceProvider = MoyaProvider<TMMContactService>(plugins: [networkActivityPlugin, SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
        let versionLabel = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 30))
        let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        versionLabel.text = "\(I18n.currentVersion.description): \(currentVersion)b\(AppBuildClosure())"
        versionLabel.textAlignment = .center
        versionLabel.textColor = UIColor.lightGray
        versionLabel.font = MainFont.light.with(size: 12)
        tableView.tableFooterView = versionLabel
        self.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MTA.trackPageViewBegin(TMMConfigs.PageName.userCenter)
        self.getContacts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.userCenter)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if userInfo == nil {
            let vc = LoginViewController.instantiate()
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupTableView() {
        //self.tableView.separatorStyle = .none
        tableView.register(cellType: SimpleTableViewCell.self)
        tableView.register(cellType: SimpleImageTableViewCell.self)
        tableView.register(cellType: UserInfoTableViewCell.self)
        tableView.register(cellType: InputTableViewCell.self)
        tableView.register(cellType: InviteStatsTableViewCell.self)
        tableView.register(cellType: CreditLevelBannerTableViewCell.self)
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
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.loadingUserInfo = false
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
        self.getInviteSummary()
        self.getCreditLevels()
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
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
        let cnyAction = UIAlertAction(title: Currency.CNY.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.CNY.rawValue
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
        let eurAction = UIAlertAction(title: Currency.EUR.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.EUR.rawValue
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
        let krwAction = UIAlertAction(title: Currency.KRW.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.KRW.rawValue
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
        let jpyAction = UIAlertAction(title: Currency.JPY.rawValue, style: .default, handler: {[weak self](_) in
            guard let weakSelf = self else { return }
            Defaults[.currency] = Currency.JPY.rawValue
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
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
    
    private func showInvitePage() {
        let vc = InviteViewController.instantiate()
        vc.inviteSummary = inviteSummary
        self.present(vc, animated: true, completion: nil)
        //self.navigationController?.pushViewController(vc, animated: true)
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
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.sections.count < section + 1 { return 0 }
        return sections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.sections[indexPath.section][indexPath.row] {
        case .accountInfo:
            let cell = tableView.dequeueReusableCell(for: indexPath) as UserInfoTableViewCell
            cell.fill(userInfo, inviteSummary: inviteSummary)
            return cell
        case .creditLevelBanner:
            let cell = tableView.dequeueReusableCell(for: indexPath) as CreditLevelBannerTableViewCell
            cell.fill(userInfo?.level?.id ?? 0, inviteSummary: inviteSummary, levels: creditLevels)
            return cell
        case .inviteSummary:
            let cell = tableView.dequeueReusableCell(for: indexPath) as InviteStatsTableViewCell
            cell.fill(inviteSummary)
            return cell
        case .myInviteCode:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.myInviteCode.description)
            cell.accessoryType = .detailButton
            return cell
        case .inviteCode:
            let cell = tableView.dequeueReusableCell(for: indexPath) as InputTableViewCell
            cell.fill(I18n.inviteCode.description, placeholder: I18n.inviteCodePlaceholder.description, value: userInfo?.inviterCode)
            cell.delegate = self
            return cell
        case .bindWechatAccount:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.bindWechatAccount.description)
            if ShareSDK.hasAuthorized(.typeWechat) || userInfo?.wxBinded ?? false {
                cell.setStatus(I18n.binded.description, statusColor: .white, statusBgColor: .greenGrass)
            } else {
                cell.setStatus(I18n.notbinded.description, statusColor: .darkGray, statusBgColor: UIColor(white: 0.9, alpha: 1))
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        case .currency:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.currency.description)
            cell.setBadge(Defaults[.currency] ?? Currency.USD.rawValue)
            cell.accessoryType = .disclosureIndicator
            return cell
        case .telegramGroup:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.telegramGroup.description)
            if self.gettingContacts {
                cell.showLoader()
            } else {
                cell.hideLoader()
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        case .wechatGroup:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.wechatGroup.description)
            if self.gettingContacts {
                cell.showLoader()
            } else {
                cell.hideLoader()
            }
            cell.accessoryType = .disclosureIndicator
            return cell
        case .feedback:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.feedback.description)
            cell.accessoryType = .disclosureIndicator
            return cell
        case .help:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.help.description)
            cell.accessoryType = .disclosureIndicator
            return cell
        case .signout:
            let cell = tableView.dequeueReusableCell(for: indexPath) as SimpleTableViewCell
            cell.fill(I18n.signout.description)
            cell.setTitleColor(UIColor.red)
            cell.accessoryType = .none
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if self.sections.count < indexPath.section + 1 { return }
        if self.sections[indexPath.section].count < indexPath.row + 1 { return }
        if self.sections[indexPath.section][indexPath.row] != .inviteCode {
            let idxPath = IndexPath(row: 2, section: 1)
            if let inviteCodeCell = tableView.cellForRow(at: idxPath) as? InputTableViewCell {
                inviteCodeCell.hideKeyboard()
            }
        }
        switch self.sections[indexPath.section][indexPath.row] {
        case .accountInfo:
            let vc = UserLevelTableViewController.instantiate()
            vc.inviteSummary = self.inviteSummary
            self.navigationController?.pushViewController(vc, animated: true)
        case .creditLevelBanner:
            self.showInvitePage()
        case .inviteSummary:
            let vc = MyInvitesTableViewController.instantiate()
            vc.inviteSummary = inviteSummary
            self.navigationController?.pushViewController(vc, animated: true)
        case .myInviteCode:
            self.showInvitePage()
        case .inviteCode:
            if let inputCell = cell as? InputTableViewCell {
                inputCell.showKeyboard()
            }
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
        case .help:
            let vc = TMMWebViewController.instantiate()
            vc.request = URLRequest(url: URL(string: TMMConfigs.helpLink)!)
            self.navigationController?.pushViewController(vc, animated: true)
        case .signout:
            if let userInfo: DefaultsUser = Defaults[.user] {
                let account = MTAAccountInfo.init()
                account.type = MTAAccountTypeExt.custom
                account.account = "UserId:\(userInfo.id ?? 0)"
                account.accountStatus = MTAAccountStatus.logout
                let accountPhone = MTAAccountInfo.init()
                accountPhone.type = MTAAccountTypeExt.phone
                accountPhone.account = "+\(userInfo.countryCode ?? 0)\(userInfo.mobile!)"
                accountPhone.accountStatus = MTAAccountStatus.logout
                if userInfo.openId != "" {
                    let openIdAccount = MTAAccountInfo.init()
                    openIdAccount.type = MTAAccountTypeExt.weixin
                    openIdAccount.account = userInfo.openId
                    openIdAccount.accountStatus = MTAAccountStatus.logout
                    MTA.reportAccountExt([account, accountPhone, openIdAccount])
                } else {
                    MTA.reportAccountExt([account, accountPhone])
                }
            }
            Defaults.removeAll()
            Defaults.synchronize()
            let vc = LoginViewController.instantiate()
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
            return
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch self.sections[indexPath.section][indexPath.row] {
        case .accountInfo:
            return true
        case .creditLevelBanner:
            return true
        case .inviteSummary:
            return true
        case .myInviteCode:
            return true
        case .inviteCode:
            return true
        case .bindWechatAccount:
            return true
        case .currency:
            return true
        case .telegramGroup:
            return true
        case .wechatGroup:
            return true
        case .feedback:
            return true
        case .help:
            return true
        case .signout:
            return true
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
        }).catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return  }
            userInfo.inviterCode = ""
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.isUpdating = false
            weakSelf.loadingUserInfo = false
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
    }
    
    private func getUserInfo() -> Promise<APIUser> {
        return Promise<APIUser> (in: .background, {[weak self] resolve, reject, _ in
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
                    resolve(user)
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
                .then(in: .background, {_ in
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
            withUserList: false,
            provider: self.userServiceProvider)
            .then(in: .main, {[weak self] summary in
                guard let weakSelf = self else { return }
                weakSelf.inviteSummary = summary
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingInviteSummary = false
                weakSelf.tableView.header?.endRefreshing()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
    
    private func getContacts() {
        if self.gettingContacts {
            return
        }
        self.gettingContacts = true
        self.tableView.reloadDataWithAutoSizingCellWorkAround()
        TMMContactService.getContacts(
            provider: self.contactServiceProvider)
            .then(in: .main, {[weak self] contacts in
                guard let weakSelf = self else { return }
                for contact in contacts {
                    weakSelf.contacts[contact.name] = contact.value
                }
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingContacts = false
                weakSelf.tableView.header?.endRefreshing()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
    
    private func bindWechat() {
        async({[weak self] _ in
            guard let weakSelf = self else { return }
            let user = try ..weakSelf.authWechat()
            let _ = try ..weakSelf.doBindWechat(user: user)
            let _ = try ..weakSelf.getUserInfo()
        }).catch(in: .main, {[weak self] error in
            if let err = error as? TMMAPIError {
                switch err {
                case .ignore:
                    return
                default: break
                }
            }
            guard let weakSelf = self else { return  }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.loadingUserInfo = false
            weakSelf.bindingWechat = false
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
        })
    }
    
    private func doBindWechat(user: SSDKUser) -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.bindingWechat {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.bindingWechat = true
            guard let rawInfo = user.rawData else { return }
            guard let openId = rawInfo["openid"] as? String else { return }
            guard let unionId = rawInfo["unionid"] as? String else { return }
            TMMUserService.bindWechatInfo(
                unionId: unionId,
                openId: openId,
                nick: user.nickname,
                avatar: user.icon,
                gender: user.gender,
                accessToken: user.credential.token,
                expires: user.credential.expired,
                provider: weakSelf.userServiceProvider)
                .then(in: .background, { _ in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
    
    private func authWechat() -> Promise<SSDKUser> {
        return Promise<SSDKUser> (in: .background, { resolve, reject, _ in
            ShareSDK.authorize(.typeWechat, settings: nil) { (state: SSDKResponseState, user: SSDKUser?, error: Error?) in
                switch state {
                case .success:
                    guard let userInfo = user else {
                        reject(TMMAPIError.ignore)
                        return
                    }
                    resolve(userInfo)
                case .fail:
                    guard let err = error else {
                        reject(TMMAPIError.ignore)
                        return
                    }
                    reject(err)
                default:
                    reject(TMMAPIError.ignore)
                }
            }
        })
    }
    
    private func getWechatInfo() {
        async({[weak self] _ in
            guard let weakSelf = self else { return }
            let user = try ..weakSelf.getWechatUser()
            let _ = try ..weakSelf.doBindWechat(user: user)
            let _ = try ..weakSelf.getUserInfo()
        }).catch(in: .main, {[weak self] error in
            if let err = error as? TMMAPIError {
                switch err {
                case .ignore:
                    return
                default: break
                }
            }
            guard let weakSelf = self else { return  }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.loadingUserInfo = false
            weakSelf.bindingWechat = false
        })
    }
    
    private func getWechatUser() -> Promise<SSDKUser> {
        return Promise<SSDKUser> (in: .background, { resolve, reject, _ in
            ShareSDK.getUserInfo(SSDKPlatformType.typeWechat) {(state: SSDKResponseState, user: SSDKUser?, error: Error?) in
                switch state {
                case .success:
                    guard let userInfo = user else {
                        reject(TMMAPIError.ignore)
                        return
                    }
                    resolve(userInfo)
                case .fail:
                    guard let err = error else {
                        reject(TMMAPIError.ignore)
                        return
                    }
                    reject(err)
                default:
                    reject(TMMAPIError.ignore)
                }
            }
        })
    }
    
    private func getCreditLevels() {
        if self.loadingCreditLevels { return }
        self.loadingCreditLevels = true
        TMMUserService.getCreditLevels(
            provider: self.userServiceProvider)
            .then(in: .main, {[weak self] levels in
                guard let weakSelf = self else { return }
                weakSelf.creditLevels = levels
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self]  in
                guard let weakSelf = self else { return }
                weakSelf.loadingCreditLevels = false
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            })
    }
}

extension AccountTableViewController: InputTableViewCellDelegate {
    
    public func textUpdated(_ text: String) {
        if text != userInfo?.inviterCode {
            self.setInviterCode(text)
        }
    }
}

extension AccountTableViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
