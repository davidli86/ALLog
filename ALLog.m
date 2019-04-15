//
//  ALLog.m
//  ActiveNetLog
//
//  Created by David Li on 2019/4/15.
//

#import "ALLog.h"

static ALLog *_instance;

@interface ALLog () {
    ALLogLevel _logLevel;
    NSMutableArray *_loggers;
}

@end

@implementation ALLog

+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[ALLog alloc] init];
    });
    return _instance;
}

- (void)configWithLogLevel:(ALLogLevel)logLevel {
    _logLevel = logLevel;
}

- (void)addLogger:(id<ALLogger>)logger {
    if (logger == nil || ![logger conformsToProtocol:@protocol(ALLogger)]) {
        return;
    }
    if (_loggers == nil) {
        _loggers = [NSMutableArray arrayWithCapacity:3];
    }
    [_loggers addObject:logger];
}

- (void)logMessage:(NSString *)message component:(nonnull NSString *)component type:(ALLogType)logType function:(nonnull NSString *)function{
    if (message == nil || logType & _logLevel == 0) {
        return;
    }
    NSString *logTypeString = kALLogTypeErrorConst;
    switch (logType) {
        case ALLogTypeInfo:
            logTypeString = kALLogTypeInfoConst;
            break;
        case ALLogTypeWarning:
            logTypeString = kALLogTypeWarningConst;
            break;
        case ALLogTypeError:
            logTypeString = kALLogTypeErrorConst;
            break;
        default:
            break;
    }
    ALLogEntity *entity = [[ALLogEntity alloc] init];
    entity.logMessage = [NSString stringWithFormat:@"%@ %@", message, function];
    entity.logComponent = component;
    entity.logLevel = logTypeString;
    entity.logTime = [NSDate date];
    
    for (id<ALLogger> logger in _loggers) {
        [logger writeLogEntity:entity];
    }
}

@end
