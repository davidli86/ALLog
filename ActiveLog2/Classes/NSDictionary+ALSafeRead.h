//
//  NSDictionary+SafeRead.h
//  MeetMobile
//
//  Created by Peter de Tagyos on 4/13/12.
//  Copyright (c) 2012 The Active Network. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ALSafeRead)

- (id)safeObjectForKey:(id)aKey defaultValue:(id)defaultValue;
- (id)safeObjectForKey:(id)aKey;

@end
