//
//  ScanQRCodeViewController.m
//  QRCodeScan
//
//  Created by 张磊 on 16/6/22.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "ZLScanQRCodeViewController.h"

#import "ZLQRScanTool.h"


#define ZLScanViewX  60.0   // 扫描视图的x轴
#define ZLScanViewY 150.0   // 扫描视图的y轴

@interface ZLScanQRCodeViewController () <AVCaptureMetadataOutputObjectsDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>

// 捕获元素输出
@property (nonatomic,strong) AVCaptureMetadataOutput *output;

// 捕获视频预览层
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *preview;
// 捕获视图
@property (nonatomic,strong) UIView *captureView;
@property (nonatomic,assign) CGRect cropRect;
//来回滑动的横线
@property (nonatomic,strong) CALayer *qrLineLayer;
@property (nonatomic,strong) CAKeyframeAnimation *anim;


@end

@implementation ZLScanQRCodeViewController

- (CALayer *)qrLineLayer {
    if (!_qrLineLayer) {
        //来回滑动的横线
        _qrLineLayer = [[CALayer alloc] init];
        _qrLineLayer.frame = CGRectMake(_cropRect.origin.x,_cropRect.origin.y,_cropRect.size.width,4);
        _qrLineLayer.backgroundColor = self.scanLineColor.CGColor;
        _qrLineLayer.opacity = 0.5;
        _qrLineLayer.opaque = NO;
        _qrLineLayer.cornerRadius = 20;
        _qrLineLayer.masksToBounds = YES;
        
    }
    return _qrLineLayer;
}

- (CAKeyframeAnimation *)anim {
    if (!_anim) {
        //动画效果
        _anim = [CAKeyframeAnimation animation];
        _anim.keyPath = @"position";
        
        CGFloat pX = CGRectGetMidX(_cropRect);
        NSValue *v1 = [NSValue valueWithCGPoint:CGPointMake(pX , CGRectGetMinY(_cropRect))];
        NSValue *v2 = [NSValue valueWithCGPoint:CGPointMake(pX, CGRectGetMaxY(_cropRect))];
        _anim.values = @[v1,v2];
        
        _anim.duration = 4;
        _anim.repeatCount = MAXFLOAT;
    }
    return _anim;
}

- (instancetype)init {
    if (self = [super init]) {
        self.scanLineColor = [UIColor colorWithRed:0.188 green:0.478 blue:1.000 alpha:1.000];
        self.showNavigationRightItemFromPhotoAlbum = YES;
        self.showMyQRCodeButton = YES;
    }
    return self;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 导航栏半透明
    self.navigationController.navigationBar.subviews[0].alpha = 0.1;
    // 返回按钮字体颜色
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    // self.title字体颜色
    [self.navigationController.navigationBar setTitleTextAttributes: @{NSFontAttributeName:[UIFont systemFontOfSize:19],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    if ([self checkCaptureDeviceAuthStatus]) {
        [self startScanning];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.subviews[0].alpha = 1;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.188 green:0.478 blue:1.000 alpha:1.000];
    [self.navigationController.navigationBar setTitleTextAttributes: @{NSForegroundColorAttributeName:[UIColor blackColor]}];
    
    [self stopScanning];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startScanning) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [self setupNavigationItem];
    [self setupCapture];
    [self setupMyQRCodeButton];
    
}
// 检查相机授权状态
- (BOOL)checkCaptureDeviceAuthStatus {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"访问摄像头失败" message:@"请在iPhone的“设置”-“隐私”-“相机”功能中，找到该APP打开相机访问权限" preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(self) wSelf = self;
        [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [wSelf.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alertCtr animated:YES completion:nil];
        return NO;
    }
    return YES;
}


- (void)setupNavigationItem {
    if (self.showNavigationRightItemFromPhotoAlbum) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册" style:UIBarButtonItemStylePlain target:self action:@selector(openPhotoAlbum)];
    }
}

- (void)openPhotoAlbum {
    [self chooseImageWithSouceType:UIImagePickerControllerSourceTypePhotoLibrary allowsEditing:NO];
}

// 打开相册
- (void)chooseImageWithSouceType:(UIImagePickerControllerSourceType)souceType allowsEditing:(BOOL)allowsEditing {
    UIImagePickerController *imgPickCtr = [[UIImagePickerController alloc] init];
    imgPickCtr.sourceType = souceType;
    imgPickCtr.allowsEditing = allowsEditing;
    imgPickCtr.delegate = self;
    [self presentViewController:imgPickCtr animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    NSString *stringValue = [ZLQRScanTool qrFromPhoto:image];
    if (stringValue) {
        [picker dismissViewControllerAnimated:NO completion:nil];
        [self handleQRCodeValue:stringValue codeType:AVMetadataObjectTypeQRCode];
        return;
    }
    
    [self fromPhotoAlbumGetQRCodeError:picker];
    
}


// 设置摄像设备
- (void)setupCapture {
    _captureView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.view addSubview:_captureView];
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        return;
    }
    _output = [[AVCaptureMetadataOutput alloc]init];
    
    //设置代理
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    _session = [[AVCaptureSession alloc]init];
    //设置会话预览质量
    [_session setSessionPreset:AVCaptureSessionPreset1920x1080];
    //添加输入设备
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    }
    //添加输出设备
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    // 条码类型 二维码AVMetadataObjectTypeQRCode,条形码AVMetadataObjectTypeEAN13Code,人脸AVMetadataObjectTypeFace
    _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode93Code];
    
    //预览Preview
    _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    
    //设置预览图层的属性填充方式
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    // 设置preview图层的大小和捕获视图一样
    _preview.frame = _captureView.bounds;
    
    // 将预览图层添加到视图的图层
    [_captureView.layer insertSublayer:_preview above:0];
    
    [self createMask];
    [self setupScanView];
    [self setupScanRect];
    [_session startRunning];
    
}


// 创建正方形镂空遮盖
- (void)createMask {
    // 创建一个贝塞尔曲线路径
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.view.bounds];
    
    CGFloat screeW = [UIScreen mainScreen].bounds.size.width;
    CGFloat x = ZLScanViewX;
    CGFloat y = ZLScanViewY;
    CGFloat w = screeW - x * 2;
    
    _cropRect = CGRectMake(x, y, w, w);
    
    // 起点，也是终点
    CGPoint topLeftP = CGPointMake(x,y);
    CGPoint topRightP = CGPointMake(screeW - x, y);
    CGPoint bottomRightP = CGPointMake(x + w, y + w);
    CGPoint bottomLeftP = CGPointMake(x, y + w);
    
    // 绘制路径
    [path moveToPoint:topLeftP];
    [path addLineToPoint:topRightP];
    [path addLineToPoint:bottomRightP];
    [path addLineToPoint:bottomLeftP];
    [path addLineToPoint:topLeftP];
    
    // 使用奇偶填充规则
    path.usesEvenOddFillRule = YES;
    
    // 创建一个形状图层
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    // 设置路径
    shapeLayer.path = path.CGPath;
    // 线条颜色
    shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    // 线条宽度
    shapeLayer.lineWidth = 1;
    //填充颜色，只要不是透明的
    shapeLayer.fillColor = [UIColor blackColor].CGColor;
    // 填充规则，‘fill-rule’ 属性用于指定使用哪一种算法去判断画布上的某区域是否属于该图形“内部” （内部区域将被填充）。对一个简单的无交叉的路径，哪块区域是“内部” 是很直观清除的。但是，对一个复杂的路径，比如自相交或者一个子路径包围另一个子路径，“内部”的理解就不那么明确了。
    // 设置为 kCAFillRuleEvenOdd 才能镂空
    shapeLayer.fillRule = kCAFillRuleEvenOdd;
    
    //把shapeLayer的透明度改为0.5，直接添加layer也一样
    shapeLayer.opacity = 0.5;
    [self.view.layer addSublayer:shapeLayer];
}

// 设置扫描的View四个角
- (void)setupScanView {
    CGFloat w = 15.0;
    CGFloat h = 2.0;
    CGFloat offset = 3.0;
    
    CGFloat cropMinX = CGRectGetMinX(_cropRect);
    CGFloat cropMaxX = CGRectGetMaxX(_cropRect);
    
    CGFloat cropMinY = CGRectGetMinY(_cropRect);
    CGFloat cropMaxY = CGRectGetMaxY(_cropRect);
    
    CGRect r1 = CGRectMake(cropMinX - offset, cropMinY - offset, w, h);
    CGRect r2 = CGRectMake(cropMinX - offset, cropMinY - offset, h, w);
    CGRect r3 = CGRectMake(cropMaxX - w + offset, cropMinY - offset, w, h);
    CGRect r4 = CGRectMake(cropMaxX + 1, cropMinY, h, w);
    CGRect r5 = CGRectMake(cropMinX - offset, cropMaxY - w + offset, h, w);
    CGRect r6 = CGRectMake(cropMinX, cropMaxY + 1, w, h);
    CGRect r7 = CGRectMake(cropMaxX + 1, cropMaxY - w + offset, h, w);
    CGRect r8 = CGRectMake(cropMaxX - w, cropMaxY + 1, w, h);
    
    [self addShapeLayer:r1];
    [self addShapeLayer:r2];
    [self addShapeLayer:r3];
    [self addShapeLayer:r4];
    [self addShapeLayer:r5];
    [self addShapeLayer:r6];
    [self addShapeLayer:r7];
    [self addShapeLayer:r8];
    
}

// 添加一个图层
- (void)addShapeLayer:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:rect];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = path.CGPath;
    shapeLayer.strokeColor = self.scanLineColor.CGColor;
    shapeLayer.lineWidth = 3;
    shapeLayer.fillColor = [UIColor clearColor].CGColor;
    shapeLayer.fillRule = kCAFillRuleNonZero;
    [self.view.layer addSublayer:shapeLayer];
}

- (void)setupMyQRCodeButton {
    if (!self.showMyQRCodeButton) {
        return;
    }
    
    _myQRCodeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cropRect.origin.x, CGRectGetMaxY(self.cropRect) + 10, self.cropRect.size.width,30)];
    
    [_myQRCodeButton setTitleColor: self.myQRCodeButtonTitleColor ? self.myQRCodeButtonTitleColor : self.scanLineColor forState:UIControlStateNormal];
    [_myQRCodeButton setTitle:@"我的二维码" forState:UIControlStateNormal];
    [_myQRCodeButton addTarget:self action:@selector(myQRCodeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    _myQRCodeButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:_myQRCodeButton];
}

- (void)myQRCodeButtonClick {
    if ([self.delegate respondsToSelector:@selector(scanQRCodeViewController:createMyQRCodeFromString:)]) {
        [self.delegate scanQRCodeViewController:self createMyQRCodeFromString:^UIImage *(NSString *valueString) {
            UIImage *img = [ZLQRScanTool createQrImageWithString:valueString];
            return img;
        }];
    }
}
//  开始扫描
- (void)startScanning {
    [self.view.layer addSublayer:self.qrLineLayer];
    [self.qrLineLayer addAnimation:self.anim forKey:nil];
    [_session startRunning];
}


// 停止扫描
- (void)stopScanning {
    //停止扫描
    [_session stopRunning];
    // 停止动画
    [self.qrLineLayer removeAllAnimations];
    [self.qrLineLayer removeFromSuperlayer];
}
// 设置扫描范围
- (void)setupScanRect {
    //扫描框位置
    CGSize size = _preview.bounds.size;
    CGFloat p1 = size.width;
    CGFloat p2 = 1920.0/1080.0;  //使用了1080p的图像输出
    if (p1 < p2) {
        CGFloat fixHeight = size.width * 1920.0 / 1080.0;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        _output.rectOfInterest = CGRectMake((_cropRect.origin.y + fixPadding)/fixHeight,
                                            _cropRect.origin.x/size.width,
                                            _cropRect.size.height/fixHeight,
                                            _cropRect.size.width/size.width);
    } else {
        CGFloat fixWidth = size.height * 1080.0 / 1920.0;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        _output.rectOfInterest = CGRectMake(_cropRect.origin.y/size.height,
                                            (_cropRect.origin.x + fixPadding)/fixWidth,
                                            _cropRect.size.height/size.height,
                                            _cropRect.size.width/fixWidth);
    }
}

// 设置导航栏半透明
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - AVCaptureOutputDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if ([metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        NSString *stringValue = metadataObject.stringValue;
        [self handleQRCodeValue:stringValue codeType:metadataObject.type];
    }
}

// 获取到值以后的处理
- (void)handleQRCodeValue:(NSString *)stringValue codeType:(NSString *)type {
    if ([self.delegate respondsToSelector:@selector(scanQRCodeViewController:codeType:handleQRCodeValue:stopScanHandle:)]) {
        __weak typeof(self) wSelf = self;
        [self.delegate scanQRCodeViewController:self codeType:type handleQRCodeValue:stringValue stopScanHandle:^(BOOL isStopScan) {
            if (isStopScan) {
                [wSelf stopScanning];
            }
        }];
    }
}

// 从相册获取不到二维码的处理
- (void)fromPhotoAlbumGetQRCodeError:(UIImagePickerController *)pickerController {
    if ([self.delegate respondsToSelector:@selector(scanQRCodeViewController:photoAlbumGetQRCodeError:)]) {
        [self.delegate scanQRCodeViewController:self photoAlbumGetQRCodeError:pickerController];
    } else {
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:@"没有发现二维码" preferredStyle:UIAlertControllerStyleAlert];
        
        [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
        
        [pickerController presentViewController:alertCtr animated:YES completion:nil];
    }
}



@end
