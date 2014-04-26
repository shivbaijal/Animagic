//
//  SBTextField.h
//  Animagic
//
//  Created by Shiv Baijal on 2014-04-17.
//  Copyright (c) 2014 Shiv Baijal. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SBTextField;

@protocol SBTextFieldDelegate <UITextFieldDelegate>

- (void)userTappedOtherFrameValue:(SBTextField *)textField;
- (void)userTappedCenter:(SBTextField *)textField;

@optional
- (void)userFinishedEditingTextField:(SBTextField *)textField;

@end


@interface SBTextField : UITextField

@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIBarButtonItem *otherFrameValueButton;
@property (nonatomic, assign) id<SBTextFieldDelegate> delegate;
@property (nonatomic, assign) BOOL isFrameTextField;

@end
