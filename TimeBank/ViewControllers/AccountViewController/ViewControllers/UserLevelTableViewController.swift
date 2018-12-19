//
//  UserLevelTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/26.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import FlexibleSteppedProgressBar
import Moya
import Hydra
import ZHRefresh
import Kingfisher
import Presentr
import SnapKit

fileprivate enum AccountTableSectionType {
    case account
    case creditLevels
}

fileprivate enum AccountTableCellType {
    case accountInfo
    case levelProgress
    case invites
    case intro
}

class UserLevelTableViewController: UITableViewController {
    
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
    
    private let sections: [[AccountTableCellType]] = [[.accountInfo, .levelProgress, .invites], [.intro]]
    
    @IBOutlet private weak var avatarImageView : UIImageView!
    @IBOutlet private weak var mobileLabel: UILabel!
    @IBOutlet private weak var levelImageView: UIImageView!
    @IBOutlet private weak var levelNameLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var upgradeDescLabel: UILabel!
    @IBOutlet private weak var levelsContainterView: UIView!
    
    @IBOutlet private weak var levelProgressBar: FlexibleSteppedProgressBar!
    @IBOutlet private weak var invitersAvatarView: UIView!
    @IBOutlet private weak var nextLevelInvitesLabel: UILabel!
    
    lazy private var levelsStackView: UIStackView = {[weak self] in
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16.0
        self?.levelsContainterView.addSubview(stackView)
        stackView.snp.remakeConstraints {[weak self] (maker) -> Void in
            maker.leading.equalToSuperview().offset(16)
            maker.trailing.equalToSuperview().offset(-16)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-16)
        }
        if let levels = self?.creditLevels {
            for l in levels {
                let iconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                iconView.contentMode = .scaleAspectFit
                iconView.clipsToBounds = true
                iconView.tintColor = l.color()
                let levelImage = UIImage(named: "CreditLevel")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
                iconView.image = levelImage
                let nameLabel = UILabel()
                nameLabel.text = l.showName(true)
                let descLabel = UILabel()
                descLabel.numberOfLines = 0
                descLabel.text = l.showDesc()
                descLabel.font = UIFont.systemFont(ofSize: 14)
                let sv = UIStackView(arrangedSubviews: [iconView, nameLabel, descLabel])
                iconView.snp.remakeConstraints {(maker) -> Void in
                    maker.width.equalTo(24)
                    maker.height.equalTo(24)
                    maker.top.equalToSuperview()
                }
                nameLabel.snp.remakeConstraints {(maker) -> Void in
                    maker.width.equalTo(80)
                }
                sv.axis = .horizontal
                sv.spacing = 8.0
                sv.alignment = .top
                sv.distribution = .fillProportionally
                stackView.addArrangedSubview(sv)
            }
        }
        
        return stackView
    }()
    
    private var loadingUserInfo = false
    private var loadingCreditLevels = false
    private var loadingInviteSummary = false
    
    private var creditLevels: [APICreditLevel] = []
    public var inviteSummary: APIInviteSummary?
    
    private var userServiceProvider = MoyaProvider<TMMUserService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    static func instantiate() -> UserLevelTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UserLevelTableViewController") as! UserLevelTableViewController
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
            navigationItem.title = I18n.userCreditLevelRights.description
        }
        setupTableView()
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.layer.borderWidth = 0.0
        avatarImageView.clipsToBounds = true
        setupLevelProcessBar()
        self.updateView()
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
        MTA.trackPageViewBegin(TMMConfigs.PageName.creditLevel)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.creditLevel)
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
        tableView?.header?.removeObservers()
        tableView?.footer?.removeObservers()
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
    
    private func setupLevelProcessBar() {
        levelProgressBar.numberOfPoints = 5
        levelProgressBar.radius = 30
        levelProgressBar.lineHeight = 3
        levelProgressBar.progressRadius = 30
        levelProgressBar.progressLineHeight = 5
        levelProgressBar.stepAnimationDuration = 0
        levelProgressBar.currentSelectedCenterColor = UIColor.pinky
        levelProgressBar.selectedBackgoundColor = UIColor.pinky
        levelProgressBar.selectedOuterCircleLineWidth = 0
        levelProgressBar.selectedOuterCircleStrokeColor = UIColor.white
        levelProgressBar.stepTextFont = UIFont.systemFont(ofSize: 8)
        levelProgressBar.centerLayerTextColor = UIColor(white: 0.8, alpha: 1.0)
        levelProgressBar.centerLayerDarkBackgroundTextColor = UIColor.white
        levelProgressBar.currentIndex = Int(userInfo?.level?.id ?? 0)
        levelProgressBar.delegate = self
    }
    
    public func refresh() {
        getUserInfo()
        getCreditLevels()
        getInviteSummary()
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
        levelImageView.tintColor = userInfo.level?.color() ?? APICreditLevel()!.color()
        levelNameLabel.text = userInfo.level?.showName(true) ?? APICreditLevel()!.showName(true)
        let levelImage = UIImage(named: "CreditLevel")?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        levelImageView.image = levelImage
        upgradeDescLabel.text = ""
        for l in self.creditLevels {
            if l.id > userInfo.level?.id ?? 0 {
                upgradeDescLabel.text = String(format: I18n.creditLevelUpgradeDesc.description, l.invites, l.showName(true))
                break
            }
        }
        
        if let summary = self.inviteSummary {
            nextLevelInvitesLabel.text = String(format: I18n.nextLevelInvitesDesc.description, summary.nextLevelInvites)
            for view in invitersAvatarView.subviews {
                view.removeFromSuperview()
            }
            var idx = 0
            let totalUsers = summary.users.count
            var leadingOffset = (tableView.bounds.width - 32) / CGFloat(totalUsers)
            if leadingOffset > 40 {
                leadingOffset = 32
            }
            for user in summary.users {
                if let avatar = user.avatar {
                    let avatarView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                    avatarView.kf.setImage(with: URL(string: avatar))
                    avatarView.layer.cornerRadius = 20
                    avatarView.layer.borderColor = UIColor.white.cgColor
                    avatarView.layer.borderWidth = 2
                    avatarView.clipsToBounds = true
                    invitersAvatarView.addSubview(avatarView)
                    if idx == 0 {
                        avatarView.snp.remakeConstraints {(maker) -> Void in
                            maker.width.equalTo(40)
                            maker.height.equalTo(40)
                            maker.top.bottom.equalToSuperview()
                            maker.leading.equalToSuperview()
                        }
                    } else {
                        let previousView = self.invitersAvatarView.subviews[idx - 1]
                        avatarView.snp.remakeConstraints {(maker) -> Void in
                            maker.width.equalTo(40)
                            maker.height.equalTo(40)
                            maker.top.bottom.equalToSuperview()
                            maker.leading.equalTo(previousView.snp.leading).offset(leadingOffset)
                        }
                    }
                }
                idx += 1
            }
        }
        tableView.header?.endRefreshing()
        tableView.reloadDataWithAutoSizingCellWorkAround()
    }
    
    private func showInvitePage() {
        let vc = InviteViewController.instantiate()
        vc.inviteSummary = inviteSummary
        self.present(vc, animated: true, completion: nil)
    }
}

extension UserLevelTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension UserLevelTableViewController {
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "     " + I18n.userCreditLevelRules.description
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if self.sections.count < indexPath.section + 1 { return }
        if self.sections[indexPath.section].count < indexPath.row + 1 { return }
        switch self.sections[indexPath.section][indexPath.row] {
        case .invites:
            self.showInvitePage()
        default:
            return
        }
    }
}

extension UserLevelTableViewController: FlexibleSteppedProgressBarDelegate {
    func progressBar(_ progressBar: FlexibleSteppedProgressBar,
                     canSelectItemAtIndex index: Int) -> Bool {
        return false
    }
    
    func progressBar(_ progressBar: FlexibleSteppedProgressBar,
                     textAtIndex index: Int, position: FlexibleSteppedProgressBarTextLocation) -> String {
        if position == FlexibleSteppedProgressBarTextLocation.center && index < self.creditLevels.count {
            let level = self.creditLevels[index]
            return level.showName()
        }
        return ""
    }
}

extension UserLevelTableViewController {
    private func getUserInfo() {
        if self.loadingUserInfo { return }
        self.loadingUserInfo = true
        TMMUserService.getUserInfo(
            true,
            provider: self.userServiceProvider)
            .then(in: .main, {[weak self] user in
                guard let weakSelf = self else { return }
                weakSelf.levelProgressBar.currentIndex = Int(user.level?.id ?? 0)
                weakSelf.levelProgressBar.completedTillIndex = Int(user.level?.id ?? 0)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self]  in
                guard let weakSelf = self else { return }
                weakSelf.loadingUserInfo = false
                weakSelf.updateView()
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
                weakSelf.levelProgressBar.numberOfPoints = levels.count
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self]  in
                guard let weakSelf = self else { return }
                weakSelf.loadingCreditLevels = false
                if weakSelf.activityIndicator != nil {
                    weakSelf.activityIndicator.isHidden = true
                    weakSelf.activityIndicator.stopAnimating()
                    weakSelf.activityIndicator.removeFromSuperview()
                }
                weakSelf.levelsStackView.needsUpdateConstraints()
                weakSelf.updateView()
            })
    }
    
    private func getInviteSummary() {
        if self.loadingInviteSummary { return }
        self.loadingInviteSummary = true
        
        TMMUserService.getInviteSummary(
            withUserList: true,
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
                weakSelf.updateView()
            }
        )
    }
}

extension UserLevelTableViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
