//
//  RNCountDownButton.swift
//  ucoin
//
//  Created by Syd on 2018/5/31.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit

@objc public protocol RNCountdownButtonDelegate: NSObjectProtocol {
    // called when seconds update
    @objc optional func countdownButton(countdownButton: RNCountdownButton, didUpdatedWith seconds: Int)
    
    // called when the Countdown begin
    @objc optional func countdownButtonDidBeganCounting(countdownButton: RNCountdownButton)
    
    // called when the Countdown to the end
    @objc optional func countdownButtonDidEndCounting(countdownButton: RNCountdownButton)
}

open class RNCountdownButton: UIButton {
    public var maxCountingSeconds: Int = 60
    public var bgColorForEnable: UIColor?
    public var bgColorForDisable: UIColor?
    public var borderColorForEnable: UIColor?
    public var borderColorForDisable: UIColor?
    public var titleColorForEnable: UIColor?
    public var titleColorForDisable: UIColor?
    public var titleColorForCountingDisable: UIColor?
    
    public var enableTitle: String?
    public var disableTitle: String?
    public var countingTitle: String?
    
    fileprivate var timer: Timer?
    public weak var delegate: RNCountdownButtonDelegate?
    public var isCounting: Bool = false //是否正在倒计时
    
    public var remainingSeconds: Int = 0 {
        willSet {
            self.isCounting = true
            self.delegate?.countdownButton?(countdownButton: self, didUpdatedWith: newValue)
            if newValue <= 0 {
                var title = I18n.resend.description
                if let enableTitle = self.enableTitle {
                    title = enableTitle
                }
                self.setTitle(title, for: UIControl.State())
                self.stop()
                self.isEnabled = true
            } else {
                var title = "\(I18n.sent.description)(\(newValue))"
                if let countingTitle = self.countingTitle {
                    title = "\(countingTitle)(\(newValue))"
                }
                self.setTitle(title, for: UIControl.State())
            }
        }
    }
    
    public func start() {
        self.remainingSeconds = self.maxCountingSeconds
        weak var weakSelf = self
        if #available(iOS 10.0, *) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
                weakSelf?.updateTime()
            })
        } else {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        }
        
        self.delegate?.countdownButtonDidBeganCounting?(countdownButton: self)
        self.isEnabled = false
    }
    
    public func showSending() {
        var title = "\(I18n.sending.description).."
        if let disableTitle = self.disableTitle {
            title = disableTitle
        }
        self.setTitle(title, for: .normal)
    }
    
    public func showFetchAgain() {
        var title = I18n.resend.description
        if let enableTitle = self.enableTitle {
            title = enableTitle
        }
        self.setTitle(title, for: .normal)
    }
    
    public func stop() {
        self.timer?.invalidate()
        self.timer = nil
        self.isCounting = false
        self.delegate?.countdownButtonDidEndCounting?(countdownButton: self)
    }
    
    
    @objc private func updateTime() {
        self.remainingSeconds -= 1
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        configUI()
    }
    
    fileprivate func configUI() {
        self.layoutIfNeeded()
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = self.frame.size.height/2
        self.layer.masksToBounds = true
        self.isEnabled = false
        self.isCounting = false
    }
    
    open override var isEnabled: Bool {
        willSet {
            if newValue {
                self.backgroundColor = self.bgColorForEnable
                self.layer.borderColor = self.borderColorForEnable?.cgColor
                self.setTitleColor(self.titleColorForEnable, for: .normal)
            } else {
                self.backgroundColor = self.bgColorForDisable
                self.layer.borderColor = self.borderColorForDisable?.cgColor
                if self.isCounting {
                    self.setTitleColor(self.titleColorForCountingDisable, for: .normal)
                } else {
                    self.setTitleColor(self.titleColorForDisable, for: .normal)
                }
            }
        }
    }
}
