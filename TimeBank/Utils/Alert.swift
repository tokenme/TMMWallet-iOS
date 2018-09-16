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
    static public func showAlert(_ presenter: Presentr, title: String, desc: String, closeBtn: String) {
        let alertController = Presentr.alertViewController(title: title, body: desc)
        let cancelAction = AlertAction(title: closeBtn, style: .cancel) { alert in
            //
        }
        alertController.addAction(cancelAction)
        if let vc = UIViewController.currentViewController() {
            vc.customPresentViewController(presenter, viewController: alertController, animated: true)
        }
    }
}
