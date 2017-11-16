//
//  ViewController.m
//  KsyTest
//
//  Created by mm on 2017/8/5.
//  Copyright © 2017年 mm. All rights reserved.
//

#import "ViewController.h"

#import "LiveViewController.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *Btn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [_Btn setBackgroundColor:[UIColor orangeColor]];
    
    [_Btn setTitle:@"aaa" forState:(UIControlStateNormal)];
    
    [_Btn addTarget:self action:@selector(GoLive) forControlEvents:(UIControlEventTouchUpInside)];
    
}

-(void)GoLive{
    
    NSLog(@"GOOO");
    
    LiveViewController *live = [[LiveViewController alloc] init];
    
    live.rtmpSrv = @"rtmp://video-center.alivecdn.com/qqpt/0842953?vhost=qqpt-live.qq-pt.com";
    
    [self presentViewController:live animated:YES completion:nil];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
