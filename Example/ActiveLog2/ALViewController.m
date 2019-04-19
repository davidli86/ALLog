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
@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@end

@implementation ALViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *string = [[NSUUID UUID] UUIDString];
    _logTextView.text = [NSString stringWithFormat:@"%@, this is a random test log, you can modify it.", string];
    _logIndex = 0;
}

- (IBAction)printInfoLog:(id)sender {
    ActiveLogInfo(@"INFO_%lu, %@", (unsigned long)++_logIndex, _logTextView.text);
}

- (IBAction)printInfoLog100:(id)sender {
    for (int i = 0; i < 100; i++) {
        ActiveLogInfo(@"INFO_%lu, %@", (unsigned long)++_logIndex, _logTextView.text);
    }
}

- (IBAction)printWarningLog:(id)sender {
    ActiveLogWarn(@"WARN_%lu, %@", (unsigned long)++_logIndex, _logTextView.text);
}

- (IBAction)printWarningLog100:(id)sender {
    for (int i = 0; i < 100; i++) {
        ActiveLogWarn(@"WARN_%lu, %@", (unsigned long)++_logIndex, _logTextView.text);
    }
}

- (IBAction)printErrorLog:(id)sender {
    ActiveLogError(@"ERROR_%lu, %@", (unsigned long)++_logIndex, _logTextView.text);
}

- (IBAction)printErrorLog100:(id)sender {
    for (int i = 0; i < 100; i++) {
        ActiveLogError(@"ERROR_%lu, %@", (unsigned long)++_logIndex, _logTextView.text);
    }
}

@end
