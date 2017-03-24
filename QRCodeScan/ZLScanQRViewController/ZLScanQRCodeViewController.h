//
//  ScanQRCodeViewController.h
//  QRCodeScan
//
//  Created by 张磊 on 16/6/22.
//  Copyright © 2016年 lei. All rights reserved.
//
/**
 二维码扫描到主界面
 */

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class ZLScanQRCodeViewController;

@protocol ZLScanQRCodeViewControllerDelegate <NSObject>
@optional
/**
 *   获取到二维码值以后的处理
 *
 *  @param type           码类型，二维码:AVMetadataObjectTypeQRCode, 条形码:AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode93Code，人脸AVMetadataObjectTypeFace
 *  @param stringValue    码值
 *  @param handle         block操作是否停止扫描
 */
- (void)scanQRCodeViewController:(ZLScanQRCodeViewController *)viewController codeType:(NSString *)type handleQRCodeValue:(NSString *)stringValue stopScanHandle:(void(^)(BOOL isStopScan))stopScanHandle;

/** 从相册获取不到二维码的处理，如果实现，则弹出UIAlertController警告 **/
- (void)scanQRCodeViewController:(ZLScanQRCodeViewController *)viewController photoAlbumGetQRCodeError:(UIImagePickerController *)pickerController;

/** 单击我的二维码的时候调用,需要生成我的二维码的字符串,block传字符串进去，返回字符串二维码 **/
- (void)scanQRCodeViewController:(ZLScanQRCodeViewController *)viewController createMyQRCodeFromString:(UIImage* (^)(NSString *valueString))handle;

@end

@interface ZLScanQRCodeViewController : UIViewController
/** 扫描动画的线条颜色，默认蓝色 **/
@property (nonatomic,strong) UIColor *scanLineColor;
/** 我的二维码字体颜色，默认和扫描条颜色(scanLineColor)一样 **/
@property (nonatomic,strong) UIColor *myQRCodeButtonTitleColor;
/** 显示导航栏右边按钮从相册获取,默认显示 **/
@property (nonatomic,assign) BOOL showNavigationRightItemFromPhotoAlbum;
/** 显示我的二维码按钮,默认显示 **/
@property (nonatomic,assign) BOOL showMyQRCodeButton;
/** 我的二维码按钮 **/
@property (nonatomic,strong) UIButton *myQRCodeButton;
/** 捕获会话 **/
@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic, weak) id<ZLScanQRCodeViewControllerDelegate> delegate;

/** 开始扫描,如果扫描停止，可以重新开始扫描 **/
- (void)startScanning;
/**  停止扫描  **/
- (void)stopScanning;
/******************************** 如果要继承此类，可以重写以下的方法  **********************************************/
/** 设置导航栏右边的item **/
- (void)setupNavigationItem;
/** 创建"我的二维码"按钮  **/
- (void)setupMyQRCodeButton;
/**  点击我的二维码的时候调用 **/
- (void)myQRCodeButtonClick;
@end
