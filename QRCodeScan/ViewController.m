//
//  ViewController.m
//  QRCodeScan
//
//  Created by 张磊 on 16/6/22.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "ViewController.h"
#import "ZLScanQRCodeViewController.h"
#import "MyQRCodeViewController.h"

@interface ViewController () <ZLScanQRCodeViewControllerDelegate>
//显示扫描到的二维码值
@property (nonatomic,strong) UITextView *qrTextView;
@end

@implementation ViewController

- (UITextView *)qrTextView {
    if (!_qrTextView) {
        _qrTextView = [[UITextView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:_qrTextView];
        _qrTextView.backgroundColor = [UIColor clearColor];
        _qrTextView.font = [UIFont systemFontOfSize:20];
        _qrTextView.editable = NO;
    }
    return _qrTextView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
}

// 点击扫一扫
- (IBAction)scanBtnClick:(UIBarButtonItem *)sender {
    // 创建扫描控制器
    ZLScanQRCodeViewController *vc = [[ZLScanQRCodeViewController alloc] init];
    // 设置扫描线的颜色
    vc.scanLineColor = [UIColor greenColor];
    // ‘我的二维码’按钮字体颜色
    vc.myQRCodeButtonTitleColor = [UIColor whiteColor];
    // 代理方法
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

/**
 获取到二维码值以后的处理
@param codeType: 二维码类型
@param handleQRCodeValue:二维码值
@param 是否要停止扫描，如果不停止，会一直扫描
 */
#pragma mark - ZLScanQRCodeViewController Delegate/
- (void)scanQRCodeViewController:(ZLScanQRCodeViewController *)viewController codeType:(NSString *)type handleQRCodeValue:(NSString *)stringValue stopScanHandle:(void (^)(BOOL))stopScanHandle {
     NSLog(@"stringValue = %@",stringValue);
    if ([type isEqualToString:AVMetadataObjectTypeQRCode]) {    // 如果是二维码
        stopScanHandle(YES);
        self.qrTextView.text = [NSString stringWithFormat:@"二维码:\n%@",stringValue];
        [self.navigationController popToRootViewControllerAnimated:YES];
        if ([stringValue hasPrefix:@"https://"] || [stringValue hasPrefix:@"http://"]) {
            if( ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:stringValue]] ) {
                return;
            }
            NSString *msg = [NSString stringWithFormat:@"是否打开 %@",stringValue];
            UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:msg preferredStyle:UIAlertControllerStyleAlert];
            
            [alertCtr addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringValue]];
            }]];
            [self presentViewController:alertCtr animated:YES completion:nil];
        }
    } else {    // 条形码
        self.qrTextView.text = [NSString stringWithFormat:@"条形码:\n%@",stringValue];
        stopScanHandle(NO);
    }
}



/**
 生成二维码：
 @param handle block传字符串进去，返回字符串二维码图片
 */
- (void)scanQRCodeViewController:(ZLScanQRCodeViewController *)viewController createMyQRCodeFromString:(UIImage *(^)(NSString *))handle {
    UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:@"请输入要生成二维码的文字" preferredStyle:UIAlertControllerStyleAlert];
    [alertCtr addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
       textField.placeholder = @"请输入文字";
    }];
    
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    __weak typeof(self) wSelf = self;
    [alertCtr addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       NSString *text = alertCtr.textFields[0].text;
        UIImage *img = handle(text);
        MyQRCodeViewController *vc = [[MyQRCodeViewController alloc] init];
        vc.image = img;
        [wSelf.navigationController popViewControllerAnimated:NO];
        [wSelf.navigationController pushViewController:vc animated:YES];
        
    }]];
    
    [self presentViewController:alertCtr animated:YES completion:nil];
}

@end
