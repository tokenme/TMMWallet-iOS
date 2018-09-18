//
//  UIImage+Utils.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/18.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import UIKit

extension UIImage {
    
    func hasAlpha() -> Bool
    {
        let alpha = self.cgImage?.alphaInfo;
        return (alpha == CGImageAlphaInfo.first ||
            alpha == CGImageAlphaInfo.last ||
            alpha == CGImageAlphaInfo.premultipliedFirst ||
            alpha == CGImageAlphaInfo.premultipliedFirst);
    }
    
    func data() -> Data? {
        if self.hasAlpha() {
            return UIImagePNGRepresentation(self)
        }
        return UIImageJPEGRepresentation(self, 1)
    }
    
    func mime() -> String {
        if self.hasAlpha() {
            return "image/png"
        }
        return "image/jpeg"
    }
    
    func fileExtension() -> String {
        if self.hasAlpha() {
            return "png"
        }
        return "jpg"
    }
}
