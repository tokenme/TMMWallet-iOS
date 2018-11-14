//
//  UIView+Utils.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/10/23.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import UIKit

extension UIView {
    func toFullyBottom() {
        self.bottom = superview!.bounds.size.height
        self.autoresizingMask = [UIView.AutoresizingMask.flexibleTopMargin, UIView.AutoresizingMask.flexibleWidth]
    }
    
    public var bottom: CGFloat{
        get {
            return self.frame.origin.y + self.frame.size.height
        }
        set {
            var frame = self.frame;
            frame.origin.y = newValue - frame.size.height;
            self.frame = frame;
        }
    }
    
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { renderContext in
            layer.render(in: renderContext.cgContext)
        }
    }
}