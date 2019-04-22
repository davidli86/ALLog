//
//  NSDictionary+SafeRead.m
//  MeetMobile
//
//  Created by Peter de Tagyos on 4/13/12.
//  Copyright (c) 2012 The Active Network. All rights reserved.
//

#import "NSDictionary+ALSafeRead.h"
#import <objc/runtime.h>

@implementation NSDictionary (ALSafeRead)

- (id)safeObjectForKey:(id)aKey defaultValue:(id)defaultValue {
    id obj = [self objectForKey:aKey];
    if ((obj == nil) || ([obj class] == [NSNull class])) {
        return defaultValue;
    }   

    return obj;
}

- (id)safeObjectForKey:(id)aKey{
    id obj = [self objectForKey:aKey];
    if ([obj class] == [NSNull class]) {
        return nil;
    }
    
    return obj;
}

@end
