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
            return self.pngData()
        }
        return self.jpegData(compressionQuality: 1)
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
    
    /**
     *  重设图片大小
     */
    func resizeImage(_ to:CGSize) -> UIImage {
        //UIGraphicsBeginImageContext(reSize);
        UIGraphicsBeginImageContextWithOptions(to, false, UIScreen.main.scale);
        self.draw(in: CGRect(x: 0, y: 0, width: to.width, height: to.height));
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        return newImage;
    }
    
    /**
     *  等比率缩放
     */
    func scaleImage(scaleSize:CGFloat)->UIImage {
        let to = CGSize(width: self.size.width * scaleSize, height: self.size.height * scaleSize)
        return resizeImage(to)
    }
    
    func tint(color: UIColor, blendMode: CGBlendMode) -> UIImage {
        let drawRect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        //let context = UIGraphicsGetCurrentContext()
        //CGContextClipToMask(context, drawRect, CGImage)
        color.setFill()
        UIRectFill(drawRect)
        draw(in: drawRect, blendMode: blendMode, alpha: 1.0)
        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return tintedImage!
    }
}
