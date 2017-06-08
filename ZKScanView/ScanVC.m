//
//  ScanVC.m
//  ZKScanView
//
//  Created by msc on 2017/6/7.
//  Copyright © 2017年 MSC. All rights reserved.
//

#import "ScanVC.h"
#import "ZKScanView.h"

@interface ScanVC ()
{
    /** 扫描视图 */
    ZKScanView *_scanView;
}
@end

@implementation ScanVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    /** 扫码视图 */
    __weak typeof(self) weakSelf = self;
    _scanView = [[ZKScanView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 240)];
    _scanView.audioName = @"beep.caf";
    [_scanView setScrollSuccess:^(NSString *barcode) {
        [weakSelf operateCode:barcode];
    }];
    [self.view addSubview:_scanView];
    [_scanView setScanRect:CGRectMake(40, 40, [UIScreen mainScreen].bounds.size.width-80, 160)];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-100)/2, 300, 100, 70)];
    btn.backgroundColor = [UIColor yellowColor];
    [btn setTitle:@"扫码" forState:UIControlStateNormal];
    [btn setTitle:@"暂停" forState:UIControlStateSelected];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    btn.tag = 100;
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(([UIScreen mainScreen].bounds.size.width-100)/2, 400, 100, 70)];
    backBtn.backgroundColor = [UIColor yellowColor];
    [backBtn setTitle:@"返回" forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    [backBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
}

/** 扫码／暂停 */
-(void)btnClick:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        [_scanView startWithDelay:0];
    }else{
        [_scanView stop];
    }
}

/** 返回 */
-(void)goBack{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)operateCode:(NSString *)code{
    NSLog(@"%@",code);
    /** 扫码成功后会暂停 */
    UIButton *btn = [self.view viewWithTag:100];
    btn.selected = NO;
}


/** 销毁时要移除，否则内存泄漏 */
-(void)dealloc{
    [_scanView remove];
}


@end
