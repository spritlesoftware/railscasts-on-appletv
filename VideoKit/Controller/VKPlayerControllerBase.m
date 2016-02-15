//
//  VKPlayerControllerBase.m
//  VideoKitSample
//
//  Created by Murat Sudan on 19/09/15.
//  Copyright © 2015 iosvideokit. All rights reserved.
//

//
//  VKPlayerControllerBase.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#if __has_feature(objc_arc)
#error iOS VideoKit is Non-ARC only. Either turn off ARC for the project or use -fobjc-no-arc flag on source files (Targets -> Build Phases -> Compile Sources)
#endif

#import "VKPlayerControllerBase.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - VKPlayerController


#import "VKGLES2View.h"
#import "VKStreamInfoView.h"

#import <MediaPlayer/MediaPlayer.h>

//Global vars
NSInteger activePlayerCount = 0;

@implementation VKFullscreenContainer

- (id)initWithPlayerController:(VKPlayerControllerBase *)player windowRect:(CGRect)rect {
    self = [super init];
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        _playerController = [player retain];
        _rectBefore = [player.view frame];
        _rectWin = rect;
        _superviewBefore = [[player.view superview] retain];
        _autoresizingMaskBefore = [player.view autoresizingMask];
    }
    return self;
}

#pragma mark - View Life Cycle

- (void) loadView {
    CGRect bounds = [[UIScreen mainScreen] bounds];
#if !TARGET_OS_TV
    if (UIInterfaceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        bounds =  CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
    }
#endif
    self.view = [[[UIView alloc] initWithFrame:bounds] autorelease];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Private Methods

- (BOOL)prefersStatusBarHidden {
    return [_playerController isStatusBarHidden];
}

- (void)onDismissWithAnimated:(BOOL)animated {
    float duration = (animated) ? 0.5 : 0.0;
    
    UIWindow *keyWindow = [[[UIApplication sharedApplication] windows] lastObject];
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending) {
        //running on iOS 7.x
        [[[keyWindow subviews] objectAtIndex:0] addSubview:_playerController.view];
        
        [UIView animateWithDuration:duration animations:^{
            _playerController.view.frame = _rectWin;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:NO completion:^{
                [_superviewBefore addSubview:_playerController.view];
                _playerController.view.frame = _rectBefore;
                _playerController.view.autoresizingMask = _autoresizingMaskBefore;
            }];
        }];
        
    } else {
        [keyWindow addSubview:_playerController.view];
        
        CGRect bounds = [[UIScreen mainScreen] bounds];
        _playerController.view.frame = bounds;
        
        [self dismissViewControllerAnimated:NO completion:^{
            [UIView animateWithDuration:duration animations:^{
                _playerController.view.frame = _rectWin;
            } completion:^(BOOL finished) {
                [_superviewBefore addSubview:_playerController.view];
                _playerController.view.frame = _rectBefore;
                _playerController.view.autoresizingMask = _autoresizingMaskBefore;
            }];
        }];
    }
}

#pragma mark - Orientation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Toolbar position delegate

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

- (void)dealloc {
    [_superviewBefore release];
    [_playerController release];
    [super dealloc];
}

@end

/* VKPlayer Fullscreen mode changed notifications */
NSString *kVKPlayerWillEnterFullscreenNotification = @"VKPlayerWillEnterFullscreenNotification";
NSString *kVKPlayerDidEnterFullscreenNotification = @"VKPlayerDidEnterFullscreenNotification";
NSString *kVKPlayerWillExitFullscreenNotification = @"VKPlayerWillExitFullscreenNotification";
NSString *kVKPlayerDidExitFullscreenNotification = @"VKPlayerDidExitFullscreenNotification";


@interface VKPlayerControllerBase ()<VKDecoderDelegate> {
    
}

@property (nonatomic, retain) UIWindow *extWindow;
@property (nonatomic, retain) UIScreen *extScreen;

@end

@implementation VKPlayerControllerBase

@synthesize barTitle = _barTitle;
@synthesize containerVc = _containerVc;
@synthesize decoderState = _decoderState;
@synthesize contentURLString = _contentURLString;
@synthesize decoderOptions = _decodeOptions;
@synthesize fullScreen = _fullScreen;
@synthesize initialPlaybackTime = _initialPlaybackTime;
@synthesize loopPlayback = _loopPlayback;
@synthesize autoStopAtEnd = _autoStopAtEnd;
@synthesize allowsAirPlay = _allowsAirPlay;
@synthesize showPictureOnInitialBuffering = _showPictureOnInitialBuffering;
@synthesize delegate = _delegate;
@synthesize renderView = _renderView;
@synthesize backgroundColor = _backgroundColor;
#ifdef VK_RECORDING_CAPABILITY
@synthesize recordingEnabled = _recordingEnabled;
#endif
@synthesize username = _username;
@synthesize secret = _secret;

#pragma mark Initialization

- (id)initBase {
    self = [super init];
    if (self) {
        // Custom initialization
        
        _fullScreen = NO;
        _initialPlaybackTime = 0.0;
        _loopPlayback = 1;
        _allowsAirPlay = NO;
        _showPictureOnInitialBuffering = NO;
        _readyToApplyPlayingActions = NO;
        
        _playStopQueue = dispatch_queue_create("play_stop_lock", NULL);
        
        _snapshotReadyToGet = NO;
        
#ifdef VK_RECORDING_CAPABILITY
        _recordingEnabled = NO;
#endif
        self.username = @"";
        self.secret = @"";
        
        _volumeLevel = 1.0;
        _mute = NO;
        _audioSessionActive = NO;
        
        _backgroundColor = [[UIColor blackColor] retain];
        
        return self;
    }
    return nil;
}

- (id)initWithURLString:(NSString *)urlString {
    
    self = [self initBase];
    if (self) {
        // Custom initialization
        [self setContentURLString:urlString];
        return self;
    }
    return nil;
}

- (void)setContentURLString:(NSString *)urlString {
    _decoderState = kVKDecoderStateNone;
    if(!urlString) urlString = @"http://url.is.null";
    
    if (_contentURLString) {
        [_contentURLString release];
        _contentURLString = nil;
    }
    _contentURLString = [urlString retain];
    
    if ([urlString lastPathComponent])
        _streamName = [[urlString lastPathComponent] retain];
}

- (NSString *)barTitle {
    if (_barTitle) {
        return _barTitle;
    } else if (_streamName) {
        return _streamName;
    }
    return @"";
}

#pragma mark Subviews management

- (void)createUICenter {
    /* Center subviews: _imgViewAudioOnly */
    int hAudioOnly = 156.0/2.0;
    int wAudioOnly = 185.0/2.0;
    int yAudioOnly = (self.view.bounds.size.height - hAudioOnly)/2.0;
    int xAudioOnly = (self.view.bounds.size.width - wAudioOnly)/2.0;
    _imgViewAudioOnly = [[UIImageView alloc] initWithFrame:CGRectMake(xAudioOnly, yAudioOnly, wAudioOnly, hAudioOnly)];
    _imgViewAudioOnly.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin| UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _imgViewAudioOnly.contentMode = UIViewContentModeScaleAspectFit;
    _imgViewAudioOnly.hidden = YES;
    _imgViewAudioOnly.opaque = NO;
    [self.view addSubview:_imgViewAudioOnly];
    
    int hViewInfo = 230.0;
    int hViewInfoMargin = 10.0;
    int wViewInfo = 280.0;
    int yViewInfo = (self.view.bounds.size.height - hViewInfo)/2.0 - hViewInfoMargin;
    int xViewInfo = (self.view.bounds.size.width - wViewInfo)/2.0;
    _viewInfo = [[VKStreamInfoView alloc] initWithFrame:CGRectMake(xViewInfo, yViewInfo, wViewInfo, hViewInfo)];
    _viewInfo.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _viewInfo.contentMode = UIViewContentModeCenter;
    _viewInfo.hidden = YES;
    [self addGesturesToInfoView:_viewInfo];
    [self.view addSubview:_viewInfo];
    
    /* set the images */
    _imgViewAudioOnly.image = [UIImage imageNamed:@"VKImages.bundle/vk-audio-only.png"];
}

- (void)updateBarWithDurationState:(VKError) state {
    // implemented in sublass
}

- (void)addScreenControlGesturesToView:(UIView *)viewGesture {
    // implemented in sublass
}

- (void)useContainerViewControllerAnimated:(BOOL)animated {
    // implemented in sublass
}

- (void)removeScreenControlGesturesFromView:(UIView *)viewGesture {
    // implemented in sublass
}

- (void)addGesturesToInfoView:(UIView *)viewGesture {
    // implemented in sublass
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (_backgroundColor) {
        [_backgroundColor release];
        _backgroundColor = nil;
    }
    _backgroundColor = [backgroundColor retain];
    self.view.backgroundColor = _backgroundColor;
    if (_renderView) {
        _renderView.backgroundColor = _backgroundColor;
    }
}

#ifdef VK_RECORDING_CAPABILITY
- (void)setRecordingEnabled:(BOOL)recordingEnabled {
    _recordingEnabled = recordingEnabled;
}
#endif

#pragma mark Subview & timer actions

- (void)showControlPanel:(BOOL)show willExpire:(BOOL)expire {
    
}

- (void)startElapsedTimer {
    [self stopElapsedTimer];
    _timerElapsedTime = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimerElapsedFired:) userInfo:nil repeats:YES] retain];
}

- (void)stopElapsedTimer {
    if (_timerElapsedTime && [_timerElapsedTime isValid]) {
        [_timerElapsedTime invalidate];
    }
    [_timerElapsedTime release];
    _timerElapsedTime = nil;
}

- (void)startDurationTimer {
    [self stopDurationTimer];
    _timerDuration = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(onTimerDurationFired:) userInfo:nil repeats:YES] retain];
}

- (void)stopDurationTimer {
    if (_timerDuration && [_timerDuration isValid]) {
        [_timerDuration invalidate];
    }
    [_timerDuration release];
    _timerDuration = nil;
}

- (void)showInfoView {
    if (_viewInfo && _viewInfo.hidden) {
        _viewInfo.alpha = 0.0;
        _viewInfo.hidden = NO;
        
        NSMutableDictionary *streamInfo = [_decodeManager streamInfo];
        NSNumber *downloadedData = [NSNumber numberWithUnsignedLong:_decodeManager.totalBytesDownloaded];
        [streamInfo setObject:downloadedData forKey:STREAMINFO_KEY_DOWNLOAD];
        [_viewInfo updateSubviewsWithInfo:streamInfo];
        
        [UIView animateWithDuration:0.4 animations:^{
            _viewInfo.alpha = 1.0;
        }];
        
        if (_timerInfoViewUpdate && [_timerInfoViewUpdate isValid]) {
            [_timerInfoViewUpdate invalidate];
        }
        [_timerInfoViewUpdate release];
        _timerInfoViewUpdate = nil;
        
        _timerInfoViewUpdate = [[NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(updateStreamInfoView) userInfo:nil repeats:YES] retain];
    }
}

- (void)hideInfoView {
    if (_viewInfo && !_viewInfo.hidden) {
        [UIView animateWithDuration:0.4 animations:^{
            _viewInfo.alpha = 0.0;
        } completion:^(BOOL finished) {
            _viewInfo.hidden = YES;
        }];
        if (_timerInfoViewUpdate && [_timerInfoViewUpdate isValid]) {
            [_timerInfoViewUpdate invalidate];
        }
        [_timerInfoViewUpdate release];
        _timerInfoViewUpdate = nil;
    }
}

- (void)updateStreamInfoView {
    NSMutableDictionary *streamInfo = [_decodeManager streamInfo];
    NSNumber *downloadedData = [NSNumber numberWithUnsignedLong:_decodeManager.totalBytesDownloaded];
    [streamInfo setObject:downloadedData forKey:STREAMINFO_KEY_DOWNLOAD];
    [_viewInfo updateSubviewsWithInfo:streamInfo];
}

#pragma mark Timers callbacks

- (void)onTimerElapsedFired:(NSTimer *)timer {
    _elapsedTime = _elapsedTime + 1;
}

- (void)onTimerDurationFired:(NSTimer *)timer {
    
}

#pragma mark - Public Player instant action methods

- (void)play {
    
    VKLog(kVKLogLevelStateChanges, @"player->play()");
    [self stop];
    
    dispatch_async(_playStopQueue, ^(void) {
        VKLog(kVKLogLevelUIControlExtra, @"dispatch_async - play()");
        
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        _elapsedTime = 0;
        _durationCurrent = 0.0;
        _durationTotal = 0.0;
        _sliderDurationCurrentTouched = NO;
        _mainScreenIsMobile = YES;
        
        /* Create decoder with parameters */
        _decodeManager = [[VKAVDecodeManager alloc] initWithUsername:_username secret:_secret];
        if (_decodeManager) {
            _decodeManager.initialPlaybackTime = _initialPlaybackTime;
            _decodeManager.autoStopAtEnd = _autoStopAtEnd;
            _decodeManager.loopPlayback = _loopPlayback;
            _decodeManager.showPicOnInitialBuffering = _showPictureOnInitialBuffering;
            _decodeManager.volumeLevel = _volumeLevel;
            if (_mute)
                _decodeManager.volumeLevel = 0.0;
            _decodeManager.delegate = self;
            
            //extra parameters
            _decodeManager.avPacketCountLogFrequency = 0.01;
            [_decodeManager setLogLevel:kVKLogLevelStateChanges];
            
            VKError error = [_decodeManager connectWithStreamURLString:_contentURLString options:_decodeOptions];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                if (error == kVKErrorNone) {
                    //create glview to render video pictures
                    _renderView = [[VKGLES2View alloc] initWithFrame:self.view.bounds];
                    _renderView.backgroundColor = _backgroundColor;
                    if ([_renderView initGLWithDecodeManager:_decodeManager] == kVKErrorNone) {
                        
                        [self.view insertSubview:_renderView atIndex:0];
                        [self addScreenControlGesturesToView:_renderView];
                        
                        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
                        
                        NSError *error;
                        if(![audioSession setCategory:AVAudioSessionCategoryPlayback error:&error]) {
                            VKLog(kVKLogLevelDecoder, @"Error: Audio Session category could not be set: %@", error.localizedDescription);
                        }
                        
                        NSTimeInterval preferredBufferDuration = .005;
                        if (![audioSession setPreferredIOBufferDuration: preferredBufferDuration error: &error]) {
                            VKLog(kVKLogLevelDecoder, @"Error: Audio Session prefered buffer duration could not be set: %@", error.localizedDescription);
                        }
                        
                        _audioSessionActive = [audioSession setActive:YES error:&error];
                        if(_audioSessionActive) {
                            activePlayerCount++;
                        } else {
                            VKLog(kVKLogLevelDecoder, @"Error: Audio Session could not be activated: %@", error.localizedDescription);
                        }
                        
                        //readPackets and start decoding
                        [_decodeManager startToReadAndDecode];
                        
                        [self screenDidChange:nil];
                        // Register for screen connect and disconnect notifications.
                        [[NSNotificationCenter defaultCenter] addObserver:self
                                                                 selector:@selector(screenDidChange:)
                                                                     name:UIScreenDidConnectNotification
                                                                   object:nil];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self
                                                                 selector:@selector(screenDidChange:)
                                                                     name:UIScreenDidDisconnectNotification
                                                                   object:nil];
                    } else
                        VKLog(kVKLogLevelStateChanges, @"Render view can not be initialized");
                } else
                    VKLog(kVKLogLevelStateChanges, @"Decoder can not be initialized");
            });
            
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^{
                VKLog(kVKLogLevelStateChanges, @"Decoder can not be allocated");
            });
        }
    });
}

- (void)togglePause {
    [_decodeManager performSelector:@selector(togglePause)];
}

- (void)stop {
    
    VKLog(kVKLogLevelStateChanges, @"player->stop()");
    
    [self stopElapsedTimer];
    [self stopDurationTimer];
    
#ifdef FIX_FOR_RTSP_TEARDOWN_MESSAGE
    [_decodeManager sendRTSPCloseMessage];
#endif
    
    [_decodeManager abort];
    
    dispatch_async(_playStopQueue, ^(void) {
        VKLog(kVKLogLevelUIControlExtra, @"dispatch_async - stop()");
        
        if (_decodeManager) {
            [_decodeManager stop];
            
            if (_audioSessionActive) {
                _audioSessionActive = NO;
                activePlayerCount--;
            }
            
            if (!activePlayerCount) {
                NSError *error;
                BOOL err = [[AVAudioSession sharedInstance] setActive:NO error:&error];
                if (!err) VKLog(kVKLogLevelDecoder, @"AudioSession error: %@, code: %ld", error.domain, (long)error.code);
            }
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                [[NSNotificationCenter defaultCenter] removeObserver:self];
                
                [self removeScreenControlGesturesFromView:_renderView];
                [self removeScreenControlGesturesFromView:_viewInfo];
                
                if (_renderView) {
                    [_renderView shutdown];
                    if ([_renderView superview]) {
                        [_renderView removeFromSuperview];
                    }
                    [_renderView  release];
                    _renderView = nil;
                }
                
                _decodeManager.delegate = nil;
                [_decodeManager release];
                _decodeManager = nil;
                
                if (_containerVc && ([NSStringFromClass([_containerVc class]) isEqualToString:@"VKPlayerViewController"])) {
                    UIViewController *presentedFromContainerVC = _containerVc.presentedViewController;
                    if(presentedFromContainerVC && [presentedFromContainerVC isKindOfClass:[UIAlertController class]]) {
                        [presentedFromContainerVC dismissViewControllerAnimated:NO completion:^{
                            [_containerVc dismissViewControllerAnimated:YES completion:NULL];
                        }];
                    } else {
                        [_containerVc dismissViewControllerAnimated:YES completion:NULL];
                    }
                }
            });
        }
    });
}

- (void)stepToNextFrame {
    [_decodeManager stepToNextFrame];
}

- (void)setStreamCurrentDuration:(float)value  {
    [_decodeManager doSeek:value];
}

- (void)changeAudioStream {
    [_decodeManager cycleAudioStream];
}

- (void)setMute:(BOOL)value {
    _mute = value;
    if (_mute)
        [_decodeManager setVolumeLevel:0.0];
    else
        [_decodeManager setVolumeLevel:_volumeLevel];
}

- (void)setVolumeLevel:(float)value {
    _volumeLevel = value;
    [_decodeManager setVolumeLevel:value];
}

- (NSArray *)playableAudioStreams {
    return [_decodeManager playableAudioStreams];
}

- (NSArray *)playableVideoStreams {
    return [_decodeManager playableVideoStreams];
}

- (UIImage *)snapshot {
    if (!_snapshotReadyToGet) {
        return nil;
    }
    return [_renderView snapshot];
}

#ifdef VK_RECORDING_CAPABILITY
- (void)startRecording {
    if (_decodeManager) {
        [_decodeManager startRecording];
    }
}

- (void)stopRecording {
    if (_decodeManager) {
        [_decodeManager stopRecording];
    }
}
#endif

#pragma mark - Public Player state change methods

- (void)setInitialPlaybackTime:(int64_t)initialPlaybackTime {
    _initialPlaybackTime = initialPlaybackTime;
    if (_decodeManager)
        [_decodeManager setInitialPlaybackTime:_initialPlaybackTime];
}

- (void)setLoopPlayback:(int)loopPlayback {
    _loopPlayback = loopPlayback;
    if (_decodeManager)
        [_decodeManager setLoopPlayback:_loopPlayback];
}

- (void)setAutoStopAtEnd:(BOOL)autoStopAtEnd {
    _autoStopAtEnd = autoStopAtEnd;
    if (_decodeManager)
        [_decodeManager setAutoStopAtEnd:_autoStopAtEnd];
}

#pragma mark Public Player UI methods

- (void)zoomInOut {
    if (_renderView.contentMode == UIViewContentModeScaleAspectFit){
        _renderView.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        _renderView.contentMode = UIViewContentModeScaleAspectFit;
    }
}

- (void)setFullScreen:(BOOL)value {
    [self setFullScreen:value animated:YES];
}

- (void)setFullScreen:(BOOL)value animated:(BOOL)animated {
    // implemented in sublass
}

#pragma mark - VKDecoder delegate methods

- (void)decoderStateChanged:(VKDecoderState)state errorCode:(VKError)errCode {
    // implemented in sublass
}

#pragma mark - External Screen Management (Cable & Airplay)

- (void)screenDidChange:(NSNotification *)notification {
    // implemented in sublass
}

#pragma mark - AudioSession interruption

#pragma mark iOS 5.x Audio interruption handling

- (void)beginInterruption {
    if (_decodeManager) {
        [_decodeManager beginInterruption];
    }
}

- (void)endInterruptionWithFlags:(NSUInteger)flags {
    // re-activate audio session after interruption
    if (_decodeManager) {
        [_decodeManager endInterruptionWithFlags:flags];
    }
}

#pragma mark iOS 6.x or higher Audio interruption handling

- (void) interruption:(NSNotification*)notification
{
    if (_decodeManager) {
        [_decodeManager interruption:notification];
    }
}

#pragma mark - Memory events & deallocation

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_barTitle release];
    [_decodeOptions release];
    
    [_singleTapGestureRecognizer release];
    [_doubleTapGestureRecognizer release];
    [_closeInfoViewGestureRecognizer release];
    
    [_backgroundColor release];
    [_renderView release];

    [_view release];
    [_contentURLString release];
    VKLog(kVKLogLevelStateChanges, @"VKPlayerController is deallocated - no more state changes captured...");
    
    [super dealloc];
}

@end

#pragma mark - Error descriptions


NSString * errorText(VKError errCode)
{
    switch (errCode) {
        case kVKErrorNone:
            return @"";
            
        case kVKErrorUnsupportedProtocol:
            return TR(@"Protocol is not supported");
            
        case kVKErrorStreamURLParseError:
            return TR(@"Stream url or params can not be parsed");
            
        case kVKErrorOpenStream:
            return TR(@"Failed to connect to the stream server");
            
        case kVKErrorStreamInfoNotFound:
            return TR(@"Can not find any stream info");
            
        case kVKErrorStreamsNotAvailable:
            return TR(@"Can not open any A-V stream");
            
        case kVKErrorAudioCodecNotFound:
            return TR(@"Audio codec is not found");
            
        case kVKErrorStreamDurationNotFound:
            return TR(@"Stream duration is not found");
            
        case kVKErrorAudioStreamNotFound:
            return TR(@"Audio stream is not found");
            
        case kVKErrorVideoCodecNotFound:
            return TR(@"Video codec is not found");
            
        case kVKErrorVideoStreamNotFound:
            return TR(@"Video stream is not found");
            
        case kVKErrorAudioCodecNotOpened:
            return TR(@"Audio codec can not be opened");
            
        case kVKErrorVideoCodecNotOpened:
            return TR(@"Video codec can not be opened");
            
        case kVKErrorAudioAllocateMemory:
            return TR(@"Can not allocate memory for Audio");
            
        case kVKErrorVideoAllocateMemory:
            return TR(@"Can not allocate memory for Video");
            
        case kVKErrorUnsupportedAudioFormat:
            return TR(@"Audio format is not supported");
            
        case kVKErrorAudioStreamAlreadyOpened:
            return TR(@"Audio is already opened, close the current first, then open again");
            
        case kVKErroSetupScaler:
            return TR(@"Unable to setup scaler");
            
        case kVKErrorStreamReadError:
            return TR(@"Can not read from stream server");
            
        case kVKErrorStreamEOFError:
            return TR(@"End of stream");
    }
    return nil;
}
