//
//  LBSegmentedButton.m
//  LamojiPreferences
//
//  Created by Laurin Brandner on 01.06.11.
//  Copyright 2011 Larcus. All rights reserved.
//
//  RT @Larcus94: "use it where ever you want!" (closed source, commercial ok)

#import "LBSegmentedButton.h"


#define cellHeightDEFAULT 20.f
#define radiusDEFAULT 10.f


#define shadowColor [UIColor colorWithRed:251.0/255.0 green:251./255.0 blue:251./255.0 alpha:0.4]
#define lightTextColor [UIColor colorWithRed:186.0/255.0 green:168.0/255.0 blue:168.0/255.0 alpha:1.0]
#define darkTextColor [UIColor colorWithRed:12.0/255.0 green:12.0/255.0 blue:12.0/255.0 alpha:1.0]
#define highlightColor [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:147.0/255.0 alpha:0.65]

#define borderColorDEFAULT [UIColor colorWithRed:244./255.0 green:244.0/255.0 blue:244.0/255.0 alpha:0.6]

#define gradientColor1 [UIColor colorWithRed:220.0/255.0 green:220.0/255.0 blue:220.0/255.0 alpha:0.6]
#define gradientColor2 [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:0.6]

NSInteger previouslySelectedSegment = -1;

@implementation LBSegmentedButton

@synthesize borderColor, target;

#pragma mark Accessors

-(NSInteger)selectedSegment {
	return selectedSegment;
}

-(void)setSelectedSegment:(NSInteger)value {
	if (selectedSegment != value) {
		selectedSegment = value;
		[self setNeedsDisplay];
	}
}

-(NSDictionary*)data {
	return data;
}

-(void)setData:(NSDictionary *)value {
	if (![data isEqualToDictionary:value]) {
		data = [value copy];
		[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, data.count * (self.cellHeight+2))];
		[self setNeedsDisplay];
	}
}

-(NSInteger)numberOfCells {
	if (self.data) {
		return [self.data count];
	}
	return 0;
}

#pragma mark -
#pragma mark Initialization

-(id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self commonInit];
	}
	return self;
}

-(id)initWithFrame:(CGRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		[self commonInit];
	}
	return self;
}

-(id)initWithFrame:(CGRect)frameRect titles:(NSArray*)titles selectors:(NSArray*)selectorsAsStrings target:(id)init_target {
	self = [super initWithFrame:frameRect];
	if (self) {
		[self commonInit];
		self.target = init_target;
		[self setData:[NSDictionary dictionaryWithObjects:selectorsAsStrings forKeys:titles]];
	}
	return self;
}


-(void) commonInit {
	self.data = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"buttonClicked:", @"buttonClicked:", @"buttonClicked:", nil] forKeys:[NSArray arrayWithObjects:@"!", @"YOURSELF", @"CHECK", nil]];
	self.target = nil;
	
	self.selectedSegment = -1;
	
	//set default drawing info
	self.borderColor = borderColorDEFAULT;
	self.cellHeight = cellHeightDEFAULT;
	self.radius = radiusDEFAULT;
	
	if (self.frame.size.height != [self numberOfCells] * (self.cellHeight + 2) + 1) {
		long properHeight = [self numberOfCells] * (self.cellHeight + 2) + 1;
		NSLog(@"The height doesn't match to the cellHeight. The proper height would be %ld", properHeight);
	}
[self setBackgroundColor:[UIColor clearColor]];
}

#pragma mark -
#pragma mark Memory

-(void)dealloc {
	self.borderColor = nil;
	self.data = nil;
	self.target = nil;
}

#pragma mark -
#pragma mark Drawing

-(void)drawTitleWithIndex:(NSInteger)i {
	UILabel *label = (UILabel*) [self viewWithTag:i+1];
	if (!label) {
		CGFloat centerDistance = 0; //self.cellHeight/2.;
		CGFloat borders = (i+1)*2;
		label = [[UILabel alloc] initWithFrame:CGRectMake(0, borders + centerDistance + i * self.cellHeight, self.bounds.size.width, self.cellHeight)];
		[label setTextAlignment:NSTextAlignmentCenter];
		[label setTextColor:darkTextColor];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setTag:i+1];
		[self addSubview:label];
	}
	[(UILabel*)[self viewWithTag:i+1] setText:[self.data.allKeys objectAtIndex:i]];
}

-(NSString*)selectedValue {
	return [self.data.allKeys objectAtIndex:selectedSegment];
}

-(void)drawCellInRect:(CGRect)rect index:(NSInteger)index {
	CGContextRef context=UIGraphicsGetCurrentContext();
	CGFloat maxX = CGRectGetMaxX(rect);
	CGFloat minX = CGRectGetMinX(rect);
	CGFloat minY = CGRectGetMinY(rect);
	if (self.selectedSegment != -1) {
		if (self.numberOfCells == 1) {
			[highlightColor setFill];
			CGRect boxRect = rect;
			boxRect.size.height -=2;
			boxRect.origin.y += 2;
			UIBezierPath* box = [UIBezierPath bezierPathWithRoundedRect:boxRect cornerRadius:self.radius];
			[box fill];
		} else {
			if (self.selectedSegment == index) {
				[highlightColor setFill];
				if (self.selectedSegment != 0 && self.selectedSegment != self.numberOfCells-1) {
					CGContextFillRect(context, rect);
				} else if (self.selectedSegment == 0) {
					minY += 2;
					
					//bottom
					
					CGMutablePathRef box = CGPathCreateMutable();
					
					CGPathMoveToPoint(box, NULL, minX, self.cellHeight+3);
					CGPathAddLineToPoint(box, NULL, minX, minY+self.radius);
					CGPathAddQuadCurveToPoint(box, NULL, minX, minY, minX+self.radius , minY); //90degrees curve (left bottom)
					CGPathAddLineToPoint(box, NULL, maxX-self.radius, minY);
					CGPathAddQuadCurveToPoint(box, NULL, maxX, minY, maxX, minY+self.radius); //90degrees curve (right bottom)
					CGPathAddLineToPoint(box, NULL, maxX, self.cellHeight+3);
					
					CGContextAddPath(context, box);
					CGContextDrawPath(context, kCGPathFill);
					
					CGPathRelease(box);
					
					minY -= 2;
				} else {
					minY -= 1;
					
					//top
					
					CGMutablePathRef box = CGPathCreateMutable();
					
					CGPathMoveToPoint(box, NULL, minX, minY+1);
					CGPathAddLineToPoint(box, NULL, maxX, minY+1);
					CGPathAddLineToPoint(box, NULL, maxX, minY+self.cellHeight-self.radius+2);
					CGPathAddQuadCurveToPoint(box, NULL, maxX, minY+self.cellHeight+2, maxX-self.radius, minY+self.cellHeight+2);
					CGPathAddLineToPoint(box, NULL, minX+self.radius, minY+self.cellHeight+2);
					CGPathAddQuadCurveToPoint(box, NULL, minX, minY+self.cellHeight+2, minX, minY+self.cellHeight-self.radius+2);
					CGPathAddLineToPoint(box, NULL, minX, minY+1);
					CGPathCloseSubpath(box);
					
					CGContextAddPath(context, box);
					CGContextDrawPath(context, kCGPathFill);
					
					CGPathRelease(box);
					
					minY += 1;
				}
			}
		}
	}
	
	if (index != 0) {
		CGMutablePathRef separator = CGPathCreateMutable();
		CGPathMoveToPoint(separator, NULL, minX, minY);
		CGPathAddLineToPoint(separator, NULL, maxX, minY);
		
		CGMutablePathRef shadow = CGPathCreateMutable();
		CGPathMoveToPoint(shadow, NULL, minX, minY-1);
		CGPathAddLineToPoint(shadow, NULL, maxX, minY-1);
		
		//draw separator
		[self.borderColor setStroke];
		CGContextAddPath(context, separator);
		CGContextDrawPath(context, kCGPathStroke);
		
		CGPathRelease(separator);
		
		//draw shadow
		[shadowColor setStroke];
		CGContextAddPath(context, shadow);
		CGContextDrawPath(context, kCGPathStroke);
		
		CGPathRelease(shadow);
	}
	//	CGContextRelease(context);
  
	[self drawTitleWithIndex:index];
}

-(void)drawBase {
	CGRect bounds_inset = CGRectInset(self.bounds, 0.5, 0.5);
	CGFloat maxX = CGRectGetMaxX(bounds_inset);
	CGFloat minX = CGRectGetMinX(bounds_inset);
	CGFloat minY = CGRectGetMinY(bounds_inset);
  
	bounds_inset.size.height -= 1;
	bounds_inset.origin.y += 1;
		
	CGContextRef context=UIGraphicsGetCurrentContext();
	
	UIBezierPath* clipPath = [UIBezierPath bezierPathWithRoundedRect:bounds_inset cornerRadius:self.radius];
	[clipPath addClip];
	
	// draw gradient
	CGColorSpaceRef myColorspace=CGColorSpaceCreateDeviceRGB();
	size_t num_locations = 2;
	CGFloat locations[2] = { 1.0, 0.0 };
	CGFloat components[8];
	[gradientColor1 getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
	[gradientColor2 getRed:&components[4] green:&components[5] blue:&components[6] alpha:&components[7]];
	CGGradientRef myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
	CGContextDrawLinearGradient (context, myGradient, CGPointMake(0,0), CGPointMake(0,self.bounds.size.height), 0);
		
	//draw border
	[self.borderColor setStroke];
	[clipPath stroke];
  
	//draw bottom shadow
	CGMutablePathRef bottomShadow = CGPathCreateMutable();
	CGPathMoveToPoint(bottomShadow, NULL, minX, minY+self.radius);
	CGPathAddQuadCurveToPoint(bottomShadow, NULL, minX, minY, minX+self.radius , minY); //90degrees curve (left bottom)
	CGPathAddLineToPoint(bottomShadow, NULL, maxX-self.radius, minY);
	CGPathAddQuadCurveToPoint(bottomShadow, NULL, maxX, minY, maxX, self.radius); //90degrees curve (right bottom)
	[shadowColor setStroke];
	CGContextAddPath(context, bottomShadow);
	CGContextDrawPath(context, kCGPathStroke);
	CGPathRelease(bottomShadow);
}

-(void)drawRect:(CGRect)dirtyRect {
  for (UIView *view in [self subviews]) {
		[view removeFromSuperview];
  }
	[self drawBase];
	for (int i = 0; i< [self numberOfCells]; i++) {
		if (i == 0) {
			//bottom
			[self drawCellInRect:CGRectInset(CGRectMake(0, 0, self.bounds.size.width, self.cellHeight+2), 1.5, 0.5) index:i];
		} else if (i == [self numberOfCells] - 1) {
			//top
			[self drawCellInRect:CGRectInset(CGRectMake(0, (self.cellHeight+2)*i, self.bounds.size.width, self.cellHeight+2), 1.5, 0.5) index:i];
		} else {
			//something between
			[self drawCellInRect:CGRectInset(CGRectMake(0, (self.cellHeight+2)*i, self.bounds.size.width, self.cellHeight+2), 1.5, 0.5) index:i];
		}
	}
}

#pragma mark -
#pragma mark User Interaction
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch1 = [touches anyObject];
	CGPoint touchLocation = [touch1 locationInView:self];
		for (int i = 0; i<[self numberOfCells]; i++) {
		if (CGRectContainsPoint(CGRectMake(0, i*(self.cellHeight+3), self.bounds.size.width, self.cellHeight+3), touchLocation) ) {
			if (i == self.selectedSegment) {
				return;
			}
			self.selectedSegment = i;
			[self setNeedsDisplay];
			NSArray* allValues = self.data.allValues;
			NSString* sel = [allValues objectAtIndex:i];
			SEL selector = NSSelectorFromString(sel);
			if (selector && [self.target respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[self.target performSelector:selector withObject:self];
#pragma clang diagnostic pop
			}
		}
	}
}

@end
