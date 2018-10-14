//
//  TransferTableViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/13.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import Moya
import Hydra
import Presentr

class TransferTableViewController: UITableViewController {
    
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
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var tokenNameLabel: UILabel!
    @IBOutlet private weak var tokenSymbolLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var balanceTitleLabel: UILabel!
    @IBOutlet private weak var transferAmountTextField: UITextField!
    
    @IBOutlet private weak var toLabel: UILabel!
    @IBOutlet private weak var walletAddressTextField: UITextField!
    
    private var transferButton: TransitionButton = TransitionButton(type: .custom)
    
    private var isTransfering: Bool = false
    
    private var gettingInfo: Bool = false
    
    private var qrcodeResult: QRCodeResult?
    
    private var token: APIToken?
    
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
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
            let scanBarItem = UIBarButtonItem(image: UIImage(named: "Scan"), style: .plain, target: self, action: #selector(self.showScanView))
            navigationItem.rightBarButtonItem = scanBarItem
        }
        setupTableView()
        
        transferAmountTextField.attributedPlaceholder = NSAttributedString(string: I18n.transferAmount.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:15), NSAttributedString.Key.foregroundColor:UIColor.lightGray])
        toLabel.text = I18n.to.description
        walletAddressTextField.attributedPlaceholder = NSAttributedString(string: I18n.walletAddress.description, attributes: [NSAttributedString.Key.font:UIFont.systemFont(ofSize:15), NSAttributedString.Key.foregroundColor:UIColor.lightGray])
        
        if let tokenAddress = qrcodeResult?.contractAddress {
            getInfo(address: tokenAddress)
        }
        setupView()
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    static func instantiate() -> TransferTableViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TransferTableViewController") as! TransferTableViewController
    }
    
    public func setToken(token: APIToken) {
        self.token = token
    }
    
    public func setQrcodeResult(_ result: QRCodeResult) {
        self.qrcodeResult = result
    }
    
    private func setupTableView() {
        self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 55.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: CGFloat.leastNormalMagnitude))
        
        transferButton.setTitle(I18n.send.description, for: .normal)
        transferButton.backgroundColor = UIColor.primaryBlue
        transferButton.disabledBackgroundColor = UIColor.lightGray
        transferButton.spinnerColor = UIColor.white
        transferButton.tintColor = UIColor.white
        transferButton.frame = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 40)
        
        transferButton.addTarget(self, action: #selector(self.transfer), for: .touchUpInside)
        
        transferButton.isEnabled = false
        tableView.tableFooterView = transferButton
    }
    
    private func setupView() {
        guard let token = self.token else { return }
        navigationItem.title = "\(token.symbol ?? "") \(I18n.send.description)"
        if let icon = token.icon {
            iconImageView.kf.setImage(with: URL(string: icon))
        }
        tokenNameLabel.text = token.name
        tokenSymbolLabel.text = token.symbol
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.groupingSeparator = "";
        formatter.numberStyle = NumberFormatter.Style.decimal
        balanceLabel.text = formatter.string(from: token.balance)
        balanceTitleLabel.text = I18n.balance.description
        transferButton.isEnabled = true
        
        if let walletAddress = qrcodeResult?.wallet {
            walletAddressTextField.text = walletAddress
        }
    }
    
    @objc func showScanView() {
        let vc = ScanViewController()
        vc.scanDelegate = self
        self.present(vc, animated: true, completion: nil)
    }
}

extension TransferTableViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FadeTransition(transitionDuration: 0.5, startingAlpha: 0.8)
    }
    
}

extension TransferTableViewController {
    
    private func verifyFields() -> Bool {
        if !verifyAmount() {
            return false
        }
        if !verifyWallet() {
            return false
        }
        return true
    }
    private func verifyAmount() -> Bool {
        guard let balance = self.token?.balance else { return false }
        let amount = NSDecimalNumber.init(string: transferAmountTextField.text)
        print(amount.floatValue, balance)
        if amount <= 0 {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.emptyTokenAmount.description, closeBtn: I18n.close.description)
            return false
        }
        if amount > balance {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.exceedTokenAmount.description, closeBtn: I18n.close.description)
            return false
        }
        return true
    }
    
    private func verifyWallet() -> Bool {
        guard let wallet = walletAddressTextField.text else {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.emptyWalletAddress.description, closeBtn: I18n.close.description)
            return false
        }
        if  wallet.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.emptyWalletAddress.description, closeBtn: I18n.close.description)
            return false
        }
        if !wallet.starts(with: "0x") || wallet.lengthOfBytes(using: String.Encoding.utf8) != 42 {
            UCAlert.showAlert(self.alertPresenter, title: I18n.error.description, desc: I18n.invalidWalletAddress.description, closeBtn: I18n.close.description)
            return false
        }
        return true
    }
    
    @objc func transfer() {
        if self.isTransfering {
            return
        }
        if !self.verifyFields() { return }
        guard let tokenAddress = self.token?.address else { return }
        guard let toAddress = walletAddressTextField.text else { return }
        let amount = NSDecimalNumber.init(string: transferAmountTextField.text)
        if amount.isNaN() { return }
        
        self.isTransfering = true
        transferButton.startAnimation()
        TMMTokenService.transferToken(
            token: tokenAddress,
            amount: amount,
            to: toAddress,
            provider: self.tokenServiceProvider)
            .then(in: .main, {[weak self] tx in
                guard let weakSelf = self else { return }
                guard let receipt = tx.receipt else { return }
                let message = String(format: I18n.newTransactionDesc.description, receipt)
                let alertController = Presentr.alertViewController(title: I18n.newTransactionTitle.description, body: message)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel) { alert in
                    //
                }
                let okAction = AlertAction(title: I18n.viewTransaction.description, style: .destructive) {[weak self] alert in
                    guard let weakSelf = self else { return }
                    let urlString = "https://etherscan.io/tx/\(receipt)"
                    guard let url = URL(string: urlString) else { return }
                    let vc = TMMWebViewController.instantiate()
                    vc.request = URLRequest(url: url)
                    weakSelf.navigationController?.pushViewController(vc, animated: true)
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.isTransfering = false
                weakSelf.transferButton.stopAnimation(animationStyle: .normal, completion: nil)
            }
        )
    }
    
    private func getInfo(address: String) {
        if self.gettingInfo {
            return
        }
        self.gettingInfo = true
        TMMTokenService.getInfo(
            address: address,
            provider: self.tokenServiceProvider)
            .then(in: .main, {[weak self] token in
                guard let weakSelf = self else { return }
                weakSelf.token = token
                weakSelf.setupView()
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
                weakSelf.navigationController?.popViewController(animated: true)
            }).always(in: .background, body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingInfo = false
            })
    }
}

extension TransferTableViewController: ScanViewDelegate {
    func collectHandler(_ qrcode: String) {
        var walletAddress: String?
        if qrcode.hasPrefix("ethereum:") {
            let data: String = qrcode.replacingOccurrences(of: "ethereum:", with: "")
            let components = data.split(separator: "?")
            walletAddress = String(components[0])
        } else {
            walletAddress = qrcode
        }
        if walletAddress?.hasPrefix("0x") ?? false && walletAddress?.count == 42 {
            walletAddressTextField.text = walletAddress
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

extension TransferTableViewController: UITextFieldDelegate {
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.isEqual(transferAmountTextField) {
            let _ = self.verifyAmount()
        } else if textField.isEqual(walletAddressTextField){
            let _ = self.verifyWallet()
        }
    }
}
