//
//  TMMWebViewLeakAvoider.swift
//  TimeBank
//
//  Created by Syd Xu on 2018/11/2.
//  Copyright © 2018 Tokenmama.io. All rights reserved.
//

import WebKit

class TMMWebViewLeakAvoider : NSObject, WKScriptMessageHandler {
    weak var delegate : WKScriptMessageHandler?
    init(delegate:WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(
            userContentController, didReceive: message)
    }
    
    deinit {
        print("LeakAvoider - dealloc")
    }
    
}
