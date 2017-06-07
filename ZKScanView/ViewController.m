//
//  ViewController.m
//  ZKScanView
//
//  Created by msc on 2017/6/7.
//  Copyright © 2017年 MSC. All rights reserved.
//

#import "ViewController.h"
#import "ScanVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, [UIScreen mainScreen].bounds.size.width-200, 70)];
    btn.backgroundColor = [UIColor yellowColor];
    [btn setTitle:@"扫码" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}


-(void)btnClick{
    ScanVC *vc = [ScanVC new];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
