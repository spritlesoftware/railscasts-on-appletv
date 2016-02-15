//
//  VKPlayerViewControllerTV.m
//  VideoKitSample
//
//  Created by Murat Sudan on 23/09/15.
//  Copyright © 2015 iosvideokit. All rights reserved.
//

#import "VKPlayerControllerTV.h"
#import "VKGLES2View.h"
#import "VKStreamInfoView.h"

@interface FocusableView : UIView

@property (nonatomic, assign) BOOL focusToSlider;
@property (nonatomic, assign) BOOL ignoreFocusAnimations;

@end

@implementation FocusableView

@synthesize focusToSlider = _focusToSlider;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Custom initialization
        return self;
    }
    return nil;
}

#pragma mark - Focus Management

- (UIView *)preferredFocusedView {
    
    if (_focusToSlider) {
        
        UIView *slider = nil;
        
        for (UIView *v in self.subviews) {
            for (UIView *z in v.subviews) {
                if ([z isKindOfClass:[FGThrowSlider class]]) {
                    slider = z;
                }
            }
        }
        
        if (slider) {
            VKLog(kVKLogLevelUIControlExtra,@"Player view: preferredFocusedView-> slider");
            return slider;
        }
    }
    
    VKLog(kVKLogLevelUIControlExtra,@"Player view: preferredFocusedView-> self");
    return self;
}

- (BOOL)canBecomeFocused {
    if (!_focusToSlider) {
        VKLog(kVKLogLevelUIControlExtra,@"Player view: canBecomeFocused-> YES");
        return YES;
    }
    
    UIView *slider = nil;
    
    for (UIView *v in self.subviews) {
        for (UIView *z in v.subviews) {
            if ([z isKindOfClass:[FGThrowSlider class]]) {
                slider = z;
            }
        }
    }
    
    if (slider && slider.isHidden) {
        VKLog(kVKLogLevelUIControlExtra,@"Player view: canBecomeFocused-> YES");
        return YES;
    }
    
    
    VKLog(kVKLogLevelUIControlExtra,@"Player view: canBecomeFocused-> NO");
    return NO;
}


- (void) didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
    [coordinator addCoordinatedAnimations:^{
        if (!_ignoreFocusAnimations) {
            if (self.focused) {
                VKLog(kVKLogLevelUIControlExtra,@"Player view: Focused");
                self.layer.masksToBounds = NO;
                self.layer.shadowColor = [[UIColor blackColor] CGColor];
                self.layer.shadowRadius = 30;
                self.layer.shadowOpacity = 1.0;
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.05, 1.05);
            } else {
                VKLog(kVKLogLevelUIControlExtra,@"Player view: Not Focused");
                self.layer.masksToBounds = YES;
                self.layer.shadowRadius = 0;
                self.layer.shadowOpacity = 0.0;
                self.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
            }
        }
    } completion:nil];
}

@end

@interface VKPlayerControllerTV () {

#ifdef VK_RECORDING_CAPABILITY
    UILabel *_labelRecording;
#endif
    FGThrowSlider *_slider;
    UILabel *_labelStreamCurrentTime;
    UILabel *_labelStreamTotalDuration;
    
    UIView *_viewBottomPanel;
    UIView *_viewTopPanel;
    UILabel *_labelTopTitle;
    UIActivityIndicatorView *_activityIndicator;
    
    UITapGestureRecognizer *_homeTapRecognizer;
    UITapGestureRecognizer *_pauseTapRecognizer;
    
    NSTimer *timerForRecordingLabel;
    
    VKPlayerControlStyleTV _controlStyle;
}

@end

@implementation VKPlayerControllerTV


#pragma mark Initialization

- (id)init {
    self = [super initBase];
    if (self) {
        [self prepare];
        return self;
    }
    return nil;
}

- (id)initWithURLString:(NSString *)urlString {
    
    self = [super initWithURLString:urlString];
    if (self) {
        [self prepare];
        return self;
    }
    return nil;
}

- (void)prepare {
    // Custom initialization
    _controlStyle = kVKPlayerControlStyleTVDefault;
    [self createUI];
    [self addAppleTVRemoteControllerGestures];
}

#pragma mark Subviews initialization

- (void)createUI {
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    _view = [[FocusableView alloc] initWithFrame:bounds];
    self.view.backgroundColor = _backgroundColor;
    
    [self createUITopPanel];
    [self createUIBottomPanel];
    [self createUICenter];
}

- (void)createUITopPanel {

    CGRect bounds = [[UIScreen mainScreen] bounds];
    CGFloat viewWidth = bounds.size.width;
    
    /* Toolbar on top: _viewTopPanel */
    _viewTopPanel = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, viewWidth, 70.0)] autorelease];
    _viewTopPanel.autoresizesSubviews = YES;
    _viewTopPanel.autoresizingMask =  UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    _viewTopPanel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    /* Toolbar on top: _labelTopTitle */
    _labelTopTitle = [[[UILabel alloc] initWithFrame:CGRectMake(0.0,10.0, _viewTopPanel.frame.size.width, 50.0)] autorelease];
    _labelTopTitle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _labelTopTitle.contentMode = UIViewContentModeCenter;
    _labelTopTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    _labelTopTitle.minimumScaleFactor = 0.6;
    _labelTopTitle.textAlignment = NSTextAlignmentCenter;
    _labelTopTitle.numberOfLines = 1;
    _labelTopTitle.backgroundColor = [UIColor clearColor];
    _labelTopTitle.shadowOffset = CGSizeMake(0.0, -1.0);
    _labelTopTitle.textColor = [UIColor darkGrayColor];
    _labelTopTitle.font = [UIFont fontWithName:@"HelveticaNeue" size:35];
    _labelTopTitle.adjustsFontSizeToFitWidth = YES;
    [_viewTopPanel addSubview:_labelTopTitle];
    
    /* Toolbar on top: _activityIndicator */
    _activityIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
    _activityIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    _activityIndicator.frame = CGRectMake((_viewTopPanel.frame.size.width - 60.0), 10.0, 50.0, 50.0);
    _activityIndicator.hidesWhenStopped = YES;
    _activityIndicator.backgroundColor = [UIColor clearColor];
    [_viewTopPanel addSubview:_activityIndicator];

    [self.view addSubview:_viewTopPanel];
}

- (void)createUIBottomPanel {

    CGRect bounds = [[UIScreen mainScreen] bounds];
    CGFloat viewWidth = bounds.size.width;
    CGFloat viewHeight = bounds.size.height;
    
    _viewBottomPanel = [[[UIView alloc] initWithFrame:CGRectMake(0, viewHeight-100, viewWidth, 200)] autorelease];
    _viewBottomPanel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _viewBottomPanel.autoresizesSubviews = YES;
    _viewBottomPanel.backgroundColor = [UIColor clearColor];
    
    _slider = [FGThrowSlider sliderWithFrame:CGRectMake(viewWidth/6, 0, viewWidth/3*2, 50) andDelegate:self];
    _slider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _slider.hidden = YES;
    
    [_viewBottomPanel addSubview:_slider];
    
    _labelStreamCurrentTime = [[[UILabel alloc] initWithFrame:CGRectMake(viewWidth/6, 30, 100, 50)] autorelease];
    _labelStreamCurrentTime.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _labelStreamCurrentTime.textAlignment = NSTextAlignmentCenter;
    _labelStreamCurrentTime.text = @"00:00";
    _labelStreamCurrentTime.numberOfLines = 1;
    _labelStreamCurrentTime.opaque = NO;
    _labelStreamCurrentTime.backgroundColor = [UIColor clearColor];
    _labelStreamCurrentTime.font = [UIFont fontWithName:@"HelveticaNeue" size:35.0];
    _labelStreamCurrentTime.textColor = [UIColor whiteColor];
    _labelStreamCurrentTime.minimumScaleFactor = 0.3;
    _labelStreamCurrentTime.adjustsFontSizeToFitWidth = YES;
    _labelStreamCurrentTime.hidden = YES;
    
    [_viewBottomPanel addSubview:_labelStreamCurrentTime];
    
    /* labelStreamTotalDuration */
    _labelStreamTotalDuration = [[[UILabel alloc] initWithFrame:CGRectMake(viewWidth-(viewWidth/6)-100, 30, 100, 50)] autorelease];
    _labelStreamTotalDuration.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _labelStreamTotalDuration.textAlignment = NSTextAlignmentCenter;
    _labelStreamTotalDuration.numberOfLines = 1;
    _labelStreamTotalDuration.opaque = NO;
    _labelStreamTotalDuration.backgroundColor = [UIColor clearColor];
    _labelStreamTotalDuration.textColor = [UIColor whiteColor];
    _labelStreamTotalDuration.font = [UIFont fontWithName:@"HelveticaNeue" size:35.0];
    _labelStreamTotalDuration.minimumScaleFactor = 0.3;
    _labelStreamTotalDuration.adjustsFontSizeToFitWidth = YES;
    _labelStreamTotalDuration.hidden = YES;
    
    [_viewBottomPanel addSubview:_labelStreamTotalDuration];
    
#ifdef VK_RECORDING_CAPABILITY
    CGRect labelRecordingFrame = CGRectMake((_labelStreamTotalDuration.frame.origin.x + _labelStreamCurrentTime.frame.origin.x)/2,_labelStreamCurrentTime.frame.origin.y,150,50);
    _labelRecording = [[UILabel alloc] initWithFrame:labelRecordingFrame];
    _labelRecording.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _labelRecording.textAlignment = NSTextAlignmentCenter;
    _labelRecording.numberOfLines = 1;
    _labelRecording.opaque = NO;
    _labelRecording.backgroundColor = [UIColor clearColor];
    _labelRecording.textColor = [UIColor redColor];
    _labelRecording.font = [UIFont fontWithName:@"HelveticaNeue" size:40.0];
    _labelRecording.minimumScaleFactor = 0.3;
    _labelRecording.adjustsFontSizeToFitWidth = YES;
    _labelRecording.hidden = YES;
    _labelRecording.text = @"Recording";
    
    [_viewBottomPanel addSubview:_labelRecording];
#endif

    [self.view addSubview:_viewBottomPanel];
}

- (void) createUICenter {
    [super createUICenter];
}

#pragma mark - Subviews management

- (void)updateBarWithDurationState:(VKError) state {
    
    BOOL value = NO;
    if (state == kVKErrorNone) {
        value = YES;
    }
    
    [_labelStreamCurrentTime setHidden:!value];
    [_labelStreamTotalDuration setHidden:!value];
    [_slider setHidden:!value];
}

- (void)focusOnSubview:(BOOL)value {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [(FocusableView *)_view setFocusToSlider:(_controlStyle != kVKPlayerControlStyleTVNone && value) ? YES : NO];
        [_view setNeedsFocusUpdate];
        [_view updateFocusIfNeeded];
    });
}

- (void)setControlStyle:(VKPlayerControlStyleTV)controlStyle {
    _controlStyle = controlStyle;
    if (_controlStyle == kVKPlayerControlStyleTVNone) {
        [self showControlPanel:NO willExpire:NO];
    }
}

- (void)setFullScreen:(BOOL)value animated:(BOOL)animated {
    if (value && !_fullScreen) {
        _fullScreen = YES;
        [(FocusableView *)_view setIgnoreFocusAnimations:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerWillEnterFullscreenNotification object:self userInfo:nil];
        if (_containerVc &&
            ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
            [(FocusableView *)_view setFocusToSlider:(_controlStyle != kVKPlayerControlStyleTVNone && !_slider.isHidden) ? YES : NO];
            _controlStyle = kVKPlayerControlStyleTVDefault;
            [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidEnterFullscreenNotification object:self userInfo:nil];
            return;
        } else {
            [self useContainerViewControllerAnimated:animated];
        }
    } else if (!value && _fullScreen) {
        _fullScreen = NO;
        if (_containerVc &&
            ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
            return;
        } else {
            if (_containerVc) {
                [(FocusableView *)_view setIgnoreFocusAnimations:NO];
                [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerWillExitFullscreenNotification object:self userInfo:nil];
                [(VKFullscreenContainer *)_containerVc onDismissWithAnimated:animated];
                [_containerVc release];
                _containerVc = nil;
                
                if (_controlStyle != kVKPlayerControlStyleTVNone) {
                    _controlStyle = kVKPlayerControlStyleTVDefault;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.9 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidExitFullscreenNotification object:self userInfo:nil];
                });
            }
        }
    }
}

- (void)useContainerViewControllerAnimated:(BOOL)animated {
    UIViewController *currentVc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    UIViewController *topVc = nil;
    
    if (currentVc) {
        if ([currentVc isKindOfClass:[UINavigationController class]]) {
            topVc = [(UINavigationController *)currentVc topViewController];
        } else if ([currentVc isKindOfClass:[UITabBarController class]]) {
            topVc = [(UITabBarController *)currentVc selectedViewController];
        } else if ([currentVc presentedViewController]) {
            topVc = [currentVc presentedViewController];
        } else if ([currentVc isKindOfClass:[UIViewController class]]) {
            topVc = currentVc;
        } else {
            VKLog(kVKLogLevelDecoder, @"Expected a view controller but not found...");
            return;
        }
    } else {
        VKLog(kVKLogLevelDecoder, @"Expected a view controller but not found...");
        return;
    }
    
    [self.view.superview bringSubviewToFront:self.view];
    
    float duration = (animated) ? 0.5 : 0.0;
    
    UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] lastObject];
    id windowActive = keyWindow;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        //running on iOS 7.x
        windowActive = [[keyWindow subviews] objectAtIndex:0];
    }
    
    CGRect newRectToWindow = [windowActive convertRect:self.view.frame fromView:self.view.superview];
    VKFullscreenContainer *fsContainerVc = [[[VKFullscreenContainer alloc] initWithPlayerController:self
                                                                                         windowRect:newRectToWindow] autorelease];
    fsContainerVc.view.backgroundColor = [UIColor clearColor];
    
    self.view.frame = newRectToWindow;
    [windowActive addSubview:self.view];
    
    [UIView animateWithDuration:duration animations:^{
        CGRect bounds = [[UIScreen mainScreen] bounds];
        
        self.view.frame = bounds;
        
    } completion:^(BOOL finished) {
        
        [topVc presentViewController:fsContainerVc animated:NO completion:^{
            self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.view.frame = fsContainerVc.view.bounds;
            [fsContainerVc.view addSubview:self.view];
            
            _containerVc = [fsContainerVc retain];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kVKPlayerDidEnterFullscreenNotification object:nil userInfo:nil];
        }];
    }];
}

#pragma mark - FGThrowSliderDelegate

- (void)slider:(FGThrowSlider *)slider changedValue:(CGFloat)value {
    _durationCurrent = value;
    _labelStreamCurrentTime.text = [NSString stringWithFormat:@"%02d:%02d", (int)_durationCurrent/60, ((int)_durationCurrent % 60)];
}

- (void)slider:(FGThrowSlider *)slider endValue:(CGFloat)value {
    [self setStreamCurrentDuration:value];
    _labelStreamCurrentTime.text = [NSString stringWithFormat:@"%02d:%02d", (int)value/60, ((int)value % 60)];
    [self showControlPanel:YES willExpire:YES];
}

#pragma mark - Gesture Recognizers management

- (void)addScreenControlGesturesToView:(UIView *)viewGesture {
    
#pragma unused (viewGesture)
    
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    _doubleTapGestureRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    _doubleTapGestureRecognizer.delegate = self;
    [_view addGestureRecognizer:_doubleTapGestureRecognizer];
    
    _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    _singleTapGestureRecognizer.numberOfTapsRequired = 1;
    _singleTapGestureRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
    _singleTapGestureRecognizer.delegate = self;
    [_view addGestureRecognizer:_singleTapGestureRecognizer];
}

- (void)addAppleTVRemoteControllerGestures {
    NSLog(@"addAppleTVRemoteControllerGestures");
    _homeTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(homeButtonTapped:)];
    _homeTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
    [_view addGestureRecognizer:_homeTapRecognizer];
    
    _pauseTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pauseButtonTapped:)];
    _pauseTapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [_view addGestureRecognizer:_pauseTapRecognizer];
}

- (void)removeScreenControlGesturesFromView:(UIView *)viewGesture {
    
#pragma unused (viewGesture)
    
    if (_singleTapGestureRecognizer) {
        [_view removeGestureRecognizer:_singleTapGestureRecognizer];
        [_singleTapGestureRecognizer release];
        _singleTapGestureRecognizer = nil;
    }
    if (_doubleTapGestureRecognizer) {
        [_view removeGestureRecognizer:_doubleTapGestureRecognizer];
        [_doubleTapGestureRecognizer release];
        _doubleTapGestureRecognizer = nil;
    }
}

- (void)removeAppleTVRemoteControllerGestures {
    NSLog(@"removeAppleTVRemoteControllerGestures");
    if (_homeTapRecognizer) {
        [_view removeGestureRecognizer:_homeTapRecognizer];
        [_homeTapRecognizer release];
        _homeTapRecognizer = nil;
    }
    if (_pauseTapRecognizer) {
        [_view removeGestureRecognizer:_pauseTapRecognizer];
        [_pauseTapRecognizer release];
        _pauseTapRecognizer = nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Recording

#ifdef VK_RECORDING_CAPABILITY

- (void) startRecording {
    [super startRecording];
    _labelRecording.hidden = NO;
    timerForRecordingLabel = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              target:self
                                                            selector:@selector(showHideRecordingLabel)
                                                            userInfo:nil
                                                             repeats:YES];
}

- (void) stopRecording {
    [super stopRecording];
    _labelRecording.hidden = YES;
    if (timerForRecordingLabel) {
        [timerForRecordingLabel invalidate];
        [timerForRecordingLabel release];
        timerForRecordingLabel = nil;
    }
}

- (void) showHideRecordingLabel {
    _labelRecording.hidden = !_labelRecording.hidden;
}

#endif

#pragma mark Timers callbacks

- (void)onTimerPanelHiddenFired:(NSTimer *)timer {
    [self showControlPanel:NO willExpire:YES];
}

- (void)onTimerElapsedFired:(NSTimer *)timer {
    [super onTimerElapsedFired:timer];
}

- (void)onTimerDurationFired:(NSTimer *)timer {
    
    if (_decoderState == kVKDecoderStatePlaying && !_slider.usesPanGestureRecognizer) {
        _durationCurrent = (_decodeManager) ? [_decodeManager currentTime] : 0.0;
        if (!isnan(_durationCurrent) && ((_durationTotal - _durationCurrent) > -1.0)) {
            _labelStreamCurrentTime.text = [NSString stringWithFormat:@"%02d:%02d", (int)_durationCurrent/60, ((int)_durationCurrent % 60)];
            _slider.value = _durationCurrent;
        }
    }
}


#pragma mark - Subview actions

- (void)showMenu {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Options"
                                                                   message:@"Select an action"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = nil;
    if (self.containerVc && ![self.containerVc isKindOfClass:[VKFullscreenContainer class]]) {
        UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"Close video" style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * action) {
                                                                [self stop];
                                                            }];
        [alert addAction:closeAction];
    } else {
        if (_fullScreen) {
            UIAlertAction *exitFullScreenAction = [UIAlertAction actionWithTitle:@"Exit Full Screen" style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action) {
                                                                             [self setFullScreen:NO];
                                                                         }];
            [alert addAction:exitFullScreenAction];
            
        } else {
            cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:NULL];
            [alert addAction:cancelAction];
        }
    }
    
    if (_readyToApplyPlayingActions) {
        NSString *muteTitle = _mute ? @"Unmute": @"Mute";
        UIAlertAction *muteAction = [UIAlertAction actionWithTitle:muteTitle style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [self setMute:!_mute];
                                                           }];
        [alert addAction:muteAction];
        
        NSString *zoomTitle = _renderView.contentMode == UIViewContentModeScaleAspectFit ? @"Zoom In" : @"Zoom Out";
        UIAlertAction *zoomAction = [UIAlertAction actionWithTitle:zoomTitle style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {
                                                               [self zoomInOut];
                                                           }];
        [alert addAction:zoomAction];
        
#ifdef VK_RECORDING_CAPABILITY
        if (![_decodeManager recordingNow]) {
            UIAlertAction *startRecordingAction = [UIAlertAction actionWithTitle:@"Start Recording" style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action) {
                                                                             [self startRecording];
                                                                         }];
            [alert addAction:startRecordingAction];
        } else {
            UIAlertAction *stopRecordingAction = [UIAlertAction actionWithTitle:@"Stop Recording" style:UIAlertActionStyleDefault
                                                                        handler:^(UIAlertAction * action) {
                                                                            [self stopRecording];
                                                                        }];
            [alert addAction:stopRecordingAction];
        }
#endif
        
    }
    
    NSString *infoTitle = _viewInfo.hidden ? @"Show Info View" : @"Hide Info View";
    UIAlertAction *infoAction = [UIAlertAction actionWithTitle:infoTitle style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           if(_viewInfo.hidden){
                                                               [self performSelector:@selector(showInfoView)];
                                                           } else {
                                                               _viewInfo.hidden=YES;
                                                           }
                                                       }];
    [alert addAction:infoAction];
    
    if(!cancelAction) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Close Menu" style:UIAlertActionStyleCancel handler:NULL];
        [alert addAction:cancelAction];
    }
    
    if (self.containerVc) {
        [self.containerVc  presentViewController:alert animated:YES completion:nil];
    } else {
        UIViewController *topVC = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
        while (topVC.presentedViewController) {
            topVC = topVC.presentedViewController;
        }
        [topVC presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showControlPanel:(BOOL)show willExpire:(BOOL)expire {
    
    if (_controlStyle == kVKPlayerControlStyleTVNone) {
        float alpha = 0.0;
        _viewBottomPanel.alpha = alpha;
        _viewTopPanel.alpha = alpha;
        
        return;
    }
    
    if (!show && [_slider usesPanGestureRecognizer]) {
        goto retry;
    }
    
    _panelIsHidden = !show;
    
    if (_timerPanelHidden && [_timerPanelHidden isValid]) {
        [_timerPanelHidden invalidate];
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         CGFloat alpha = _panelIsHidden ? 0 : 1;
                         
                         _viewBottomPanel.alpha = alpha;
                         _viewTopPanel.alpha = alpha;
                         
                     }
                     completion:^(BOOL finished) {
                         if (_panelIsHidden) {
                             [self focusOnSubview:NO];
                         }
                     }];
    
retry:
    if (!_panelIsHidden && expire) {
        [_timerPanelHidden release];
        _timerPanelHidden = nil;
        _timerPanelHidden = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(onTimerPanelHiddenFired:) userInfo:nil repeats:NO] retain];
    }
}


#pragma mark - VKDecoder delegate methods

- (void)decoderStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
    _decoderState = state;
    if (state == kVKDecoderStateConnecting) {
        _readyToApplyPlayingActions = NO;
        _imgViewAudioOnly.hidden = YES;
        _slider.value = 0.0;
        _labelTopTitle.text = TR(@"Loading...");
        [_activityIndicator startAnimating];
        [self showControlPanel:YES willExpire:NO];
        _snapshotReadyToGet = NO;
        VKLog(kVKLogLevelStateChanges, @"Trying to connect to %@", _contentURLString);
    } else if (state == kVKDecoderStateConnected) {
        VKLog(kVKLogLevelStateChanges, @"Connected to the stream server");
    } else if (state == kVKDecoderStateInitialLoading) {
        _readyToApplyPlayingActions = YES;
        VKLog(kVKLogLevelStateChanges, @"Trying to get packets");
    } else if (state == kVKDecoderStateReadyToPlay) {
        VKLog(kVKLogLevelStateChanges, @"Got enough packets to start playing");
        [_activityIndicator stopAnimating];
        _labelTopTitle.frame = _viewTopPanel.bounds;
        _labelTopTitle.text = [self barTitle];
    } else if (state == kVKDecoderStateBuffering) {
        VKLog(kVKLogLevelStateChanges, @"Buffering now...");
    } else if (state == kVKDecoderStatePlaying) {
        VKLog(kVKLogLevelStateChanges, @"Playing now...");
        [self showControlPanel:YES willExpire:YES];
        _snapshotReadyToGet = YES;
    } else if (state == kVKDecoderStatePaused) {
        VKLog(kVKLogLevelStateChanges, @"Paused now...");
    } else if (state == kVKDecoderStateGotStreamDuration) {
        if (errCode == kVKErrorNone) {
            _slider.hidden = NO;
            _labelStreamCurrentTime.hidden = NO;
            _labelStreamTotalDuration.hidden = NO;
            [self focusOnSubview:YES];
            
            _durationTotal = [_decodeManager durationInSeconds];
            VKLog(kVKLogLevelDecoder, @"Got stream duration: %f seconds", _durationTotal);
            _slider.maximumValue = _durationTotal;
            _labelStreamTotalDuration.text = [NSString stringWithFormat:@"%02d:%02d", (int)_durationTotal/60, ((int)_durationTotal % 60)];
            if (_initialPlaybackTime > 0.0 && _initialPlaybackTime < _durationTotal) {
                _durationCurrent = _initialPlaybackTime;
            }
            [self startDurationTimer];
        } else {
            VKLog(kVKLogLevelDecoder, @"Stream duration error -> %@", errorText(errCode));
        }
        [self updateBarWithDurationState:errCode];

    } else if (state == kVKDecoderStateGotAudioStreamInfo) {
        if (errCode != kVKErrorNone) {
            VKLog(kVKLogLevelStateChanges, @"Got audio stream error -> %@", errorText(errCode));
        }
    } else if (state == kVKDecoderStateGotVideoStreamInfo) {
        if (errCode != kVKErrorNone) {
            _imgViewAudioOnly.hidden = NO;
            VKLog(kVKLogLevelStateChanges, @"Got video stream error -> %@", errorText(errCode));
        }
    } else if (state == kVKDecoderStateConnectionFailed) {
        if (_controlStyle == kVKPlayerControlStyleTVDefault) {
            NSString *title = TR(@"Error: Stream can not be opened");
            NSString *body = errorText(errCode);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:body preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                                handler:^(UIAlertAction * action) {
                                                                    if (self.containerVc && ![self.containerVc isKindOfClass:[VKFullscreenContainer class]]) {
                                                                        [self stop];
                                                                    }
                                                                }];
            [alert addAction:closeAction];
            [self.containerVc presentViewController:alert animated:YES completion:nil];
        }
        
        _readyToApplyPlayingActions = NO;
        _labelTopTitle.text = TR(@"Connection error");
        [self stopElapsedTimer];
        [self stopDurationTimer];
        
        [_activityIndicator stopAnimating];
        [self updateBarWithDurationState:kVKErrorOpenStream];
        
        [self updateBarWithDurationState:kVKErrorOpenStream];
        VKLog(kVKLogLevelStateChanges, @"Connection error - %@",errorText(errCode));
    } else if (state == kVKDecoderStateStoppedByUser) {
        _readyToApplyPlayingActions = NO;
        [self stopElapsedTimer];
        [self stopDurationTimer];
        [self updateBarWithDurationState:kVKErrorStreamReadError];
        [_activityIndicator stopAnimating];
        VKLog(kVKLogLevelStateChanges, @"Stopped now...");
    } else if (state == kVKDecoderStateStoppedWithError) {
        _readyToApplyPlayingActions = NO;
        if (errCode == kVKErrorStreamReadError) {
            if (_controlStyle == kVKPlayerControlStyleTVDefault) {
                NSString *title = TR(@"Error: Read error");
                NSString *body = errorText(errCode);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:body preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *closeAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel
                                                                    handler:^(UIAlertAction * action) {
                                                                        if (self.containerVc && ![self.containerVc isKindOfClass:[VKFullscreenContainer class]]) {
                                                                            [self stop];
                                                                        }
                                                                    }];
                [alert addAction:closeAction];
                [self.containerVc presentViewController:alert animated:YES completion:nil];
            }
            _labelTopTitle.text = TR(@"Error: Read error");
            VKLog(kVKLogLevelStateChanges, @"Player stopped - %@",errorText(errCode));
        } else if (errCode == kVKErrorStreamEOFError) {
            VKLog(kVKLogLevelStateChanges, @"%@, stopped now...", errorText(errCode));
        }
        [self stopElapsedTimer];
        [self stopDurationTimer];
        
        [_activityIndicator stopAnimating];
        [self updateBarWithDurationState:errCode];
        
    }
    if(_delegate && [_delegate respondsToSelector:@selector(player:didChangeState:errorCode:)]) {
        [_delegate player:self didChangeState:state errorCode:errCode];
    }
}

#pragma mark - Gesture Recognizers handling

- (void)homeButtonTapped:(UITapGestureRecognizer *)recognizer {
    NSLog(@"homeButtonTapped");
    [self showMenu];
}

- (void)pauseButtonTapped:(UITapGestureRecognizer *)recognizer {
    [self togglePause];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    
    if (recognizer.numberOfTapsRequired == 1) {
        BOOL updateFocus = NO;
        if ([_view isFocused]) {
            [self showControlPanel:YES willExpire:YES];
            updateFocus = YES;
        } else {
            [self showControlPanel:_panelIsHidden willExpire:YES];
            if (!_panelIsHidden) {
                updateFocus = YES;
            }
        }
        
        if (updateFocus) {
            [self focusOnSubview:YES];
        }
    } else {
        [self setFullScreen:!_fullScreen];
    }
}

#pragma mark - External Screen Management (Cable & Airplay)

- (void)screenDidChange:(NSNotification *)notification {
    //no airplay feature
}

#pragma mark - Memory events & deallocation

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeAppleTVRemoteControllerGestures];
    
#ifdef VK_RECORDING_CAPABILITY
    [_labelRecording release];
#endif
    [_viewInfo release];
    [_slider setDelegate:nil];
    [_slider release];
    
    [super dealloc];
}

@end
