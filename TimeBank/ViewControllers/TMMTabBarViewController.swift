//
//  TMMTabBarViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/12/24.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit

class TMMTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        if let toolBarItems = self.tabBar.items {
            if CheckVersionStatus() == .validating {
                toolBarItems[1].title = I18n.discover.description
                toolBarItems[1].image = UIImage(named: "Discover")
                toolBarItems[1].selectedImage = UIImage(named: "Discover")
            } else {
                toolBarItems[1].title = I18n.uEarn.description
                toolBarItems[1].image = UIImage(named: "Money")
                toolBarItems[1].selectedImage = UIImage(named: "Money")
            }
        }
    }
    
    public func updateView() {
        if let toolBarItems = self.tabBar.items {
            if CheckVersionStatus() == .validating {
                toolBarItems[1].title = I18n.discover.description
                toolBarItems[1].image = UIImage(named: "Discover")
                toolBarItems[1].selectedImage = UIImage(named: "Discover")
            } else {
                toolBarItems[1].title = I18n.uEarn.description
                toolBarItems[1].image = UIImage(named: "Money")
                toolBarItems[1].selectedImage = UIImage(named: "Money")
            }
        }
    }
}
