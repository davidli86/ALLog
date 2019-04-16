//
//  ALLogAPIManager.h
//  ActiveLog2
//
//  Created by David Li on 2019/4/16.
//

#import "ALBaseAPIManager.h"
#import "ALLogEntity.h"
#import "ALLogContants.h"

NS_ASSUME_NONNULL_BEGIN

@class ALLogAPIManager;

@protocol ALLogAPIManagerProtocol <NSObject>

@optional
- (void)logAPIManager:(ALLogAPIManager *)apiManager didGetLogLevel:(ALLogLevel)logLevel withError:(nullable NSError *)error;
- (void)logAPIManager:(ALLogAPIManager *)apiManager didUploadLog:(BOOL)success withError:(nullable NSError *)error;

@end

@interface ALLogAPIManager : ALBaseAPIManager

@property(nonatomic, weak)id<ALLogAPIManagerProtocol> delegate;

- (ALAPIRequestId)requestLogLevelWithAppName:(NSString *)appName
                                    deviceId:(NSString *)deviceId;

- (ALAPIRequestId)uploadLogEntities:(NSArray<ALLogEntity *> *)logEntities
                        withAppName:(NSString *)appName
                           deviceId:(NSString *)deviceId;

@end

NS_ASSUME_NONNULL_END
