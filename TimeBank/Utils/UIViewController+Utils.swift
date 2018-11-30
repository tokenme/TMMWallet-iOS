//
//  UIViewController+Utils.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/13.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit

extension UIViewController {
    class func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return currentViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        return base
    }
}

public protocol ShouldPopDelegate
{
    func currentViewControllerShouldPop() -> Bool
}

extension UIViewController: ShouldPopDelegate
{
    @objc public func currentViewControllerShouldPop() -> Bool {
        return true
    }
}
