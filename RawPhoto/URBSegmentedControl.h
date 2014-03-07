/* MIT LICENSE - 

Copyright (c) 2012 Nicholas Shipes, Urban10 Interactive and other contributors.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/
//
//  URBSegmentedControl.h
//  URBSegmentedControlDemo
//
//  Created by Nicholas Shipes on 2/1/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
	URBSegmentedControlOrientationHorizontal = 0,
	URBSegmentedControlOrientationVertical
};
typedef NSInteger URBSegmentedControlOrientation;

enum {
	URBSegmentViewLayoutDefault = 0,
	URBSegmentViewLayoutVertical
};
typedef NSInteger URBSegmentViewLayout;

@interface URBSegmentedControl : UISegmentedControl <UIAppearance>

typedef void (^URBSegmentedControlBlock)(NSInteger index, URBSegmentedControl *segmentedControl);

/**
 Layout behavior for the segments (row or columns).
 */
@property (nonatomic) URBSegmentedControlOrientation layoutOrientation;

/**
 Layout behavior of the segment contents.
 */
@property (nonatomic) URBSegmentViewLayout segmentViewLayout;

/**
 Block handle called when the selected segment has changed.
 */
@property (nonatomic, copy) URBSegmentedControlBlock controlEventBlock;

/**
 Background color for the base container view.
 */
@property (nonatomic, strong) UIColor *baseColor;

/**
 Stroke color used around the base container view.
 */
@property (nonatomic, strong) UIColor *strokeColor;

/**
 Stroke width for the base container view.
 */
@property (nonatomic, assign) CGFloat strokeWidth;

/**
 Corner radius for the base container view.
 */
@property (nonatomic) CGFloat cornerRadius;

/**
 Whether or not a gradient should be automatically applied to the base and segment backgrounds based on the defined base colors.
 */
@property (nonatomic, assign) BOOL showsGradient;

/**
 Padding between the segments and the base container view.
 */
@property (nonatomic, assign) UIEdgeInsets segmentEdgeInsets;

///----------------------------
/// @name Segment Customization
///----------------------------

@property (nonatomic, strong) UIColor *segmentBackgroundColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *imageColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *selectedImageColor UI_APPEARANCE_SELECTOR;

@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;
@property (nonatomic, assign) UIEdgeInsets titleEdgeInsets;
@property (nonatomic, assign) UIEdgeInsets imageEdgeInsets;

- (id)initWithTitles:(NSArray *)titles;
- (id)initWithIcons:(NSArray *)icons;
- (id)initWithTitles:(NSArray *)titles icons:(NSArray *)icons;
- (void)insertSegmentWithTitle:(NSString *)title image:(UIImage *)image atIndex:(NSUInteger)segment animated:(BOOL)animated;
- (void)setSegmentBackgroundColor:(UIColor *)segmentBackgroundColor atIndex:(NSUInteger)segment;

- (void)setTextAttributes:(NSDictionary *)textAttributes forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void)setImageColor:(UIColor *)imageColor forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (void)setSegmentBackgroundColor:(UIColor *)segmentBackgroundColor UI_APPEARANCE_SELECTOR;

- (void)setControlEventBlock:(URBSegmentedControlBlock)controlEventBlock;

@end

@interface UIImage (URBSegmentedControl)

- (UIImage *)imageTintedWithColor:(UIColor *)color;

@end
