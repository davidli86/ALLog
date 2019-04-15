//
//  ALNetworkLogger.h
//  ActiveNetLog
//
//  Created by David Li on 2019/4/15.
//

#import <Foundation/Foundation.h>
#import "ALLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface ALNetworkLogger : NSObject<ALLogger>

@property(nonatomic, assign) int    sendThreshold;
@property(nonatomic, assign) int    maxLineForSend;
@property(nonatomic, assign) int    maxLineInMemory;
@property(nonatomic, assign) BOOL   canWriteToDisk;

@end

NS_ASSUME_NONNULL_END
