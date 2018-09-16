//
// QCloud Terminal Lab --- service for developers
//
#import <Foundation/Foundation.h>
#import <TACCore/TACCoreVersion.h>

#ifndef TACCrashModuleVersion_h
#define TACCrashModuleVersion_h
#define TACCrashModuleVersionNumber 100000

//dependency
#if TACCoreModuleVersionNumber != 100000 
    #error "库TACCrash依赖TACCore最小版本号为1.0.0，当前引入的TACCore版本号过低，请及时升级后使用" 
#endif

//
FOUNDATION_EXTERN NSString * const TACCrashModuleVersion;
FOUNDATION_EXTERN NSString * const TACCrashModuleName;

#endif