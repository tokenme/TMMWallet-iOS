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
import Charts
import DynamicBlurView

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
    
    private var exchangeRate: APIOrderBookRate?
    private var graph: [APIMarketGraph] = []
    private var topAsks: [APIOrderBook] = []
    private var topBids: [APIOrderBook] = []
    
    @IBOutlet private weak var blurOverlay: DynamicBlurView!
    @IBOutlet private weak var featureNotAvailableLabel: UILabel!
    @IBOutlet private weak var chartTitleLabel: UILabel!
    @IBOutlet private weak var chartView: LineChartView!
    @IBOutlet private weak var chartRangeControl: UISegmentedControl!
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
    
    @IBOutlet private weak var totalEtherLabel: UILabel!
    
    @IBOutlet private weak var submitButton: TransitionButton!
    
    @IBOutlet private weak var tableView: UITableView!
    
    private let navHeaderView: MarketNavHeaderView = MarketNavHeaderView()
    
    private var marketGraphHours: UInt = 24
    private var gettingMarketTopAsks: Bool = false
    private var gettingMarketTopBids: Bool = false
    private var isSubmitting: Bool = false
    
    private var orderBookServiceProvider = MoyaProvider<TMMOrderBookService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
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
            navigationItem.titleView = navHeaderView
            
            let myOrdersBarItem = UIBarButtonItem(title: I18n.myOrderbooks.description, style: .plain, target: self, action: #selector(self.showMyOrdersView))
            navigationItem.rightBarButtonItem = myOrdersBarItem
        }
        blurOverlay.blurRatio = 0.5
        blurOverlay.trackingMode = .common
        UIView.animate(withDuration: 0.5) {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.blurOverlay.blurRadius = 20
            weakSelf.featureNotAvailableLabel.alpha = 1
        }
        featureNotAvailableLabel.text = I18n.exchangeNotAvailableInYourCountryError.description
        
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
        setupChartView()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let exchangeEnabled = userInfo?.exchangeEnabled ?? false
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.setNavigationBarHidden(!exchangeEnabled, animated: animated)
        }
        blurOverlay.isHidden = exchangeEnabled
        buySelectButton.isEnabled = exchangeEnabled
        sellSelectButton.isEnabled = exchangeEnabled
        submitButton.isEnabled = exchangeEnabled
        refresh()
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
    
    private func setupChartView() {
        
        chartRangeControl.tintColor = UIColor.clear
        let normalTextAttributes = [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize:14), NSAttributedString.Key.foregroundColor:UIColor.lightGray];
        let selectedTextAttributes = [NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize:14), NSAttributedString.Key.foregroundColor:UIColor.primaryBlue];
        chartRangeControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        chartRangeControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        chartRangeControl.setTitle(I18n.day.description, forSegmentAt: 0)
        chartRangeControl.setTitle(I18n.week.description, forSegmentAt: 1)
        chartRangeControl.setTitle(I18n.month.description, forSegmentAt: 2)
        chartRangeControl.setTitle(I18n.year.description, forSegmentAt: 3)
        
        chartView.delegate = self
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = true
        chartView.setScaleEnabled(true)
        chartView.pinchZoomEnabled = false
        chartView.autoScaleMinMaxEnabled = true
        
        //chartView.highlightFullBarEnabled = false
        
        chartView.legend.enabled = false
        
        //chartView.maxVisibleCount = 24
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = false
        xAxis.drawAxisLineEnabled = false
        //xAxis.labelCount = 7
        xAxis.valueFormatter = ChartTimeFormatter()
        
        let leftAxis = chartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = false
        
        let rightAxis = chartView.rightAxis
        rightAxis.axisMinimum = 0
        rightAxis.drawAxisLineEnabled = false
        rightAxis.drawLabelsEnabled = false
        rightAxis.drawGridLinesEnabled = false
        
        chartView.animate(xAxisDuration: 2.5)
    }
    
    private func setChartData() {
        var quantities: [ChartDataEntry] = []
        var prices: [ChartDataEntry] = []
        for d in self.graph {
            let x = Double(d.at?.timeIntervalSince1970 ?? 0)
            quantities.append(BarChartDataEntry(x: x, y: d.quantity.doubleValue, data: d))
            prices.append(ChartDataEntry(x: x, y: d.price.doubleValue, data: d))
        }
        let quantitySet = LineChartDataSet(values: quantities, label: "Quantity")
        quantitySet.axisDependency = .right
        quantitySet.setColor(UIColor(white: 0.8, alpha: 1))
        quantitySet.lineWidth = 0.6
        quantitySet.drawCirclesEnabled = false
        quantitySet.drawValuesEnabled = false
        quantitySet.fillAlpha = 0.2
        let gradientColors1 = [UIColor(white: 1, alpha: 1).cgColor,
                               UIColor(white: 0.9, alpha: 1).cgColor]
        let gradient1 = CGGradient(colorsSpace: nil, colors: gradientColors1 as CFArray, locations: nil)!
        quantitySet.fill = Fill(linearGradient: gradient1, angle: 90)
        quantitySet.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        quantitySet.drawFilledEnabled = true
        quantitySet.mode = .cubicBezier
        
        let priceSet = LineChartDataSet(values: prices, label: "Price")
        priceSet.axisDependency = .left
        priceSet.setColor(UIColor(red: 51/255, green: 181/255, blue: 229/255, alpha: 1))
        priceSet.lineWidth = 1
        priceSet.drawCirclesEnabled = false
        priceSet.drawValuesEnabled = false
        priceSet.fillAlpha = 0.2
        let gradientColors = [UIColor(red: 1, green: 1, blue: 1, alpha: 1.0).cgColor,
                              UIColor(red: 52/255.0, green: 152/255.0, blue: 219/255.0, alpha: 1.0).cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        priceSet.fill = Fill(linearGradient: gradient, angle: 90)
        priceSet.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        priceSet.drawFilledEnabled = true
        priceSet.mode = .stepped
        
        let data = LineChartData(dataSets: [priceSet, quantitySet])
        chartView.data = data
    }
    
    private func setupTableView() {
        tableView.register(cellType: MarketTopTableViewCell.self)
        self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 32.0
        tableView.rowHeight = UITableView.automaticDimension
        //tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func switchMarketGraphRange(_ sender: UISegmentedControl) {
        var range: UInt = 0
        switch sender.selectedSegmentIndex {
        case 0: range = 24
        case 1: range = 24 * 7
        case 2: range = 24 * 30
        case 3: range = 24 * 365
        default:
            range = 24
        }
        if range != self.marketGraphHours {
            self.marketGraphHours = range
            self.getMarketGraph()
        }
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
    
    @objc func showMyOrdersView() {
        let vc = MyOrderbooksViewController.instantiate()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    public func refresh() {
        getRate()
        getMarketTop(side: .ask)
        getMarketTop(side: .bid)
        getMarketGraph()
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return MarketTopTableViewHeader.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return MarketTopTableViewHeader()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(topBids.count, topAsks.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var askOrder: APIOrderBook?
        var bidOrder: APIOrderBook?
        if indexPath.row < topAsks.count {
            askOrder = topAsks[indexPath.row]
        }
        if indexPath.row < topBids.count {
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
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
        let alertController = AlertViewController(title: I18n.alert.description, body: I18n.confirmOrder.description)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
        let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak self] in
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
                weakSelf.refresh()
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
    
    private func getRate() {
        TMMOrderBookService.getRate(
            provider: self.orderBookServiceProvider)
            .then(in: .main, {[weak self] rate in
                guard let weakSelf = self else { return }
                weakSelf.exchangeRate = rate
                weakSelf.navHeaderView.fill(rate)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
            })
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
                weakSelf.tableView.header?.endRefreshing()
            }
        )
    }
    
    private func getMarketGraph() {
        TMMOrderBookService.getMarketGraph(
            hours: self.marketGraphHours,
            provider: self.orderBookServiceProvider)
            .then(in: .main, {[weak self] graph in
                guard let weakSelf = self else { return }
                weakSelf.graph = graph
                weakSelf.setChartData()
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
                }
        )
    }
    
}

extension ExchangeViewController: UITextFieldDelegate {
    
    @IBAction func textFieldDidChange(_ textField:UITextField) {
        var amount: NSDecimalNumber = 0
        var price: NSDecimalNumber = 0
        
        if textField == self.amountTextField {
            amount = NSDecimalNumber.init(string: textField.text)
            price = NSDecimalNumber.init(string: priceTextField.text)
        } else {
            amount = NSDecimalNumber.init(string: amountTextField.text)
            price = NSDecimalNumber.init(string: textField.text)
        }
        if amount.isNaN() {
            amount = 0
        }
        if price.isNaN() {
            price = 0
        }
        let totalEther = amount * price
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 2
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let totalEtherStr = formatter.string(from: totalEther)!
        totalEtherLabel.text = "Total Ether: \(totalEtherStr)"
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ExchangeViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        self.chartView.centerViewToAnimated(xValue: entry.x, yValue: entry.y,
                                            axis: self.chartView.data!.getDataSetByIndex(highlight.dataSetIndex).axisDependency,
                                            duration: 1)
        guard let data = entry.data as? APIMarketGraph else { return }
        var dateStr: String = ""
        if let at = data.at {
            let timeZone = NSTimeZone.local
            let formatterDate = DateFormatter()
            formatterDate.timeZone = timeZone
            formatterDate.dateFormat = "yyyy-MM-dd HH:mm"
            dateStr = formatterDate.string(from: at)
        }
        
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        let quantity = formatter.string(from: data.quantity)
        let price = formatter.string(from: data.price)
        let low = formatter.string(from: data.low)
        let high = formatter.string(from: data.high)
        self.chartTitleLabel.text = "\(dateStr) \(I18n.volumn.description): \(quantity ?? "0")\n\(I18n.price.description): \(price ?? "0") \(I18n.lowPrice.description): \(low ?? "0"), \(I18n.highPrice.description): \(high ?? "0")"
        //[_chartView moveViewToAnimatedWithXValue:entry.x yValue:entry.y axis:[_chartView.data getDataSetByIndex:dataSetIndex].axisDependency duration:1.0];
        //[_chartView zoomAndCenterViewAnimatedWithScaleX:1.8 scaleY:1.8 xValue:entry.x yValue:entry.y axis:[_chartView.data getDataSetByIndex:dataSetIndex].axisDependency duration:1.0];
    }
}
extension ExchangeViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
