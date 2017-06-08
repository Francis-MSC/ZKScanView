//
//  ZKScanView.h
//  ZKScanView
//
//  Created by msc on 2017/6/7.
//  Copyright © 2017年 MSC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZKScanView : UIView

/** 扫描范围,相对整体视图位置 */
@property(nonatomic,assign) CGRect scanRect;
/** 扫描成功 */
@property(nonatomic,copy) void (^scrollSuccess)(NSString *barcode);
/** 是否在扫描 */
@property(nonatomic,assign,readonly) BOOL running;

/** 扫码成功时的声音 */
@property(nonatomic,copy) NSString *audioName;

/** 初始化方法 */
- (instancetype)initWithFrame:(CGRect)frame;

/** 开始扫描(可以指定延时时间) */
-(void)startWithDelay:(NSTimeInterval)ti;
/** 暂停扫描 */
-(void)stop;

/** 移除(否则内存泄漏) */
-(void)remove;

@end
