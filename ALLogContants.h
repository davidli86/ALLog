//
//  ALLogContants.h
//  Pods
//
//  Created by David Li on 2019/4/15.
//

#ifndef ALLogContants_h
#define ALLogContants_h
#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, ALLogType){
    /**
     *  0...00001 ALLogTypeError
     */
    ALLogTypeError      = (1 << 0),
    
    /**
     *  0...00010 ALLogTypeWarning
     */
    ALLogTypeWarning    = (1 << 1),
    
    /**
     *  0...00100 ALLogTypeInfo
     */
    ALLogTypeInfo       = (1 << 2),
};

/**
 * Used for local log
 */
static NSString * const kALLogTypeErrorConst    = @"ERROR";
static NSString * const kALLogTypeWarningConst  = @"WARNING";
static NSString * const kALLogTypeInfoConst     = @"INFO";

typedef NS_ENUM(NSUInteger, ALLogLevel){
    /**
     *  No logs
     */
    ALLogLevelOff       = 0,
    
    /**
     *  Error logs only
     */
    ALLogLevelError     = (ALLogTypeError),
    
    /**
     *  Error and warning logs
     */
    ALLogLevelWarning   = (ALLogLevelError | ALLogTypeWarning),
    
    /**
     *  Error, warning and info logs
     */
    ALLogLevelInfo      = (ALLogLevelWarning | ALLogTypeInfo),
    
    /**
     *  All logs (1...11111)
     */
    ALLogLevelAll       = NSUIntegerMax
};

/**
 *  Server will give the log level
 */
static NSString * const kALLogLevelErrorConst   = @"ERROR";
static NSString * const kALLogLevelWarningConst = @"WARNING";
static NSString * const kALLogLevelInfoConst    = @"INFO";

/**
 *  Default log component
 */
static NSString * const kDefaultLogComponent    = @"IOS";

/**
 * Log time format
 **/
static NSString * const kDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";

#endif /* ALLogContants_h */
