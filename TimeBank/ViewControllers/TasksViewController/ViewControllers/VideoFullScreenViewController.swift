//
//  VideoFullScreenViewController.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/28.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit

class VideoFullScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func instantiate() -> VideoFullScreenViewController
    {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoFullScreenViewController") as! VideoFullScreenViewController
    }

}
