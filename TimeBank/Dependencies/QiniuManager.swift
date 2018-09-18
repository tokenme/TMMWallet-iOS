//
//  QiniuManager.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/9/18.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

import Foundation
import Qiniu

class QiniuManager: NSObject {
    
    static let sharedInstance = QiniuManager()
    
    public let uploader: QNUploadManager = QNUploadManager()
    
}
