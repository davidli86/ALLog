//
//  ALLogAPIManager.h
//  ActiveLog2
//
//  Created by David Li on 2019/4/16.
//

#import "ALBaseAPIManager.h"
#import "ALLogContants.h"

NS_ASSUME_NONNULL_BEGIN

@class ALLogAPIManager;

@protocol ALLogAPIManagerProtocol <NSObject>

@optional
- (void)logAPIManager:(ALLogAPIManager *)apiManager didGetLogLevel:(ALLogLevel)logLevel withError:(nullable NSError *)error;
- (void)logAPIManager:(ALLogAPIManager *)apiManager didUploadJsonLogs:(BOOL)success configDisabled:(BOOL)disabled withError:(nullable NSError *)error;

@end

@interface ALLogAPIManager : ALBaseAPIManager

@property(nonatomic, weak)id<ALLogAPIManagerProtocol> delegate;

- (ALAPIRequestId)requestLogLevelWithAppName:(NSString *)appName
                                    deviceId:(NSString *)deviceId;

- (ALAPIRequestId)uploadJsonLogs:(NSArray *)jsonLogs
                    withAppName:(NSString *)appName
                        deviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
