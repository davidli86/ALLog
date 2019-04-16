//
//  LPBaseAPIManager.m
//  MeetMobile
//
//  Created by David Li on 18/01/2018.
//  Copyright © 2018 The Active Network. All rights reserved.
//

#import "ALBaseAPIManager.h"

#define kTimeoutIntervalForRequest          30

#define kResponseKeySuccess                 @"success"
#define kResponseKeyErrorString             @"errorString"

@interface ALBaseAPIManager() {
    NSString *_baseUrl;
}

@property(nonatomic, strong) NSURLSessionConfiguration  *defaultSessionConfiguration;
@property(nonatomic, strong) NSMutableDictionary        *sessionTaskDict;

@end

@implementation ALBaseAPIManager

@synthesize defaultSessionManager = _defaultSessionManager;

#pragma public methods

-(instancetype)initWithBaseUrl:(NSString *)baseUrl
{
    self = [super init];
    if (self) {
        _baseUrl = baseUrl;
        _sessionTaskDict = [NSMutableDictionary dictionary];
    }
    return self;
}

-(ALAPIRequestId)GET:(NSString *)URLString
          parameters:(id)parameters
            progress:(void (^)(NSProgress *))downloadProgress
             success:(void (^)(ALAPIRequestId, NSDictionary *))success
             failure:(void (^)(ALAPIRequestId, NSError *))failure
{
    NSURLSessionDataTask *task = [self.defaultSessionManager
                                  GET:URLString
                                  parameters:parameters
                                  progress:downloadProgress
                                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                      [self parseSuccessTask:task
                                          withResponseObject:responseObject
                                             andSuccessBlock:success
                                             andFailureBlock:failure];
                                  }
                                  failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      //Discussion: why task is nullable? From implementation code, it's impossible to be null or nil. If there happens nil for task, there will be a risk task cannot be deallocated unitl the manager is deallocated.
                                      [self parseFailureTask:task withError:error andFailureBlock:failure];
                                  }];
    ALAPIRequestId requestId = [self requstIdFromSessionDataTask:task];
    if (requestId) {
        [self.sessionTaskDict setObject:task forKey:requestId];
    }
    return requestId;
}

-(ALAPIRequestId)POST:(NSString *)URLString
           parameters:(id)parameters
             progress:(void (^)(NSProgress *))uploadProgress
              success:(void (^)(ALAPIRequestId, NSDictionary *))success
              failure:(void (^)(ALAPIRequestId, NSError *))failure
{
    NSURLSessionDataTask *task = [self.defaultSessionManager
                                  POST:URLString
                                  parameters:parameters
                                  progress:uploadProgress
                                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                                      [self parseSuccessTask:task
                                          withResponseObject:responseObject
                                             andSuccessBlock:success
                                             andFailureBlock:failure];
                                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                      [self parseFailureTask:task withError:error andFailureBlock:failure];
                                  }];
    ALAPIRequestId requestId = [self requstIdFromSessionDataTask:task];
    if (requestId) {
        [self.sessionTaskDict setObject:task forKey:requestId];
    }
    return requestId;
}

-(void)cancelRequest:(ALAPIRequestId)requestId
{
    if (requestId) {
        NSURLSessionDataTask *task = [self.sessionTaskDict objectForKey:requestId];
        if (task) {
            [self.sessionTaskDict removeObjectForKey:requestId];
            [task cancel];
        }
    }
}

-(void)cancelAll
{
    [self.sessionTaskDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [((NSURLSessionDataTask *) obj) cancel];
    }];
    [self.sessionTaskDict removeAllObjects];
}

#pragma mark - 

#pragma mark - private methods

-(void)parseSuccessTask:(NSURLSessionDataTask *)task
     withResponseObject:(NSDictionary *)responseObject
        andSuccessBlock:(void (^)(ALAPIRequestId, id))success
        andFailureBlock:(void (^)(ALAPIRequestId, NSError *))failure
{
    ALAPIRequestId requestId = [self requstIdFromSessionDataTask:task];
    if (success) {
        success(requestId, responseObject);
    }
    if (requestId) {
        [self.sessionTaskDict removeObjectForKey:requestId];
    }
}

-(void)parseFailureTask:(NSURLSessionDataTask *)task
              withError:(NSError *)error
        andFailureBlock:(void (^)(ALAPIRequestId, NSError *))failure
{
    ALAPIRequestId requestId = [self requstIdFromSessionDataTask:task];
    if (failure) {
        failure(requestId, error);
    }
    if (requestId) {
        [self.sessionTaskDict removeObjectForKey:requestId];
    }
}

-(ALAPIRequestId)requstIdFromSessionDataTask:(NSURLSessionDataTask *)task
{
    if (task == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"%lu_%lu", (unsigned long)task.hash, (unsigned long)task.taskIdentifier];
}

-(AFHTTPSessionManager *)defaultSessionManager
{
    if (_defaultSessionManager == nil) {
        _defaultSessionManager = [[AFHTTPSessionManager alloc]
                           initWithBaseURL:[NSURL URLWithString:_baseUrl]
                           sessionConfiguration:self.defaultSessionConfiguration];
        _defaultSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        NSString *baseUrl = _baseUrl;
        [_defaultSessionManager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
                SecPolicyRef sslPolicy = SecPolicyCreateSSL(YES, (__bridge CFStringRef)(baseUrl));
                SecTrustSetPolicies(serverTrust, sslPolicy);
                CFRelease(sslPolicy);
                
                SecTrustResultType result;
                OSStatus status = SecTrustEvaluate(serverTrust, &result);
                if (status == errSecSuccess && (result == kSecTrustResultProceed || result == kSecTrustResultUnspecified)) {
                    *credential = [NSURLCredential credentialForTrust:serverTrust];
                    disposition = NSURLSessionAuthChallengeUseCredential;
                } else {
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            return disposition;
        }];
    }
    return _defaultSessionManager;
}

-(NSURLSessionConfiguration *)defaultSessionConfiguration
{
    if (_defaultSessionConfiguration == nil) {
        _defaultSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _defaultSessionConfiguration.timeoutIntervalForRequest = kTimeoutIntervalForRequest;
        [_defaultSessionConfiguration setTLSMinimumSupportedProtocol:kTLSProtocol12];
    }
    return _defaultSessionConfiguration;
}

-(void)dealloc
{
    [self cancelAll];
}

@end
