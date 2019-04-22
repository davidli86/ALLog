//
//  LPBaseAPIManager.h
//  MeetMobile
//
//  Created by David Li on 18/01/2018.
//  Copyright © 2018 The Active Network. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

typedef NSString* ALAPIRequestId;

@interface ALBaseAPIManager : NSObject

@property(nonatomic, strong, readonly) AFHTTPSessionManager *defaultSessionManager;

- (instancetype)initWithBaseUrl:(NSString *)baseUrl;

- (ALAPIRequestId)GET:(NSString *)URLString
           parameters:(nullable id)parameters
             progress:(nullable void (^)(NSProgress *downloadProgress))downloadProgress
              success:(nullable void (^)(ALAPIRequestId requestId, NSDictionary *responseObject))success
              failure:(nullable void (^)(ALAPIRequestId requestId, NSError *error))failure;

- (ALAPIRequestId)POST:(NSString *)URLString
            parameters:(nullable id)parameters
              progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgress
               success:(nullable void (^)(ALAPIRequestId requestId, NSDictionary *responseObject))success
               failure:(nullable void (^)(ALAPIRequestId requestId, NSError *error))failure;

-(void)cancelRequest:(ALAPIRequestId)requestId;
-(void)cancelAll;

@end
