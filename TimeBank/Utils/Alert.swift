//
//  Alert.swift
//  ucoin
//
//  Created by Syd on 2018/6/4.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Presentr
import UIKit

class UCAlert {
    static public func showAlert(_ presenter: Presentr, title: String, desc: String, closeBtn: String, viewController: UIViewController? = nil) {
        let alertController = AlertViewController(title: title, body: desc)
        let cancelAction = AlertAction(title: closeBtn, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        if let vc = viewController {
            vc.customPresentViewController(presenter, viewController: alertController, animated: true)
            return
        }
        if let vc = UIViewController.currentViewController() {
            vc.customPresentViewController(presenter, viewController: alertController, animated: true)
        }
    }
}
