//
//  MyFeedbacksTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/23.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import ZHRefresh
import SkeletonView
import ViewAnimator
import Kingfisher
import EmptyDataSet_Swift
import Presentr

class MyFeedbacksTableViewController: UIViewController {
    
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
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var keyboardTextField : KeyboardTextField!
    
    private var feedbacks: [APIFeedback] = []
    
    private var selectedFeedback: APIFeedback?
    
    private var loadingFeedbacks: Bool = false
    private var sendingReply: Bool = false
    
    private var feedbackServiceProvider = MoyaProvider<TMMFeedbackService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
        }
        setupTableView()
        configureInputBar()
        if userInfo != nil {
            refresh()
        }
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
        tableView.header?.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.header?.removeObservers()
        tableView.footer?.removeObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> MyFeedbacksTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MyFeedbacksTableViewController") as! MyFeedbacksTableViewController
    }
    
    private func setupTableView() {
        tableView.register(cellType: FeedbackReplyTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    func configureInputBar() {
        keyboardTextField = TMMKeyboardTextField(point: CGPoint(x: 0, y: 0), width: tableView.bounds.size.width)
        keyboardTextField.delegate = self
        keyboardTextField.isLeftButtonHidden = true
        keyboardTextField.isRightButtonHidden = false
        keyboardTextField.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth , UIView.AutoresizingMask.flexibleTopMargin]
        tableView.addSubview(keyboardTextField)
        keyboardTextField.toFullyBottom()
        keyboardTextField.isHidden = true
    }
    
    func refresh() {
        getFeedbacks()
    }
}

extension MyFeedbacksTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension MyFeedbacksTableViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return feedbacks.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if feedbacks.count == 0 { return 0 }
        let feedback = feedbacks[section]
        let vc = FeedbackHeaderView()
        vc.fill(feedback)
        return vc.viewHeight()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let feedback = feedbacks[section]
        let vc = FeedbackHeaderView()
        vc.fill(feedback)
        return vc
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedbacks[section].replies?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let feedback = feedbacks[indexPath.section]
        let cell = tableView.dequeueReusableCell(for: indexPath) as FeedbackReplyTableViewCell
        if let reply = feedback.replies?[indexPath.row] {
            cell.fill(reply, username: userInfo?.showName)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if self.feedbacks.count < indexPath.section + 1 { return }
        let feedback = feedbacks[indexPath.section]
        guard let reply = feedback.replies?[indexPath.row] else { return }
        selectedFeedback = reply
        keyboardTextField.isHidden = false
        keyboardTextField.show()
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingFeedbacks
    }
}

extension MyFeedbacksTableViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView) -> Bool {
        return self.feedbacks.count == 0
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView) -> Bool {
        return true
    }
    
    func emptyDataSet(_ scrollView: UIScrollView, didTapButton button: UIButton) {
        self.refresh()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyTransactionsTitle.description)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: I18n.emptyTransactionsDesc.description)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView, for state: UIControl.State) -> NSAttributedString? {
        return NSAttributedString(string: I18n.refresh.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:17), NSAttributedString.Key.foregroundColor:UIColor.primaryBlue])
    }
}

extension MyFeedbacksTableViewController: SkeletonTableViewDataSource {
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return LoadingTableViewCell.self.reuseIdentifier
    }
}

extension MyFeedbacksTableViewController : KeyboardTextFieldDelegate {
    func keyboardTextFieldPressReturnButton(_ keyboardTextField: KeyboardTextField) {
        guard let selectedFeedback = self.selectedFeedback else {
            self.keyboardTextField.hide()
            self.keyboardTextField.isHidden = true
            return
        }
        self.sendFeedback(selectedFeedback.ts, keyboardTextField.text)
    }
    
    func keyboardTextFieldPressRightButton(_ keyboardTextField :KeyboardTextField) {
        guard let selectedFeedback = self.selectedFeedback else {
            self.keyboardTextField.hide()
            self.keyboardTextField.isHidden = true
            return
        }
        self.sendFeedback(selectedFeedback.ts, keyboardTextField.text)
    }
}

extension MyFeedbacksTableViewController {
    private func getFeedbacks() {
        if loadingFeedbacks {
            return
        }
        loadingFeedbacks = true
        TMMFeedbackService.getList(
            provider: self.feedbackServiceProvider
        ).then(in: .background, {[weak self] feedbacks in
            guard let weakSelf = self else { return }
            weakSelf.feedbacks = feedbacks
        })
        .catch(in: .background, {[weak self] error in
            guard let weakSelf = self else { return }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
        }).always(in: .main, body: {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.loadingFeedbacks = false
            weakSelf.tableView.header?.isHidden = false
            weakSelf.tableView.hideSkeleton()
            weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            weakSelf.tableView.header?.endRefreshing()
            let zoomAnimation = AnimationType.zoom(scale: 0.2)
            UIView.animate(views: weakSelf.tableView.visibleCells, animations: [zoomAnimation], completion:nil)
        })
    }
    
    private func sendFeedback(_ replyTs: String, _ msg: String) {
        if sendingReply {
            return
        }
        sendingReply = true
        self.keyboardTextField.isEnabled = false
        TMMFeedbackService.doReply(
            ts: replyTs,
            message: msg,
            provider: self.feedbackServiceProvider
            ).then(in: .background, {[weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.getFeedbacks()
            })
            .catch(in: .background, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as? TMMAPIError)?.description ?? error.localizedDescription, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.sendingReply = false
                weakSelf.keyboardTextField.isEnabled = false
                weakSelf.keyboardTextField.hide()
                weakSelf.keyboardTextField.isHidden = true
            })
    }
}
