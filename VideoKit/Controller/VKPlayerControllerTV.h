//
//  VKPlayerViewControllerTV.m
//  VideoKitSample
//
//  Created by Murat Sudan on 23/09/15.
//  Copyright © 2015 iosvideokit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKPlayerControllerBase.h"
#import "FGThrowSlider.h"

/**
 * Determines the User interface of control elements on screen
 *
 * VKPlayerControlStyleTV enums are
 * - kVKPlayerControlStyleNone        > Shows only Video screen, no bar, no panel, no any user interface component
 * - kVKPlayerControlStyleDefault     > Shows User interface elements on screen according to view size
 */
typedef enum {
    kVKPlayerControlStyleTVNone,
    kVKPlayerControlStyleTVDefault,
} VKPlayerControlStyleTV;

@interface VKPlayerControllerTV : VKPlayerControllerBase<FGThrowSliderDelegate,UIGestureRecognizerDelegate>

- (id)init;

/**
 *  Initialization of VKPlayerControllerBase object with the url string object
 *
 *  @param urlString The location of the file or remote stream url. If it's a file then it must be located either in your app directory or on a remote server
 *
 *  @return VKPlayerControllerBase object
 */
- (id)initWithURLString:(NSString *)urlString;

/**
 *  A focus management method to switch focus between player's view and slider
 *
 *  @param focusOnSubview If value is set to YES, then slider of player's view has the focus if slider is not hidden otherwise player's view has the focus
 *
 */
- (void)focusOnSubview:(BOOL)focusOnSubview;

///Determines the User interface of control elements on screen
@property (nonatomic, assign) VKPlayerControlStyleTV controlStyle;

@end