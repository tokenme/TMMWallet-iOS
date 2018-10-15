//
// QCloud Terminal Lab --- service for developers
//
#import <Foundation/Foundation.h>
#import <TACCore/TACCoreVersion.h>
#import <AOPKit/AOPKitVersion.h>

#ifndef TACMessagingModuleVersion_h
#define TACMessagingModuleVersion_h
#define TACMessagingModuleVersionNumber 100000

//dependency
#if TACCoreModuleVersionNumber != 100000 
    #error "库TACMessaging依赖TACCore最小版本号为1.0.0，当前引入的TACCore版本号过低，请及时升级后使用" 
#endif
#if AOPKitModuleVersionNumber != 100001 
    #error "库TACMessaging依赖AOPKit最小版本号为1.0.1，当前引入的AOPKit版本号过低，请及时升级后使用" 
#endif

//
FOUNDATION_EXTERN NSString * const TACMessagingModuleVersion;
FOUNDATION_EXTERN NSString * const TACMessagingModuleName;

#endif