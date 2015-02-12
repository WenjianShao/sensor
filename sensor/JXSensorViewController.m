//
//  JXSensorViewController.m
//  Watchhhh
//
//  Created by Xiaolei Wang on 9/16/14.
//  Copyright (c) 2014 Joker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

#import "JXSensorViewController.h"
#import "ChartView.h"


#ifndef FACTOR_RAD_TO_DEG
#define FACTOR_RAD_TO_DEG 57.295779505601046646705075978956f
#endif

#define  IMU_SIZE 180

typedef enum drawType {RAW_ACC, RAW_GRY, ATT, RATE, GRAVITY, USER_ACC, RAW_ACC_GRAVITY} drawType;

typedef struct IMU
{
    double rawAcc[3];
    double rawGry[3];
    double att[3];
    double rate[3];
    double gravity[3];
    double userAcc[3];
    
    double accTimestamp;
    double gyroTimestamp;
    double deviceTimestamp;
} IMU;

@interface JXSensorViewController ()
{
    drawType mDrawType;
    IMU IMU_data[IMU_SIZE];

    ChartView *cv_x;
    ChartView *cv_y;
    ChartView *cv_z;
    
    UIView *ruler_view;
    int rulerPosition;
    
    NSMutableArray *mutableArray_x;
    NSMutableArray *mutableArray_y;
    NSMutableArray *mutableArray_z;
    
    NSMutableArray *mutableArray_accTimestamp;
    NSMutableArray *mutableArray_gyroTimestamp;
    NSMutableArray *mutableArray_deviceTimestamp;
    
    int scaleY;
    
    UIColor *color_x;
    UIColor *color_y;
    UIColor *color_z;
    
    NSObject *lock;
    
    int index;
    
    BOOL isFirstClick;
    BOOL isStart;
}

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSTimer *timer;

@property (weak, nonatomic) IBOutlet UIView *ChartView;
@property (weak, nonatomic) IBOutlet UIButton *start_button;
@property (weak, nonatomic) IBOutlet UILabel *scale_label;

@end

@implementation JXSensorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil frame:(CGRect)frame
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.view.frame = frame;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIFont *fixedWidthFont = [UIFont fontWithName:@"Courier" size:17];
    self.scale_label.font = fixedWidthFont;
    
    //Motion Manager
    self.motionManager = [CMMotionManager new];
    
    self.motionManager.deviceMotionUpdateInterval =1.0/60.0;
    self.motionManager.accelerometerUpdateInterval= 1.0/60.0;
    self.motionManager.gyroUpdateInterval = 1.0/60.0;
    
    [self.motionManager startAccelerometerUpdates];
    [self.motionManager startGyroUpdates];
    [self.motionManager startDeviceMotionUpdates];
    //[self.motionManager startMagnetometerUpdates]; // 暂时不收集数据，但要开着
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60
                                                  target:self
                                                selector:@selector(onMotionData:)
                                                userInfo:nil
                                                 repeats:YES];
   
    mDrawType = RAW_ACC;
    scaleY = 1;
    self.scale_label.text = @"RAW_ACC scale:1";
    
    color_x = [UIColor redColor];
    color_y = [UIColor greenColor];
    color_z = [UIColor blueColor];
    
    lock = [NSObject new];
    index = 0;
    isFirstClick = YES;
    isStart = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onClickStartButton:(id)sender
{
    NSString *Start = @"Start";
    NSString *Pause = @"Pause";
    BOOL result = [self.start_button.titleLabel.text isEqualToString: Start];
    if(result)
    {
        [self.start_button setTitle:Pause forState:UIControlStateNormal];
        isStart = YES;
    }
    else
    {
        [self.start_button setTitle:Start forState:UIControlStateNormal];
        isStart = NO;
        
    }
}

- (void)onMotionData:(NSTimer *)timer
{
    if (isFirstClick) {
        CGRect rect = self.ChartView.frame;
        
        CGRect rulerFrame = CGRectMake((rect.size.width-40)/2, 10, 40, rect.size.height-20);
        ruler_view=[[UIView alloc] initWithFrame:rulerFrame];
        ruler_view.backgroundColor=[UIColor clearColor];
        CGRect rulerFrameSmall = CGRectMake((rulerFrame.size.width-2)/2, 0, 2, rulerFrame.size.height);
        UIView *ruler = [[UIView alloc] initWithFrame:rulerFrameSmall];
        ruler.backgroundColor=[UIColor yellowColor];
        [ruler_view addSubview:ruler];
        [self.ChartView addSubview:ruler_view];
        rulerPosition = rect.size.width/2;
        
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc]
                                                        initWithTarget:self
                                                        action:@selector(handlePan:)];
        [ruler_view addGestureRecognizer:panGestureRecognizer];
        
        //实例化chart
        cv_x =[[ChartView alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height/3)];
        [self.ChartView addSubview:cv_x];
        [self.ChartView sendSubviewToBack:cv_x];
        
        cv_y =[[ChartView alloc] initWithFrame:CGRectMake(0, rect.size.height/3, rect.size.width, rect.size.height/3)];
        [self.ChartView addSubview:cv_y];
        [self.ChartView sendSubviewToBack:cv_y];
        
        cv_z =[[ChartView alloc] initWithFrame:CGRectMake(0, 2*rect.size.height/3, rect.size.width, rect.size.height/3)];
        [self.ChartView addSubview:cv_z];
        [self.ChartView sendSubviewToBack:cv_z];
        isFirstClick = NO;
    }
    
    CMAccelerometerData *acc = self.motionManager.accelerometerData;
    CMGyroData *gyro = self.motionManager.gyroData;
    CMDeviceMotion *d = self.motionManager.deviceMotion;
    
    //NSLog(@"%f, %f, %f", accTimestamp, gyroTimestamp, deviceTimestamp);
    
    if (isStart) {
        @synchronized(lock)
        {
            IMU_data[index%IMU_SIZE].rawAcc[0] = acc.acceleration.x;
            IMU_data[index%IMU_SIZE].rawAcc[1] = acc.acceleration.y;
            IMU_data[index%IMU_SIZE].rawAcc[2] = acc.acceleration.z;
            IMU_data[index%IMU_SIZE].rawGry[0] = gyro.rotationRate.x * FACTOR_RAD_TO_DEG;
            IMU_data[index%IMU_SIZE].rawGry[1] = gyro.rotationRate.y * FACTOR_RAD_TO_DEG;
            IMU_data[index%IMU_SIZE].rawGry[2] = gyro.rotationRate.z * FACTOR_RAD_TO_DEG;
            IMU_data[index%IMU_SIZE].rate[0] = d.rotationRate.x * FACTOR_RAD_TO_DEG;
            IMU_data[index%IMU_SIZE].rate[1] = d.rotationRate.y * FACTOR_RAD_TO_DEG;
            IMU_data[index%IMU_SIZE].rate[2] = d.rotationRate.z * FACTOR_RAD_TO_DEG;
            
            IMU_data[index%IMU_SIZE].att[0] = d.attitude.roll * FACTOR_RAD_TO_DEG;
            IMU_data[index%IMU_SIZE].att[1] = d.attitude.pitch * FACTOR_RAD_TO_DEG;
            IMU_data[index%IMU_SIZE].att[2] = d.attitude.yaw * FACTOR_RAD_TO_DEG;

            IMU_data[index%IMU_SIZE].gravity[0] = d.gravity.x;
            IMU_data[index%IMU_SIZE].gravity[1] = d.gravity.y;
            IMU_data[index%IMU_SIZE].gravity[2] = d.gravity.z;
            IMU_data[index%IMU_SIZE].userAcc[0] = d.userAcceleration.x;
            IMU_data[index%IMU_SIZE].userAcc[1] = d.userAcceleration.y;
            IMU_data[index%IMU_SIZE].userAcc[2] = d.userAcceleration.z;
            
            IMU_data[index%IMU_SIZE].accTimestamp = acc.timestamp;
            IMU_data[index%IMU_SIZE].gyroTimestamp = gyro.timestamp;
            IMU_data[index%IMU_SIZE].deviceTimestamp = d.timestamp;
            
            index++;
        }
        
        if (index%4 == 0) {
            [self onDrawIMU];
            //[NSThread detachNewThreadSelector:@selector(onDrawIMU) toTarget:self withObject:nil];
        }
    }
}
- (IBAction)onButtonRawAcc:(id)sender {
    mDrawType = RAW_ACC;
    self.scale_label.text = @"RAW_ACC scale:1";
    scaleY = 1;
    if (isStart == NO) {
        [self onDrawIMU];
    }
}
- (IBAction)onButtonRawGry:(id)sender {
    mDrawType = RAW_GRY;
    self.scale_label.text = @"RAW_GRY scale:180";
    scaleY = 180;
    if (isStart == NO) {
        [self onDrawIMU];
    }
}
- (IBAction)onButtonAtt:(id)sender {
    mDrawType = ATT;
    self.scale_label.text = @"ATT scale:180";
    scaleY = 180;
    if (isStart == NO) {
        [self onDrawIMU];
    }
}
- (IBAction)onButtonRate:(id)sender {
    mDrawType = RATE;
    self.scale_label.text = @"RATE scale:180";
    scaleY = 180;
    if (isStart == NO) {
        [self onDrawIMU];
    }
}
- (IBAction)onButtonGravity:(id)sender {
    mDrawType = GRAVITY;
    self.scale_label.text = @"GRAVITY scale:1";
    scaleY = 1;
    if (isStart == NO) {
        [self onDrawIMU];
    }
}
- (IBAction)onButtonUserAcc:(id)sender {
    mDrawType = USER_ACC;
    self.scale_label.text = @"USER_ACC scale:1";
    scaleY = 1;
    if (isStart == NO) {
        [self onDrawIMU];
    }
}
- (IBAction)onButtonRawAccGravity:(id)sender {
    mDrawType = RAW_ACC_GRAVITY;
    self.scale_label.text = @"RAW_ACC-GRAVITY scale:1";
    scaleY = 1;
    if (isStart == NO) {
        [self onDrawIMU];
    }
}

- (void) drawDataLine_x
{
    [cv_x drawDataLine:mutableArray_x color:color_x scale:scaleY rulerPoistion:rulerPosition];
}

- (void) drawDataLine_y
{
    [cv_y drawDataLine:mutableArray_y color:color_y scale:scaleY rulerPoistion:rulerPosition];
}

- (void) drawDataLine_z
{
    [cv_z drawDataLine:mutableArray_z color:color_z scale:scaleY rulerPoistion:rulerPosition];
}

- (void) drawDataLine
{
    [cv_x drawDataLine:mutableArray_x color:color_x scale:scaleY rulerPoistion:rulerPosition];
    [cv_y drawDataLine:mutableArray_y color:color_y scale:scaleY rulerPoistion:rulerPosition];
    [cv_z drawDataLine:mutableArray_z color:color_z scale:scaleY rulerPoistion:rulerPosition];
}

- (void) showRulerValue:(int) position
{
    [cv_x showRulerValue:position];
    [cv_y showRulerValue:position];
    [cv_z showRulerValue:position];
}

- (void)onDrawIMU
{
    int len = index < IMU_SIZE ? index : IMU_SIZE;
    
    mutableArray_x = [NSMutableArray arrayWithCapacity:len];
    mutableArray_y = [NSMutableArray arrayWithCapacity:len];
    mutableArray_z = [NSMutableArray arrayWithCapacity:len];
    
    mutableArray_accTimestamp = [NSMutableArray arrayWithCapacity:len];
    mutableArray_gyroTimestamp = [NSMutableArray arrayWithCapacity:len];
    mutableArray_deviceTimestamp = [NSMutableArray arrayWithCapacity:len];
    
    switch (mDrawType)
    {
        case RAW_ACC:
            @synchronized(lock)
            {
                for (int i = 0; i < len; i++)
                {
                    [mutableArray_x addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawAcc[0]]];
                    [mutableArray_y addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawAcc[1]]];
                    [mutableArray_z addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawAcc[2]]];
                    //NSLog(@"%f, %f, %f", IMU_data[i].rawAcc[0], IMU_data[i].rawAcc[1], IMU_data[i].rawAcc[2]);
                }
            }
            break;
        case RAW_GRY:
            @synchronized(lock)
            {
                for (int i = 0; i < len; i++)
                {
                    [mutableArray_x addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawGry[0]]];
                    [mutableArray_y addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawGry[1]]];
                    [mutableArray_z addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawGry[2]]];
                    //NSLog(@"%f, %f, %f", IMU_data[i].rawAcc[0], IMU_data[i].rawAcc[1], IMU_data[i].rawAcc[2]);
                }
            }
            break;
        case ATT:
            @synchronized(lock)
            {
                for (int i = 0; i < len; i++)
                {
                    [mutableArray_x addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].att[0]]];
                    [mutableArray_y addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].att[1]]];
                    [mutableArray_z addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].att[2]]];
                    //NSLog(@"%f, %f, %f", IMU_data[i].rawAcc[0], IMU_data[i].rawAcc[1], IMU_data[i].rawAcc[2]);
                }
            }
            break;
        case RATE:
            @synchronized(lock)
            {
                for (int i = 0; i < len; i++)
                {
                    [mutableArray_x addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rate[0]]];
                    [mutableArray_y addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rate[1]]];
                    [mutableArray_z addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rate[2]]];
                    //NSLog(@"%f, %f, %f", IMU_data[i].rawAcc[0], IMU_data[i].rawAcc[1], IMU_data[i].rawAcc[2]);
                }
            }
            break;
        case GRAVITY:
            @synchronized(lock)
            {
                for (int i = 0; i < len; i++)
                {
                    [mutableArray_x addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].gravity[0]]];
                    [mutableArray_y addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].gravity[1]]];
                    [mutableArray_z addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].gravity[2]]];
                    //NSLog(@"%f, %f, %f", IMU_data[i].rawAcc[0], IMU_data[i].rawAcc[1], IMU_data[i].rawAcc[2]);
                }
            }
            break;
        case USER_ACC:
            @synchronized(lock)
            {
                for (int i = 0; i < len; i++)
                {
                    [mutableArray_x addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].userAcc[0]]];
                    [mutableArray_y addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].userAcc[1]]];
                    [mutableArray_z addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].userAcc[2]]];
                    //NSLog(@"%f, %f, %f", IMU_data[i].rawAcc[0], IMU_data[i].rawAcc[1], IMU_data[i].rawAcc[2]);
                }
            }
            break;
        case RAW_ACC_GRAVITY:
            @synchronized(lock)
            {
                for (int i = 0; i < len; i++)
                {
                    [mutableArray_x addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawAcc[0]-IMU_data[(index-i-1)%IMU_SIZE].gravity[0]]];
                    [mutableArray_y addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawAcc[1]-IMU_data[(index-i-1)%IMU_SIZE].gravity[1]]];
                    [mutableArray_z addObject:[NSNumber numberWithFloat:IMU_data[(index-i-1)%IMU_SIZE].rawAcc[2]-IMU_data[(index-i-1)%IMU_SIZE].gravity[2]]];
                    //NSLog(@"%f, %f, %f", IMU_data[i].rawAcc[0], IMU_data[i].rawAcc[1], IMU_data[i].rawAcc[2]);
                }
            }
            break;
            
        default:
            break;
    }
//    [NSThread detachNewThreadSelector:@selector(drawDataLine_x) toTarget:self withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(drawDataLine_y) toTarget:self withObject:nil];
//    [NSThread detachNewThreadSelector:@selector(drawDataLine_z) toTarget:self withObject:nil];
    [NSThread detachNewThreadSelector:@selector(drawDataLine) toTarget:self withObject:nil];
    
}

- (void) handlePan:(UIPanGestureRecognizer*) recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         recognizer.view.center.y);
    [recognizer setTranslation:CGPointZero inView:self.view];
    rulerPosition = recognizer.view.center.x + translation.x;
    //NSLog(@"%f", recognizer.view.center.x + translation.x);
    if (isStart == NO) {
        [self showRulerValue:rulerPosition];
        //[self onDrawIMU];
    }

}


@end
