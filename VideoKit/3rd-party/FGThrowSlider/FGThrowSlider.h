//
//  FGThrowSlider.h
//  Throw Slider Control Demo
//
//  Created by Finn Gaida on 15.02.14.
//  Copyright (c) 2014 Finn Gaida. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FGThrowSlider;
@protocol FGThrowSliderDelegate

- (void)slider:(FGThrowSlider *)slider changedValue:(CGFloat)value;
- (void)slider:(FGThrowSlider *)slider endValue:(CGFloat)value;

@end

@interface FGThrowSlider : UIControl

+ (FGThrowSlider *)sliderWithFrame:(CGRect)frame andDelegate:(id <FGThrowSliderDelegate>)del;

- (instancetype)initWithFrame:(CGRect)frame andDelegate:(id <FGThrowSliderDelegate>)del;

@property (nonatomic,assign) BOOL usesPanGestureRecognizer;
@property (nonatomic,assign) CGFloat value;
@property (nonatomic,assign) CGFloat maximumValue;
@property (nonatomic,retain) id <FGThrowSliderDelegate> delegate;

@end
