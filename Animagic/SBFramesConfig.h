//
//  SBFrameConfig.h
//  Animagic
//
//  Created by Shiv Baijal on 2014-04-25.
//  Copyright (c) 2014 Shiv Baijal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SBFramesConfig : NSObject

@property (nonatomic, assign) CGRect initialFrame;
@property (nonatomic, assign) CGRect finalFrame;
@property (nonatomic, strong, readonly) NSString *initialString;
@property (nonatomic, strong, readonly) NSString *finalString;
@property (nonatomic, strong, readonly) NSValue *initialValue;
@property (nonatomic, strong, readonly) NSValue *finalValue;
@property (nonatomic, assign, getter = areProportional) BOOL proportional;

- (CGRect)frameAtIndex:(NSInteger)index;

@end
