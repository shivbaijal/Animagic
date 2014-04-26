//
//  SBTextField.m
//  Animagic
//
//  Created by Shiv Baijal on 2014-04-17.
//  Copyright (c) 2014 Shiv Baijal. All rights reserved.
//

#import "SBTextField.h"

@interface SBTextField ()

@property (nonatomic, strong) UIToolbar *toolbar;

@end

@implementation SBTextField

- (void)awakeFromNib {
	[super awakeFromNib];
	[self setup];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)setup {
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelEditing)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneEditing)];
    if ([self isFrameTextField]) {
        self.otherFrameValueButton = [[UIBarButtonItem alloc] initWithTitle:@"Final" style:UIBarButtonItemStylePlain target:self action:@selector(setToOtherFrameValue)];
        UIBarButtonItem *centerButton = [[UIBarButtonItem alloc] initWithTitle:@"Center" style:UIBarButtonItemStylePlain target:self action:@selector(centerView)];
        self.toolbar.items = @[ cancelButton, flexSpace, self.otherFrameValueButton, flexSpace, centerButton, flexSpace,doneButton ];
    } else {
        self.toolbar.items = @[cancelButton, flexSpace, doneButton];
    }
    for (UIBarButtonItem *button in self.toolbar.items) {
        [button setTitleTextAttributes:@{ NSForegroundColorAttributeName:[UIColor blackColor] } forState:UIControlStateNormal];
    }
    self.inputAccessoryView = self.toolbar;
}


- (void)cancelEditing {
    [self resignFirstResponder];
    if (self.slider) self.text = [NSString stringWithFormat:@"%.2f", (CGFloat)self.slider.value];
}


- (void)doneEditing {
    [self resignFirstResponder];
    if (self.slider) {
        self.slider.value = self.text.floatValue;
        [self.slider sendActionsForControlEvents:UIControlEventValueChanged];
    }
    [self.delegate userFinishedEditingTextField:self];
}


- (void)setToOtherFrameValue {
    [self resignFirstResponder];
    [self.delegate userTappedOtherFrameValue:self];
}


- (void)centerView {
    [self resignFirstResponder];
    [self.delegate userTappedCenter:self];
}

@end
