//
//  AppTaskChecker.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/5.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import Schedule
import SwiftyUserDefaults

class AppTaskChecker: NSObject, AppTaskFetcherDelegate {
    
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
    
    private var tasks: [APIAppTask] = []
    
    private let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
    
    private var getTasksSchedule: Task?
    
    private var checkTasksSchedule: Task?
    
    private var fetcher: AppTaskFetcher?
    
    private let maxSchemeQuery = MaxSchemeQuery()
    
    static let sharedInstance = AppTaskChecker()
    
    override init() {
        super.init()
        
        self.fetcher = AppTaskFetcher()
        self.fetcher?.delegate = self
        
        self.getTasksSchedule = Schedule.every(1.hour).do(queue: self.queue) {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.fetchTasks()
        }
        
        self.checkTasksSchedule = Schedule.every(30.seconds).do(queue: self.queue) {[weak self] in
            guard let weakSelf = self else { return }
            weakSelf.checkTasks()
        }
        
        self.stop()
    }
    
    public func addTask(_ task: APIAppTask) {
        var found = false
        for t in self.tasks {
            if t.bundleId == task.bundleId {
                found = true
            }
        }
        if !found {
            self.tasks.append(task)
        }
    }
    
    public func start() {
        self.fetchTasks()
        self.getTasksSchedule?.resume()
        self.checkTasksSchedule?.resume()
    }
    
    public func stop() {
        self.getTasksSchedule?.suspend()
        self.checkTasksSchedule?.suspend()
    }
    
    private func fetchTasks() {
        guard let _ = userInfo else { return }
        fetcher?.getTasks()
    }
    
    private func updateTask(_ task: APIAppTask, _ status: Int8) {
        guard let _ = userInfo else { return }
        fetcher?.updateTask(task, status)
    }
    
    private func checkTasks() {
        guard let _ = userInfo else { return }
        for task in self.tasks {
            if task.schemeId > maxSchemeQuery && Double(UIDevice.current.systemVersion)! >= 12.0 {
                continue
            }
            let isInstalled = DetectApp.isInstalled(task.bundleId, schemeId: task.schemeId)
            if isInstalled && task.status != 1 {
                updateTask(task, 1)
            } else if !isInstalled && task.status == 1 {
                updateTask(task, -1)
            }
        }
    }
    
    func updateTasks(_ tasks: [APIAppTask]) {
        self.tasks = tasks
        self.checkTasks()
    }
    
    func updateTask(_ task: APIAppTask) {
        for t in self.tasks {
            if t.bundleId == task.bundleId {
                t.bonus = task.bonus
                t.status = task.status
            }
        }
    }
}
