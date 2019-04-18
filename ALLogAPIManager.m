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
static NSString * const kParameterKeyLogs = @"logs";

static NSString * const kResponseKeySuccess = @"success";
static NSString * const kResponseKeyErrorString = @"errorString";
static NSString * const kResponseKeyErrorCode = @"errorCode";
static NSString * const kResponseKeyResults = @"results";
static NSString * const kResponseKeyConfig = @"config";
static NSString * const kResponseKeyLogLevel = @"logLevel";
static NSString * const kResponseKeyConfigDisabled = @"configDisabled";


@implementation ALLogAPIManager

- (instancetype)initWithBaseUrl:(NSString *)baseUrl {
    if (self = [super initWithBaseUrl:baseUrl]) {
        [self.defaultSessionManager setRequestSerializer:[AFJSONRequestSerializer serializer]];
    }
    return self;
}

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

- (void)processRequestLogLevelResponse:(NSDictionary *)responseObject {
    NSNumber *success = [responseObject safeObjectForKey:kResponseKeySuccess];
    NSNumber *errorCode = [responseObject safeObjectForKey:kResponseKeyErrorCode];
    NSString *errorString = [responseObject safeObjectForKey:kResponseKeyErrorString];
    ALLogLevel logLevel = ALLogLevelOff;
    if (success.boolValue) {
        NSString *logLevelString = [[[responseObject safeObjectForKey:kResponseKeyResults]
                                     safeObjectForKey:kResponseKeyConfig]
                                    safeObjectForKey:kResponseKeyLogLevel];
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

- (ALAPIRequestId)uploadJsonLogs:(NSArray *)jsonLogs
                     withAppName:(NSString *)appName
                        deviceId:(NSString *)deviceId {
    if (jsonLogs == nil || jsonLogs.count == 0) {
        if ([self.delegate respondsToSelector:@selector(logAPIManager:didUploadJsonLogs:configDisabled:withError:)]) {
            NSString *errorString = @"Log is empty!";
            NSError *error = [NSError errorWithDomain:@"Error" code:1 userInfo:@{NSLocalizedDescriptionKey : errorString}];
            [self.delegate logAPIManager:self didUploadJsonLogs:NO configDisabled:NO withError:error];
            return nil;
        }
    }
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                appName, kParameterKeyAppName,
                                deviceId, kParameterKeyDeviceId,
                                jsonLogs, kParameterKeyLogs,
                                nil];
    ALAPIRequestId requestId = [self POST:kUrlComponentUploadLogEntities
                               parameters:parameters
                                 progress:nil
                                  success:^(ALAPIRequestId requestId, NSDictionary *responseObject) {
                                      [self processUploadLogEntitiesResponse:responseObject];
                                  } failure:^(ALAPIRequestId requestId, NSError *error) {
                                      if ([self.delegate respondsToSelector:@selector(logAPIManager:didUploadJsonLogs:configDisabled:withError:)]) {
                                          [self.delegate logAPIManager:self didUploadJsonLogs:NO configDisabled:NO withError:error];
                                      }
                                  }];
    
    return requestId;
}

- (void)processUploadLogEntitiesResponse:(NSDictionary *)responseObject {
    NSNumber *success = [responseObject safeObjectForKey:kResponseKeySuccess];
    NSNumber *errorCode = [responseObject safeObjectForKey:kResponseKeyErrorCode];
    NSString *errorString = [responseObject safeObjectForKey:kResponseKeyErrorString];
    NSNumber *configDisabled = [responseObject safeObjectForKey:kResponseKeyConfigDisabled];
    if (success.boolValue) {
        if ([self.delegate respondsToSelector:@selector(logAPIManager:didUploadJsonLogs:configDisabled:withError:)]) {
            [self.delegate logAPIManager:self didUploadJsonLogs:YES configDisabled:configDisabled.boolValue withError:nil];
        }
    } else {
        /**
         errorCode=1001, The upload log record cannot be empty
         errorCode=1002, The relevant configuration could not be found
         errorCode=1003, Log config has been disabled
         errorCode=1004, Upload log exceeds maximum limit 500
         errorCode=1005, Failed to upload log record, please try again
         **/
        if (errorString == nil) {
            errorString = @"Unknown Error";
        }
        NSError *error = [NSError errorWithDomain:@"Error" code:errorCode.intValue userInfo:@{NSLocalizedDescriptionKey : errorString}];
        if ([self.delegate respondsToSelector:@selector(logAPIManager:didUploadJsonLogs:configDisabled:withError:)]) {
            [self.delegate logAPIManager:self didUploadJsonLogs:NO configDisabled:configDisabled.boolValue withError:error];
        }
    }
}

@end
