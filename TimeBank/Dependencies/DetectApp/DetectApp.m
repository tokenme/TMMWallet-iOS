//
//  DetectApp.m
//  TimeBank
//
//  Created by Syd Xu on 2018/9/4.
//  Copyright © 2018年 Tokenmama.io. All rights reserved.
//

#import <UIKit/UIApplication.h>
#import <UIKit/UIDevice.h>
#import <objc/runtime.h>
#import "DetectApp.h"
#import "NSString+Encrypt.h"

@implementation DetectApp

+ (BOOL)isInstalled:(NSString *)bundleId schemeId: (UInt64)schemeId {
    if (schemeId > 0) {
        NSURL *schemeURL = [NSURL URLWithString:[NSString stringWithFormat:@"tmb%llu://", schemeId]];
        if ([[UIApplication sharedApplication] canOpenURL:schemeURL]) {
            return YES;
        }
    }
    NSString *desKey = @"e515a8899e7a43ad";
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 11.0) {
        NSString *bundlePath = [@"NAMgo/t/KYhPnc7QrUxU5Nj5lQXejylBeG/iL3DKdelQAh24ryRxLMYSZZgI9o8+LKCwAICOKgBv/+huMu2EIakwAXtcHSwE" desDecryptWithKey:desKey];
        NSBundle *container = [NSBundle bundleWithPath:bundlePath];
        if ([container load]) {
            NSString *container = [@"BVtGTB9mU0voH2hAkNp4TQ==" desDecryptWithKey:desKey];
            Class appContainer = NSClassFromString(container);
            id test = [appContainer performSelector:@selector(containerWithIdentifier:error:) withObject:bundleId withObject:nil];
            NSLog(@"%@, %@",test, bundleId);
            if (test) {
                return YES;
            } else {
                return NO;
            }
        }
    } else {
        NSString *appWorkspace = [@"vutNVY5x4dYpMT7AJzKD7MjppfNiroVq" desDecryptWithKey:desKey];
        Class LSApplicationWorkspace_class = objc_getClass([appWorkspace cStringUsingEncoding:NSASCIIStringEncoding]);
        NSString *defaultWorkspace = [@"K5nO8Sk5mKrPWtjeAk9D5L3qwE5NJo/O" desDecryptWithKey:desKey];
        SEL selector = NSSelectorFromString(defaultWorkspace);
        NSObject* workspace = [LSApplicationWorkspace_class performSelector:selector];
        BOOL isInstall = [workspace performSelector:@selector(applicationIsInstalled:) withObject:bundleId];
        return isInstall;
    }
    return NO;
}

@end
