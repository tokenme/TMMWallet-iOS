//
//  BlowupViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/18.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import Presentr
import IKEventSource
import Charts
import TMMSDK

class BlowupViewController: UIViewController {
    
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
    
    private var eventSource: EventSource?
    private var currentSession: APIBlowupEvent? {
        willSet {
            if newValue?.sessionId != self.currentSession?.sessionId {
                self.events.removeAll()
                self.roundBids.removeAll()
                self.getBids()
            }
        }
        didSet {
            if let session = self.currentSession {
                self.events.append(session)
            }
            if self.currentSession?.sessionId == 0 {
                DispatchQueue.main.async {[weak self] in
                    guard let weakSelf = self else { return }
                    weakSelf.rateLabel.text = I18n.waitBlowupNewSession.description
                    weakSelf.setChartData()
                    weakSelf.bidValueTextField.isEnabled = false
                    weakSelf.bidButton.isEnabled = false
                    weakSelf.escapeButton.stop()
                    weakSelf.escapeButton.showFetchAgain()
                    weakSelf.escapeButton.isEnabled = false
                }
                return
            } else if self.bidSessionId == self.currentSession?.sessionId {
                self.bidValueTextField.isEnabled = false
                self.bidButton.isEnabled = false
                self.escapeButton.isEnabled = !self.escapeButton.isCounting
            } else {
                self.bidValueTextField.isEnabled = true
                self.bidButton.isEnabled = true
                self.escapeButton.stop()
                self.escapeButton.showFetchAgain()
                self.escapeButton.isEnabled = false
            }
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 2
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            let rate: NSDecimalNumber = (currentSession?.rate ?? 0) + 1.0
            let rateStr = "\(formatter.string(from: rate)!)"
            
            let xAttributes = [NSAttributedString.Key.font:MainFont.light.with(size: 23), NSAttributedString.Key.foregroundColor:UIColor.white]
            let rateAttributes = [NSAttributedString.Key.font:MainFont.bold.with(size: 32), NSAttributedString.Key.foregroundColor:UIColor.white]
                
            let attString = NSMutableAttributedString(string: "x \(rateStr)")
                attString.addAttributes(xAttributes, range:NSRange.init(location: 0, length: 1))
                attString.addAttributes(rateAttributes, range: NSRange.init(location: 2, length: rateStr.count))
            DispatchQueue.main.async {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.rateLabel.attributedText = attString
                weakSelf.setChartData()
            }
        }
    }
    
    @IBOutlet private weak var chartView: CombinedChartView!
    @IBOutlet private weak var rateLabel: UILabel!
    @IBOutlet private weak var bidValueTextField: UITextField!
    @IBOutlet private weak var bidButton: TransitionButton!
    @IBOutlet private weak var escapeButton: RNCountdownButton!
    @IBOutlet private weak var tableView: UITableView!
    
    private var events: [APIBlowupEvent] = []
    private var roundBids: [APIBlowupEvent] = []
    private var bids: [APIBlowupBid] = []
    
    private var bidSessionId: UInt64 = 0 {
        didSet {
            if bidSessionId == self.currentSession?.sessionId {
                self.bidValueTextField.isEnabled = false
                self.bidButton.isEnabled = false
                self.escapeButton.isEnabled = true
            } else {
                self.bidValueTextField.isEnabled = true
                self.bidButton.isEnabled = true
                self.escapeButton.isEnabled = false
            }
        }
    }
    private var isBidding: Bool = false
    private var isEscaping: Bool = false
    private var gettingBids: Bool = false
    
    private var blowupServiceProvider = MoyaProvider<TMMBlowupService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static func instantiate() -> BlowupViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BlowupViewController") as! BlowupViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitioningDelegate = self
        self.setupChartView()
        bidButton.setTitle(I18n.bid.description, for: .normal)
        bidButton.setTitleColor(UIColor.darkGray, for: .disabled)
        escapeButton.setTitleColor(UIColor.darkGray, for: .disabled)
        setupTableView()
        setupEscapeButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        rateLabel.text = I18n.connecting.description
        self.bidValueTextField.isEnabled = false
        self.bidButton.isEnabled = false
        self.escapeButton.isEnabled = false
        setupServerListener()
        getBids()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.eventSource?.close()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupTableView() {
        self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: BlowupBidTableViewCell.self)
    }
    
    private func setupEscapeButton() {
        escapeButton.titleColorForEnable = UIColor.white
        escapeButton.bgColorForEnable = UIColor.red
        escapeButton.titleColorForDisable = UIColor.lightGray
        escapeButton.bgColorForDisable = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        escapeButton.titleColorForCountingDisable = UIColor.lightGray
        escapeButton.isEnabled = false
        escapeButton.maxCountingSeconds = 30
        escapeButton.enableTitle = I18n.escape.description
        escapeButton.disableTitle = I18n.escape.description
        escapeButton.countingTitle = I18n.escape.description
        escapeButton.borderColorForEnable = nil
        escapeButton.borderColorForDisable = nil
        escapeButton.layer.borderWidth = 0
        escapeButton.layer.cornerRadius = 10
    }
}

extension BlowupViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension BlowupViewController {
    
    private func setupChartView() {
        
        chartView.drawOrder = [DrawOrder.line.rawValue,
                               DrawOrder.scatter.rawValue]
        
        //chartView.delegate = self
        chartView.chartDescription?.enabled = false
        chartView.dragEnabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.autoScaleMinMaxEnabled = true
        chartView.drawGridBackgroundEnabled = false
        chartView.drawBordersEnabled = false
        chartView.backgroundColor = UIColor.darkDefault
        
        //chartView.highlightFullBarEnabled = false
        
        chartView.legend.enabled = false
        
        chartView.layer.cornerRadius = 10
        chartView.layer.borderWidth = 0.0
        chartView.clipsToBounds = true
        
        //chartView.maxVisibleCount = 24
        
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawGridLinesEnabled = false
        xAxis.drawLabelsEnabled = false
        xAxis.drawAxisLineEnabled = true
        xAxis.axisLineWidth = 1
        xAxis.axisLineColor = UIColor.lightGray
        //xAxis.labelCount = 7
        
        let leftAxis = chartView.leftAxis
        leftAxis.axisLineColor = UIColor.lightGray
        leftAxis.drawAxisLineEnabled = true
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = false
        leftAxis.axisLineWidth = 1
        
        let rightAxis = chartView.rightAxis
        rightAxis.enabled = false
        
        chartView.animate(xAxisDuration: 2.5)
    }
    
    private func setChartData() {
        var entries: [ChartDataEntry] = []
        var scatters: [ChartDataEntry] = []
        var x: Double = 0
        for ev in self.events {
            entries.append(ChartDataEntry(x: x, y: (ev.rate + 1).doubleValue))
            x = x + 1
        }
        for ev in self.roundBids {
            x = 0
            var y: Double = 0
            for evp in self.events {
                let evpY = (evp.rate + 1).doubleValue
                if y == 0 || y >= evpY {
                    y = evpY
                } else if y < evpY {
                    break
                }
                x = x + 1
            }
            scatters.append(ChartDataEntry(x: x, y: (ev.rate + 1).doubleValue ))
        }
        let dataSet = LineChartDataSet(values: entries, label: "Bids")
        dataSet.axisDependency = .left
        dataSet.setColor(UIColor.redish)
        dataSet.lineWidth = 1
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.fillAlpha = 0.2
        let gradientColors = [UIColor(red: 1, green: 1, blue: 1, alpha: 1.0).cgColor,
                              UIColor(red: 52/255.0, green: 152/255.0, blue: 219/255.0, alpha: 1.0).cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        dataSet.fill = Fill(linearGradient: gradient, angle: 90)
        dataSet.highlightColor = UIColor(red: 244/255, green: 117/255, blue: 117/255, alpha: 1)
        dataSet.drawFilledEnabled = true
        dataSet.mode = .stepped
        
        let scatterSet = ScatterChartDataSet(values: scatters, label: "Bid")
        scatterSet.axisDependency = .left
        scatterSet.setScatterShape(.circle)
        scatterSet.scatterShapeHoleColor = .black
        scatterSet.setColor(.white)
        scatterSet.valueTextColor = .white
        scatterSet.scatterShapeSize = 6
        scatterSet.drawValuesEnabled = true
        scatterSet.valueFont = .systemFont(ofSize: 10)
        
        let data = CombinedChartData()
        data.lineData = LineChartData(dataSet: dataSet)
        data.scatterData = ScatterChartData(dataSet: scatterSet)
        chartView.data = data
    }
    
    private func setupServerListener() {
        self.eventSource = EventSource(url: TMMConfigs.Blowup.notifyServer, headers: ["Authorization" : "Bearer \(AccessTokenClosure())"])
        guard let es = eventSource else { return }
        es.onOpen {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.rateLabel.text = I18n.connected.description
        }
        es.onError {[weak self] (error) in
            guard let err = error else { return }
            guard let weakSelf = self else { return }
            print(err.localizedDescription)
            weakSelf.rateLabel.text = I18n.disconnected.description
        }
        es.addEventListener("message", handler: {[weak self] (id, event, data) in
            let decoder = JSONDecoder()
            if let jsonData = data?.data(using: .utf8) {
                do {
                    guard let weakSelf = self else { return }
                    let ev = try decoder.decode(APIBlowupEvent.self, from: jsonData)
                    if ev.type == .session {
                        weakSelf.currentSession = ev
                    } else if ev.type == .bid && weakSelf.currentSession?.sessionId == ev.sessionId {
                        weakSelf.roundBids.append(ev)
                    }
                } catch  {
                    //print(err.localizedDescription)
                }
            }
            // print("event: \(event ?? ""), data: \(data ?? "")")
        })
    }
}

extension BlowupViewController {
    
    @IBAction private func bid() {
        if self.isBidding {
            return
        }
        guard let ev = self.eventSource else { return }
        if ev.readyState != .open {
            return
        }
        self.isBidding = true
        self.bidValueTextField.resignFirstResponder()
        guard let sessionId = self.currentSession?.sessionId, sessionId > 0 else { return }
        let points = NSDecimalNumber.init(string: bidValueTextField.text)
        if points.isNaN() { return }
        guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else { return }
        bidButton.startAnimation()
        TMMBlowupService.newBid(
            sessionId: sessionId,
            points: points,
            idfa: deviceId,
            provider: self.blowupServiceProvider)
            .then(in: .main, {[weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.bidSessionId = sessionId
                weakSelf.escapeButton.start()
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: I18n.biddingSuccessMsg.description, closeBtn: I18n.close.description)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isBidding = false
                weakSelf.bidButton.stopAnimation(animationStyle: .normal, completion: nil)
            }
        )
    }
    
    @IBAction private func escape() {
        if self.isEscaping {
            return
        }
        guard let ev = self.eventSource else { return }
        if ev.readyState != .open {
            return
        }
        self.isEscaping = true
        guard let sessionId = self.currentSession?.sessionId, sessionId > 0 else { return }
        guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else { return }
        TMMBlowupService.tryEscape(
            sessionId: sessionId,
            idfa: deviceId,
            provider: self.blowupServiceProvider)
            .then(in: .main, {[weak self] ev in
                guard let weakSelf = self else { return }
                weakSelf.bidSessionId = 0
                let formatter = NumberFormatter()
                formatter.maximumFractionDigits = 4
                formatter.groupingSeparator = "";
                formatter.numberStyle = NumberFormatter.Style.decimal
                let points = formatter.string(from: ev.value * (ev.rate + 1))
                let msg = String(format: I18n.escapeSuccessMsg.description, points!)
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.success.description, desc: msg, closeBtn: I18n.close.description)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isEscaping = false
                }
        )
    }
    
    private func getBids() {
        if self.gettingBids {
            return
        }
        self.gettingBids = true
        TMMBlowupService.getBids(
            provider: self.blowupServiceProvider)
            .then(in: .main, {[weak self] bids in
                guard let weakSelf = self else { return }
                weakSelf.bids = bids
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingBids = false
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
            }
        )
    }
}


extension BlowupViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bids.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bid = self.bids[indexPath.row]
        let cell = tableView.dequeueReusableCell(for: indexPath) as BlowupBidTableViewCell
        cell.fill(bid)
        return cell
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
