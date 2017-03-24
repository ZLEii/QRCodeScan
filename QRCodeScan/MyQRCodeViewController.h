//
//  MyQRCodeViewController.h
//  QRCodeScan
//
//  Created by 张磊 on 16/6/23.
//  Copyright © 2016年 lei. All rights reserved.
//
/**
 这个类展示生成的二维码，以及保存二维码到相册
 */

#import <UIKit/UIKit.h>

@interface MyQRCodeViewController : UIViewController
// 二维码图片
@property (nonatomic,strong) UIImage *image;
@end
