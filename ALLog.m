//
//  ALLog.m
//  ActiveNetLog
//
//  Created by David Li on 2019/4/15.
//

#import "ALLog.h"
#import "ALLogAPIManager.h"

static ALLog *_instance;

@interface ALLog ()<ALLogAPIManagerProtocol> {
    NSMutableArray *_loggers;
    ALLogAPIManager *_apiManager;
    NSUInteger _remainNetworkRetryTimes;
    NSDateFormatter *_dateFormatter;
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

- (instancetype)init {
    if (self = [super init]) {
        _logLevel = ALLogLevelOff;
        _networkRetryTimes = 2;
        _remainNetworkRetryTimes = _networkRetryTimes;
        _networkRetryDuration = 5.0;
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = kDateFormat;
    }
    return self;
}

- (void)configFromBaseUrl:(NSString *)baseUrl appName:(NSString *)appName deviceId:(NSString *)deviceId {
    if (baseUrl == nil || appName == nil || deviceId == nil) {
#ifdef DEBUG
        NSLog(@"Active Log Config Error: parameter shouldn't be nil!");
#endif
        return;
    }
    _baseUrl = baseUrl;
    _appName = appName;
    _deviceId = deviceId;
    _apiManager = [[ALLogAPIManager alloc] initWithBaseUrl:_baseUrl];
    _apiManager.delegate = self;
    [_apiManager requestLogLevelWithAppName:_appName deviceId:_deviceId];
}

- (void)configWithLogLevel:(ALLogLevel)logLevel appName:(NSString *)appName deviceId:(NSString *)deviceId{
    if (appName == nil || deviceId == nil) {
#ifdef DEBUG
        NSLog(@"Active Log Config Error: parameter shouldn't be nil!");
#endif
        return;
    }
    _logLevel = logLevel;
    _appName = appName;
    _deviceId = deviceId;
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
    if (message == nil || (logType & _logLevel) == 0) {
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
    entity.logTime = [_dateFormatter stringFromDate:[NSDate date]];
    
    for (id<ALLogger> logger in _loggers) {
        [logger writeLogEntity:entity];
    }
}

-(void)setNetworkRetryDuration:(float)networkRetryDuration {
    if (networkRetryDuration < 0) {
        _networkRetryDuration = 0;
    } else {
        _networkRetryDuration = networkRetryDuration;
        _remainNetworkRetryTimes = _networkRetryTimes;
    }
}

#pragma mark - ALLogAPIManagerProtocol

- (void)logAPIManager:(ALLogAPIManager *)apiManager didGetLogLevel:(ALLogLevel)logLevel withError:(NSError *)error {
    if (error) {
        NSLog(@"%@", error);
        if (_remainNetworkRetryTimes > 0) {
            _remainNetworkRetryTimes--;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, _networkRetryDuration * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self->_apiManager requestLogLevelWithAppName:self->_appName deviceId:self->_deviceId];
            });
        }
    } else {
        _logLevel = logLevel;
    }
}


@end
