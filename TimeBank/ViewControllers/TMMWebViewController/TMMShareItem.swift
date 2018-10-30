//
//  TMMShareItem.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/8.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import Foundation
import UIKit

public struct TMMShareItem {
    let id: UInt64?
    let title: String?
    let description: String?
    let image: UIImage?
    let link: URL?
    
    public init(id: UInt64?, title: String?, description: String?, image: UIImage?, link: URL?) {
        self.id = id
        self.title = title
        self.description = description
        self.image = image
        self.link = link
    }
}
