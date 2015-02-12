//
//  ChartView.m
//  sensor
//
//  Created by omygod on 15/1/19.
//  Copyright (c) 2015年 Watchhhh. All rights reserved.
//

#import "ChartView.h"
#define  IMU_SIZE 180
@implementation ChartView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        intPadding = 10;
        intPaddingLeft = 10;
        self.clearsContextBeforeDrawing = YES;
        
        CGRect leftFrame = CGRectMake(intPaddingLeft,0,100,42);
        mLeftLabel=[[UILabel alloc] initWithFrame:leftFrame];
        mLeftLabel.backgroundColor=[UIColor clearColor];
        mLeftLabel.textColor=[UIColor whiteColor];
        [self addSubview:mLeftLabel];
        
        CGRect rightFrame = CGRectMake(frame.size.width-intPaddingLeft-100,0,100,42);
        mRightLabel=[[UILabel alloc] initWithFrame:rightFrame];
        mRightLabel.backgroundColor=[UIColor clearColor];
        mRightLabel.textColor=[UIColor whiteColor];
        [self addSubview:mRightLabel];
        
    }
    return self;
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 */
- (void)drawRect:(CGRect)rect
{
    mLeftLabel.text = [NSString stringWithFormat:@"%+.3f", [[data lastObject] floatValue]];
    
    // Drawing code
    mContext = UIGraphicsGetCurrentContext();
    CGContextClearRect(mContext, rect);
    //绘制坐标系
    [self drawCoordinate:mContext chartColor:[UIColor lightGrayColor] lineHeight:2];
    
    //test code
    float radioX = 1.0;
    float radioY = 1.0;
    //NSNumber* min = [data valueForKeyPath:@"@min.self"];
    //NSNumber* max = [data valueForKeyPath:@"@max.self"];
    
    float maxXValue = IMU_SIZE;
    //float minXValue = 0;
    
    NSUInteger aryCount = data.count;
    NSMutableArray *arytemp = [[NSMutableArray alloc] init];
    if(aryCount > 0)
    {
        float tmpWidth = self.frame.size.width - intPaddingLeft - intPadding;
        radioY = (self.frame.size.height - intPadding * 2 )/2;//Y轴每个像素比例。
        radioX = tmpWidth / (maxXValue - 1);//X轴横向每个值的比例。
        //NSLog(@"%f, %f", self.frame.size.width, self.frame.size.height);
        [self showRulerValue:mRulerPostion];
        
        for (int i = 0; i < aryCount; i++)
        {
            float x = i * radioX + intPadding;
            float value = [[data objectAtIndex:i] floatValue]/mScaleY;
            float y = radioY*(1-value)+intPadding;
            CGPoint p = CGPointMake(x, y);
            //NSLog(@"%f, %f", x, y);
            [arytemp addObject:[NSValue valueWithCGPoint:p]];
        }
        
        // Add control points to make the math make sense
        NSMutableArray *points = [arytemp mutableCopy];
        UIBezierPath *lineGraph = [UIBezierPath bezierPath];
        
        [lineGraph moveToPoint:[points[0] CGPointValue]];
        for (NSUInteger index = 1; index < points.count; index++)
        {
            [lineGraph addLineToPoint:[points[index] CGPointValue]];
        }
        
        [strokeColor setStroke];
        lineGraph.lineCapStyle = kCGLineCapRound;
        lineGraph.lineJoinStyle = kCGLineJoinRound;
        lineGraph.flatness = 0.5;
        lineGraph.lineWidth = 2; // line width
        [lineGraph stroke];
    }
}

-(void)drawCoordinate:(CGContextRef)context chartColor:(UIColor *)backgroundColor lineHeight:(float)lineHeight
{
    //绘制边框
    CGContextSetLineWidth(context, lineHeight);    //线条粗细
    CGPoint p1= CGPointMake(0 + intPadding, 0 + intPadding);
    CGPoint p2= CGPointMake(0 + intPadding, self.frame.size.height - intPadding);
    CGPoint p3= CGPointMake(self.frame.size.width - intPaddingLeft, self.frame.size.height - intPadding);
    CGPoint p4= CGPointMake(self.frame.size.width - intPaddingLeft, 0 + intPadding);
    
    CGPoint p12 = CGPointMake((p1.x+p2.x)/2, (p1.y+p2.y)/2);
    CGPoint p34 = CGPointMake((p3.x+p4.x)/2, (p3.y+p4.y)/2);
    NSArray *ary1 = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:p12],[NSValue valueWithCGPoint:p34],nil];
    [self drawLines:backgroundColor pointArray:ary1];
    
    NSArray *ary2 = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:p1],[NSValue valueWithCGPoint:p2],nil];
    [self drawLines:backgroundColor pointArray:ary2];
    
    NSArray *ary3 = [NSArray arrayWithObjects:[NSValue valueWithCGPoint:p3],[NSValue valueWithCGPoint:p4],nil];
    [self drawLines:backgroundColor pointArray:ary3];

}

-(CGContextRef)drawLines:(UIColor *)color pointArray:(NSArray *)ary
{
    
    CGContextSetLineCap(mContext, kCGLineCapRound);         //线条风格
    CGContextSetStrokeColorWithColor(mContext, color.CGColor);
    CGContextBeginPath(mContext);
    //设置下一个坐标点
    if ([ary count]>0) {
        //起始点设置为(0,0):注意这是上下文对应区域中的相对坐标，
        //初始坐标，读取第一条数据。
        
        for (int i = 0; i < [ary count]; i++) {
            NSValue *value = [ary objectAtIndex:i];
            CGPoint point = [value CGPointValue];
            if(i==0)
            {
                CGContextMoveToPoint(mContext, point.x, point.y);
            }else{
                CGContextAddLineToPoint(mContext, point.x, point.y);
            }
        }
    }
    CGContextStrokePath(mContext);
    
    return mContext;
}
//数据绘制。
-(void)drawDataLine:(NSArray *)ary color:(UIColor *)color scale:(int)scaleY rulerPoistion:(int) position
{
    data = ary;
    strokeColor = color;
    mScaleY = scaleY;
    mRulerPostion = position;
    [self setNeedsDisplay];
}
-(void)showRulerValue:(int) position
{
    //right label
    mRulerPostion = position;
    
    NSUInteger aryCount = data.count;
    float tmpWidth = self.frame.size.width - intPaddingLeft - intPadding;
    float maxXValue = IMU_SIZE;
    float radioX = tmpWidth / (maxXValue - 1);//X轴横向每个值的比例。
    
    int pos = (mRulerPostion - intPaddingLeft)/radioX;
    if (pos > aryCount-1) {
        mRightLabel.text = [NSString stringWithFormat:@"%+.3f", 0.0];
    }
    else if (pos < 0)
    {
        mRightLabel.text = [NSString stringWithFormat:@"%+.3f", 0.0];
    }
    else
    {
        float value = [[data objectAtIndex:pos] floatValue];
        //NSLog(@"%f", value);
        mRightLabel.text = [NSString stringWithFormat:@"%+.3f", value];
    }
}
@end
