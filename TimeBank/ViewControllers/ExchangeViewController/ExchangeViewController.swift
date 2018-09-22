//
//  ExchangeViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/21.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Pastel
import Moya
import Hydra
import ZHRefresh
import SkeletonView
import ViewAnimator
import Presentr

class ExchangeViewController: UIViewController {
    
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
    
    let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    let confirmPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    public var side: APIOrderBookSide = .bid {
        didSet {
            switch side {
            case .bid:
                self.submitButton.setTitle(I18n.buyOrder.description, for: .normal)
                self.buySelectButton.isSelected = true
                self.sellSelectButton.isSelected = false
            case .ask:
                self.submitButton.setTitle(I18n.sellOrder.description, for: .normal)
                self.buySelectButton.isSelected = false
                self.sellSelectButton.isSelected = true
            }
        }
    }
    
    private var topAsks: [APIOrderBook] = []
    private var topBids: [APIOrderBook] = []
    
    @IBOutlet private weak var amountInputWrapper: UIView!
    @IBOutlet private weak var amountInputLabel: UILabel!
    @IBOutlet private weak var amountTextField: UITextField!
    @IBOutlet private weak var buySelectButton: UIButton!
    @IBOutlet private weak var buyOrdersLabel: UILabel!
    
    @IBOutlet private weak var priceInputWrapper: UIView!
    @IBOutlet private weak var priceInputLabel: UILabel!
    @IBOutlet private weak var priceTextField: UITextField!
    @IBOutlet private weak var sellSelectButton: UIButton!
    @IBOutlet private weak var sellOrdersLabel: UILabel!
    
    @IBOutlet private weak var submitButton: TransitionButton!
    
    @IBOutlet private weak var tableView: UITableView!
    
    private var gettingMarketTopAsks: Bool = false
    private var gettingMarketTopBids: Bool = false
    private var isSubmitting: Bool = false
    
    private var orderBookServiceProvider = MoyaProvider<TMMOrderBookService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
            navigationItem.title = "TBC/ETH"
        }
        amountInputWrapper.layer.borderColor = UIColor.lightGray.cgColor
        amountInputWrapper.layer.borderWidth = 0.5
        amountInputWrapper.layer.cornerRadius = 5
        amountInputLabel.text = I18n.amount.description
        buyOrdersLabel.text = I18n.buyOrders.description
        buySelectButton.setTitle(I18n.buy.description, for: .normal)
        buySelectButton.setImage(UIImage(named: "SelectFill"), for: .selected)
        buySelectButton.setImage(UIImage(named: "SelectCircle"), for: .normal)
        
        priceInputWrapper.layer.borderColor = UIColor.lightGray.cgColor
        priceInputWrapper.layer.borderWidth = 0.5
        priceInputWrapper.layer.cornerRadius = 5
        priceInputLabel.text = I18n.price.description
        sellOrdersLabel.text = I18n.sellOrders.description
        sellSelectButton.setTitle(I18n.sell.description, for: .normal)
        sellSelectButton.setImage(UIImage(named: "SelectFill"), for: .selected)
        sellSelectButton.setImage(UIImage(named: "SelectCircle"), for: .normal)
        
        side = .bid
        
        setupTableView()
        
        refresh()
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
    
    static func instantiate() -> ExchangeViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ExchangeViewController") as! ExchangeViewController
    }
    
    private func setupTableView() {
        tableView.register(cellType: MarketTopTableViewCell.self)
        self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 32.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func switchSide(_ sender:UIButton) {
        switch sender {
        case buySelectButton:
            self.side = .bid
        case sellSelectButton:
            self.side = .ask
        default:
            return
        }
    }
    
    public func refresh() {
        getMarketTop(side: .ask)
        getMarketTop(side: .bid)
    }
}

extension ExchangeViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension ExchangeViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(topBids.count, topAsks.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var askOrder: APIOrderBook?
        var bidOrder: APIOrderBook?
        if topAsks.count < indexPath.row {
            askOrder = topAsks[indexPath.row]
        }
        if topBids.count < indexPath.row {
            bidOrder = topBids[indexPath.row]
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as MarketTopTableViewCell
        cell.fill(askOrder: askOrder, bidOrder: bidOrder)
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}

extension ExchangeViewController {
    @IBAction func submit() {
        let amount = NSDecimalNumber.init(string: amountTextField.text)
        if amount.isNaN() || amount <= 0 {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.emptyQuantity.description, closeBtn: I18n.close.description)
            return
        }
        let price = NSDecimalNumber.init(string: priceTextField.text)
        if price.isNaN() || price <= 0{
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.emptyPrice.description, closeBtn: I18n.close.description)
            return
        }
        let alertController = Presentr.alertViewController(title: I18n.alert.description, body: I18n.confirmOrder.description)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
            //
        }
        let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak self] alert in
            guard let weakSelf = self else { return }
            weakSelf.doSubmit()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        customPresentViewController(self.confirmPresenter, viewController: alertController, animated: true)
    }
    
    private func doSubmit() {
        if self.isSubmitting { return }
        let amount = NSDecimalNumber.init(string: amountTextField.text)
        if amount.isNaN() || amount <= 0 {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.emptyQuantity.description, closeBtn: I18n.close.description, viewController: self)
            return
        }
        let price = NSDecimalNumber.init(string: priceTextField.text)
        if price.isNaN() || price <= 0{
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.emptyPrice.description, closeBtn: I18n.close.description, viewController: self)
            return
        }
        self.isSubmitting = true
        submitButton.startAnimation()
        TMMOrderBookService.addOrder(
            quantity: amount,
            price: price,
            side: self.side,
            processType: .limit,
            provider: self.orderBookServiceProvider)
            .then(in: .main, {[weak self] resp in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: I18n.orderAddSuccess.description, closeBtn: I18n.close.description, viewController: weakSelf)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isSubmitting = false
                weakSelf.submitButton.stopAnimation(animationStyle: .normal, completion: nil)
            }
        )
    }
    
    private func getMarketTop(side: APIOrderBookSide) {
        if side == .ask && self.gettingMarketTopAsks { return }
        if side == .bid && self.gettingMarketTopBids { return }
        switch side {
        case .ask: self.gettingMarketTopAsks = true
        case .bid: self.gettingMarketTopBids = true
        }
        TMMOrderBookService.getMarketTop(
            side: side,
            provider: self.orderBookServiceProvider)
            .then(in: .main, {[weak self] orders in
                guard let weakSelf = self else { return }
                switch side {
                case .ask: weakSelf.topAsks = orders
                case .bid: weakSelf.topBids = orders
                }
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                switch side {
                case .ask: weakSelf.gettingMarketTopAsks = false
                case .bid: weakSelf.gettingMarketTopBids = false
                }
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
    
}

extension ExchangeViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
