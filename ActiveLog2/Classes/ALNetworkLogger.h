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

/**
 Default is 200. sendThreshold > 0
 **/
@property(nonatomic, assign, readonly) int    sendThreshold;

/**
 Default is 500. maxLineForSend > sendThreshold
 **/
@property(nonatomic, assign, readonly) int    maxLineForSend;

/**
 Default is 2000. maxLineInMemory > maxLineForSend. This is a
 suggest value. So the max log line in memory may exceed this
 value. For example, when fail to sync log to file for some
 reason, logs will be keeped in memory.
 **/
@property(nonatomic, assign, readonly) int    maxLineInMemory;

/**
 Default is Yes.
 **/
@property(nonatomic, assign, readonly) BOOL   canWriteToDisk;

- (instancetype)initWithSendThreshold:(int)sendThreshold
                       maxLineForSend:(int)maxLineForSend
                      maxLineInMemory:(int)maxLineInMemory
                       canWriteToDisk:(int)canWriteToDisk;

@end

NS_ASSUME_NONNULL_END
