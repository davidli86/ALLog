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
static char * const kWriteLogQueuqFlag = "al_network_logger_write_log_queue_flag";

@interface ALNetworkLogger ()<ALLogAPIManagerProtocol, NSStreamDelegate> {
    ALLogAPIManager *_apiManager;
    NSUInteger _remainNetworkRetryTimes;

    NSMutableArray *_logs;
    NSMutableArray *_memoryLogSendingBuffer;
    
    NSString *_logDirectory;
    NSMutableArray *_fileLogSendingBuffer;
    NSString *_logFilePathInSending;
    
    BOOL _isInSending;
    NSMutableArray *_inSendingBuffer;
    NSUInteger _inSendingLogCount;
    
    dispatch_queue_t _writeLogQueue;
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
#ifdef DEBUG
        NSLog(@"Active Log Error: sendThreshold must be greater than 0!");
#endif
        return nil;
    }
    if (maxLineForSend < sendThreshold) {
#ifdef DEBUG
        NSLog(@"Active Log Error: maxLineForSend must be greater than sendThreshold!");
#endif
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

- (void)setupWithSendThreshold:(int)sendThreshold
                maxLineForSend:(int)maxLineForSend
               maxLineInMemory:(int)maxLineInMemory
                canWriteToDisk:(int)canWriteToDisk {
    _sendThreshold = sendThreshold;
    _maxLineForSend = maxLineForSend;
    _maxLineInMemory = maxLineInMemory;
    _canWriteToDisk = canWriteToDisk;
    _logDirectory = [self createLogFileDirectory];
    _writeLogQueue = dispatch_queue_create(kWriteLogQueuqFlag, DISPATCH_QUEUE_SERIAL);
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

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (void)writeLogEntity:(ALLogEntity *)logEntity {
    // because NSMutableArray is not thread-safe. so we use a
    // SERIAL queue to sync all the write task.
    dispatch_async(_writeLogQueue, ^{
        [self->_logs addObject:[logEntity toJsonDictionary]];
        if (self->_logs.count >= self->_sendThreshold) {
            // move logs to memoryLogSendingBuffer to prepare for sending
            [self->_memoryLogSendingBuffer addObjectsFromArray:self->_logs];
            [self->_logs removeAllObjects];
            
            // try to send log, reset network retry time everytime
            self->_remainNetworkRetryTimes = [ALLog shared].networkRetryTimes;
            [self tryToSendLogs];
        }
    });
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
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:_logFilePathInSending error:&error];
            if (error) {
                NSLog(@"%@", error);
            }
        }
        _isInSending = NO;
        [self tryToSendLogs];
    } else {
        if (error) {
            NSLog(@"%@", error);
        }
        if (_remainNetworkRetryTimes > 0) {
            _remainNetworkRetryTimes--;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([ALLog shared].networkRetryDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self->_isInSending = NO;
                [self tryToSendLogs];
            });
        } else {
            // To improve performance, reduce sync times with file.
            // So only write logs to file when fail to upload to server.
            // Write memoryLogSendingBuffer to file.
            if (_memoryLogSendingBuffer.count > _maxLineInMemory) {
                [self writeMemoryLogsToFile];
            }
            //it should be reset after sync with file
            _isInSending = NO;
        }
    }
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
    switch (streamEvent) {
        case NSStreamEventOpenCompleted:
        {
#ifdef DEBUG
            NSLog(@"NSStreamEventOpenCompleted");
#endif
            dispatch_async(_writeLogQueue, ^{
                if ([theStream isKindOfClass:[NSOutputStream class]]) {
                    [self processOutputStreamTask:(NSOutputStream *)theStream];
                } else {
                    [self processInputStreamTask:(NSInputStream *)theStream];
                }
            });
        }
            break;
        case NSStreamEventHasSpaceAvailable:
#ifdef DEBUG
            NSLog(@"NSStreamEventHasSpaceAvailable");
#endif
            break;
        case NSStreamEventHasBytesAvailable:
#ifdef DEBUG
            NSLog(@"NSStreamEventHasBytesAvailable");
#endif
            break;
        case NSStreamEventErrorOccurred:
#ifdef DEBUG
            NSLog(@"NSStreamEventErrorOccurred: %@", theStream.streamError);
#endif
            if ([theStream isKindOfClass:[NSInputStream class]]) {
                _isInSending = NO;
            }
            [theStream close];
            break;
        case  NSStreamEventEndEncountered:
#ifdef DEBUG
            NSLog(@"NSStreamEventEndEncountered");
#endif
            break;
        case NSStreamEventNone:
            break;
    }
}

- (void)processOutputStreamTask:(NSOutputStream *)theStream {
    NSError *error = nil;
    [NSJSONSerialization writeJSONObject:_memoryLogSendingBuffer
                                toStream:(NSOutputStream *)theStream
                                 options:NSJSONWritingPrettyPrinted
                                   error:&error];
    if (error) {
        NSLog(@"%@", error);
    } else {
        [_memoryLogSendingBuffer removeAllObjects];
    }
    [theStream close];
}

- (void)processInputStreamTask:(NSInputStream *)theStream {
    NSError *error = nil;
    id streamObject = [NSJSONSerialization JSONObjectWithStream:(NSInputStream *)theStream
                                                        options:NSJSONReadingAllowFragments
                                                          error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
    if ([streamObject isKindOfClass:[NSArray class]]) {
        _fileLogSendingBuffer = [NSMutableArray arrayWithArray:(NSArray *)streamObject];
        [self sendLogFromBuffer:_fileLogSendingBuffer];
#ifdef DEBUG
        NSLog(@"sendLogsFromFileWithPath: %@\tlines: %lu",
              _logFilePathInSending,
              (unsigned long)_fileLogSendingBuffer.count);
#endif
    } else {
        // avoid block sending on this file, whenever find wrong log
        // file, delete it and restart sending logs process.
        [[NSFileManager defaultManager] removeItemAtPath:_logFilePathInSending error:nil];
        _isInSending = NO;
        [self tryToSendLogs];
    }
    [theStream close];
}

#pragma mark - Private Methods

- (void)tryToSendLogs {
    // only allow only one task to send log concurrently.
    if (_isInSending) {
        return;
    }
    _isInSending = YES;
    
    // send logs read from file last time
    if (_fileLogSendingBuffer.count > 0) {
        [self sendLogFromBuffer:_fileLogSendingBuffer];
    } else {
        NSString *filePath = [self logFilePathForSend];
        
        // send logs in file first, then send logs in memory
        if (filePath.length > 0) {
            _logFilePathInSending = filePath;
            [self sendLogsFromFileWithPath:filePath];
        
        // check if there are logs for sending in memory
        } else if (_memoryLogSendingBuffer.count > 0){
            [self sendLogFromBuffer:_memoryLogSendingBuffer];
        
        // if no logs need to be sent, set _isInSending to NO
        } else {
            _isInSending = NO;
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

- (void)writeMemoryLogsToFile{
    NSString *fileName = [[NSDate date] description];
    NSString *filePath = [_logDirectory stringByAppendingPathComponent:fileName];
    [self writeMemoryLogsToFileWithPath:filePath];
}

- (void)writeMemoryLogsToFileWithPath:(NSString *)filePath{
    if (!_canWriteToDisk) {
        return;
    }
    // remove existing file first. if the log file is read to momory for
    // sending, but not finish.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    }
    NSOutputStream *outStream = [[NSOutputStream alloc] initToFileAtPath:filePath append:NO];
    outStream.delegate = self;
    // must send to mainRunLoop, if not, the delegate will not be called.
    [outStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [outStream open];
#ifdef DEBUG
    NSLog(@"writeMemoryLogsToFileWithPath: %@\tlines: %lu", filePath, (unsigned long)_memoryLogSendingBuffer.count);
#endif
}

- (void)sendLogsFromFileWithPath:(NSString *)filePath {
    NSInputStream *inStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
    inStream.delegate = self;
    // must send to mainRunLoop, if not, the delegate will not be called.
    [inStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [inStream open];
}

- (NSString *)logFilePathForSend {
    NSArray *subpaths = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    if ([fileManager fileExistsAtPath:_logDirectory isDirectory:&isDir] && isDir) {
        subpaths = [fileManager subpathsAtPath:_logDirectory];
    }
    if (subpaths.count == 0 || subpaths == nil) {
        return nil;
    }
    NSArray *sortedPaths = [subpaths sortedArrayUsingComparator:^(NSString * firstPath, NSString* secondPath) {
        return [firstPath compare:secondPath];
    }];
#ifdef DEBUG
    NSLog(@"log files: %@", sortedPaths);
#endif
    return [_logDirectory stringByAppendingPathComponent:sortedPaths.firstObject];
}

- (void)flushAllLogsToFile {
    // cancel all upload task in progress, then sync memory to file
#ifdef DEBUG
    NSLog(@"flushAllLogsToFile");
#endif
    [_apiManager cancelAll];
    [_memoryLogSendingBuffer addObjectsFromArray:_logs];
    [_logs removeAllObjects];
    
    // write memory logs to a new file
    if (_memoryLogSendingBuffer.count > 0) {
        [self writeMemoryLogsToFile];
    }
    
    // replace origial file if logs in this file don't finish sending.
    if (_fileLogSendingBuffer.count > 0 &&
        _logFilePathInSending != nil) {
        [self writeMemoryLogsToFileWithPath:_logFilePathInSending];
    }
}

- (NSString *)createLogFileDirectory {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    NSString *logDirectory = [documentDir stringByAppendingPathComponent:kLogFileDirectoryName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:logDirectory isDirectory:&isDir] && isDir) {
    } else {
        [fileManager removeItemAtPath:logDirectory error:nil];
        NSError *error = nil;
        [fileManager createDirectoryAtPath:logDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) {
            NSLog(@"%@", error);
        }
    }
    return logDirectory;
}

- (NSArray *)jsonLogArrayFromLogEntities:(NSArray<ALLogEntity *> *)logEntities{
    NSMutableArray *jsonLogs = [NSMutableArray arrayWithCapacity:logEntities.count];
    [logEntities enumerateObjectsUsingBlock:^(ALLogEntity * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [jsonLogs addObject:[obj toJsonDictionary]];
    }];
    return jsonLogs;
}

@end
