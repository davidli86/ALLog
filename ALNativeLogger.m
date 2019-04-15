//
//  ALNativeLogger.m
//  ActiveNetLog
//
//  Created by David Li on 2019/4/15.
//

#import "ALNativeLogger.h"

@implementation ALNativeLogger

- (void)writeLogEntity:(ALLogEntity *)logEntity {
    NSLog(@"%@", logEntity);
}

@end
