//
//  UINavigationController+Utils.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/28.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit
extension UINavigationController {
    
    open override var childForStatusBarStyle: UIViewController? {
        return viewControllers.last
    }
    
    open override var childForStatusBarHidden: UIViewController? {
        return viewControllers.last
    }
    
}
