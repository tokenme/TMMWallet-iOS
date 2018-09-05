//
//  AppTaskFetcher.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/5.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import Moya
import Hydra
import TMMSDK

class AppTaskFetcher {
    
    weak public var delegate: AppTaskFetcherDelegate?
    private var gettingTasks = false
    private var updatingTask = false
    
    private var taskServiceProvider = MoyaProvider<TMMTaskService>(plugins: [networkActivityPlugin, AccessTokenPlugin(tokenClosure: AccessTokenClosure())])
    
    public func getTasks() {
        if gettingTasks { return }
        gettingTasks = true
        TMMTaskService.getAppsCheck(
            idfa: TMMBeacon.shareInstance().deviceId(),
            provider: self.taskServiceProvider)
            .then(in: .background, {[weak self] tasks in
                guard let weakSelf = self else { return }
                weakSelf.delegate?.updateTasks(tasks)
            }).catch(in: .main, { error in
                UCAlert.showAlert(imageName: "Error", title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background,  body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.gettingTasks = false
            })
    }
    
    public func updateTask(_ task: APIAppTask, _ status: Int8) {
        if updatingTask { return }
        updatingTask = true
        guard let taskId = task.id else {return}
        TMMTaskService.appInstall(
            idfa: TMMBeacon.shareInstance().deviceId(),
            bundleId: task.bundleId,
            taskId: taskId,
            status: status,
            provider: self.taskServiceProvider)
            .then(in: .background, {[weak self] task in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.delegate?.updateTask(task)
                DispatchQueue.main.async {
                    let formatter = NumberFormatter()
                    formatter.maximumFractionDigits = 2
                    formatter.groupingSeparator = "";
                    formatter.numberStyle = NumberFormatter.Style.decimal
                    let formattedBonus = formatter.string(from: task.bonus)!
                    if task.status == -1 {
                        let title = "\(I18n.minusPoints.description) \(formattedBonus) \(I18n.points.description)"
                        UCAlert.showAlert(imageName: "Error", title: title, desc: I18n.appTaskFailed.description, closeBtn: I18n.close.description)
                    } else {
                        let title = "\(I18n.earn.description) \(formattedBonus) \(I18n.points.description)"
                        UCAlert.showAlert(imageName: "Success", title: title, desc: I18n.appTaskSuccess.description, closeBtn: I18n.close.description)
                    }
                }
            }).catch(in: .main, {error in
                UCAlert.showAlert(imageName: "Error", title: I18n.error.description, desc: (error as! TMMAPIError).description, closeBtn: I18n.close.description)
            }).always(in: .background,  body: {[weak self] in
                guard let weakSelf = self else { return }
                weakSelf.updatingTask = false
            })
    }
}

public protocol AppTaskFetcherDelegate: NSObjectProtocol {
    func updateTasks(_ tasks: [APIAppTask])
    func updateTask(_ task: APIAppTask)
}
