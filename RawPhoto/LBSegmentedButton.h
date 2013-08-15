//
//  LBSegmentedButton.h
//  LamojiPreferences
//
//  Created by Laurin Brandner on 01.06.11.
//  Copyright 2011 Larcus. All rights reserved.
//
//  RT @Larcus94: "use it where ever you want!" (closed source, commercial ok)


//#import <Cocoa/Cocoa.h>

@interface LBSegmentedButton : UIView {
    
    //Drawing Infos
    NSDictionary* data;
    UIColor* borderColor;
    
    //Button Infos
    id target;
    NSInteger selectedSegment;
}

@property (readwrite, copy) NSDictionary* data;
@property (readwrite) CGFloat cellHeight;
@property (readwrite) CGFloat radius;
@property (readwrite, retain) UIColor* borderColor;

@property (readwrite, retain) IBOutlet id target;
@property (readwrite) NSInteger selectedSegment;


-(id)initWithFrame:(CGRect)frameRect titles:(NSArray*)titles selectors:(NSArray*)selectorsAsStrings target:(id)target;

-(NSInteger)numberOfCells;

-(void)drawBase;
-(void)drawCellInRect:(CGRect)rect index:(NSInteger)index;
-(void)drawTitleWithIndex:(NSInteger)index;
-(NSString*) selectedValue;

@end
