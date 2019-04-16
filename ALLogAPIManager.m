//
//  ALLogAPIManager.m
//  ActiveLog2
//
//  Created by David Li on 2019/4/16.
//

#import "ALLogAPIManager.h"
#import "ALLogContants.h"
#import "NSDictionary+ALSafeRead.h"

static NSString * const kUrlComponentRequestLogConfig = @"/rest/common/getLogConfigByAppNameAndDeviceId";
static NSString * const kUrlComponentUploadLogEntities = @"/rest/common/uploadLogTrackRecords";

static NSString * const kParameterKeyAppName = @"appName";
static NSString * const kParameterKeyDeviceId = @"deviceId";

static NSString * const kResponseKeySuccess = @"success";
static NSString * const kResponseKeyErrorString = @"errorString";
static NSString * const kResponseKeyErrorCode = @"errorCode";
static NSString * const kResponseKeyResults = @"results";
static NSString * const kResponseKeyConfig = @"config";
static NSString * const kResponseLogLevel = @"logLevel";


@implementation ALLogAPIManager

- (ALAPIRequestId)requestLogLevelWithAppName:(NSString *)appName
                                    deviceId:(NSString *)deviceId {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                appName, kParameterKeyAppName,
                                deviceId, kParameterKeyDeviceId,
                                nil];
    ALAPIRequestId requestId = [self GET:kUrlComponentRequestLogConfig
                              parameters:parameters
                                progress:nil
                                 success:^(ALAPIRequestId requestId, NSDictionary *responseObject) {
                                     [self processRequestLogLevelResponse:responseObject];
                                } failure:^(ALAPIRequestId requestId, NSError *error) {
                                    if ([self.delegate respondsToSelector:@selector(logAPIManager:didGetLogLevel:withError:)]) {
                                        [self.delegate logAPIManager:self didGetLogLevel:ALLogLevelOff withError:error];
                                    }
                                }];
    return requestId;
}

- (ALAPIRequestId)uploadLogEntities:(NSArray<ALLogEntity *> *)logEntities
                        withAppName:(NSString *)appName
                           deviceId:(NSString *)deviceId {
    
    
    
    return 0;
}

- (void)processRequestLogLevelResponse:(NSDictionary *)responseObject {
    NSNumber *success = [responseObject safeObjectForKey:kResponseKeySuccess];
    NSNumber *errorCode = [responseObject safeObjectForKey:kResponseKeyErrorCode];
    NSString *errorString = [responseObject safeObjectForKey:kResponseKeyErrorString];
    ALLogLevel logLevel = ALLogLevelOff;
    if (success.boolValue) {
        NSString *logLevelString = [[[responseObject safeObjectForKey:kResponseKeyResults]
                                     safeObjectForKey:kResponseKeyConfig]
                                    safeObjectForKey:kResponseLogLevel];
        if ([logLevelString isEqualToString:kALLogLevelInfoConst]) {
            logLevel = ALLogLevelInfo;
        } else if ([logLevelString isEqualToString:kALLogLevelWarningConst]) {
            logLevel = ALLogLevelWarning;
        } else if ([logLevelString isEqualToString:kALLogLevelErrorConst]) {
            logLevel = ALLogLevelError;
        }
        if ([self.delegate respondsToSelector:@selector(logAPIManager:didGetLogLevel:withError:)]) {
            [self.delegate logAPIManager:self didGetLogLevel:logLevel withError:nil];
        }
    } else {
        /**
         errorCode=1003, The relevant configuration could not be found
         errorCode=1004, Log config has been disabled
         **/
        if (errorCode.intValue == 1003 || errorCode.intValue == 1004) {
            if ([self.delegate respondsToSelector:@selector(logAPIManager:didGetLogLevel:withError:)]) {
                [self.delegate logAPIManager:self didGetLogLevel:logLevel withError:nil];
            }
        } else {
            /**
             errorCode=1001, Loss of deviceId parameter
             errorCode=1002, Loss of appName parameter
             errorCode=1005, An exception occurred while getting the log configuration. Please try again
             **/
            if (errorString == nil) {
                errorString = @"Unknown Error";
            }
            NSError *error = [NSError errorWithDomain:@"Error" code:errorCode.intValue userInfo:@{NSLocalizedDescriptionKey : errorString}];
            if ([self.delegate respondsToSelector:@selector(logAPIManager:didGetLogLevel:withError:)]) {
                [self.delegate logAPIManager:self didGetLogLevel:logLevel withError:error];
            }
        }
    }
}

@end
