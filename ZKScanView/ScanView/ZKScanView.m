//
//  ZKScanView.m
//  ZKScanView
//
//  Created by msc on 2017/6/7.
//  Copyright © 2017年 MSC. All rights reserved.
//

#import "ZKScanView.h"
#import <AVFoundation/AVFoundation.h>

@interface ZKScanView ()<AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession *_session;//输入输出的中间桥梁
    AVCaptureVideoPreviewLayer *_preView;
    AVCaptureMetadataOutput *_outputStream;
    CALayer *_maskLayer;/** 遮罩 */
    UIImageView *_scrollImgv;
    CADisplayLink *_displayLink;
    /** 四个角 */
    UIImageView *_leftTopCorner;
    UIImageView *_leftBottomCorner;
    UIImageView *_rightTopCorner;
    UIImageView *_rightBottomCorner;
}
@end

@implementation ZKScanView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
        /** 模拟器不能扫码 */
        if (TARGET_IPHONE_SIMULATOR) {
            return self;
        }
        
        /** 如果没有相机使用权限 */
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusRestricted || status == AVAuthorizationStatusDenied) {
            /** 受限或不允许 */
            
            UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"相机权限未开启，请前往系统“设置”开启相机使用权限" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil];
            [alertView show];
            
            return self;
        }
        
        AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        AVCaptureDeviceInput* inputStream = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
        
        _outputStream = [[AVCaptureMetadataOutput alloc]init];
        
        [_outputStream setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        // 创建会话
        _session = [[AVCaptureSession alloc]init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        
        // 添加输入流
        if ([_session canAddInput:inputStream]) {
            
            [_session addInput:inputStream];
        }
        // 添加输出流
        if ([_session canAddOutput:_outputStream]) {
            
            [_session addOutput:_outputStream];
        }
        // 要在session后面设置扫描接受的类型
        NSMutableArray *metaTypes = [[NSMutableArray alloc] init];
        if ([_outputStream.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
            [metaTypes addObject:AVMetadataObjectTypeEAN13Code];
        }
        if ([_outputStream.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
            [metaTypes addObject:AVMetadataObjectTypeEAN8Code];
        }
        if ([_outputStream.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
            [metaTypes addObject:AVMetadataObjectTypeCode128Code];
        }
        if ([_outputStream.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            [metaTypes addObject:AVMetadataObjectTypeQRCode];
        }
        [_outputStream setMetadataObjectTypes:metaTypes];
        
        // 创建输出对象
        _preView = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        _preView.videoGravity = AVLayerVideoGravityResizeAspectFill;
        
        CGRect intertRect = [_preView metadataOutputRectOfInterestForRect:_preView.frame];
        _outputStream.rectOfInterest = intertRect;
        
        [self.layer addSublayer:_preView];
        
        /** 扫描区域默认和视图区域一样大 */
        _scanRect = _preView.bounds;
        
        _scrollImgv = [[UIImageView alloc]initWithFrame:CGRectMake(_scanRect.origin.x, _scanRect.origin.y-32, _scanRect.size.width, 32)];
        _scrollImgv.image = [UIImage imageNamed:@"sm"];
        [self addSubview:_scrollImgv];
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scroll)];
        _displayLink.paused = YES;
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
    }
    return self;
}

-(void)setScanRect:(CGRect)scanRect{
    
    if (!_session) {
        return;
    }
    
    _scanRect = scanRect;
    _scrollImgv.frame = CGRectMake(_scanRect.origin.x, _scanRect.origin.y-32, _scanRect.size.width, 32);
    CGRect intertRect = [_preView metadataOutputRectOfInterestForRect:_scanRect];
    _outputStream.rectOfInterest = intertRect;
    
    if (!_maskLayer) {
        _maskLayer = [CALayer layer];
        _maskLayer.frame = self.bounds;
        _maskLayer.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7].CGColor;
        [self.layer addSublayer:_maskLayer];
    }
    
    /** 绘制镂空扫描框 */
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:_maskLayer.bounds];
    [path appendPath:[[UIBezierPath bezierPathWithRect:_scanRect] bezierPathByReversingPath]];
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    [_maskLayer setMask:shapeLayer];
    
    if (!_leftTopCorner) {
        _leftTopCorner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scrollcorner_leftup"]];
        _leftBottomCorner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scrollcorner_leftbottom"]];
        _rightTopCorner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scrollcorner_rightup"]];
        _rightBottomCorner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"scrollcorner_rightbottom"]];
        [self addSubview:_leftTopCorner];
        [self addSubview:_leftBottomCorner];
        [self addSubview:_rightTopCorner];
        [self addSubview:_rightBottomCorner];
    }
    _leftTopCorner.frame = CGRectMake(scanRect.origin.x-2.5, scanRect.origin.y-2.5, _leftTopCorner.frame.size.width, _leftTopCorner.frame.size.height);
    _leftBottomCorner.frame = CGRectMake(_leftTopCorner.frame.origin.x, CGRectGetMaxY(scanRect)-(_leftBottomCorner.frame.size.height-2.5), _leftBottomCorner.frame.size.width, _leftBottomCorner.frame.size.height);
    _rightTopCorner.frame = CGRectMake(CGRectGetMaxX(scanRect)-(_rightTopCorner.frame.size.width-2.5), _leftTopCorner.frame.origin.y, _rightTopCorner.frame.size.width, _rightTopCorner.frame.size.height);
    _rightBottomCorner.frame = CGRectMake(_rightTopCorner.frame.origin.x, _leftBottomCorner.frame.origin.y, _rightBottomCorner.frame.size.width, _rightBottomCorner.frame.size.height);

}

/** 扫描动画 */
-(void)scroll{
    CGRect rect = _scrollImgv.frame;
    rect.origin.y += 1.5;
    _scrollImgv.frame = rect;
    if (CGRectGetMaxY(_scrollImgv.frame)>=CGRectGetMaxY(_scanRect)) {
        rect.origin.y = _scanRect.origin.y-_scrollImgv.frame.size.height;
        _scrollImgv.frame = rect;
    }
}

/** 开始扫描 */
-(void)startWithDelay:(NSTimeInterval)ti{
    if (!_session) {
        return;
    }
    
    if (_displayLink && _session) {
        _displayLink.paused = NO;
        [_session performSelector:@selector(startRunning) withObject:nil afterDelay:ti];
        _running = YES;
    }
}

/** 暂停扫描 */
-(void)stop{
    if (!_session) {
        return;
    }
    
    if (_displayLink && _session) {
        _displayLink.paused = YES;
        [_session stopRunning];
        _running = NO;
    }
}


/** 扫描结果代理方法 */
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    if (metadataObjects.count>0) {
        
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        //输出扫描字符串
        NSLog(@"%@",metadataObject.stringValue);
        if(metadataObject.stringValue > 0){
            [self stop];
            AudioServicesPlaySystemSound(1007);
            if (_scrollSuccess) {
                _scrollSuccess(metadataObject.stringValue);
            }
        }
    }
}

-(void)remove{
    
    if (!_session) {
        return;
    }
    
    [self stop];
    
    _session = nil;
    [_preView removeFromSuperlayer];
    _preView = nil;
    [_displayLink invalidate];
    _displayLink = nil;
    
    [self removeFromSuperview];
}


-(void)dealloc{
    [self remove];
}


@end
