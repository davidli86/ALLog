//
//  ALLogger.h
//  ActiveNetLog
//
//  Created by David Li on 2019/4/15.
//

#import <Foundation/Foundation.h>
#import <ALLogEntity.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ALLogger <NSObject>

- (void)writeLogEntity:(ALLogEntity *)logEntity;

@end

NS_ASSUME_NONNULL_END
