//
//  ALViewController.m
//  ActiveLog2
//
//  Created by David Li on 04/15/2019.
//  Copyright (c) 2019 David Li. All rights reserved.
//

#import "ALViewController.h"
#import "ALLog.h"

@interface ALViewController () {
    NSUInteger _logIndex;
}

@end

@implementation ALViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _logIndex = 0;
}

- (IBAction)printInfoLog:(id)sender {
    ActiveLogInfo(@"INFO: active log test: %lu", (unsigned long)++_logIndex);
}

- (IBAction)printInfoLog100:(id)sender {
    for (int i = 0; i < 100; i++) {
        ActiveLogInfo(@"INFO: active log test: %d", ++_logIndex);
    }
}

- (IBAction)printWarningLog:(id)sender {
    ActiveLogWarn(@"WARN: active log test: %d", ++_logIndex);
}

- (IBAction)printWarningLog100:(id)sender {
    for (int i = 0; i < 100; i++) {
        ActiveLogWarn(@"WARN: active log test: %d", ++_logIndex);
    }
}

- (IBAction)printErrorLog:(id)sender {
    ActiveLogError(@"ERROR: active log test: %d", ++_logIndex);
}

- (IBAction)printErrorLog100:(id)sender {
    for (int i = 0; i < 100; i++) {
        ActiveLogError(@"ERROR: active log test: %d", ++_logIndex);
    }
}

@end
