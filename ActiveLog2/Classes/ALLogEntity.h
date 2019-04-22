//
//  ALLogEntity.h
//  ActiveNetLog
//
//  Created by David Li on 2019/4/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ALLogEntity : NSObject<NSCoding>

@property(nonatomic, strong) NSString   *logLevel;
@property(nonatomic, strong) NSString   *logMessage;
@property(nonatomic, strong) NSString   *logComponent;
@property(nonatomic, strong) NSString   *logTime;

- (NSDictionary *)toJsonDictionary;

@end

NS_ASSUME_NONNULL_END
