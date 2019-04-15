//
//  ALLogEntity.m
//  ActiveNetLog
//
//  Created by David Li on 2019/4/12.
//

#import "ALLogEntity.h"

static NSString * const kLogLevel = @"logLevel";
static NSString * const kLogMessage = @"logMessage";
static NSString * const kLogComponent = @"logComponent";
static NSString * const kLogTime = @"logTime";
static NSString * const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";

@implementation ALLogEntity

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.logLevel = [aDecoder decodeObjectForKey:kLogLevel];
        self.logMessage = [aDecoder decodeObjectForKey:kLogMessage];
        self.logComponent = [aDecoder decodeObjectForKey:kLogComponent];
        self.logTime = [aDecoder decodeObjectForKey:kLogTime];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.logLevel forKey:kLogLevel];
    [aCoder encodeObject:self.logMessage forKey:kLogMessage];
    [aCoder encodeObject:self.logComponent forKey:kLogComponent];
    [aCoder encodeObject:self.logTime forKey:kLogTime];
}

- (NSDictionary *)toJsonDictionary {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 self.logLevel, kLogLevel,
                                 self.logMessage, kLogMessage,
                                 self.logComponent, kLogComponent,
                                 nil];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = kDateFormat;
    NSString *dateString = [dateFormatter stringFromDate:self.logTime];
    [json setObject:dateString forKey:kDateFormat];
    return json;
}

- (NSString *)description {
    NSDictionary *dict = [self toJsonDictionary];
    NSArray *keys = @[kLogLevel, kLogMessage, kLogComponent, kLogTime];
    NSMutableString *string = [NSMutableString string];
    for (NSString *key in keys) {
        [string appendFormat:@"%@: %@\t", key, dict[key]];
    }
    return string;
}

@end
