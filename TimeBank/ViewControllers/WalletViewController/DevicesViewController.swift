//
//  DevicesViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/21.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
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
import TMMSDK
import SnapKit
import SwipeCellKit

public enum DeviceSelectAction {
    case withdraw
    case change
    case redeemCdp
}

class DevicesViewController: UIViewController {
    
    public weak var selectorDelegate: DeviceSelectorDelegate?
    
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
    
    private var currentDeviceIsBinded: Bool {
        get {
            if self.loadingDevices {
                return true
            }
            guard let deviceId = TMMBeacon.shareInstance()?.deviceId() else {
                return false
            }
            for device in self.devices {
                if device.idfa == deviceId {
                    return true
                }
            }
            return false
        }
    }
    
    public var selectAction: DeviceSelectAction?
    
    private var loadingDevices = false
    private var unbindingDevice = false
    
    public var devices: [APIDevice] = []
    
    private let alertPresenter: Presentr = {
        let presenter = Presentr(presentationType: .alert)
        presenter.transitionType = TransitionType.coverVerticalFromTop
        presenter.dismissOnSwipe = true
        return presenter
    }()
    
    @IBOutlet private weak var selectDeviceLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    
    private var deviceServiceProvider = MoyaProvider<TMMDeviceService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure), SignaturePlugin(appKeyClosure: AppKeyClosure, secretClosure: SecretClosure, appBuildClosure: AppBuildClosure)])
    
    deinit {
        tableView?.header?.removeObservers()
        tableView?.footer?.removeObservers()
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController = self.navigationController {
            if #available(iOS 11.0, *) {
                navigationController.navigationBar.prefersLargeTitles = false
                self.navigationItem.largeTitleDisplayMode = .automatic;
            }
            navigationController.navigationBar.isTranslucent = false
            navigationController.navigationBar.setBackgroundImage(UIImage(color: UIColor(white: 0.98, alpha: 1)), for: .default)
            navigationController.navigationBar.shadowImage = UIImage(color: UIColor(white: 0.91, alpha: 1), size: CGSize(width: 0.5, height: 0.5))
        }
        selectDeviceLabel.text = I18n.selectDevice.description
        setupTableView()
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
        MTA.trackPageViewBegin(TMMConfigs.PageName.devices)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        MTA.trackPageViewEnd(TMMConfigs.PageName.devices)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setupTableView() {
        tableView.register(cellType: DeviceTableViewCell.self)
        tableView.register(cellType: LoadingTableViewCell.self)
        tableView.register(cellType: AdTableViewCell.self)
        //self.tableView.separatorStyle = .none
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.header = ZHRefreshNormalHeader.headerWithRefreshing { [weak self] in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }
        if devices.count > 0 {
            tableView.reloadDataWithAutoSizingCellWorkAround()
        } else {
            SkeletonAppearance.default.multilineHeight = 10
            tableView.showAnimatedSkeleton()
        }
    }
    
    public func refresh() {
        getDevices()
    }
}

extension DevicesViewController: SwipeTableViewCellDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let device = self.devices[indexPath.row]
        if device.creative != nil {
            return nil
        }
        if orientation == .right {
            let sendAction = SwipeAction(style: .default, title: I18n.unbind.description) {[weak self] action, indexPath in
                guard let weakSelf = self else { return }
                guard let deviceId = weakSelf.devices[indexPath.row].id else { return }
                let alertController = AlertViewController(title: I18n.alert.description, body: I18n.confirmUnbind.description)
                let cancelAction = AlertAction(title: I18n.close.description, style: .cancel, handler: nil)
                let okAction = AlertAction(title: I18n.confirm.description, style: .destructive) {[weak weakSelf] in
                    guard let weakSelf2 = weakSelf else { return }
                    weakSelf2.runUnbindDevice(deviceId)
                }
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                weakSelf.customPresentViewController(weakSelf.alertPresenter, viewController: alertController, animated: true)
                
            }
            sendAction.backgroundColor = UIColor.red
            sendAction.textColor = UIColor.white
            
            return [sendAction]
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .selection
        options.transitionStyle = .border
        return options
    }
}

extension DevicesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.currentDeviceIsBinded {
            return 0
        }
        return UnbindDeviceHeaderView.height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.currentDeviceIsBinded {
            return nil
        }
        let view = UnbindDeviceHeaderView()
        view.delegate = self
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = self.devices[indexPath.row]
        if let creative = device.creative {
            let cell = tableView.dequeueReusableCell(for: indexPath) as AdTableViewCell
            cell.fill(creative, fullFill: true)
            return cell
        }
        let cell = tableView.dequeueReusableCell(for: indexPath) as DeviceTableViewCell
        cell.delegate = self
        cell.fill(device)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.isSelected = false
        if self.devices.count < indexPath.row + 1 { return }
        let device = self.devices[indexPath.row]
        
        if let creative = device.creative {
            if let link = URL(string:creative.link) {
                let vc = TMMWebViewController.instantiate()
                vc.request = URLRequest(url: link)
                self.navigationController?.pushViewController(vc, animated: true)
            }
            return
        }
        
        if let selectorDelegate = self.selectorDelegate,
            let selectAction = self.selectAction {
            self.dismiss(animated: true, completion: {
                selectorDelegate.selected(device: device, selectAction: selectAction)
            })
            return
        }
        let vc = DeviceAppsViewController.instantiate()
        vc.setDevice(device)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: device.name, style: .plain, target: nil, action: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return !self.loadingDevices
    }
    
}

extension DevicesViewController: SkeletonTableViewDataSource {
    
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

extension DevicesViewController {
    
    private func runUnbindDevice(_ deviceId: String) {
        self.unbindDevice(id: deviceId).then(in: .main, {[weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.refresh()
        }).catch(in: .main, {[weak self] error in
            switch error as! TMMAPIError {
            case .ignore:
                return
            default: break
            }
            guard let weakSelf = self else { return  }
            UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description, viewController: weakSelf)
        }).always(in: .main, body: {[weak self]  in
            guard let weakSelf = self else { return }
            weakSelf.unbindingDevice = false
        })
    }
    
    private func getDevices() {
        if self.loadingDevices {
            return
        }
        self.loadingDevices = true
        TMMDeviceService.getDevices(
            provider: self.deviceServiceProvider)
            .then(in: .main, {[weak self] devices in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.devices = devices
            }).catch(in: .main, {[weak self] error in
                guard let weakSelf = self else { return }
                UCAlert.showAlert(weakSelf.alertPresenter, title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .main, body: {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.loadingDevices = false
                weakSelf.tableView.hideSkeleton()
                weakSelf.tableView.reloadDataWithAutoSizingCellWorkAround()
                weakSelf.tableView.header?.endRefreshing()
                let fromAnimation = AnimationType.from(direction: .right, offset: 30.0)
                UIView.animate(views: weakSelf.tableView.visibleCells, animations: [fromAnimation], completion:nil)
                }
        )
    }
    
    private func unbindDevice(id: String) -> Promise<Void> {
        return Promise<Void> (in: .background, {[weak self] resolve, reject, _ in
            guard let weakSelf = self else {
                reject(TMMAPIError.ignore)
                return
            }
            if weakSelf.unbindingDevice {
                reject(TMMAPIError.ignore)
                return
            }
            weakSelf.unbindingDevice = true
            TMMDeviceService.unbindUser(
                id: id,
                provider: weakSelf.deviceServiceProvider)
                .then(in: .background, {user in
                    resolve(())
                }).catch(in: .background, { error in
                    reject(error)
                })
        })
    }
}

extension DevicesViewController: ViewUpdateDelegate {
    func shouldRefresh() {
        self.refresh()
    }
}

public protocol DeviceSelectorDelegate: NSObjectProtocol {
    func selected(device: APIDevice, selectAction: DeviceSelectAction)
}
