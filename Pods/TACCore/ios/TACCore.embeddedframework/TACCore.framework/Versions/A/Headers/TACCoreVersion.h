//
// QCloud Terminal Lab --- service for developers
//
#import <Foundation/Foundation.h>
#import <QCloudCore/QCloudCoreVersion.h>
#import <AOPKit/AOPKitVersion.h>

#ifndef TACCoreModuleVersion_h
#define TACCoreModuleVersion_h
#define TACCoreModuleVersionNumber 100000

//dependency
#if QCloudCoreModuleVersionNumber != 504005 
    #error "库TACCore依赖QCloudCore最小版本号为5.4.5，当前引入的QCloudCore版本号过低，请及时升级后使用" 
#endif
#if AOPKitModuleVersionNumber != 100001 
    #error "库TACCore依赖AOPKit最小版本号为1.0.1，当前引入的AOPKit版本号过低，请及时升级后使用" 
#endif

//
FOUNDATION_EXTERN NSString * const TACCoreModuleVersion;
FOUNDATION_EXTERN NSString * const TACCoreModuleName;

#endif