//
//  ViewController.m
//  sensor
//
//  Created by omygod on 15/1/13.
//  Copyright (c) 2015年 Watchhhh. All rights reserved.
//

#import "ViewController.h"
#import "JXSensorViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //NSLog(@"%f, %f, %f, %f", self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.width, self.view.frame.size.height);
    JXSensorViewController *sensorController =[[JXSensorViewController alloc] initWithNibName:nil bundle:nil frame:self.view.frame];
    //NSLog(@"%f, %f, %f, %f", sensorController.view.frame.origin.x, sensorController.view.frame.origin.y, sensorController.view.frame.size.width, sensorController.view.frame.size.height);
    [self.view addSubview:sensorController.view];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
