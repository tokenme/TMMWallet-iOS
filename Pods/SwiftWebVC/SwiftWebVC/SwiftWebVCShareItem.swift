//
//  SwiftWebVCShareItem.swift
//  SwiftWebVC
//
//  Created by Syd Xu on 2018/9/4.
//

import Foundation
import UIKit

public struct SwiftWebVCShareItem {
    let title: String?
    let image: UIImage?
    let link: URL?
    
    public init(title: String?, image: UIImage?, link: URL?) {
        self.title = title
        self.image = image
        self.link = link
    }
}
