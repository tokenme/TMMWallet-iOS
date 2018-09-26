//
//  ETHWalletViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/11.
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
import SwipeCellKit

class ETHWalletViewController: UIViewController {
    
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
    
    @IBOutlet private weak var summaryView: PastelView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var addressButton: UIButton!
    @IBOutlet private weak var balanceLabel: UILabel!
    
    
    let walletQRCodePresenter: Presentr = {
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
    
    private var tokens: [APIToken] = [] {
        didSet {
            var totalPrice: NSDecimalNumber = 0
            for token in tokens {
                totalPrice += token.price * token.balance
            }
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 4
            formatter.groupingSeparator = "";
            formatter.numberStyle = NumberFormatter.Style.decimal
            balanceLabel.text = formatter.string(from: totalPrice)
        }
    }
    
    private var loadingTokens = false
    
    private var tokenServiceProvider = MoyaProvider<TMMTokenService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
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
            navigationController.navigationBar.isTranslucent = true
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
            navigationItem.title = I18n.ethWallet.description
            
            let scanBarItem = UIBarButtonItem(image: UIImage(named: "Scan"), style: .plain, target: self, action: #selector(self.showScanView))
            navigationItem.rightBarButtonItem = scanBarItem
        }
        
        setupSummaryView()
        setupTableView()
        if userInfo != nil {
            refresh()
        }
        
        guard let userInfo = self.userInfo else { return }
        let copyImage = UIImage(named: "Wallet")?.kf.resize(to: CGSize(width: 14, height: 14)).withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        addressButton.set(image: copyImage, title: userInfo.wallet ?? "", titlePosition: .left, additionalSpacing: 5.0, state: .normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = true
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
    
    static func instantiate() -> ETHWalletViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ETHWalletViewController") as! ETHWalletViewController
    }
    
    private func setupSummaryView() {
        summaryView.layer.cornerRadius = 15.0
        summaryView.layer.borderWidth = 0
        summaryView.layer.rasterizationScale = UIScreen.main.scale
        summaryView.layer.contentsScale =  UIScreen.main.scale
        summaryView.clipsToBounds = true
        
        summaryView.startPastelPoint = .bottomLeft
        summaryView.endPastelPoint = .topRight
        summaryView.animationDuration = 3.0
        summaryView.setColors([UIColor(red: 156/255, green: 39/255, blue: 176/255, alpha: 1.0),
                               UIColor(red: 255/255, green: 64/255, blue: 129/255, alpha: 1.0),
                               UIColor(red: 123/255, green: 31/255, blue: 162/255, alpha: 1.0),
                               UIColor(red: 32/255, green: 76/255, blue: 255/255, alpha: 1.0),
                               UIColor(red: 32/255, green: 158/255, blue: 255/255, alpha: 1.0),
                               UIColor(red: 90/255, green: 120/255, blue: 127/255, alpha: 1.0),
                               UIColor(red: 58/255, green: 255/255, blue: 217/255, alpha: 1.0)])
        
        summaryView.startAnimation()
    }
    
    private func setupTableView() {
        tableView.register(cellType: TokenTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 60.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        
        SkeletonAppearance.default.multilineHeight = 10
        tableView.showAnimatedSkeleton()
    }
    
    public func refresh() {
        getTokens()
    }
    
    @IBAction func showWalletQRCode() {
        let vc = WalletQRCodeViewController.instantiate()
        vc.address = userInfo?.wallet
        customPresentViewController(walletQRCodePresenter, viewController: vc, animated: true)
    }
    
    @objc func showScanView() {
        let vc = ScanViewController()
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
}

extension ETHWalletViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension ETHWalletViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if orientation == .left {
            let receiveAction = SwipeAction(style: .default, title: I18n.receive.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                let vc = WalletQRCodeViewController.instantiate()
                vc.address = weakSelf.userInfo?.wallet
                let token = weakSelf.tokens[indexPath.row]
                vc.token = token
                weakSelf.customPresentViewController(weakSelf.walletQRCodePresenter, viewController: vc, animated: true)
            }
            receiveAction.backgroundColor = UIColor.greenGrass
            receiveAction.image = UIImage(named: "TransferIn")?.kf.resize(to: CGSize(width: 30, height: 30), for: .aspectFit).withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            
            return [receiveAction]
        }else {
            let sendAction = SwipeAction(style: .default, title: I18n.send.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                var ethBalance: NSDecimalNumber = 0
                for token in weakSelf.tokens {
                    if token.address == "" && token.name == "Ethereum" {
                        ethBalance = token.balance
                        break
                    }
                }
                let token = weakSelf.tokens[indexPath.row]
                if ethBalance < token.minGas {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 4
                    formatter.groupingSeparator = "";
                    formatter.numberStyle = NumberFormatter.Style.decimal
                    let message = I18n.needMinGasError.description.replacingOccurrences(of: "#gas#", with: formatter.string(from: token.minGas)!)
                    UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: message, closeBtn: I18n.close.description)
                    return
                }
                let vc = TransferTableViewController.instantiate()
                vc.setToken(token: token)
                weakSelf.navigationController?.pushViewController(vc, animated: true)
            }
            sendAction.backgroundColor = UIColor.primaryBlue
            sendAction.image = UIImage(named: "TransferOut")?.kf.resize(to: CGSize(width: 30, height: 30), for: .aspectFit).withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
            
            return [sendAction]
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        return options
    }
}

extension ETHWalletViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SimpleHeaderView.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: self.tableView(tableView, heightForHeaderInSection: section))
        let view = SimpleHeaderView(frame: frame)
        view.fill(I18n.assets.description)
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tokens.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath) as TokenTableViewCell
        cell.delegate = self
        let token = self.tokens[indexPath.row]
        cell.fill(token)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let token = self.tokens[indexPath.row]
        let vc = TransactionsTableViewController.instantiate()
        vc.setToken(token: token)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingTokens
    }
}

extension ETHWalletViewController: SkeletonTableViewDataSource {
    
    func numSections(in collectionSkeletonView: UITableView) -> Int {
        return 1
    }
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return LoadingTableViewCell.self.reuseIdentifier
    }
}

extension ETHWalletViewController {
    private func getTokens() {
        if self.loadingTokens {
            return
        }
        self.loadingTokens = true
        TMMTokenService.getAssets(
            provider: self.tokenServiceProvider)
            .then(in: .main, {[weak self] tokens in
                guard let weakSelf = self else { return }
                weakSelf.tokens = tokens
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadingTokens = false
                weakSelf.tableView.hideSkeleton()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
                let fromAnimation = AnimationType.from(direction: .right, offset: 30.0)
                UIView.animate(views: weakSelf.tableView.visibleCells, animations: [fromAnimation], completion:nil)
            }
        )
    }
}

extension ETHWalletViewController: ScanViewDelegate {
    func collectHandler(_ qrcode: String) {
        if qrcode.hasPrefix("ethereum:") {
            let data: String = qrcode.replacingOccurrences(of: "ethereum:", with: "")
            let components = data.split(separator: "?")
            let wallet = components[0]
            var result = QRCodeResult(String(wallet))
            if components.count == 2 {
                let args = components[1].split(separator: "&")
                for arg in args {
                    let splitted = arg.split(separator: "=")
                    if splitted.count != 2 {
                        continue
                    }
                    let key = splitted[0]
                    let val = splitted[1]
                    switch key {
                    case "contractAddress":
                        result.setContractAddress(String(val))
                    case "decimals":
                        if let decimals = Int8(val) {
                            result.setDecimals(decimals)
                        }
                    default:
                        continue
                    }
                }
            }
            if result.contractAddress == nil || result.contractAddress == "" {
                result.setContractAddress("0x")
            }
            let vc = TransferTableViewController.instantiate()
            vc.setQrcodeResult(result)
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
        let alertController = Presentr.alertViewController(title: I18n.alert.description, body: qrcode)
        let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
            //
        }
        let okAction = AlertAction(title: I18n.copy.description, style: .destructive) { alert in
            let paste = UIPasteboard.general
            paste.string = qrcode
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        customPresentViewController(alertPresenter, viewController: alertController, animated: true)
    }
}

extension ETHWalletViewController: LoginViewDelegate {
    func loginSucceeded(token: APIAccessToken?) {
        self.refresh()
    }
}
