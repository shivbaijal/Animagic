//
//  SBFrameConfig.m
//  Animagic
//
//  Created by Shiv Baijal on 2014-04-25.
//  Copyright (c) 2014 Shiv Baijal. All rights reserved.
//

#import "SBFramesConfig.h"

@implementation SBFramesConfig

- (NSString *)initialString {
    return NSStringFromCGRect(self.initialFrame);
}


- (NSString *)finalString {
    return NSStringFromCGRect(self.finalFrame);
}


- (NSValue *)initialValue {
    return [NSValue valueWithCGRect:self.initialFrame];
}


- (NSValue *)finalValue {
    return [NSValue valueWithCGRect:self.finalFrame];
}


- (CGRect)frameAtIndex:(NSInteger)index {
    if (index == 0) {
        return self.initialFrame;
    } else {
       return self.finalFrame;
    }
}

@end
