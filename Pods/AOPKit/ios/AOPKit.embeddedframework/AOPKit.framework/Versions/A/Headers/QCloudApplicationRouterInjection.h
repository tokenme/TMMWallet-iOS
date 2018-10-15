//
//  QCloudApplicationRouterInjection.h
//  AOPKit
//
//  Created by Dong Zhao on 2017/12/19.
//

#import <Foundation/Foundation.h>


/**
 用于注册Application处理URL的基础机制，将所有的方法转发到了QCloudURLRouter上进行处理，如果您有需要处理程序打开URL的需求的地方，可以通过在QCloudURLRouter里面注册处理Pattern来实现。
 */
@interface QCloudApplicationRouterInjection : NSObject
@end
