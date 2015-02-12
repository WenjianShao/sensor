//
//  ChartView.h
//  sensor
//
//  Created by omygod on 15/1/19.
//  Copyright (c) 2015年 Watchhhh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChartView : UIView
{
    int intPadding;
    int intPaddingLeft;
    int mScaleY;
    int mRulerPostion;
    
    NSArray * data;
    UIColor * strokeColor;
    CGContextRef mContext;
    
    UILabel *mLeftLabel;
    UILabel *mRightLabel;
    
}
-(void)drawDataLine:(NSArray *)ary color:(UIColor *)color scale:(int)scaleY rulerPoistion:(int) position;

-(void)showRulerValue:(int) position;

@end
