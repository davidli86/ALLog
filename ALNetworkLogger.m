//
//  ALNetworkLogger.m
//  ActiveNetLog
//
//  Created by David Li on 2019/4/15.
//

#import "ALNetworkLogger.h"
#import "ALLogAPIManager.h"
#import "ALLog.h"

static NSString * const kLogFileDirectoryName = @"active_log_json";

@interface ALNetworkLogger ()<ALLogAPIManagerProtocol> {
    ALLogAPIManager *_apiManager;
    NSUInteger _remainNetworkRetryTimes;

    NSMutableArray *_logs;
    NSMutableArray *_memoryLogSendingBuffer;
    
    NSMutableArray *_fileLogSendingBuffer;
    NSString *_logFilePathInSending;
    
    NSMutableArray *_inSendingBuffer;
    NSUInteger _inSendingLogCount;
}

@end

@implementation ALNetworkLogger

- (instancetype)init {
    if (self = [super init]) {
        [self setupWithSendThreshold:200
                      maxLineForSend:500
                     maxLineInMemory:2000
                      canWriteToDisk:YES];
    }
    return self;
}

- (instancetype)initWithSendThreshold:(int)sendThreshold
                       maxLineForSend:(int)maxLineForSend
                      maxLineInMemory:(int)maxLineInMemory
                       canWriteToDisk:(int)canWriteToDisk {
    if (sendThreshold <= 0) {
        NSLog(@"Active Log Error: sendThreshold must be greater than 0!");
        return nil;
    }
    if (maxLineForSend < sendThreshold) {
        NSLog(@"Active Log Error: maxLineForSend must be greater than sendThreshold!");
        return nil;
    }

    if (self = [super init]) {
        [self setupWithSendThreshold:sendThreshold
                      maxLineForSend:maxLineForSend
                     maxLineInMemory:maxLineInMemory
                      canWriteToDisk:canWriteToDisk];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)writeLogEntity:(ALLogEntity *)logEntity {
    [_logs addObject:[logEntity toJsonDictionary]];
    if (_logs.count >= _sendThreshold) {
        //move logs to memoryLogSendingBuffer
        [_memoryLogSendingBuffer addObjectsFromArray:_logs];
        [_logs removeAllObjects];
        
        // try to send log, reset network retry time everytime
        _remainNetworkRetryTimes = [ALLog shared].networkRetryTimes;
        [self tryToSendLogs];
    }
}

#pragma mark - ALLogAPIManagerProtocol

- (void)logAPIManager:(ALLogAPIManager *)apiManager
    didUploadJsonLogs:(BOOL)success
       configDisabled:(BOOL)disabled
            withError:(nullable NSError *)error {
    if (success) {
        [_inSendingBuffer removeObjectsInRange:NSMakeRange(0, _inSendingLogCount)];
        
        // if sending logs are from file, then check if logs in this
        // file finished sending. If so, delete the file.
        if (_inSendingBuffer == _fileLogSendingBuffer && _inSendingBuffer.count == 0 && _logFilePathInSending != nil) {
            [[NSFileManager defaultManager] removeItemAtPath:_logFilePathInSending error:nil];
        }
        [self tryToSendLogs];
    } else {
        if (error) {
            NSLog(@"%@", error);
        }
        if (_remainNetworkRetryTimes > 0) {
            _remainNetworkRetryTimes--;
            [self tryToSendLogs];
        } else {
            // To improve performance, reduce sync times with file.
            // So only write logs to file when fail to upload to server.
            // Write memoryLogSendingBuffer to file.
            if (_memoryLogSendingBuffer.count > _maxLineInMemory) {
                if ([self writeLogsToFile:_memoryLogSendingBuffer]) {
                    [_memoryLogSendingBuffer removeAllObjects];
                }
            }
        }
    }
}

#pragma mark - Private Methods

- (void)setupWithSendThreshold:(int)sendThreshold
                maxLineForSend:(int)maxLineForSend
               maxLineInMemory:(int)maxLineInMemory
                canWriteToDisk:(int)canWriteToDisk {
    _sendThreshold = sendThreshold;
    _maxLineForSend = maxLineForSend;
    _maxLineInMemory = maxLineInMemory;
    _canWriteToDisk = canWriteToDisk;
    _logs = [NSMutableArray arrayWithCapacity:_sendThreshold];
    _memoryLogSendingBuffer = [NSMutableArray arrayWithCapacity:_maxLineInMemory];
    _apiManager = [[ALLogAPIManager alloc] initWithBaseUrl:[ALLog shared].baseUrl];
    _apiManager.delegate = self;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(flushAllLogsToFile)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(flushAllLogsToFile)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}

- (void)tryToSendLogs {
    // send logs read from file last time
    if (_fileLogSendingBuffer.count > 0) {
        [self sendLogFromBuffer:_fileLogSendingBuffer];
    } else {
        NSString *filePath = nil;
        NSArray *jsonLogs = [self readJsonLogsFromFile:&filePath];
        
        // send logs in file first, then send logs in memory
        if (jsonLogs.count > 0) {
            _logFilePathInSending = filePath;
            _fileLogSendingBuffer = [NSMutableArray arrayWithArray:jsonLogs];
            [self sendLogFromBuffer:_fileLogSendingBuffer];
        } else {
            [self sendLogFromBuffer:_memoryLogSendingBuffer];
        }
    }
}

- (void)sendLogFromBuffer:(NSMutableArray *)logBuffer {
    _inSendingBuffer = logBuffer;
    _inSendingLogCount = _maxLineForSend;
    if (_inSendingBuffer.count < _maxLineForSend) {
        _inSendingLogCount = _inSendingBuffer.count;
    }
    
    NSRange range = NSMakeRange(0, _inSendingLogCount);
    NSArray *sendingBuffer = [_inSendingBuffer subarrayWithRange:range];
    [_apiManager uploadJsonLogs:sendingBuffer
                    withAppName:[ALLog shared].appName
                       deviceId:[ALLog shared].deviceId];
}

- (BOOL)writeLogsToFile:(NSArray *)jsonLogs{
    NSString *fileName = [[NSDate date] description];
    NSString *filePath = [[self logFileDirectory] stringByAppendingPathComponent:fileName];
    return [self writeLogs:jsonLogs toFile:filePath];
}

- (BOOL)writeLogs:(NSArray *)jsonLogs toFile:(NSString *)filePath{
    if (!_canWriteToDisk) {
        return NO;
    }
    NSOutputStream *outStream = [[NSOutputStream alloc] initToFileAtPath:filePath append:NO];
    [outStream open];
    NSError *error = nil;
    [NSJSONSerialization writeJSONObject:jsonLogs
                                toStream:outStream
                                 options:NSJSONWritingPrettyPrinted
                                   error:&error];
    [outStream close];
    if (error) {
        NSLog(@"%@", error);
        return NO;
    }
    return YES;
}


- (NSArray *)readJsonLogsFromFile:(NSString **)returnFilePath {
    NSString *logDirectory = [self logFileDirectory];
    NSArray *paths = [[NSFileManager defaultManager] subpathsAtPath:logDirectory];
    if (paths.count == 0 || paths == nil) {
        return nil;
    }
    NSArray *sortedPaths = [paths sortedArrayUsingComparator:^(NSString * firstPath, NSString* secondPath) {
        return [firstPath compare:secondPath];
    }];
    
    NSArray *jsonLogs = nil;
    for (NSString *fileName in sortedPaths) {
        NSString *filePath = [logDirectory stringByAppendingPathComponent:fileName];
        NSInputStream *inStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
        [inStream open];
        NSError *error = nil;
        id streamObject = [NSJSONSerialization JSONObjectWithStream:inStream options:NSJSONReadingAllowFragments error:&error];
        if ([streamObject isKindOfClass:[NSArray class]]) {
            *returnFilePath = filePath;
            jsonLogs = (NSArray *)streamObject;
            break;
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
        [inStream close];
    }
    return jsonLogs;
}

- (void)flushAllLogsToFile {
    // cancel all upload task in progress, then sync memory to file
    [_apiManager cancelAll];
    [_memoryLogSendingBuffer addObjectsFromArray:_logs];
    [_logs removeAllObjects];
    
    // write memory logs to a new file
    if (_memoryLogSendingBuffer.count > 0 &&
        [self writeLogsToFile:_memoryLogSendingBuffer]) {
        [_memoryLogSendingBuffer removeAllObjects];
    }
    
    // replace origial file if logs in this file don't finish sending.
    if (_fileLogSendingBuffer.count > 0 &&
        _logFilePathInSending != nil &&
        [self writeLogs:_fileLogSendingBuffer toFile:_logFilePathInSending]) {
        [_fileLogSendingBuffer removeAllObjects];
    }
}

- (NSString *)logFileDirectory {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    return [documentDir stringByAppendingPathComponent:kLogFileDirectoryName];
}

- (NSArray *)jsonLogArrayFromLogEntities:(NSArray<ALLogEntity *> *)logEntities{
    NSMutableArray *jsonLogs = [NSMutableArray arrayWithCapacity:logEntities.count];
    [logEntities enumerateObjectsUsingBlock:^(ALLogEntity * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [jsonLogs addObject:[obj toJsonDictionary]];
    }];
    return jsonLogs;
}

@end
