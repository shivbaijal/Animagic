//
//  SBSettingsViewController.m
//  Animagic
//
//  Created by Shiv Baijal on 2014-04-02.
//  Copyright (c) 2014 Shiv Baijal. All rights reserved.
//

#import "SBAnimationViewController.h"
#import "SBTextField.h"
#import "SBFramesConfig.h"
#import "JBLineChartView.h"
#import "RBBSpringAnimation.h"
#import "TPKeyboardAvoidingScrollView.h"


@interface SBAnimationViewController () <JBLineChartViewDataSource, JBLineChartViewDelegate, UIScrollViewDelegate, SBTextFieldDelegate>

@property (nonatomic, strong) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UISlider *stiffnessSlider;
@property (nonatomic, strong) IBOutlet UISlider *massSlider;
@property (nonatomic, strong) IBOutlet UISlider *dampingSlider;
@property (nonatomic, strong) IBOutlet UISlider *velocitySlider;
@property (nonatomic, strong) IBOutlet UILabel *durationLabel;
@property (nonatomic, strong) IBOutlet JBLineChartView *curveView;
@property (nonatomic, strong) IBOutlet UIView *animatableView;
@property (nonatomic, strong) IBOutlet UIView *finalFrameView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *framesControl;
@property (nonatomic, strong) IBOutlet UISlider *widthSlider;
@property (nonatomic, strong) IBOutlet UISlider *heightSlider;
@property (nonatomic, strong) IBOutlet UISlider *xPositionSlider;
@property (nonatomic, strong) IBOutlet UISlider *yPositionSlider;
@property (nonatomic, strong) IBOutlet UIButton *scaleProportionally;
@property (nonatomic, strong) IBOutlet UIView *curveCard;
@property (nonatomic, strong) IBOutlet UIView *framesCard;
@property (nonatomic, strong) IBOutlet SBTextField *stiffnessTextField;
@property (nonatomic, strong) IBOutlet SBTextField *massTextField;
@property (nonatomic, strong) IBOutlet SBTextField *dampingTextField;
@property (nonatomic, strong) IBOutlet SBTextField *velocityTextField;
@property (nonatomic, strong) IBOutlet SBTextField *xPositionTextField;
@property (nonatomic, strong) IBOutlet SBTextField *yPositionTextField;
@property (nonatomic, strong) IBOutlet SBTextField *widthTextField;
@property (nonatomic, strong) IBOutlet SBTextField *heightTextField;
@property (nonatomic, strong) IBOutlet SBTextField *scaleTextField;
@property (nonatomic, strong) IBOutlet UIButton *curveSettingsButton;
@property (nonatomic, strong) IBOutlet UIButton *frameSettingsButton;

@property (nonatomic, strong) NSString *lastChanged;
@property (nonatomic, strong) SBFramesConfig *frames;
@property (nonatomic, strong) RBBSpringAnimation *spring;
@property (nonatomic, assign) BOOL inMotion;
@property (nonatomic, assign) BOOL firstTimeFinalFrameSelected;
@property (nonatomic, assign) NSInteger currentPage;

@end

@implementation SBAnimationViewController

#pragma mark - UIViewController Methods


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadAnimationData];

    [self setupTextFieldSliders];
    
    self.spring = [self springWithKeyPath:@"position.x" fromValue:@0 toValue:@1];
    
    self.curveView.mininumValue = 0;
    self.curveView.maximumValue = 2;
    self.curveView.delegate = self;
    self.curveView.dataSource = self;
    [self.curveView reloadData];
    
    self.durationLabel.text = [NSString stringWithFormat:@"%.2f", self.spring.duration];
    
    self.scaleTextField.text = @"1.0";
    //since UITextField does not have a textEdgeInsets property -- see http://stackoverflow.com/questions/2694411/text-inset-for-uitextfield
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 6, self.scaleTextField.frame.size.height)];
    leftView.userInteractionEnabled = NO;
    self.scaleTextField.leftView = leftView;
    self.scaleTextField.leftViewMode = UITextFieldViewModeAlways;
    
    
    self.framesCard.layer.cornerRadius = self.curveCard.layer.cornerRadius = 8.0f;
    self.framesCard.layer.borderWidth = self.curveCard.layer.borderWidth = 1.0f;
    self.framesCard.layer.borderColor = self.curveCard.layer.borderColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor;

    
    [self.framesControl setTitleTextAttributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:15.0f] } forState:UIControlStateNormal];
    
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.framesControl
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1
                                                                   constant:36];
    [self.framesControl addConstraint:constraint];
    
    self.currentPage = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveAnimationData:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}


- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.scrollView setContentSize:CGSizeMake(960, 328)];
    [self.scrollView setFrame:CGRectMake(0,self.view.frame.size.height - 328,640, 328)];
    
    //when loading from previous settings, sometimes the frame does not get redrawn
    self.animatableView.frame = self.frames.initialFrame;
    self.finalFrameView.frame = self.frames.finalFrame;
}


#pragma mark - IBAction Methods


- (IBAction)stiffnessChanged:(UISlider *)sender {
    [self springChangedForKeyPath:@"stiffness" withValue:(CGFloat)sender.value textField:self.stiffnessTextField duration:NO];
}


- (IBAction)dampingChanged:(UISlider *)sender {
    [self springChangedForKeyPath:@"damping" withValue:(CGFloat)sender.value textField:self.dampingTextField duration:YES];
}


- (IBAction)massChanged:(UISlider *)sender {
    [self springChangedForKeyPath:@"mass" withValue:(CGFloat)sender.value textField:self.massTextField duration:YES];
}


- (IBAction)velocityChanged:(UISlider *)sender {
    [self springChangedForKeyPath:@"velocity" withValue:(CGFloat)sender.value textField:self.velocityTextField duration:NO];
}


- (IBAction)xPositionChanged:(UISlider *)sender {
    [self originChangedToNewValue:(CGFloat)sender.value withTextField:self.xPositionTextField];
}


- (IBAction)yPositionChanged:(UISlider *)sender {
    [self originChangedToNewValue:(CGFloat)sender.value withTextField:self.yPositionTextField];
}


- (IBAction)widthChanged:(UISlider *)sender {
    [self sizeChangedToNewValue:(CGFloat)sender.value withTextField:self.widthTextField];
}


- (IBAction)heightChanged:(UISlider *)sender {
    [self sizeChangedToNewValue:(CGFloat)sender.value withTextField:self.heightTextField];
}


- (IBAction)curveSettingsTapped:(UITapGestureRecognizer *)sender {
    if (self.inMotion) [self.animatableView.layer removeAllAnimations];
}


- (IBAction)frameSettingsTapped:(UITapGestureRecognizer *)sender {
    if (self.inMotion) [self.animatableView.layer removeAllAnimations];
}


- (IBAction)scaleProportionallyChanged:(UIButton *)sender {
    if ([self.frames  areProportional]) {
        self.frames.proportional = NO;
        sender.backgroundColor = [UIColor grayColor];
    } else {
        if ([self.lastChanged isEqualToString:@"width"]) {
            [self changeScale:self.widthSlider.value/self.frames.initialFrame.size.width];
        } else if ([self.lastChanged isEqualToString:@"height"]) {
            [self changeScale:self.heightSlider.value/self.frames.initialFrame.size.height];
        }
    }
}


- (IBAction)framesChanged:(UISegmentedControl *)sender {
    BOOL hideScale = (self.framesControl.selectedSegmentIndex == 0);
    self.scaleProportionally.hidden = self.scaleTextField.hidden = hideScale;
    if (self.firstTimeFinalFrameSelected) {
        self.frames.finalFrame = self.frames.initialFrame;
        self.firstTimeFinalFrameSelected = NO;
    }
    [self showInitialAndFinalViews];
    CGRect currentFrame = [self.frames frameAtIndex:self.framesControl.selectedSegmentIndex];
    self.xPositionSlider.value = currentFrame.origin.x;
    self.yPositionSlider.value = currentFrame.origin.y;
    self.widthSlider.value = currentFrame.size.width;
    self.heightSlider.value = currentFrame.size.height;
    
    self.xPositionTextField.text = [NSString stringWithFormat:@"%.2f", currentFrame.origin.x];
    self.yPositionTextField.text = [NSString stringWithFormat:@"%.2f", currentFrame.origin.y];
    self.widthTextField.text = [NSString stringWithFormat:@"%.2f", currentFrame.size.width];
    self.heightTextField.text = [NSString stringWithFormat:@"%.2f", currentFrame.size.height];
    CGFloat initialArea = self.frames.initialFrame.size.width*self.frames.initialFrame.size.height;
    CGFloat finalArea = self.frames.finalFrame.size.width*self.frames.finalFrame.size.height;
    CGFloat scale = sqrt(finalArea/initialArea);
    self.scaleTextField.text = [NSString stringWithFormat:@"%.2f", scale];
}


- (IBAction)tapToAnimateView:(UITapGestureRecognizer *)sender {
    CGRect fromRect = self.frames.initialFrame;
    CGRect toRect = self.frames.finalFrame;
    RBBSpringAnimation *positionSpring = [self springWithKeyPath:@"position"
                                                       fromValue:[NSValue valueWithCGPoint:self.animatableView.layer.position]
                                                         toValue:[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(toRect), CGRectGetMidY(toRect))]];
    RBBSpringAnimation *sizeSpring = [self springWithKeyPath:@"bounds.size"
                                                   fromValue:[NSValue valueWithCGSize:fromRect.size]
                                                     toValue:[NSValue valueWithCGSize:toRect.size]];
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.delegate = self;
    group.animations = @[ positionSpring, sizeSpring ];
    group.duration = [self.spring durationForEpsilon:0.01];
    [self.animatableView.layer addAnimation:group forKey:@"animation"];
}


- (IBAction)cardSwipedDown:(UISwipeGestureRecognizer *)sender {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (self.scrollView.contentOffset.x + (0.5f * pageWidth)) / pageWidth;
    
    if (page == 0) {
       [self swipeDownCard:self.curveCard withButton:self.curveSettingsButton];
    } else if (page == 1) {
        [self swipeDownCard:self.framesCard withButton:self.frameSettingsButton];
        self.finalFrameView.hidden = YES;
        self.animatableView.alpha = 1.0f;
    }
}


- (IBAction)cardSwipedUp:(UISwipeGestureRecognizer *)sender {
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (self.scrollView.contentOffset.x + (0.5f * pageWidth)) / pageWidth;
    
    if (page == 0) {
      [self swipeUpCard:self.curveCard withButton:self.curveSettingsButton];
    } else if (page == 1){
        [self swipeUpCard:self.framesCard withButton:self.frameSettingsButton];
    }
}


- (IBAction)presentCurveSettingsButtonTapped:(UIButton *)sender {
    [self swipeUpCard:self.curveCard withButton:self.curveSettingsButton];
}


- (IBAction)presentFrameSettingsButtonTapped:(UIButton *)sender {
    [self swipeUpCard:self.framesCard withButton:self.frameSettingsButton];
}


#pragma mark - UIScrollViewDelegate Methods


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = scrollView.frame.size.width;
    float partialPage = scrollView.contentOffset.x / pageWidth;
    NSInteger newPage = lround(partialPage);
    if (self.currentPage != newPage) {
        if (newPage == 0) {
            self.finalFrameView.hidden = YES;
            self.animatableView.alpha = 1.0f;
        } else if (newPage == 1) {
            [self showInitialAndFinalViews];
        }
        self.currentPage = newPage;
    }
}


#pragma mark - SBTextFieldDelegate Methods


- (void)userFinishedEditingTextField:(SBTextField *)textField {
    if (textField == self.scaleTextField) [self changeScale:textField.text.floatValue];
}


- (void)userTappedOtherFrameValue:(SBTextField *)textField {
    NSInteger otherIndex = [@(self.framesControl.selectedSegmentIndex == 0) integerValue];
    if (textField == self.xPositionTextField) {
        self.xPositionSlider.value = [self.frames frameAtIndex:otherIndex].origin.x;
        textField.text = [NSString stringWithFormat:@"%.2f", self.xPositionSlider.value];
    } else if (textField == self.yPositionTextField) {
        self.yPositionSlider.value = [self.frames frameAtIndex:otherIndex].origin.y;
        textField.text = [NSString stringWithFormat:@"%.2f", self.yPositionSlider.value];
    } else if (textField == self.widthTextField) {
        self.widthSlider.value = [self.frames frameAtIndex:otherIndex].size.width;
        textField.text = [NSString stringWithFormat:@"%.2f", self.widthSlider.value];
    } else if (textField == self.heightTextField) {
        self.heightSlider.value = [self.frames frameAtIndex:otherIndex].size.height;
        textField.text = [NSString stringWithFormat:@"%.2f", self.heightSlider.value];
    }
    [textField.slider sendActionsForControlEvents:UIControlEventValueChanged];
}


- (void)userTappedCenter:(SBTextField *)textField {
    if (textField == self.xPositionTextField) {
        self.xPositionSlider.value = ([UIScreen mainScreen].bounds.size.width - self.widthSlider.value)/2;
        textField.text = [NSString stringWithFormat:@"%.2f", self.xPositionSlider.value];
    } else if (textField == self.yPositionTextField) {
        self.yPositionSlider.value = ([UIScreen mainScreen].bounds.size.height - self.heightSlider.value)/2;
        textField.text = [NSString stringWithFormat:@"%.2f", self.yPositionSlider.value];
    } else if (textField == self.widthTextField) {
        self.xPositionSlider.value = ([UIScreen mainScreen].bounds.size.width - self.widthSlider.value)/2;
        self.xPositionTextField.text = [NSString stringWithFormat:@"%.2f", self.xPositionSlider.value];
        [self.xPositionSlider sendActionsForControlEvents:UIControlEventValueChanged];
    } else if (textField == self.heightTextField) {
        self.yPositionSlider.value = ([UIScreen mainScreen].bounds.size.height - self.heightSlider.value)/2;
        self.yPositionTextField.text = [NSString stringWithFormat:@"%.2f", self.yPositionSlider.value];
        [self.yPositionSlider sendActionsForControlEvents:UIControlEventValueChanged];
    }
    [textField.slider sendActionsForControlEvents:UIControlEventValueChanged];
}


- (void)textFieldDidBeginEditing:(UITextField *)textField {
    SBTextField *customTextField = (SBTextField *)textField;
    if (self.framesControl.selectedSegmentIndex == 0) {
        customTextField.otherFrameValueButton.title = @"Final";
    } else if (self.framesControl.selectedSegmentIndex == 1) {
        customTextField.otherFrameValueButton.title = @"Initial";
    }
}


#pragma mark - JBLineChartViewDelegate Methods


- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
    return (((NSNumber *)[self.spring.values objectAtIndex:horizontalIndex]).floatValue);
}


#pragma mark - JBLineChartViewDataSource Methods


- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView {
    return 1;
}


- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex {
    return self.spring.values.count;
}


- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex {
    return YES;
}


#pragma mark - Gesture Recognizer Methods


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}


#pragma mark - Animation Data Methods


- (void)saveAnimationData:(NSNotification *)notification {
    NSArray *framesData = @[ self.frames.initialString, self.frames.finalString ];
    NSDictionary *animationData = @{ @"frames":framesData, @"curve":@{ @"stiffness":self.stiffnessTextField.text, @"mass":self.massTextField.text, @"damping":self.dampingTextField.text, @"velocity":self.velocityTextField.text }, @"scaleProportionally":@(self.frames.proportional) };
    [[NSUserDefaults standardUserDefaults] setObject:animationData forKey:@"animationData"];
}


- (void)loadAnimationData {
    if (!self.frames) self.frames = [[SBFramesConfig alloc] init];
    NSDictionary *animationData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"animationData"];
    if (animationData) {
        NSArray *framesArray = (NSArray *)[animationData objectForKey:@"frames"];
        self.frames.initialFrame = CGRectFromString([framesArray objectAtIndex:0]);
        self.frames.finalFrame = CGRectFromString([framesArray objectAtIndex:1]);
        self.frames.proportional = [(NSNumber *)[animationData objectForKey:@"scaleProportionally"] boolValue];
        NSDictionary *curveData = [animationData objectForKey:@"curve"];
        self.stiffnessSlider.value = [[curveData objectForKey:@"stiffness"] floatValue];
        self.massSlider.value = [[curveData objectForKey:@"mass"] floatValue];
        self.dampingSlider.value = [[curveData objectForKey:@"damping"] floatValue];
        self.velocitySlider.value = [[curveData objectForKey:@"velocity"] floatValue];
        
        self.stiffnessTextField.text = [NSString stringWithFormat:@"%.2f", (CGFloat)self.stiffnessSlider.value];
        self.massTextField.text = [NSString stringWithFormat:@"%.2f", (CGFloat)self.massSlider.value];
        self.dampingTextField.text = [NSString stringWithFormat:@"%.2f", (CGFloat)self.dampingSlider.value];
        self.velocityTextField.text = [NSString stringWithFormat:@"%.2f", (CGFloat)self.velocitySlider.value];
        
        if (![self.frames areProportional]) self.scaleProportionally.backgroundColor = [UIColor grayColor];
    } else {
        self.frames.initialFrame = self.frames.finalFrame = self.animatableView.frame;
        self.firstTimeFinalFrameSelected = YES;
        self.frames.proportional = YES;
    }
    
    CGRect initialFrame = self.frames.initialFrame;
    self.xPositionSlider.value = initialFrame.origin.x;
    self.yPositionSlider.value = initialFrame.origin.y;
    self.widthSlider.value = initialFrame.size.width;
    self.heightSlider.value = initialFrame.size.height;
    
    self.xPositionTextField.text = [NSString stringWithFormat:@"%.2f", initialFrame.origin.x];
    self.yPositionTextField.text = [NSString stringWithFormat:@"%.2f", initialFrame.origin.y];
    self.widthTextField.text = [NSString stringWithFormat:@"%.2f", initialFrame.size.width];
    self.heightTextField.text = [NSString stringWithFormat:@"%.2f", initialFrame.size.height];
}


#pragma mark - Update Methods


- (void)springChangedForKeyPath:(NSString *)aKeyPath withValue:(CGFloat)newValue textField:(SBTextField *)textField duration:(BOOL)updateDuration {
    textField.text = [NSString stringWithFormat:@"%.2f", newValue];
    [self.spring setValue:@(newValue) forKeyPath:aKeyPath];
    if (updateDuration) {
        self.spring.duration = [self.spring durationForEpsilon:0.01];
        self.durationLabel.text = [NSString stringWithFormat:@"%.2f", self.spring.duration];
    }
    [self.curveView reloadData];
}


- (void)originChangedToNewValue:(CGFloat)newValue withTextField:(SBTextField *)textField {
    NSInteger index = self.framesControl.selectedSegmentIndex;
    textField.text = [NSString stringWithFormat:@"%.2f", newValue];
    CGRect originalFrame = [self.frames frameAtIndex:index];
    if (textField == self.xPositionTextField) {
        originalFrame.origin.x = newValue;
    } else if (textField == self.yPositionTextField) {
        originalFrame.origin.y = newValue;
    }
    [self updateFrame:originalFrame forIndex:index];
}


- (void)sizeChangedToNewValue:(CGFloat)newValue withTextField:(SBTextField *)textField {
    NSInteger index = self.framesControl.selectedSegmentIndex;
    CGRect originalFrame = [self.frames frameAtIndex:index];
    textField.text = [NSString stringWithFormat:@"%.2f", newValue];
    if (index == 1) {
        CGFloat scale = self.scaleTextField.text.floatValue;
        if (textField == self.heightTextField) {
            self.lastChanged = @"height";
            if ([self.frames areProportional]){
                scale = newValue/self.frames.initialFrame.size.height;
                originalFrame.size.width = self.widthSlider.value = self.frames.initialFrame.size.width * scale;
                self.widthTextField.text = [NSString stringWithFormat:@"%.2f", self.heightSlider.value];
            }
        } else if (textField == self.widthTextField) {
            self.lastChanged = @"width";
            if ([self.frames areProportional]) {
                scale = newValue/self.frames.initialFrame.size.width;
                originalFrame.size.height = self.heightSlider.value = self.frames.initialFrame.size.height * scale;
                self.heightTextField.text = [NSString stringWithFormat:@"%.2f", self.widthSlider.value];
            }
        }
        if (![self.frames areProportional]) {
            scale = sqrt((self.widthSlider.value*self.heightSlider.value)/((self.frames.initialFrame.size.width)*(self.frames.initialFrame.size.height)));
        }
        self.scaleTextField.text = [NSString stringWithFormat:@"%.2f", scale];
    }
    if (textField == self.heightTextField) {
        originalFrame.size.height = newValue;
    } else if (textField == self.widthTextField) {
        originalFrame.size.width = newValue;
    }
    [self updateFrame:originalFrame forIndex:index];
}


- (void)updateFrame:(CGRect)newFrame forIndex:(NSInteger)index {
    if (index == 0) {
        self.frames.initialFrame = newFrame;
    }
    else if (index == 1) {
        self.frames.finalFrame = newFrame;
    }
    if (!self.inMotion) {
        if (index == 0) {
            self.animatableView.frame = newFrame;
        }
        else if (index == 1 ) {
            self.finalFrameView.frame = newFrame;
        }
    }
}


- (void)changeScale:(CGFloat)scale {
    self.frames.proportional = YES;
    self.scaleProportionally.backgroundColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    self.scaleTextField.text = [NSString stringWithFormat:@"%.2f", scale];
    if ([self.lastChanged isEqualToString:@"width"]) {
        self.heightSlider.value = self.frames.initialFrame.size.height * scale;
        self.heightTextField.text = [NSString stringWithFormat:@"%.2f", self.heightSlider.value];
        [self.heightSlider sendActionsForControlEvents:UIControlEventValueChanged];
    } else {
        self.widthSlider.value = self.frames.initialFrame.size.width * scale;
        self.widthTextField.text = [NSString stringWithFormat:@"%.2f", self.widthSlider.value];
        [self.widthSlider sendActionsForControlEvents:UIControlEventValueChanged];
    }
}


#pragma mark - Spring Builder Methods


- (RBBSpringAnimation *)springWithKeyPath:(NSString *)aKeyPath fromValue:(NSValue *)fromVal toValue:(NSValue *)toVal {
    RBBSpringAnimation *newSpring = [RBBSpringAnimation animationWithKeyPath:aKeyPath];
    newSpring.stiffness = self.stiffnessTextField.text.floatValue;
    newSpring.mass = self.massTextField.text.floatValue;
    newSpring.damping = self.dampingTextField.text.floatValue;
    newSpring.velocity = self.velocityTextField.text.floatValue;
    newSpring.fromValue = fromVal;
    newSpring.toValue = toVal;
    newSpring.duration = [newSpring durationForEpsilon:0.01];
    return newSpring;
}


#pragma mark - Helper Methods


- (void)setupTextFieldSliders {
    self.stiffnessTextField.slider = self.stiffnessSlider;
    self.dampingTextField.slider = self.dampingSlider;
    self.massTextField.slider = self.massSlider;
    self.velocityTextField.slider = self.velocitySlider;
    self.xPositionTextField.slider = self.xPositionSlider;
    self.yPositionTextField.slider = self.yPositionSlider;
    self.widthTextField.slider = self.widthSlider;
    self.heightTextField.slider = self.heightSlider;
}


- (void)animationDidStart:(CAAnimation *)anim {
    self.curveCard.alpha = self.framesCard.alpha = 0.2f;
    self.inMotion = YES;
}


- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.curveCard.alpha = self.framesCard.alpha = 1.0f;
    self.inMotion = NO;
    
}


- (void)showInitialAndFinalViews {
    self.finalFrameView.hidden = self.firstTimeFinalFrameSelected;
    if (self.framesControl.selectedSegmentIndex == 0) {
        self.animatableView.alpha = 1.0f;
        self.finalFrameView.alpha = 0.4f;
    } else {
        self.animatableView.alpha = 0.4f;
        self.finalFrameView.alpha = 1.0f;
    }
}


- (void)swipeDownCard:(UIView *)card withButton:(UIButton *)button {
    self.scrollView.scrollEnabled = NO;
    self.scrollView.userInteractionEnabled = NO;
        button.hidden = NO;
    [UIView animateWithDuration:0.15
                     animations:^{
                         CGRect currentFrame = card.frame;
                         currentFrame.origin.y = 292;
                         card.frame = currentFrame;
                         button.alpha = 1.0f;
                     }
     ];
}


- (void)swipeUpCard:(UIView *)card withButton:(UIButton *)button {
    if (card.frame.origin.y == 292) {
        self.scrollView.userInteractionEnabled = YES;
        [UIView animateWithDuration:0.15 animations:^{
            CGRect currentFrame = card.frame;
            currentFrame.origin.y = 0;
            card.frame = currentFrame;
            button.alpha = 0;
        } completion:^(BOOL finished) {
            button.hidden = YES;
            self.scrollView.scrollEnabled = YES;
            if (button == self.frameSettingsButton) [self showInitialAndFinalViews];
        }];
    }
}

@end
