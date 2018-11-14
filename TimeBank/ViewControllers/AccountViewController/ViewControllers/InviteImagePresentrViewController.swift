//
//  InviteImagePresentrViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/14.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit

class InviteImagePresentrViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    private var image: UIImage?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = self.image
    }
    
    public func setImage(img: UIImage) {
        self.image = img
    }
}
