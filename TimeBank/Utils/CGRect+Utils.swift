//
//  CGRect+Utils.swift
//  ucoin
//
//  Created by Syd on 2018/6/4.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit

extension CGRect {
    var minEdge: CGFloat {
        return min(width, height)
    }
}
