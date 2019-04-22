//
//  ALLog.h
//  ActiveNetLog
//
//  Created by David Li on 2019/4/15.
//

#import <Foundation/Foundation.h>
#import "ALLogContants.h"
#import "ALLogger.h"

NS_ASSUME_NONNULL_BEGIN

#define ActiveLogInfo(frmt, ...)    [[ALLog shared] logMessage:[NSString stringWithFormat:frmt, ## __VA_ARGS__] component:kDefaultLogComponent type:ALLogTypeInfo function:[NSString stringWithFormat:@"%s [%d]", __FUNCTION__, __LINE__]]

#define ActiveLogWarn(frmt, ...)    [[ALLog shared] logMessage:[NSString stringWithFormat:frmt, ## __VA_ARGS__] component:kDefaultLogComponent type:ALLogTypeWarning function:[NSString stringWithFormat:@"%s [%d]", __FUNCTION__, __LINE__]]

#define ActiveLogError(frmt, ...)   [[ALLog shared] logMessage:[NSString stringWithFormat:frmt, ## __VA_ARGS__] component:kDefaultLogComponent type:ALLogTypeError function:[NSString stringWithFormat:@"%s [%d]", __FUNCTION__, __LINE__]]

@interface ALLog : NSObject

@property(nonatomic, assign, readonly) ALLogLevel   logLevel;
@property(nonatomic, strong, readonly) NSString     *appName;
@property(nonatomic, strong, readonly) NSString     *deviceId;
@property(nonatomic, strong, readonly) NSString     *baseUrl;

/**
 Retry times when failed to get config / upload log. Default is 2.
 **/
@property(nonatomic, assign) NSUInteger networkRetryTimes;
/**
 Unit is second. Default duration is 5s. Cannot be negative.
 **/
@property(nonatomic, assign) float networkRetryDuration;

+ (instancetype)shared;

- (void)configFromBaseUrl:(NSString *)baseUrl appName:(NSString *)appName deviceId:(NSString *)deviceId;
- (void)configWithLogLevel:(ALLogLevel)logLevel appName:(NSString *)appName deviceId:(NSString *)deviceId;

- (void)addLogger:(id<ALLogger>)logger;
- (void)logMessage:(NSString *)message component:(NSString *)component type:(ALLogType)logType function:(NSString *)function;

@end

NS_ASSUME_NONNULL_END
