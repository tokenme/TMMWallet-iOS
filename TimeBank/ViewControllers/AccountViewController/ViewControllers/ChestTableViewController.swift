//
//  ChestTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/18.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import SnapKit
import Presentr

fileprivate enum TableSectionType {
    case inviteTasks
    case commonTasks
}

fileprivate enum TableCellType {
    case invite
    case inviteBonus
    case share
    case reading
    case push
}

class ChestTableViewController: UITableViewController {
    
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
    
    private var inviteSummary: APIInviteSummary?
    private var creditLevels: [APICreditLevel] = []
    
    private let sections: [[TableCellType]] = [[.invite, .inviteBonus], [.share, .reading, .push]]
    
    private var loadingInviteSummary: Bool = false
    private var loadingCreditLevels: Bool = false
    
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
            navigationItem.title = "开宝箱跟我赚"
        }
        setupTableView()
        self.refresh()
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
        MTA.trackPageViewBegin(TMMConfigs.PageName.chestView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.chestView)
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
    
    static func instantiate() -> ChestTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChestTableViewController") as! ChestTableViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupTableView() {
        //self.tableView.separatorStyle = .none
        tableView.register(cellType: ChestTableViewCell.self)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableView.automaticDimension
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.width * 180.0 / 640.0))
        headerView.backgroundColor = UIColor.white
        let inviteBanner = UIImageView(image: UIImage(named:"InviteBanner"))
        inviteBanner.contentMode = .scaleAspectFit
        headerView.addSubview(inviteBanner)
        inviteBanner.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(4)
            maker.leading.equalToSuperview().offset(8)
            maker.bottom.equalToSuperview().offset(-4)
            maker.trailing.equalToSuperview().offset(-8)
            maker.height.equalTo(inviteBanner.snp.width).multipliedBy(180.0/640.0)
        }
        headerView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showInvitePage))
        tapGesture.numberOfTapsRequired = 1
        headerView.addGestureRecognizer(tapGesture)
        tableView.tableHeaderView = headerView
    }
    
    public func refresh() {
        self.getInviteSummary()
        self.getCreditLevels()
    }
    
    @objc private func showInvitePage() {
        let vc = InviteViewController.instantiate()
        self.present(vc, animated: true, completion: nil)
    }
    
}
extension ChestTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension ChestTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.sections.count < section + 1 { return 0 }
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as ChestTableViewCell
        switch self.sections[indexPath.section][indexPath.row] {
        case .invite:
            cell.fill(title: "邀请好友", subTitle: "升级为白金会员，做任务得2.5倍积分", icon: UIImage(named:"InviteIcon"), buttonTitle: "去升级")
        case .inviteBonus:
            cell.fill(title: "好友贡献奖励", subTitle: "好友做任务的积分，给您进贡20%", icon: UIImage(named:"InviteBonusIcon"), buttonTitle: "去激活")
        case .share:
            cell.fill(title: "分享文章", subTitle: "每次奖励100积分", icon: UIImage(named:"ShareIcon"), buttonTitle: "领100积分")
        case .reading:
            cell.fill(title: "阅读文章或看视频", subTitle: "每次奖励100积分", icon: UIImage(named:"ReadingIcon"), buttonTitle: "领100积分")
        case .push:
            cell.fill(title: "阅读推送文章", subTitle: "每次奖励100积分", icon: UIImage(named:"PushReadingIcon"), buttonTitle: "领100积分")
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if self.sections.count < indexPath.section + 1 { return }
        if self.sections[indexPath.section].count < indexPath.row + 1 { return }
        switch self.sections[indexPath.section][indexPath.row] {
        case .invite:
            self.showInvitePage()
        case .inviteBonus:
            let vc = MyInvitesTableViewController.instantiate()
            vc.inviteSummary = inviteSummary
            self.navigationController?.pushViewController(vc, animated: true)
        case .share:
            self.tabBarController?.selectedIndex = 1
        case .reading:
            self.tabBarController?.selectedIndex = 1
        case .push:
            self.tabBarController?.selectedIndex = 1
        }
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "   邀请赚积分"
        case 1:
            return "   日常任务赚积分"
        default:
            return nil
        }
    }

}

extension ChestTableViewController {
    private func getInviteSummary() {
        if self.loadingInviteSummary { return }
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
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
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

extension ChestTableViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
